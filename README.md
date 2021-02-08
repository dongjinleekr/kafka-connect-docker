kafka-connect-docker (graalvm ce)
=====

Dockerfile for [Kafka Connect](http://kafka.apache.org/), based on [dongjinleekr/kafka-docker](https://github.com/dongjinleekr/kafka-docker) and in turn its upstream, [wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker).

This image includes the following connect plugins and converters:

plugins:

- kafka-connect-jdbc (with [mysql-connector-java](https://mvnrepository.com/artifact/mysql/mysql-connector-java))
- kafka-connect-hdfs

converters:

- avro-converter
- json-schema-converter
- protobuf-converter

Tags and releases
-----------------

| version | based on | mysql-connector-java | converters | plugins |
|:-------:|:--------:|:--------------------:|:----------:|:-------:|
| 2.13-2.5.1 | Kafka 2.13-2.5.1 | 8.0.22 | 5.5.2 | 5.5.2 |

# How to Run

The following configuration shows how to configure a kafka connect cluster with this Docker image in Kubernetes cluster, with a Kafka cluster available in `djlee-kafka-headless` service.

Note:

- For configuring Kafka cluster, see [here](https://github.com/dongjinleekr/kafka-docker).
- For configuring Schema Registry cluster, see [here](https://github.com/helm/charts/tree/master/incubator/schema-registry).
- **This configuration is intended for dev or testing purpose; it may be used in production environment, but I can't give any guarantees in that respect.**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: djlee-connect
  labels:
    app: djlee-connect
spec:
  replicas: 3
  selector:
    matchLabels:
      app: djlee-connect
  template:
    metadata:
      labels:
        app: djlee-connect
    spec:
      containers:
        - name: djlee-connect
          image: dongjinleekr/kafka-connect:2.13-2.5.1
          imagePullPolicy: IfNotPresent
          ports:
            - name: kafka-connect
              containerPort: 8083
              protocol: TCP
            - name: jmx
              containerPort: 9999
          env:
            - name: CONNECT_BOOTSTRAP_SERVERS
              value: "djlee-kafka-0.djlee-kafka-headless:9092,djlee-kafka-1.djlee-kafka-headless:9092,djlee-kafka-2.djlee-kafka-headless:9092,djlee-kafka-3.djlee-kafka-headless:9092"
            - name: CONNECT_GROUP_ID
              value: "djlee-connect"
            - name: CONNECT_CONFIG_STORAGE_TOPIC
              value: "connect-config"
            - name: CONNECT_OFFSET_STORAGE_TOPIC
              value: "connect-offsets"
            - name: CONNECT_STATUS_STORAGE_TOPIC
              value: "connect-status"
            - name: CONNECT_KEY_CONVERTER
              value: "io.confluent.connect.avro.AvroConverter"
            - name: CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL
              value: "djlee-schema-registry-service"
            - name: CONNECT_VALUE_CONVERTER
              value: "io.confluent.connect.avro.AvroConverter"
            - name: CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL
              value: "djlee-schema-registry-service"
            - name: CONNECT_REST_ADVERTISED_HOST_NAME
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: CONNECT_JMX_PORT
              value: "9999"
---
apiVersion: v1
kind: Service
metadata:
  name: djlee-kafka-connect-service
  labels:
    app: djlee-connect
spec:
  ports:
    - name: kafka-connect
      port: 8083
  selector:
    app: djlee-connect
```

As you can see above, a environment variale named with `CONNECT_A_B` corresponds to a configuration property of `a.b`. For example, `CONNECT_KEY_CONVERTER` corresponds to [`key.converter` property](](https://kafka.apache.org/documentation/#connectconfigs_key.converter) in Kafka Connect configuration).

# How to Extend

As described above, this image includes some connector plugins by default. If you need a image with additional plugins, create a Dockerfile like below and build a custom extension image.

```
FROM dongjinleekr/kafka-connect:latest

# before building the image, place built connector plugins in converters directory.
COPY converters /usr/local/share/java/converters
```

# How to Build

To build the image yourself, run following:

```
# Build image based on dongjinleekr/kafka:2.13-2.7.0 (Scala 2.13, Apache Kafka 2.7.0)
# before building the image, place built connectors and converters into the connectors/ and converters/ directory, respectively.
SCALA_VERSION=2.13 KAFKA_VERSION=2.7.0 && docker build --build-arg scala_version=${SCALA_VERSION} --build-arg kafka_version=${KAFKA_VERSION} -t dongjinleekr/kafka-connect:${SCALA_VERSION}-${KAFKA_VERSION} .
```
