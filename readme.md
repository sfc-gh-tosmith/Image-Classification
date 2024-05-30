## Overview
#### In this Hands-on-Lab, you will create an image classification service that runs in Snowpark Container Services. You will also create a file processing pipeline using streams, tasks, and a UDF. 

<img width="1173" alt="Screenshot 2024-05-29 at 1 24 39 PM" src="https://github.com/sfc-gh-tosmith/image-classification-spcs/assets/168590825/430a5f51-791d-4e8e-bde9-02e10f21b741">


### This Hands-on-Lab has two parts. 
- Part 1: local development/testing of the container
- Part 2: creating the SPCS service and image processing pipeline through the Snowsight UI.

## Part 1 - Local testing
The service that we will be running is a Flask API that utilizes a Tensorflow model to classify American Sign Language numbers from images. This service was written in Python, but it is import to know that SPCS can run containers with code written in **any language, with any package**. Awesome, right!?

We will start by running the code for the Flask server locally.
First, create a conda environment by typing this in your terminal. If you do not have conda already installed, follow the [install directions on the official conda website](https://conda.io/projects/conda/en/latest/user-guide/install/index.html).
```
  conda create -n "image-classification-spcs" python=3.9
```
Activate your new environment by entering 
```
  conda activate image-classification-spcs
```
Install the necessary dependencies by typing
```
  conda install --yes --file requirements.txt
```
Test the flask app by running
```
  python3 app.py
```
Go to [localhost:5000/healthcheck](localhost:5000/healthcheck) and it should say "I'm ready"

##### Optional:
Using an API request tool like Postman, build a POST request to [localhost:5000/prediction](localhost:5000/prediction). Copy the example_request.json file contents into the body of the request. Send it, and the response should look something like this:
```json
{
    "data": [
        [
            0,
            "3"
        ]
    ]
}
```

## Part 2 - Create SPCS Service and file processing ipeline
For part 2, follow the **setup.sql** file. In this file you will:
- Create a database, schema, and stages
- Create a compute pool to run your service on
- Build and push the docker container from your local machine into Snowflake
- Create the image classification service, running in Snowpark Container Services
- Create a function to interact with the running service
- Build the stream, UDF, and task for the file processing pipeline

### Possible changes and improvements
- Use dynamic tables instead of a stream and task
- Access and process the image file directly in the container, rather than with the stream, task, UDF pipeline

### Acknowledgments
This lab brings together content from the following sources:
- [SPCS Tutorial - Level 1](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/tutorials/tutorial-1)
- [Creating a file processing pipeline in Snowflake](https://docs.snowflake.com/en/user-guide/data-load-dirtables-pipeline)
- [Image Classification using Tensorflow and Flask](https://geekpython.in/flask-app-for-image-recognition#google_vignette)
