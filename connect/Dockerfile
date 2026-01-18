# Stage 1: Maven で依存関係をダウンロード
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /build

COPY pom.xml .

# 依存関係をダウンロード
RUN mvn dependency:copy-dependencies -DoutputDirectory=/build/libs

# Stage 2: Debezium Connect に jar を追加
FROM debezium/connect:2.7.3.Final

USER root

# Elasticsearch Sink Connector（全ての依存関係をまとめてコピー）
RUN mkdir -p /kafka/connect/kafka-connect-elasticsearch
COPY --from=builder /build/libs/*.jar /kafka/connect/kafka-connect-elasticsearch/

# JDBC Sink Connector（必要な jar のみコピー）
RUN mkdir -p /kafka/connect/kafka-connect-jdbc
COPY --from=builder /build/libs/kafka-connect-jdbc-*.jar /kafka/connect/kafka-connect-jdbc/
COPY --from=builder /build/libs/postgresql-*.jar /kafka/connect/kafka-connect-jdbc/

USER kafka
