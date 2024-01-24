#!/bin/bash
# экспорт ключей для кранения terraform state

export AWS_SECRET_ACCESS_KEY=$(terraform output -raw s3-secret-key)
export AWS_ACCESS_KEY_ID=$(terraform output -raw s3-access-key)