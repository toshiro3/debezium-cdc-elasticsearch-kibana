-- ========================================
-- Debezium CDC Demo - PostgreSQL Sink初期化
-- ========================================

CREATE SCHEMA IF NOT EXISTS cdc;

-- 顧客テーブル（Sink先）
CREATE TABLE cdc.customers (
    id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    __op VARCHAR(10),
    __table VARCHAR(100),
    __source_ts_ms BIGINT,
    __deleted VARCHAR(10)
);

-- 商品テーブル（Sink先）
CREATE TABLE cdc.products (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    price DECIMAL(10, 2),
    quantity INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    __op VARCHAR(10),
    __table VARCHAR(100),
    __source_ts_ms BIGINT,
    __deleted VARCHAR(10)
);

-- 注文テーブル（Sink先）
CREATE TABLE cdc.orders (
    id INT PRIMARY KEY,
    customer_id INT,
    order_date TIMESTAMP,
    total_amount DECIMAL(10, 2),
    status VARCHAR(20),
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    __op VARCHAR(10),
    __table VARCHAR(100),
    __source_ts_ms BIGINT,
    __deleted VARCHAR(10)
);

-- インデックス
CREATE INDEX idx_customers_op ON cdc.customers(__op);
CREATE INDEX idx_products_op ON cdc.products(__op);
CREATE INDEX idx_orders_op ON cdc.orders(__op);
