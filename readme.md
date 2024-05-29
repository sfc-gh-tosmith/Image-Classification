

<img width="1173" alt="Screenshot 2024-05-29 at 1 24 39 PM" src="https://github.com/sfc-gh-tosmith/image-classification-spcs/assets/168590825/430a5f51-791d-4e8e-bde9-02e10f21b741">
Based heavily on this link: https://docs.snowflake.com/en/developer-guide/snowpark-container-services/tutorials/tutorial-1 and https://docs.snowflake.com/en/user-guide/data-load-dirtables-pipeline and https://geekpython.in/flask-app-for-image-recognition#google_vignette

This Hands-on-Lab has two parts. Part 1: the local development of the container. Part 2: creating the SPCS service and image processing pipeline through the Snowsight UI.

**Part 1:**
First, create a conda environment by typing this in your terminal

  conda create -n "image-classification-spcs" python=3.9

Activate by typing 

  conda activate image-classification-spcs

Install the necessary dependencies by typing

  conda install --yes --file requirements.txt

Test the flask app by running

  python3 app.py

Go to localhost:5000/healthcheck and it should say "I'm ready"

Optional:
Using an API request tool like Postman, build a request that looks like the one in the example_request.json file. The contents of the file should be the raw body of the request.

**Part 2:**
For part 2, follow the setup.sql file. 
