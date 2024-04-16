## Project Overview

This project is about predicting the future closing prices of tokens in the blockchain space using a sequence model implemented in Python.

A sequence model is a type of machine learning model that's great for making predictions based on a series of data points. In this project, we use it to analyze historical token prices and predict future ones.

## Running the Project

To run the project, you need to have python 3.11 or higher installed on your machine. You can download it from the [official website](https://www.python.org/downloads/).

After installing python, you can clone the project repository and navigate to the project directory in your terminal. Then, run the following command to install the required dependencies:

```bash
pip install -r requirements.txt
```

Once the dependencies are installed, you can run the project using the following command:

```bash
jupyter notebook model.ipynb
```

This will open the Jupyter notebook in your browser, where you can see the code and run it to make predictions.

## Deploy to AWS Fargate

### Prerequisites

- An AWS account
- The AWS CLI installed and configured (configure it with your AWS credentials by running `aws configure`)
- Docker
- Terraform

### Steps

1. Create an ECR repository to store the Docker image

    ```bash
    aws ecr create-repository --repository-name your-repository-name --image-scanning-configuration scanOnPush=true --region your-region
    ```

2. Build the Docker image

    ```bash
    docker build -t your-aws-account-id.dkr.ecr.your-region.amazonaws.com/your-repository-name:latest .
    ```

3. Authenticate Docker to your ECR repository

    ```bash
    aws ecr get-login-password --region your-region | docker login --username AWS --password-stdin your-aws-account-id.dkr.ecr.your-region.amazonaws.com
    ```

4. Push the Docker image to your ECR repository

    ```bash
    docker push your-aws-account-id.dkr.ecr.your-region.amazonaws.com/your-repository-name:latest
    ```

5. Fill in all variables in `fargate.tf`

6. Deploy the Fargate service

    ```bash
    terraform init
    terraform apply
    ```

    The endpoint of the model should be `http://ecs-task-public-ip:8501/v1/models/TokenPricePredictionModel:predict`.
