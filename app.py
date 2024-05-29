# Importing required libs
from flask import Flask, request, make_response
from model import predict_result
from logging.config import dictConfig
import json
import logging
import sys

def get_logger(logger_name):
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.DEBUG)
    handler.setFormatter(
        logging.Formatter(
            '%(name)s [%(asctime)s] [%(levelname)s] %(message)s'))
    logger.addHandler(handler)
    return logger

logger = get_logger('image-service')


# Instantiating flask app
app = Flask(__name__)
 
@app.get("/healthcheck")
def readiness_probe():
    return "I'm ready!"
 
@app.route('/yes')
def yes():
    return 'yes'
 
# Prediction route
@app.route('/prediction', methods=['POST'])
def prediction():

    if request.method == 'POST':
        try:
            message = request.json
            logger.debug(f'Received request: {message}')


            if message is None or not message['data']:
                logger.info('Received empty message')
                return {}
            
            input_rows = message['data']
            logger.info(f'Received {len(input_rows)} rows')

            output_rows = [[row[0], predict_result(row[1])] for row in input_rows]
            logger.info(f'Produced {len(output_rows)} rows')
            response = make_response({"data": output_rows})
            response.headers['Content-type'] = 'application/json'
            logger.debug(f'Sending response: {response.json}')
            return response
        
        except Exception as e:
            response = make_response({"data": [[0,f'ERROR: {e} Likely a problem with image type']]})
            response.headers['Content-type'] = 'application/json'
            logger.debug(f'Sending response: {response.json}')
            return response
 
# Driver code
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)