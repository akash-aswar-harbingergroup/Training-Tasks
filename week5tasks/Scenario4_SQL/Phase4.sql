-- Phase 4: Query Optimization

-- 4.1 Analyze Query Performance using EXPLAIN
-- Purpose : Understand how MySQL executes a query:

-- Example: Analyze a potentially slow query

EXPLAIN
SELECT 
  p.product_name,
  COUNT(oi.order_item_id) AS times_ordered,
  SUM(oi.quantity) AS total_quantity
FROM products p
LEFT JOIN order_items oi 
  ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY times_ordered DESC;

-- 4.2 Index Optimization
-- Purpose
-- Indexes help MySQL find rows faster, especially for:

-- JOIN conditions
-- WHERE filters
-- ORDER BY clauses


-- Create composite indexes for frequent access patterns
CREATE INDEX idx_orders_customer_date
ON orders(customer_id, order_date);

CREATE INDEX idx_order_items_product_order
ON order_items(product_id, order_id);

CREATE INDEX idx_reviews_product_rating
ON reviews(product_id, rating);

SHOW INDEX FROM products;

-- 4.3 Query Rewriting for Better Performance
-- ❌ Inefficient Query (uses OR)

SELECT *
FROM products
WHERE category_id = 2 
   OR category_id = 3 
   OR category_id = 5;
  
-- Optimized Query (uses IN)--   
SELECT *
FROM products
WHERE category_id IN (2, 3, 5);   


--  4.4 Avoid Functions on Indexed Columns
-- ❌ Slow (function blocks index usage)
SELECT *
FROM orders
WHERE YEAR(order_date) = 2024;

-- Fast (range scan using index)
SELECT *
FROM orders
WHERE order_date >= '2024-01-01'
  AND order_date <  '2025-01-01';