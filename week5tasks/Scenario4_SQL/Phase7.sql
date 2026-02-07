--  Phase 7: Practice Challenges

--  Challenge 1: Inventory Management — SQL Queries

-- Challenge 1.1
-- Identify products that need reordering (across all warehouses)
-- Business meaning:
-- A product needs reordering if the total quantity across all warehouses is less than its reorder level.

SELECT
  p.product_id,
  p.product_name,
  p.reorder_level,
  COALESCE(SUM(i.quantity), 0) AS total_inventory,
  (p.reorder_level - COALESCE(SUM(i.quantity), 0)) AS units_to_order
FROM products p
LEFT JOIN inventory i
  ON p.product_id = i.product_id
GROUP BY
  p.product_id,
  p.product_name,
  p.reorder_level
HAVING total_inventory < p.reorder_level
ORDER BY units_to_order DESC;
-- output : blank , so, No product needs reorder


-- Challenge 1.2
-- Calculate total cost of restocking all products below reorder level
-- Business meaning:
-- How much money is needed to restock all understocked products to their reorder level.

SELECT
  ROUND(
    SUM(
      (p.reorder_level - COALESCE(inv.total_inventory, 0)) 
      * p.cost_price
    ),
    2
  ) AS total_restocking_cost
FROM products p
LEFT JOIN (
  SELECT
    product_id,
    SUM(quantity) AS total_inventory
  FROM inventory
  GROUP BY product_id
) inv
  ON p.product_id = inv.product_id
WHERE COALESCE(inv.total_inventory, 0) < p.reorder_level;
-- output : null   so, SUM over zero rows = NULL





--  Challenge 1.3
-- Recommend warehouse transfers to balance inventory
-- Business meaning:
-- Identify products where:

-- One warehouse has excess stock
-- Another warehouse has low stock
-- → Suggest a transfer

SELECT
  p.product_name,
  w1.warehouse_name AS source_warehouse,
  i1.quantity AS source_quantity,
  w2.warehouse_name AS target_warehouse,
  i2.quantity AS target_quantity,
  FLOOR((i1.quantity - i2.quantity) / 2) AS recommended_transfer_units
FROM inventory i1
JOIN inventory i2
  ON i1.product_id = i2.product_id
 AND i1.warehouse_id <> i2.warehouse_id
JOIN products p
  ON i1.product_id = p.product_id
JOIN warehouses w1
  ON i1.warehouse_id = w1.warehouse_id
JOIN warehouses w2
  ON i2.warehouse_id = w2.warehouse_id
WHERE i1.quantity > i2.quantity + 10
ORDER BY p.product_name, recommended_transfer_units DESC;
-- output : blank so, No large warehouse imbalance


-- Challenge 2: Customer Analytics — SQL Queries

-- 🔹 Challenge 2.1
-- Customer Cohort Analysis (by registration month)
-- 🎯 Business question
-- “How do customers who joined in the same month behave over time in terms of orders?”

-- ✅ Query: Customers grouped by registration month + order activity

SELECT
  DATE_FORMAT(c.registration_date, '%Y-%m') AS cohort_month,
  COUNT(DISTINCT c.customer_id) AS customers_in_cohort,
  COUNT(o.order_id) AS total_orders,
  ROUND(COUNT(o.order_id) / COUNT(DISTINCT c.customer_id), 2) AS avg_orders_per_customer
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
GROUP BY cohort_month
ORDER BY cohort_month;


--  Challenge 2.2
-- Customer Churn Analysis
-- 🎯 Business question
-- “Which customers have stopped ordering recently?”
-- We’ll define churn as:

-- No orders in the last 60 days

SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.email,
  MAX(o.order_date) AS last_order_date,
  DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING
  MAX(o.order_date) IS NULL
  OR MAX(o.order_date) < DATE_SUB(CURDATE(), INTERVAL 60 DAY)
ORDER BY days_since_last_order DESC;

