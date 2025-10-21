CREATE TABLE dim_customers (
    customer_key SERIAL PRIMARY KEY,
    customer_id INT,
    name VARCHAR(100),
    age INT,
    city VARCHAR(50),
    state VARCHAR(50),
    signup_date DATE
);

CREATE TABLE dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price NUMERIC(10,2)
);

CREATE TABLE dim_campaigns (
    campaign_key SERIAL PRIMARY KEY,
    campaign_id INT,
    channel VARCHAR(50),          -- Email, SMS, Social, etc.
    start_date DATE,
    end_date DATE,
    budget NUMERIC(12,2)
);

CREATE TABLE dim_date (
    date_key SERIAL PRIMARY KEY,
    full_date DATE,
    month INT,
    year INT,
    quarter INT
);

CREATE TABLE fact_transactions (
    txn_id SERIAL PRIMARY KEY,
    customer_key INT REFERENCES dim_customers(customer_key),
    product_key INT REFERENCES dim_products(product_key),
    campaign_key INT REFERENCES dim_campaigns(campaign_key),
    date_key INT REFERENCES dim_date(date_key),
    amount NUMERIC(10,2),
    payment_type VARCHAR(20),
    is_fraud BOOLEAN DEFAULT FALSE
);

-- Example customers
INSERT INTO dim_customers (customer_id, name, age, city, state, signup_date)
VALUES
(1001, 'Asha Kumar', 32, 'Dallas', 'TX', '2023-01-10'),

-- 1. Campaign ROI
SELECT c.channel,
       SUM(f.amount) AS total_sales,
       c.budget,
       ROUND((SUM(f.amount)-c.budget)/c.budget*100,2) AS ROI_percent
FROM fact_transactions f
JOIN dim_campaigns c ON f.campaign_key=c.campaign_key
GROUP BY c.channel,c.budget;

-- 2. Fraud rate by payment type
SELECT payment_type,
       COUNT(*) AS total_txns,
       SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) AS fraud_cases,
       ROUND(SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END)::numeric/COUNT(*)*100, 2) AS fraud_rate
FROM fact_transactions
GROUP BY payment_type;

-- 3. Top customers by spend
SELECT c.name,
       SUM(f.amount) AS total_spent,
       RANK() OVER(ORDER BY SUM(f.amount) DESC) AS rank
FROM fact_transactions f
JOIN dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.name;

(1002, 'Ravi Patel', 28, 'Austin', 'TX', '2023-02-20');

-- Example products
INSERT INTO dim_products (product_id, product_name, category, price)
VALUES
(501, 'Smartwatch', 'Electronics', 150),
(502, 'Yoga Mat', 'Fitness', 40);

-- Example campaigns
INSERT INTO dim_campaigns (campaign_id, channel, start_date, end_date, budget)
VALUES
(901, 'Email', '2024-01-01', '2024-03-01', 20000),
(902, 'Social Media', '2024-02-01', '2024-04-01', 30000);

-- Example date dimension
INSERT INTO dim_date (full_date, month, year, quarter)
VALUES
('2024-02-05', 2, 2024, 1),
('2024-02-12', 2, 2024, 1);

-- Example fact table
INSERT INTO fact_transactions
(customer_key, product_key, campaign_key, date_key, amount, payment_type, is_fraud)
VALUES
(1, 1, 1, 1, 150, 'Credit', FALSE),
(2, 2, 2, 2, 40, 'Credit', TRUE);

CREATE MATERIALIZED VIEW mv_monthly_fraud AS
SELECT d.year, d.month,
       COUNT(*) AS total_txns,
       SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) AS fraud_txns
FROM fact_transactions f
JOIN dim_date d ON f.date_key=d.date_key
GROUP BY d.year,d.month;

REFRESH MATERIALIZED VIEW mv_monthly_fraud;

