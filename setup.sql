USE ROLE ACCOUNTADMIN;

-- Create role for HOL
CREATE ROLE SPCS_HOL_ROLE;

-- Create database for HOL
CREATE DATABASE IF NOT EXISTS SPCS_HOL_DB;
-- Give new role ownership of HOL database
GRANT OWNERSHIP ON DATABASE SPCS_HOL_DB TO ROLE SPCS_HOL_ROLE COPY CURRENT GRANTS;

-- Create warehouse to use for HOL
CREATE OR REPLACE WAREHOUSE SPCS_HOL_WH WITH
  WAREHOUSE_SIZE='X-SMALL';
-- Allow HOL role to use the HOL warehouse
GRANT USAGE ON WAREHOUSE SPCS_HOL_WH TO ROLE SPCS_HOL_ROLE;

-- Create a compute pool for our HOL service and give the SPCS_HOL_ROLE permissions on it.
-- This size/type will use 0.11 credits/hour
CREATE COMPUTE POOL SPCS_HOL_COMPUTE_POOL
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS;
GRANT USAGE, MONITOR ON COMPUTE POOL SPCS_HOL_COMPUTE_POOL TO ROLE SPCS_HOL_ROLE;

-- Give role ability to bind service endpoints to services
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SPCS_HOL_ROLE;

-- Give role ability to turn tasks off and on
GRANT EXECUTE TASK ON ACCOUNT TO ROLE SPCS_HOL_ROLE;

-- Give the current user the SPCS_HOL_ROLE. Fill in your username.
GRANT ROLE SPCS_HOL_ROLE TO USER <insert_current_user_here>;

-- Create DB objects
USE ROLE SPCS_HOL_ROLE;
USE DATABASE SPCS_HOL_DB;
USE WAREHOUSE SPCS_HOL_WH;

-- Create schema for HOL
CREATE SCHEMA IF NOT EXISTS DATA_SCHEMA;

-- Create the image repository to hold the docker image for the service
CREATE IMAGE REPOSITORY IF NOT EXISTS HOL_IMAGE_REPOSITORY;

-- Create a stage to hold our .yml file and the UDF we will create for encoding images
CREATE STAGE IF NOT EXISTS HOL_STAGE
  DIRECTORY = ( ENABLE = true );

-- Create a stage to hold the .jpeg image files
CREATE OR REPLACE STAGE IMAGE_FILES
DIRECTORY = (ENABLE = TRUE AUTO_REFRESH = FALSE) 
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE') 
COMMENT='Stage to store Image Files';

-- Before moving forward, you must push your container image from your local machine.
-- to the HOL_IMAGE_REPOSITORY in your Snowflake account. Directions are below, but see 
-- the following link for more information: https://docs.snowflake.com/en/developer-guide/snowpark-container-services/tutorials/tutorial-1#build-an-image-and-upload

-- First find the repository_url for your image repository
SHOW IMAGE REPOSITORIES;

-- Build your container. In the terminal of your local machine, run:
--      "docker build --rm --platform linux/amd64 -t <repository_url>/<image_name> . " Don't forget the . at the end

-- Next, we will push the container to the Snowflake image repository. To do that, you need to authenticate. Run:
--      "docker login <registry_hostname> -u <username>" registry_hostname is the beginning of the repository_url, ending at snowflakecomputing.com
-- You will then be prompted for your password and authenticate with Snowflake

-- Now, push the container to the Snowflake image repository
--      "docker push <repository_url>/<image_name>"

-- After pushing the image, we need to upload the image-service.yml file into the HOL_STAGE. The easiest way to do this is
-- through the Snowsight UI. Navigate to the stage and upload image-service.yml from your local machine

-- Once the image is in Snowflake, we can create the IMAGE_CLASSIFIER_SERVICE based on the image-service.yml document 
-- and from the SPCS_HOL_COMPUTE_POOL.
CREATE SERVICE IMAGE_CLASSIFIER_SERVICE
IN COMPUTE POOL SPCS_HOL_COMPUTE_POOL
FROM @SPCS_HOL_DB.DATA_SCHEMA.HOL_STAGE
SPEC = 'image-service.yml';

