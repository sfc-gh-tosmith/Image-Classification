# Importing required libs
from keras.models import load_model
from keras.utils import img_to_array
import numpy as np
from PIL import Image
import io
import base64
 
# Loading model
model = load_model("./digit_model.h5")
 
 
# Predicting function
def predict_result(img_string):
    op_img = Image.open(io.BytesIO(base64.b64decode(img_string.encode('utf-8'))))
    img_resize = op_img.resize((224, 224))
    img2arr = img_to_array(img_resize) / 255.0
    img_reshape = img2arr.reshape(1, 224, 224, 3)
    pred = model.predict(img_reshape)
    return str(np.argmax(pred[0], axis=-1))