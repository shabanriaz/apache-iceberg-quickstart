FROM python:3.9-bullseye

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      sudo \
      curl \
      vim \
      unzip \
      openjdk-11-jdk \
      build-essential \
      software-properties-common \
      ssh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Jupyter and other python deps
COPY requirements.txt .
RUN pip3 install -r requirements.txt

# Add scala kernel via spylon-kernel
RUN python3 -m spylon_kernel install

# Download and install IJava jupyter kernel
RUN curl https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip -Lo ijava-1.3.0.zip \
  && unzip ijava-1.3.0.zip \
  && python3 install.py --sys-prefix \
  && rm ijava-1.3.0.zip

## Download spark and hadoop dependencies and install

# Optional env variables
ENV SPARK_HOME=${SPARK_HOME:-"/opt/spark"}

RUN mkdir -p ${SPARK_HOME}
WORKDIR ${SPARK_HOME}

# Download spark
RUN curl https://dlcdn.apache.org/spark/spark-3.3.0/spark-3.3.0-bin-hadoop3.tgz -o spark-3.3.0-bin-hadoop3.tgz \
 && tar xvzf spark-3.3.0-bin-hadoop3.tgz --directory /opt/spark --strip-components 1 \
 && rm -rf spark-3.3.0-bin-hadoop3.tgz

# Download postgres connector jar
RUN curl https://jdbc.postgresql.org/download/postgresql-42.2.24.jar -o postgresql-42.2.24.jar \
 && cp postgresql-42.2.24.jar /opt/spark/jars \
 && rm postgresql-42.2.24.jar

# Download iceberg spark runtime
RUN curl https://search.maven.org/remotecontent?filepath=org/apache/iceberg/iceberg-spark-runtime-3.3_2.12/0.14.1/iceberg-spark-runtime-3.3_2.12-0.14.1.jar -Lo iceberg-spark-runtime-3.3_2.12-0.14.1.jar \
 && mv iceberg-spark-runtime-3.3_2.12-0.14.1.jar /opt/spark/jars

# Download Java AWS SDK
#RUN curl https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/2.17.165/bundle-2.17.165.jar -Lo bundle-2.17.165.jar \
# && mv bundle-2.17.165.jar /opt/spark/jars

# Download URL connection client required for S3FileIO
#RUN curl https://repo1.maven.org/maven2/software/amazon/awssdk/url-connection-client/2.17.165/url-connection-client-2.17.165.jar -Lo url-connection-client-2.17.165.jar \
# && mv url-connection-client-2.17.165.jar /opt/spark/jars

# Install AWS CLI
#RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
# && unzip awscliv2.zip \
# && sudo ./aws/install \
# && rm awscliv2.zip \
# && rm -rf aws/

# Add iceberg spark runtime jar to IJava classpath
ENV IJAVA_CLASSPATH=/opt/spark/jars/*

RUN mkdir -p /home/iceberg/localwarehouse /home/iceberg/notebooks /home/iceberg/warehouse /home/iceberg/spark-events /home/iceberg /home/datalake/
COPY sample_data/ /home/datalake/

# Add a notebook command
RUN echo '#! /bin/sh' >> /bin/notebook \
 && echo 'export PYSPARK_DRIVER_PYTHON=jupyter-notebook' >> /bin/notebook \
 && echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"--notebook-dir=/home/iceberg/notebooks --ip='*' --NotebookApp.token='' --NotebookApp.password='sha256:4f89800f267c:09f0bc77e2e868b981b61fba4e2ea0f0afa41082d0662dcd9ca4d740758bd468' --port=8888 --no-browser --allow-root\"" >> /bin/notebook \
 && echo "pyspark --packages org.apache.spark:spark-avro_2.12:3.3.0" >> /bin/notebook \
 && chmod u+x /bin/notebook

COPY conf/spark-defaults.conf /opt/spark/conf
ENV PATH="/opt/spark/sbin:/opt/spark/bin:${PATH}"
ENV SPARK_HOME="/opt/spark"

RUN chmod u+x /opt/spark/sbin/* && \
    chmod u+x /opt/spark/bin/*

COPY scripts/entrypoint_iceberg.sh ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
CMD ["notebook"]