-- Use these functions to see the status of the service and container logs.
-- Spinning up the container usually takes around a minute or less
SHOW SERVICES;
SELECT SYSTEM$GET_SERVICE_STATUS('IMAGE_CLASSIFIER_SERVICE');
CALL SYSTEM$GET_SERVICE_LOGS('IMAGE_CLASSIFIER_SERVICE', '0', 'image-service', 100);

-- Create a service function. This allows you to pass data to the service endpoint.
-- In our case, the endpoint is 'imageendpoint', as specified in our image-service.yml
-- '/prediction' refers to the path in our Flask API (see app.py)
CREATE OR REPLACE FUNCTION IMAGE_CLASSIFY_FUNCTION (InputText varchar)
  RETURNS varchar
  SERVICE=IMAGE_CLASSIFIER_SERVICE
  ENDPOINT=imageendpoint
  AS '/prediction';

-- At this point, you can test your function by running the below command.
-- Insert the utf-8 string from example_request.json (starts with /9j/4AAQ)
-- In a real world scenario/in the pipeline we will build, this will be dynamic. 
SELECT IMAGE_CLASSIFY_FUNCTION(<insert utf-8 encoded string here>);


------ Creating the pipeline ------

-- Create a UDF to turn a .jpeg image into UTF-8 string
CREATE OR REPLACE FUNCTION ENCODE_IMAGE(file_path string)
RETURNS string
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
HANDLER = 'encode_image'
PACKAGES = ('snowflake-snowpark-python')
AS
$$
import base64
from snowflake.snowpark.files import SnowflakeFile

def encode_image(file_path):
  with SnowflakeFile.open(file_path, 'rb') as image_file:
    b64_string = base64.b64encode(image_file.read())
  text_string = b64_string.decode('utf-8')

  return text_string
$$;

-- Create a stream on the directory table of the image stage
CREATE OR REPLACE STREAM IMAGE_STAGE_STREAM ON STAGE IMAGE_FILES;

-- Create a table to hold the image info and predictions
CREATE OR REPLACE TABLE SPCS_HOL_DB.DATA_SCHEMA.IMAGE_CLASSIFICATIONS (
  FILE_NAME VARCHAR,
  SIZE NUMBER,
  MD5 VARCHAR,
  SCOPED_FILE_URL VARCHAR,
  UTF_ENCODED_STRING_FIRST_50 VARCHAR,
  ASL_NUMBER_PREDICTION VARCHAR
);

-- Create a task to read from stream and write the classification prediction
-- and associated image data to table
CREATE OR REPLACE TASK CONVERT_AND_PREDICT_IMAGE
WAREHOUSE = 'SPCS_HOL_WH'
SCHEDULE = '1 minute'
COMMENT = 'Encode new .jpeg images on the stage, create prediction, and write the prediction w/ associated image data into the table.'
WHEN
SYSTEM$STREAM_HAS_DATA('IMAGE_STAGE_STREAM')
AS
INSERT INTO SPCS_HOL_DB.DATA_SCHEMA.IMAGE_CLASSIFICATIONS (
SELECT relative_path as file_name,
size,
md5,
build_scoped_file_url('@IMAGE_FILES', RELATIVE_PATH),
LEFT(ENCODE_IMAGE(build_scoped_file_url('@IMAGE_FILES', RELATIVE_PATH)),50) as UTF_ENCODED_STRING_FIRST_50,
IMAGE_CLASSIFY_FUNCTION(ENCODE_IMAGE(build_scoped_file_url('@IMAGE_FILES', RELATIVE_PATH))) as PREDICTION
FROM IMAGE_STAGE_STREAM
WHERE METADATA$ACTION='INSERT'
);
-- Start the task
ALTER TASK CONVERT_AND_PREDICT_IMAGE RESUME;
  

-- To demonstrate the pipeline, upload some of the .jpeg images to the image_files stage. Then, query the IMAGE_STAGE_STREAM
SELECT * FROM IMAGE_STAGE_STREAM;

-- Navigate to the CONVERT_AND_PREDICT_IMAGE task in Snowsight and click on the 'Run History' to see past, current and future runs of the task. 

-- Once it runs successully, see the results of your work!
SELECT * FROM IMAGE_CLASSIFICATIONS;