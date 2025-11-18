DROP DATABASE IF EXISTS adventureworks_dw;
CREATE DATABASE adventureworks_dw  DEFAULT CHARACTER SET utf8mb4  DEFAULT COLLATE utf8mb4_general_ci;
USE adventureworks_dw;

SHOW TABLES;


DROP TABLE IF EXISTS fact_sales;
CREATE TABLE IF NOT EXISTS fact_sales (
    sales_order_id INT,
    product_key INT,
    customer_key INT,
    date_key INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    sales_amount DECIMAL(10,2)
);

DROP TABLE IF EXISTS dim_product;
CREATE TABLE IF NOT EXISTS dim_product (
    product_key INT PRIMARY KEY,
    product_name VARCHAR(100),
    product_number VARCHAR(25),
    list_price DECIMAL(10,2)
);

DROP TABLE IF EXISTS dim_customer;
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_key INT PRIMARY KEY,
    territory_id INT,
    account_number VARCHAR(10),
    customer_type VARCHAR(1)
);

DROP TABLE IF EXISTS dim_date;
CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    year INT,
    month INT,
    day INT
);


-- poplulating empty tables
USE adventureworks_dw;

INSERT INTO dim_customer (customer_key, territory_id, account_number, customer_type)
SELECT DISTINCT
    CustomerID,
    TerritoryID,
    AccountNumber,
    CustomerType
FROM adventureworks.customer;


INSERT IGNORE INTO dim_product (product_key, product_name, product_number, list_price)
SELECT DISTINCT 
	ProductID, 
	Name, 
	ProductNumber, 
    ListPrice
FROM adventureworks.product;

INSERT IGNORE INTO dim_date (date_key, full_date, year, month, day)
SELECT DISTINCT
    YEAR(OrderDate)*10000 + MONTH(OrderDate)*100 + DAY(OrderDate) AS date_key,
    OrderDate AS full_date,
    YEAR(OrderDate),
    MONTH(OrderDate),
    DAY(OrderDate)
FROM adventureworks.salesorderheader;

INSERT IGNORE INTO fact_sales (sales_order_id, product_key, customer_key, date_key, quantity, unit_price, sales_amount)
SELECT
    sod.SalesOrderID,
    sod.ProductID AS product_key,
    soh.CustomerID AS customer_key,
    YEAR(soh.OrderDate)*10000 + MONTH(soh.OrderDate)*100 + DAY(soh.OrderDate) AS date_key,
    sod.OrderQty AS quantity,
    sod.UnitPrice AS unit_price,
    (sod.OrderQty * sod.UnitPrice) AS sales_amount
FROM adventureworks.salesorderdetail sod
JOIN adventureworks.salesorderheader soh
    ON sod.SalesOrderID = soh.SalesOrderID;
    
SELECT COUNT(*) AS customer_count FROM dim_customer;
SELECT COUNT(*) AS product_count FROM dim_product;
SELECT COUNT(*) AS date_count FROM dim_date;
SELECT COUNT(*) AS sales_count FROM fact_sales;

-- my queries

SELECT * FROM dim_customer LIMIT 10;
SELECT * FROM dim_date LIMIT 10;
SELECT * FROM dim_product LIMIT 10;
SELECT * FROM fact_sales LIMIT 10;

SELECT
    p.product_name,
    d.year,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_product p
    ON f.product_key = p.product_key
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY p.product_name, d.year
ORDER BY total_sales DESC
LIMIT 10;


SELECT
    c.customer_key,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_key
ORDER BY total_sales DESC
LIMIT 10;

SELECT
    p.product_name,
    d.year,
    SUM(f.sales_amount) AS total_revenue
FROM fact_sales f
JOIN dim_product p
    ON f.product_key = p.product_key
JOIN dim_date d
    ON f.date_key = d.date_key
GROUP BY p.product_name, d.year
ORDER BY total_revenue DESC
LIMIT 10;