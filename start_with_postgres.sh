# bin/bash

docker build -t spark-iceberg . -f icerberg-postgres.Dockerfile
docker compose -f docker-compose-iceberg-postgres.yml up