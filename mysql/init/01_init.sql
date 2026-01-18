-- ========================================
-- Debezium CDC Demo - MySQL初期化
-- ========================================

-- Debeziumユーザーに必要な権限を付与
-- binlogを読むためにREPLICATION権限が必要
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

-- ========================================
-- サンプルテーブル作成
-- ========================================

USE inventory;

-- 顧客テーブル（DATETIME型を使用 - time.precision.mode: connect との相性が良い）
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 商品テーブル
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 注文テーブル
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL,
    status ENUM('pending', 'confirmed', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- ========================================
-- サンプルデータ投入
-- ========================================

INSERT INTO customers (first_name, last_name, email) VALUES
    ('Taro', 'Yamada', 'taro.yamada@example.com'),
    ('Hanako', 'Suzuki', 'hanako.suzuki@example.com'),
    ('Ichiro', 'Tanaka', 'ichiro.tanaka@example.com');

INSERT INTO products (name, description, price, quantity) VALUES
    ('Laptop', 'High-performance laptop', 120000.00, 50),
    ('Mouse', 'Wireless mouse', 3500.00, 200),
    ('Keyboard', 'Mechanical keyboard', 15000.00, 100);

INSERT INTO orders (customer_id, total_amount, status) VALUES
    (1, 123500.00, 'confirmed'),
    (2, 3500.00, 'pending');
