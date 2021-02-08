ARG kafka_version=2.6.0
ARG scala_version=2.13

FROM dongjinleekr/kafka:${scala_version}-${kafka_version}

LABEL org.label-schema.name="kafka-connect" \
      org.label-schema.description="Apache Kafka (Connect)" \
      org.label-schema.build-date="${build_date}" \
      org.label-schema.vcs-url="https://github.com/dongjinleekr/kafka-connect-docker" \
      org.label-schema.vcs-ref="${vcs_ref}" \
      org.label-schema.version="${scala_version}_${kafka_version}" \
      org.label-schema.schema-version="1.0" \
      maintainer="dongjin@apache.org"

# converters
# mvn clean package -DskipTests -Pdist -pl avro-converter,json-schema-converter,protobuf-converter -am
# converters/confluentinc-kafka-connect-avro-converter-5.5.2
# converters/confluentinc-kafka-connect-json-schema-converter-5.5.2
# converters/confluentinc-kafka-connect-protobuf-converter-5.5.2
COPY converters /usr/share/java/converters

# connectors
# connectors/kafka-connect-storage-common-5.5.1
# connectors/kafka-connect-hdfs-5.5.2
# connectors/kafka-connect-jdbc-5.5.2
# connectors/kafka-connect-s3-5.5.2
# TODO: https://github.com/confluentinc/kafka-connect-datagen
# TODO: https://github.com/Eneco/kafka-connect-twitter
COPY connectors /usr/share/java/connectors

COPY start-kafka-connect.sh /tmp/

RUN chmod a+x /tmp/*.sh \
 && mv /tmp/start-kafka-connect.sh /usr/bin \
 && sync

# Use "exec" form so that it runs as PID 1 (useful for graceful shutdown)
CMD ["start-kafka-connect.sh"]
