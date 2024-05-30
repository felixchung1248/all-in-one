#----------------------------------
# IMPORTS
#----------------------------------
import sqlalchemy as db
import pandas as pd
from pyspark.sql import SparkSession
from pyspark.sql.types import *
import requests
from flask import Flask,request

from langchain.agents import create_spark_sql_agent
from langchain_community.agent_toolkits import SparkSQLToolkit
from langchain_community.utilities.spark_sql import SparkSQL
from langchain_openai import ChatOpenAI
from langchain_core import exceptions
import re
import os

#----------------------------------
# Setup
#----------------------------------
app = Flask(__name__)
denodo_url=os.environ['DENODO_URL']
genai_model=os.environ['GENAI_MODEL']


# Initialize Spark session
spark = SparkSession.builder \
    .appName("DenodoToSparkSQLExample") \
    .config('spark.network.timeout', '800s') \
    .config('spark.executor.heartbeatInterval', '120s') \
    .getOrCreate()
schema = "langchain_example"
spark.sql(f"CREATE DATABASE IF NOT EXISTS {schema}")
spark.sql(f"USE {schema}")   

engine=db.create_engine(denodo_url)   
    
def cache_views():
    result_proxy = engine.execute("LIST VIEWS ALL")
    views = result_proxy.fetchall()

    # Iterate over the result set and print each row
    for row in views:
        view_name = row[0]  
        # Pandas DataFrame
        result_proxy = engine.execute(f"select * from {view_name}")
        pandas_df = pd.DataFrame(result_proxy.fetchall())   
        # Convert the Pandas DataFrame to a Spark DataFrame
        spark_df = spark.createDataFrame(pandas_df) 
        # Write the Spark DataFrame to a Spark table
        spark_df.write.saveAsTable(view_name)
        
    cached_views_as_turple = set((view[0], ) for view in views)
    return cached_views_as_turple
    
cached_views_as_turple = cache_views() 

print(cached_views_as_turple)


    
spark_sql = SparkSQL(schema=schema)
llm = ChatOpenAI(model=genai_model,temperature=0)
toolkit = SparkSQLToolkit(db=spark_sql, llm=llm)
agent_executor = create_spark_sql_agent(llm=llm, toolkit=toolkit, verbose=True,handle_parsing_errors=True) 

@app.route('/genai-response', methods=['POST'])
def genAiResponse():
    global cached_views_as_turple
    # Get the JSON from the POST request body
    try:   
        result_proxy = engine.execute("LIST VIEWS ALL")
        views = result_proxy.fetchall()
        views_as_turple_cur = set((view[0], ) for view in views)
        print(cached_views_as_turple)
        print(views_as_turple_cur)
        new_views = [d for d in views_as_turple_cur if d not in cached_views_as_turple]
        print(new_views)
        for view in new_views:
            result_proxy = engine.execute(f"select * from {view}")
            pandas_df = pd.DataFrame(result_proxy.fetchall())   
            # Convert the Pandas DataFrame to a Spark DataFrame
            spark_df = spark.createDataFrame(pandas_df) 
            # Write the Spark DataFrame to a Spark table
            spark_df.write.saveAsTable(view_name)


        json_array = request.get_json()
        msg = json_array.get('msg')       
        result = agent_executor.run(msg)
        return result
    except exceptions.OutputParserException as e:
        # Handle the specific OutputParserException
        error_message = str(e)
        print(f"OutputParserException caught: {error_message}", flush=True)
        # Extract meaningful error message if it matches the expected pattern
        if error_message.startswith("Could not parse LLM output: `"):
            error_message = error_message.removeprefix("Could not parse LLM output: `").removesuffix("`")
        #return jsonify({"error": "Output parsing error", "details": error_message}), 500
    except ValueError as e:
        # Handle any other ValueError that might be related to parsing
        error_message = str(e)
        print(f"ValueError caught: {error_message}", flush=True)
        match = re.search(r"Could not parse LLM output: `([^`]*)`", error_message)

        # Check if we found a match
        if match:
            extracted_message = match.group(1)  # This is "I don't know"
            return(extracted_message)
        else:
            return("I don't know")
        #return jsonify({"error": "ValueError", "details": error_message}), 500
    except Exception as e:
        # General exception handler for any unexpected exceptions
        error_message = str(e)
        print(f"Unexpected error caught: {error_message}", flush=True)
        #return jsonify({"error": "Unexpected error", "details": error_message}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5201)