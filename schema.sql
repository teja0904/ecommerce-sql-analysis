CREATE TABLE IF NOT EXISTS customers (
    customer_id              VARCHAR PRIMARY KEY,
    customer_unique_id       VARCHAR,
    customer_zip_code_prefix VARCHAR(5),
    customer_city            VARCHAR,
    customer_state           VARCHAR(2)
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id              VARCHAR PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city            VARCHAR,
    seller_state           VARCHAR(2)
);

CREATE TABLE IF NOT EXISTS products (
    product_id                 VARCHAR PRIMARY KEY,
    product_category_name      VARCHAR,
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE IF NOT EXISTS orders (
    order_id                      VARCHAR PRIMARY KEY,
    customer_id                   VARCHAR REFERENCES customers(customer_id),
    order_status                  VARCHAR,
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id            VARCHAR REFERENCES orders(order_id),
    order_item_id       INT,
    product_id          VARCHAR REFERENCES products(product_id),
    seller_id           VARCHAR REFERENCES sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id             VARCHAR REFERENCES orders(order_id),
    payment_sequential   INT,
    payment_type         VARCHAR,
    payment_installments INT,
    payment_value        NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id              VARCHAR,
    order_id               VARCHAR REFERENCES orders(order_id),
    review_score           INT,
    review_comment_title   TEXT,
    review_comment_message TEXT,
    review_creation_date   TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat             NUMERIC(10,6),
    geolocation_lng             NUMERIC(10,6),
    geolocation_city            VARCHAR,
    geolocation_state           VARCHAR(2)
);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_purchase ON orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_order_items_seller ON order_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order ON order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_order ON order_payments(order_id);
