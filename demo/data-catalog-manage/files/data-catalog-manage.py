from flask import Flask, request, jsonify
import requests
import logging
import os
from requests.auth import HTTPBasicAuth
import json

app = Flask(__name__)
datahub_url = os.environ['DATAHUB_URL']

# Function to retrieve value by key
def get_value_by_key(data, search_key):
    for item in data:
        if item['key'] == search_key:
            return item['value']
    return None  # Return None if the key is not found

@app.after_request
def after_request(response):
    # Only add CORS headers if the Origin header exists and is from localhost
    origin = request.headers.get('Origin')
    if origin and 'localhost' in origin:
        # Add CORS headers to the response
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

@app.route('/listalldatacatalogdatasets', methods=['GET'])
def ListAllDataCatalogDatasets():
    final_list = []
    query = """
                {
                  search(input: { type: DATASET, query: "*", start: 0, count: 9999 }) {
                    start
                    count
                    total
                    searchResults {
                      entity {
                         urn
                         type
                         ...on Dataset {
                            name
                         }
                      }
                    }
                  }
                }
            """
    headers = {
                'Content-Type': 'application/json'
            }
    
    payload = {
        'query': query
    }

    graphqlUrl = f"{datahub_url}/api/graphql"
    response = requests.post(graphqlUrl, headers=headers, data=json.dumps(payload))

    if response.status_code == 200:
        response_json = response.json()
        view_list = response_json['data']['search']['searchResults']
        for item in view_list:
            dataset_name = item['entity']['name']
            
            # urn_str = item['entity']['urn'].split('(')[1].split(')')[0]
            # urn_itm = urn_str.split(',')
            # dataset_name = urn_itm[1]


            query = f"""
                {{
                  dataset(urn: "{item['entity']['urn']}") {{
                  properties {{
                    description
                    ,customProperties{{
                         key,value
                    }}
                  }}
                    ownership 
                    {{
                      owners 
                      {{
                        owner 
                        {{
                          ... on CorpUser 
                          {{
                            urn
                            type
                          }}
                          ... on CorpGroup 
                          {{
                            urn
                            type
                          }}
                        }}
                      }}
                    }}
                  }}
                }}
            """
            payload = {
                'query': query
            }
            response = requests.post(graphqlUrl, headers=headers, data=json.dumps(payload))
            response_json = response.json()
            data = response_json['data']
            dataset = data['dataset']
            ownership = dataset['ownership']
            owners = ownership['owners']
            table_description = dataset['properties']['description']
            rating = get_value_by_key(dataset['properties']['customProperties'],'rating')
            rating = rating if int(rating) > -1 else 'No rating'

            for owner in owners:
                user_urn = owner['owner']['urn']
                response = requests.get(f"{datahub_url}/entities/{user_urn}", headers=headers)
                response_json = response.json()
                owner_aspects = response_json['value']['com.linkedin.metadata.snapshot.CorpUserSnapshot']['aspects']

                for item in owner_aspects:
                    if "com.linkedin.identity.CorpUserEditableInfo" in item:
                        user_info = item["com.linkedin.identity.CorpUserEditableInfo"]
                        owner_name = user_info.get("displayName", "Name not found")
                        break
                    else:
                        owner_name = "Name not found"
                owner['owner_name'] = owner_name
            info = {"dataset_name": dataset_name, "owners": owners, "table_description": table_description, "rating": rating}
            final_list.append(info)
         
        return jsonify(final_list)   
    else:
        print(f"Failed to get metadata for dataset: {response.content}")
        return "Error occurred", 400

    

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7011)

    
