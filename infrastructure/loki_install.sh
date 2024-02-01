#!/bin/bash

# Выполнить первую команду и сохранить вывод в переменную
output=$(yc iam access-key create --service-account-name=momo-store-service-account)

# Извлечь значения access_key и secret из вывода
access_key=$(echo $output | awk '/access_key:/ {print $3}')
secret=$(echo $output | awk '/secret:/ {print $2}')

# Вставить значения во вторую команду и выполнить её
helm install \
  --namespace monitoring \
  --create-namespace \
  --set loki-distributed.loki.storageConfig.aws.bucketnames=loki-dmitryz-bucket \
  --set loki-distributed.serviceaccountawskeyvalue_generated.accessKeyID=$access_key \
  --set loki-distributed.serviceaccountawskeyvalue_generated.secretAccessKey=$secret \
  loki ./loki/
