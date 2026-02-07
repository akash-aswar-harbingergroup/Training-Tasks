-- Phase 3: Core SQL Queries & Business Analytics

--  3.1 Basic SELECT & Filtering Queries
-- 1. Products below reorder level
SELECT
  p.product_name,
  p.stock_quantity,
  p.reorder_level,
  s.supplier_name,
  (p.reorder_level - p.stock_quantity) AS units_to_order
FROM products p
JOIN suppliers s 
  ON p.supplier_id = s.supplier_id
WHERE p.stock_quantity < p.reorder_level
ORDER BY units_to_order DESC;
-- output : Nothing so, there are no products below reorder level

-- Q2. Customers who haven’t ordered in the last 30 days
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.email,
  c.loyalty_tier,
  MAX(o.order_date) AS last_order_date,
  DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_order
FROM customers c
LEFT JOIN orders o 
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING MAX(o.order_date) < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
   OR MAX(o.order_date) IS NULL
ORDER BY days_since_order DESC;

--  3.2 INNER JOIN – Transactional Queries
-- Q3. Complete order details (customer + products)
SELECT
  o.order_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.email,
  o.order_date,
  p.product_name,
  oi.quantity,
  oi.unit_price,
  oi.subtotal,
  o.order_status
FROM orders o
INNER JOIN customers c 
  ON o.customer_id = c.customer_id
INNER JOIN order_items oi 
  ON o.order_id = oi.order_id
INNER JOIN products p 
  ON oi.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
ORDER BY o.order_date DESC, o.order_id;

-- Q4. Revenue and profit by product category
SELECT
  cat.category_name,
  COUNT(DISTINCT oi.order_id) AS total_orders,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.subtotal) AS total_revenue,
  AVG(oi.unit_price) AS avg_selling_price,
  SUM(oi.subtotal - (p.cost_price * oi.quantity)) AS profit
FROM categories cat
INNER JOIN products p 
  ON cat.category_id = p.category_id
INNER JOIN order_items oi 
  ON p.product_id = oi.product_id
INNER JOIN orders o 
  ON oi.order_id = o.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY cat.category_id, cat.category_name
ORDER BY total_revenue DESC;

-- 🔹 3.3 LEFT JOIN – Finding Gaps in Data
-- Q5. Products with no sales
SELECT
  p.product_id,
  p.product_name,
  p.stock_quantity,
  c.category_name,
  COUNT(oi.order_item_id) AS times_ordered
FROM products p
LEFT JOIN order_items oi 
  ON p.product_id = oi.product_id
LEFT JOIN categories c 
  ON p.category_id = c.category_id
GROUP BY 
  p.product_id, 
  p.product_name, 
  p.stock_quantity, 
  c.category_name
HAVING times_ordered = 0
ORDER BY p.stock_quantity DESC;

-- Q6. Customers with no orders in 2024
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.email,
  c.registration_date,
  c.loyalty_tier,
  COUNT(o.order_id) AS order_count_2024
FROM customers c
LEFT JOIN orders o 
  ON c.customer_id = o.customer_id
 AND YEAR(o.order_date) = 2024
GROUP BY c.customer_id
HAVING order_count_2024 = 0;

--  3.4 SELF JOIN – Hierarchical Data
-- Q7. Employee hierarchy (manager → employee)
SELECT
  e1.employee_id,
  CONCAT(e1.first_name, ' ', e1.last_name) AS employee_name,
  e1.department,
  CONCAT(e2.first_name, ' ', e2.last_name) AS manager_name,
  e2.department AS manager_department
FROM employees e1
LEFT JOIN employees e2 
  ON e1.manager_id = e2.employee_id
ORDER BY e2.employee_id, e1.employee_id;


-- 3.6 Subqueries – Advanced Analytics
-- Q11. Top customers (above average spending)
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.loyalty_tier,
  COUNT(o.order_id) AS total_orders,
  SUM(o.total_amount) AS total_spent,
  (SELECT AVG(total_amount) FROM orders) AS avg_order_value,
  SUM(o.total_amount) 
    - (SELECT AVG(total_amount) FROM orders) * COUNT(o.order_id) 
    AS vs_average
FROM customers c
INNER JOIN orders o 
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING total_spent > (SELECT AVG(total_spent) FROM customers)
ORDER BY total_spent DESC;

-- 3.7 Window Functions – Advanced Analytics
-- Q14. Running total & moving average of daily revenue
SELECT
  DATE(order_date) AS order_day,
  COUNT(order_id) AS orders_count,
  SUM(total_amount) AS daily_revenue,
  SUM(SUM(total_amount)) 
    OVER (ORDER BY DATE(order_date)) AS running_total,
  AVG(SUM(total_amount)) 
    OVER (
      ORDER BY DATE(order_date)
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3day
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY DATE(order_date)
ORDER BY order_day;
