# Debezium CDC + Elasticsearch + Kibana Demo

Debezium CDC を使って MySQL の変更データを Elasticsearch にリアルタイム同期し、Kibana で可視化する検証環境です。

## アーキテクチャ

```
┌─────────┐    ┌───────────┐    ┌─────────┐    ┌────────────────┐    ┌─────────────────┐
│  MySQL  │───▶│  Debezium │───▶│  Kafka  │───▶│ Elasticsearch  │───▶│     Kibana      │
│ (binlog)│    │  Source   │    │ (Topic) │    │ Sink Connector │    │  (ダッシュボード) │
└─────────┘    └───────────┘    └─────────┘    └────────────────┘    └─────────────────┘
                                      │
                                      ▼
                               ┌────────────┐
                               │ PostgreSQL │
                               │    Sink    │
                               └────────────┘
```

## 必要な環境

- Docker
- Docker Compose

## 起動方法

```bash
# コンテナ起動
docker compose up -d --build

# 起動確認
docker compose ps
```

## Connector 登録

### 1. Source Connector（MySQL → Kafka）

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "inventory-connector",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "tasks.max": "1",
      "database.hostname": "mysql",
      "database.port": "3306",
      "database.user": "debezium",
      "database.password": "debezium",
      "database.server.id": "184054",
      "topic.prefix": "dbserver1",
      "database.include.list": "inventory",
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.inventory",
      "include.schema.changes": "true",
      "time.precision.mode": "connect"
    }
  }'
```

### 2. JDBC Sink Connector（Kafka → PostgreSQL）

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "jdbc-sink-connector",
    "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "tasks.max": "1",
      "connection.url": "jdbc:postgresql://postgres:5432/cdc_sink",
      "connection.user": "postgres",
      "connection.password": "postgres",
      "topics": "dbserver1.inventory.customers",
      "table.name.format": "customers_cdc",
      "insert.mode": "upsert",
      "pk.mode": "record_key",
      "pk.fields": "id",
      "auto.create": "true",
      "auto.evolve": "true",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "true"
    }
  }'
```

### 3. Elasticsearch Sink Connector（Kafka → Elasticsearch）

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "elasticsearch-sink-customers",
    "config": {
      "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
      "tasks.max": "1",
      "connection.url": "http://elasticsearch:9200",
      "topics": "dbserver1.inventory.customers",
      "key.ignore": "false",
      "schema.ignore": "true",
      "behavior.on.null.values": "delete",
      "transforms": "unwrap,extractKey",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "none",
      "transforms.extractKey.type": "org.apache.kafka.connect.transforms.ExtractField$Key",
      "transforms.extractKey.field": "id"
    }
  }'
```

### Connector 状態確認

```bash
curl -s http://localhost:8083/connectors?expand=status | jq
```

## 動作確認

### INSERT

```bash
docker compose exec mysql mysql -u debezium -pdebezium inventory -e "
INSERT INTO customers (first_name, last_name, email) 
VALUES ('Jiro', 'Sato', 'jiro.sato@example.com');
"

# Elasticsearch で確認
sleep 2
curl -s 'http://localhost:9200/dbserver1.inventory.customers/_search?pretty' | jq '.hits.hits[]._source.first_name'
```

### UPDATE

```bash
docker compose exec mysql mysql -u debezium -pdebezium inventory -e "
UPDATE customers SET first_name = 'Taro-Updated' WHERE id = 1;
"

# Elasticsearch で確認
sleep 2
curl -s 'http://localhost:9200/dbserver1.inventory.customers/_doc/1?pretty'
```

### DELETE

```bash
docker compose exec mysql mysql -u debezium -pdebezium inventory -e "
DELETE FROM customers WHERE id = 3;
"

# Elasticsearch で確認
sleep 2
curl -s 'http://localhost:9200/dbserver1.inventory.customers/_search?pretty' | jq '.hits.total.value'
```

## Web UI

| サービス | URL |
|---------|-----|
| Kafka UI | http://localhost:8080 |
| Kibana | http://localhost:5601 |
| Elasticsearch | http://localhost:9200 |

## 停止

```bash
docker compose down
```
