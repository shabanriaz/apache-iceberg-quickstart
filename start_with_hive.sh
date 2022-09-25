# bin/bash

docker build -t hive-metastore:latest . -f hive-metastore.Dockerfile
docker build -t spark-iceberg-hive . -f icerberg-hive.Dockerfile
docker compose -f docker-compose-iceberg-hive.yml up