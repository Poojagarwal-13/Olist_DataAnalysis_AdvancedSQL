DROP DATABASE IF EXISTS olist;

CREATE DATABASE olist;

use olist;

-- Table 1

CREATE TABLE customers(
	customer_id varchar(250),
	customer_unique_id varchar(250),
	customer_zip_code_prefix varchar(250),
	customer_city varchar(250),
    customer_state varchar (250)
);

LOAD DATA INFILE 'olist_customers_dataset.csv' 
INTO TABLE customers 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from customers;


-- Table 2

CREATE TABLE geolocation(
    zip_code_prefix varchar(250),
    geolocation_lat float,
	geolocation_lng float,
	city varchar(250),
    state varchar (250)
);

LOAD DATA INFILE 'olist_geolocation_dataset.csv' 
INTO TABLE geolocation 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from geolocation;

-- Table 3

CREATE TABLE items(
	order_id varchar(250),
	order_item_id varchar(250),
    product_id varchar(250),
    seller_id varchar(250),
    shipping_limit_date datetime,
    price float,
    freight_value float
);

LOAD DATA INFILE 'olist_order_items_dataset.csv' 
INTO TABLE items 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from items;


-- Table 4

CREATE TABLE payments(
	order_id varchar(250),
	payment_sequential varchar(250),
    payment_type varchar(250),
    payment_installments int,
    payment_value float
);

LOAD DATA INFILE 'olist_order_payments_dataset.csv' 
INTO TABLE payments 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from payments;

-- Table 5

CREATE TABLE reviews(
	review_id varchar(250),
	order_id varchar(250),
    review_score int,
    comment_title varchar (250),
    comment_message varchar (10000),
    creation_date datetime,
    answer_timestamp datetime
);

LOAD DATA INFILE 'olist_order_reviews_dataset.csv' 
INTO TABLE reviews
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from reviews;

-- Table 6

CREATE TABLE orders(
	order_id varchar(250),
    customer_id varchar (250),
    order_status varchar (250),
    purchase_timestamp datetime,
    approved_at datetime,
    order_delivered_carrier_date datetime,
    order_delivered_customer_date datetime,
    estimated_delivery_date datetime
);


LOAD DATA INFILE 'olist_orders_dataset.csv' 
INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM ORDERS;

-- Table 7

CREATE TABLE products(
	product_id varchar(250),
    product_name varchar (250),
    product_name_length int,
    product_description_length int,
    product_photo_qty int,
    product_weight_g int,
    product_length_cm int,
    product_height_cm int,
    product_width_cm int
);

LOAD DATA INFILE 'olist_products_dataset.csv' 
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select * from products;

-- Table 8

CREATE TABLE sellers(
	seller_id varchar(250),
    seller_zip_code_prefix int,
    seller_city varchar (250),
    seller_state varchar (250)
);

LOAD DATA INFILE 'olist_sellers_dataset.csv' 
INTO TABLE sellers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from sellers;

-- Table 9

CREATE TABLE product_category_name_translation(
	product_category_name varchar(250),
    product_category_name_english varchar(250)
);

LOAD DATA INFILE 'product_category_name_translation.csv' 
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from product_category_name_translation;