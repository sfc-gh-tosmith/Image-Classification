ARG BASE_IMAGE=python:3.10-slim-buster
FROM $BASE_IMAGE
COPY app.py ./
COPY model.py ./
COPY digit_model.h5 ./
RUN pip install --upgrade pip && \
    pip install flask \
    pip install tensorflow==2.10.0 \
    pip install Pillow
CMD ["python3", "app.py"]

