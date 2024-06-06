from flask import Flask, request, jsonify
import requests
import logging
import os
from requests.auth import HTTPBasicAuth
from bs4 import BeautifulSoup
import json

app = Flask(__name__)
url = os.environ['ZAMMAD_URL']
username = os.environ['ZAMMAD_USR']
password = os.environ['ZAMMAD_PW']


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

@app.route('/listticket', methods=['GET'])
def ListTicket():
    logging.info('ListTicket function processed a request.')
    response = requests.get(
       f"{url}/api/v1/tickets/search?query=approved:false",
       auth=HTTPBasicAuth(username, password)
    )

    if response.status_code == 200:
       result = response.json()
       return result

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=6080)

    
