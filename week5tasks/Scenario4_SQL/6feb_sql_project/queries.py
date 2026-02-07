# =========================================================
# PHASE 3: CORE SQL QUERIES & BUSINESS ANALYTICS
# =========================================================

# 3.1 Basic SELECT & Filtering Queries

Q3_1_PRODUCTS_BELOW_REORDER = """
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
"""

Q3_2_INACTIVE_CUSTOMERS_30_DAYS = """
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
"""


# 3.2 INNER JOIN – Transactional Queries

Q3_3_ORDER_DETAILS = """
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
JOIN customers c 
  ON o.customer_id = c.customer_id
JOIN order_items oi 
  ON o.order_id = oi.order_id
JOIN products p 
  ON oi.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
ORDER BY o.order_date DESC, o.order_id;
"""

Q3_4_REVENUE_BY_CATEGORY = """
SELECT
  cat.category_name,
  COUNT(DISTINCT oi.order_id) AS total_orders,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.subtotal) AS total_revenue,
  AVG(oi.unit_price) AS avg_selling_price,
  SUM(oi.subtotal - (p.cost_price * oi.quantity)) AS profit
FROM categories cat
JOIN products p 
  ON cat.category_id = p.category_id
JOIN order_items oi 
  ON p.product_id = oi.product_id
JOIN orders o 
  ON oi.order_id = o.order_id
WHERE o.order_status != 'Cancelled'
GROUP BY cat.category_id, cat.category_name
ORDER BY total_revenue DESC;
"""


# 3.3 LEFT JOIN – Finding Gaps in Data

Q3_5_PRODUCTS_NO_SALES = """
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
"""

Q3_6_CUSTOMERS_NO_ORDERS_2024 = """
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
"""


# 3.4 SELF JOIN – Hierarchical Data

Q3_7_EMPLOYEE_HIERARCHY = """
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
"""


# 3.6 Subqueries – Advanced Analytics

Q3_11_TOP_CUSTOMERS = """
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.loyalty_tier,
  COUNT(o.order_id) AS total_orders,
  SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o 
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING total_spent > (SELECT AVG(total_spent) FROM customers)
ORDER BY total_spent DESC;
"""


# 3.7 Window Functions – Advanced Analytics

Q3_14_DAILY_REVENUE_TREND = """
SELECT
  DATE(order_date) AS order_day,
  COUNT(order_id) AS orders_count,
  SUM(total_amount) AS daily_revenue
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY DATE(order_date)
ORDER BY order_day;
"""


# =========================================================
# PHASE 6: BUSINESS INTELLIGENCE QUERIES
# =========================================================

Q6_MONTHLY_SALES = """
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS month,
  COUNT(DISTINCT order_id) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers,
  SUM(total_amount) AS revenue,
  AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
"""

Q6_DAILY_REVENUE = """
SELECT
  DATE(order_date) AS order_day,
  COUNT(order_id) AS total_orders,
  SUM(total_amount) AS daily_revenue
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY DATE(order_date)
ORDER BY order_day;
"""

Q6_NEW_CUSTOMERS = """
SELECT
  DATE_FORMAT(registration_date, '%Y-%m') AS month,
  COUNT(customer_id) AS new_customers
FROM customers
GROUP BY DATE_FORMAT(registration_date, '%Y-%m')
ORDER BY month;
"""

Q6_ACTIVE_CUSTOMERS = """
SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS month,
  COUNT(DISTINCT customer_id) AS active_customers
FROM orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
"""

Q6_REVENUE_BY_PAYMENT = """
SELECT
  payment_method,
  COUNT(order_id) AS total_orders,
  SUM(total_amount) AS revenue
FROM orders
WHERE order_status != 'Cancelled'
GROUP BY payment_method
ORDER BY revenue DESC;
"""

Q6_REVENUE_BY_STATUS = """
SELECT
  order_status,
  COUNT(order_id) AS order_count,
  SUM(total_amount) AS revenue
FROM orders
GROUP BY order_status;
"""

Q6_AOV = """
SELECT
  ROUND(AVG(total_amount), 2) AS avg_order_value
FROM orders
WHERE order_status != 'Cancelled';
"""


# =========================================================
# PHASE 7: PRACTICE CHALLENGES
# =========================================================

# Challenge 1: Inventory Management

Q7_C1_REORDER = """
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
"""

Q7_C1_RESTOCK_COST = """
SELECT
  COALESCE(
    ROUND(
      SUM(
        (p.reorder_level - COALESCE(inv.total_inventory, 0)) 
        * p.cost_price
      ),
      2
    ),
    0
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
"""

Q7_C1_TRANSFER = """
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
"""


# Challenge 2: Customer Analytics

Q7_C2_COHORT = """
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
"""

Q7_C2_CHURN = """
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
"""

Q7_C2_CHURN_RATE = """
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
"""

Q7_C2_UPGRADE = """
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
"""


# Challenge 3: Revenue Optimization

Q7_C3_COMBINATIONS = """
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
"""

Q7_C3_DISCOUNTS = """
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
"""

Q7_C3_REVENUE_BY_WAREHOUSE = """
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
"""