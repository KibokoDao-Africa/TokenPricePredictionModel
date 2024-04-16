FROM tensorflow/serving:2.16.1

# Copy the saved model to the models directory
COPY ./TokenPricePredictionModel /models/TokenPricePredictionModel

# Update the MODEL_NAME environment variable
ENV MODEL_NAME=TokenPricePredictionModel
