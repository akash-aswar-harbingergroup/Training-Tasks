-- STEP 6 / Phase 6: Business Intelligence Queries

-- 🔹 Purpose of Phase 6
-- This phase answers questions like:

-- How much are we selling each month?
-- How many customers are active?
-- What is the cancellation rate?
-- Are sales growing or declining?

-- 6.1 Monthly Sales Dashboard
-- Monthly orders, customers, revenue & cancellation rate
SELECT
  DATE_FORMAT(o.order_date, '%Y-%m') AS month,
  COUNT(DISTINCT o.order_id) AS total_orders,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  SUM(o.total_amount) AS revenue,
  AVG(o.total_amount) AS avg_order_value,
  SUM(CASE 
        WHEN o.order_status = 'Cancelled' THEN 1 
        ELSE 0 
      END) AS cancelled_orders,
  ROUND(
    SUM(CASE 
          WHEN o.order_status = 'Cancelled' THEN 1 
          ELSE 0 
        END) * 100.0 / COUNT(*),
    2
  ) AS cancellation_rate
FROM orders o
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month DESC;


-- 🔹 6.2 Revenue Trend Over Time
-- Daily revenue trend
SELECT
  DATE(order_date) AS order_day,
  COUNT(order_id) AS total_orders,
  SUM(total_amount) AS daily_revenue
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY DATE(order_date)
ORDER BY order_day;

--  6.3 Customer Activity Metrics
-- New customers per month
SELECT
  DATE_FORMAT(registration_date, '%Y-%m') AS registration_month,
  COUNT(customer_id) AS new_customers
FROM customers
GROUP BY DATE_FORMAT(registration_date, '%Y-%m')
ORDER BY registration_month;

-- Active customers per month 
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS month,
  COUNT(DISTINCT customer_id) AS active_customers
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

--  6.4 Revenue Breakdown Queries
-- Revenue by payment method
SELECT
  payment_method,
  COUNT(order_id) AS total_orders,
  SUM(total_amount) AS total_revenue
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- Revenue by order status
SELECT
  order_status,
  COUNT(order_id) AS order_count,
  SUM(total_amount) AS revenue
FROM orders
GROUP BY order_status;

-- 🔹 6.5 Top‑Level KPI Queries (Executive View)
-- Average order value (AOV)
SELECT
  ROUND(AVG(total_amount), 2) AS avg_order_value
FROM orders
WHERE order_status != 'Cancelled';

-- Lifetime value by loyalty tier
SELECT
  loyalty_tier,
  COUNT(customer_id) AS customer_count,
  SUM(total_spent) AS total_revenue,
  AVG(total_spent) AS avg_customer_value
FROM customers
GROUP BY loyalty_tier
ORDER BY total_revenue DESC;