-- churn rate percentage : 
SELECT
  ROUND(
    SUM(
      CASE
        WHEN last_order_date IS NULL
          OR last_order_date < DATE_SUB(CURDATE(), INTERVAL 60 DAY)
        THEN 1 ELSE 0
      END
    ) * 100.0 / COUNT(*),
    2
  ) AS churn_rate_percentage
FROM (
  SELECT
    c.customer_id,
    MAX(o.order_date) AS last_order_date
  FROM customers c
  LEFT JOIN orders o
    ON c.customer_id = o.customer_id
  GROUP BY c.customer_id
) t;

--  Challenge 2.3
-- Customers Likely to Upgrade Loyalty Tier
-- 🎯 Business question
-- “Which customers are close to the next loyalty tier?”
-- Assumed business rules:

-- Silver → Gold at ₹5000
-- Gold → Platinum at ₹10000
-- ✅ Query: Loyalty upgrade candidates

SELECT
  customer_id,
  CONCAT(first_name, ' ', last_name) AS customer_name,
  loyalty_tier,
  total_spent,
  CASE
    WHEN loyalty_tier = 'Silver' AND total_spent >= 4500 THEN 'Near Gold'
    WHEN loyalty_tier = 'Gold' AND total_spent >= 9000 THEN 'Near Platinum'
    ELSE 'Not Eligible'
  END AS upgrade_status
FROM customers
WHERE loyalty_tier IN ('Silver', 'Gold')
ORDER BY total_spent DESC;


--  Challenge 3.1
-- Most Profitable Product Combinations (Bought Together)
-- 🎯 Business Question
-- “Which product pairs are frequently purchased together, and how profitable are those combinations?”

-- ✅ Query: Product pairs bought together in the same order

SELECT
  p1.product_name AS product_1,
  p2.product_name AS product_2,
  COUNT(DISTINCT oi1.order_id) AS times_bought_together,
  SUM(
    (oi1.subtotal + oi2.subtotal)
    - ((p1.cost_price * oi1.quantity) + (p2.cost_price * oi2.quantity))
  ) AS combined_profit
FROM order_items oi1
JOIN order_items oi2
  ON oi1.order_id = oi2.order_id
 AND oi1.product_id < oi2.product_id
JOIN products p1
  ON oi1.product_id = p1.product_id
JOIN products p2
  ON oi2.product_id = p2.product_id
GROUP BY
  p1.product_name,
  p2.product_name
HAVING times_bought_together >= 1
ORDER BY combined_profit DESC;


-- Challenge 3.2
-- Discount Effectiveness Analysis
-- 🎯 Business Question
-- “Do discounts increase revenue or reduce profit?”

-- ✅ Query: Discounted vs non‑discounted sales

SELECT
  CASE 
    WHEN discount_amount > 0 THEN 'Discounted'
    ELSE 'No Discount'
  END AS discount_type,
  COUNT(order_id) AS total_orders,
  SUM(total_amount) AS total_revenue,
  ROUND(AVG(total_amount), 2) AS avg_order_value
FROM orders
GROUP BY discount_type;

-- ✅ Deeper version: Discount impact on profit
SELECT
  CASE
    WHEN oi.discount > 0 THEN 'Discounted Items'
    ELSE 'No Discount Items'
  END AS item_discount_type,
  COUNT(*) AS line_items,
  SUM(oi.subtotal) AS revenue,
  SUM(oi.subtotal - (p.cost_price * oi.quantity)) AS profit
FROM order_items oi
JOIN products p
  ON oi.product_id = p.product_id
GROUP BY item_discount_type;

--  Challenge 3.3
-- Revenue by Warehouse
-- 🎯 Business Question
-- “Which warehouse contributes most to revenue?”

-- ✅ Query: Revenue contribution per warehouse

SELECT
  w.warehouse_name,
  COUNT(DISTINCT s.order_id) AS total_orders,
  SUM(o.total_amount) AS total_revenue
FROM shipments s
JOIN warehouses w
  ON s.warehouse_id = w.warehouse_id
JOIN orders o
  ON s.order_id = o.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY w.warehouse_name
ORDER BY total_revenue DESC;



