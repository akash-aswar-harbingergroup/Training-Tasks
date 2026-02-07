-- Phase 5: Advanced DBMS Operations

--  5.1 Transactions & ACID Properties
-- Purpose :  Ensure multiple SQL operations succeed or fail as one unit.
-- This is critical for:
-- Order processing
-- Inventory updates
-- Payment consistency

-- Example: Process a New Order Safely (Transaction)

START TRANSACTION;

-- 1. Insert new order
INSERT INTO orders 
(customer_id, shipping_address_id, order_status, total_amount, payment_method)
VALUES 
(1, 1, 'Pending', 1549.98, 'Credit Card');

SET @new_order_id = LAST_INSERT_ID();

-- 2. Insert order items
INSERT INTO order_items 
(order_id, product_id, quantity, unit_price, subtotal)
VALUES
(@new_order_id, 1, 1, 1499.99, 1499.99),
(@new_order_id, 7, 1, 49.99, 49.99);

-- 3. Update product inventory
UPDATE products 
SET stock_quantity = stock_quantity - 1 
WHERE product_id = 1;

UPDATE products 
SET stock_quantity = stock_quantity - 1 
WHERE product_id = 7;

-- 4. Update customer total spending
UPDATE customers
SET total_spent = total_spent + 1549.98
WHERE customer_id = 1;

COMMIT;


-- 5.3 Views for Data Security & Simplification
-- Purpose
-- Hide sensitive data
-- Simplify complex joins
-- Create reusable reporting layers

-- Create a Customer Order Summary View
CREATE VIEW vw_customer_order_summary AS
SELECT 
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.loyalty_tier,
  COUNT(DISTINCT o.order_id) AS total_orders,
  SUM(o.total_amount) AS lifetime_value,
  AVG(o.total_amount) AS avg_order_value,
  MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o 
  ON c.customer_id = o.customer_id
WHERE o.order_status != 'Cancelled'
GROUP BY c.customer_id;

-- Use the View
SELECT *
FROM vw_customer_order_summary
WHERE lifetime_value > 1000
ORDER BY lifetime_value DESC;



