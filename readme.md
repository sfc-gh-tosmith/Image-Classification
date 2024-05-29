based heavily on this link: https://docs.snowflake.com/en/developer-guide/snowpark-container-services/tutorials/tutorial-1 and https://docs.snowflake.com/en/user-guide/data-load-dirtables-pipeline and https://geekpython.in/flask-app-for-image-recognition#google_vignette

First, create a conda environment by typing this in your terminal

conda create -n "image-classification-spcs" python=3.9

Activate by typing 

conda activate image-classification-spcs

Install the necessary dependencies by typing

conda install --yes --file requirements.txt

Test the flask app by running

python3 app.py

Go to localhost:5000/healthcheck and it should say "I'm ready"

Using an API request tool like Postman, build a request that looks like the one in the example_request.json file. The contents of the file should be the raw body of the request.