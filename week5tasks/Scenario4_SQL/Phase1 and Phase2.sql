
CREATE DATABASE techmart_db;
USE techmart_db;

-- Table Creation 

CREATE TABLE customers (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  registration_date DATE NOT NULL,
  loyalty_tier ENUM('Bronze','Silver','Gold','Platinum') DEFAULT 'Bronze',
  total_spent DECIMAL(10,2) DEFAULT 0,
  INDEX idx_email (email),
  INDEX idx_loyalty (loyalty_tier)
);

CREATE TABLE addresses (
  address_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  address_type ENUM('Billing','Shipping') NOT NULL,
  street_address VARCHAR(200) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(50) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  country VARCHAR(50) DEFAULT 'USA',
  is_default BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
  INDEX idx_customer (customer_id)
);

CREATE TABLE categories (
  category_id INT PRIMARY KEY AUTO_INCREMENT,
  category_name VARCHAR(100) NOT NULL,
  parent_category_id INT NULL,
  description TEXT,
  FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
);

CREATE TABLE suppliers (
  supplier_id INT PRIMARY KEY AUTO_INCREMENT,
  supplier_name VARCHAR(100) NOT NULL,
  contact_name VARCHAR(100),
  email VARCHAR(100),
  phone VARCHAR(20),
  country VARCHAR(50),
  rating DECIMAL(3,2) CHECK (rating BETWEEN 0 AND 5),
  INDEX idx_rating (rating)
);
CREATE TABLE products (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  product_name VARCHAR(200) NOT NULL,
  category_id INT NOT NULL,
  supplier_id INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  cost_price DECIMAL(10,2) NOT NULL,
  stock_quantity INT DEFAULT 0,
  reorder_level INT DEFAULT 10,
  is_active BOOLEAN DEFAULT TRUE,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(category_id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
  INDEX idx_category (category_id),
  INDEX idx_price (unit_price),
  INDEX idx_stock (stock_quantity)
);

CREATE TABLE warehouses (
  warehouse_id INT PRIMARY KEY AUTO_INCREMENT,
  warehouse_name VARCHAR(100) NOT NULL,
  location VARCHAR(100) NOT NULL,
  capacity INT NOT NULL,
  manager_name VARCHAR(100)
);

CREATE TABLE inventory (
  inventory_id INT PRIMARY KEY AUTO_INCREMENT,
  product_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  quantity INT DEFAULT 0,
  last_restocked DATE,
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
  UNIQUE KEY unique_product_warehouse (product_id, warehouse_id),
  INDEX idx_quantity (quantity)
);

CREATE TABLE orders (
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  shipping_address_id INT NOT NULL,
  order_status ENUM('Pending','Processing','Shipped','Delivered','Cancelled') DEFAULT 'Pending',
  total_amount DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  payment_method ENUM('Credit Card','Debit Card','PayPal','Bank Transfer') NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id),
  INDEX idx_customer (customer_id),
  INDEX idx_order_date (order_date),
  INDEX idx_status (order_status)
);

CREATE TABLE order_items (
  order_item_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  discount DECIMAL(10,2) DEFAULT 0,
  subtotal DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  INDEX idx_order (order_id),
  INDEX idx_product (product_id)
);

CREATE TABLE shipments (
  shipment_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  shipment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  carrier VARCHAR(50),
  tracking_number VARCHAR(100),
  estimated_delivery DATE,
  actual_delivery DATE,
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
  INDEX idx_order (order_id)
);

CREATE TABLE employees (
  employee_id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE,
  hire_date DATE NOT NULL,
  department ENUM('Sales','Support','Warehouse','Management') NOT NULL,
  salary DECIMAL(10,2),
  manager_id INT,
  FOREIGN KEY (manager_id) REFERENCES employees(employee_id),
  INDEX idx_department (department)
);

CREATE TABLE reviews (
  review_id INT PRIMARY KEY AUTO_INCREMENT,
  product_id INT NOT NULL,
  customer_id INT NOT NULL,
  order_id INT NOT NULL,
  rating INT CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_verified_purchase BOOLEAN DEFAULT TRUE,
  helpful_count INT DEFAULT 0,
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  INDEX idx_product (product_id),
  INDEX idx_rating (rating)
);

-- insert data 

INSERT INTO categories (category_name, parent_category_id, description) VALUES
('Electronics', NULL, 'Electronic devices and accessories'),
('Computers', 1, 'Desktop and laptop computers'),
('Mobile Devices', 1, 'Smartphones and tablets'),
('Accessories', 1, 'Electronic accessories'),
('Audio', 1, 'Audio equipment and headphones');

INSERT INTO suppliers (supplier_name, contact_name, email, phone, country, rating) VALUES
('TechSupply Inc', 'John Smith', 'john@techsupply.com', '555-0101', 'USA', 4.5),
('GlobalElectronics', 'Maria Garcia', 'maria@global.com', '555-0102', 'China', 4.2),
('QuickShip Electronics', 'David Lee', 'david@quickship.com', '555-0103', 'Taiwan', 4.8),
('Premium Parts Co', 'Sarah Johnson', 'sarah@premiumparts.com', '555-0104', 'Germany', 4.6);

INSERT INTO products
(product_name, category_id, supplier_id, unit_price, cost_price, stock_quantity, reorder_level) 
VALUES
('Dell XPS 15 Laptop', 2, 1, 1499.99, 1100.00, 25, 5),
('MacBook Pro 14"', 2, 1, 1999.99, 1500.00, 15, 5),
('iPhone 15 Pro', 3, 2, 999.99, 750.00, 50, 10),
('Samsung Galaxy S24', 3, 2, 899.99, 680.00, 40, 10),
('Sony WH-1000XM5 Headphones', 5, 3, 349.99, 220.00, 60, 15),
('Logitech MX Master 3', 4, 3, 99.99, 65.00, 100, 20),
('USB-C Hub', 4, 4, 49.99, 25.00, 150, 30),
('Samsung 27" Monitor', 4, 2, 299.99, 200.00, 35, 10);

INSERT INTO warehouses (warehouse_name, location, capacity, manager_name) VALUES
('West Coast Hub', 'Los Angeles, CA', 10000, 'Mike Anderson'),
('East Coast Hub', 'New York, NY', 8000, 'Jennifer White'),
('Central Hub', 'Chicago, IL', 12000, 'Robert Brown');

INSERT INTO inventory (product_id, warehouse_id, quantity, last_restocked) VALUES
(1, 1, 10, '2024-01-15'),
(1, 2, 15, '2024-01-20'),
(2, 1, 8, '2024-01-18'),
(3, 2, 25, '2024-01-22'),
(3, 3, 25, '2024-01-22'),
(4, 1, 20, '2024-01-20'),
(5, 2, 30, '2024-01-25'),
(6, 3, 50, '2024-01-10'),
(7, 1, 75, '2024-01-12'),
(8, 2, 20, '2024-01-28');

INSERT INTO customers
(first_name, last_name, email, phone, registration_date, loyalty_tier, total_spent) 
VALUES
('Alice', 'Johnson', 'alice.j@email.com', '555-1001', '2023-06-15', 'Gold', 5200.00),
('Bob', 'Williams', 'bob.w@email.com', '555-1002', '2023-08-20', 'Silver', 2800.00),
('Carol', 'Davis', 'carol.d@email.com', '555-1003', '2024-01-10', 'Bronze', 450.00),
('David', 'Miller', 'david.m@email.com', '555-1004', '2023-03-05', 'Platinum', 12500.00),
('Emma', 'Wilson', 'emma.w@email.com', '555-1005', '2023-11-12', 'Silver', 1900.00);

INSERT INTO addresses
(customer_id, address_type, street_address, city, state, postal_code, is_default) 
VALUES
(1, 'Shipping', '123 Main St', 'Los Angeles', 'CA', '90001', TRUE),
(1, 'Billing', '123 Main St', 'Los Angeles', 'CA', '90001', TRUE),
(2, 'Shipping', '456 Oak Ave', 'New York', 'NY', '10001', TRUE),
(3, 'Shipping', '789 Pine Rd', 'Chicago', 'IL', '60601', TRUE),
(4, 'Shipping', '321 Elm St', 'Houston', 'TX', '77001', TRUE),
(5, 'Shipping', '654 Maple Dr', 'Phoenix', 'AZ', '85001', TRUE);

INSERT INTO employees
(first_name, last_name, email, hire_date, department, salary, manager_id) 
VALUES
('James', 'Taylor', 'james.t@techmart.com', '2020-01-15', 'Management', 95000.00, NULL),
('Lisa', 'Anderson', 'lisa.a@techmart.com', '2021-03-20', 'Sales', 65000.00, 1),
('Tom', 'Martinez', 'tom.m@techmart.com', '2022-06-10', 'Support', 55000.00, 1),
('Amy', 'Thomas', 'amy.t@techmart.com', '2021-09-05', 'Warehouse', 48000.00, 1);

INSERT INTO orders
(customer_id, order_date, shipping_address_id, order_status, total_amount, discount_amount, tax_amount, payment_method)
VALUES
(1, '2024-01-15 10:30:00', 1, 'Delivered', 1649.98, 50.00, 132.00, 'Credit Card'),
(2, '2024-01-20 14:15:00', 3, 'Delivered', 1099.98, 0.00, 88.00, 'PayPal'),
(1, '2024-01-25 09:45:00', 1, 'Shipped', 449.98, 0.00, 36.00, 'Credit Card'),
(3, '2024-02-01 16:20:00', 4, 'Processing', 2099.98, 100.00, 160.00, 'Debit Card'),
(4, '2024-02-03 11:00:00', 5, 'Pending', 3499.95, 200.00, 264.00, 'Bank Transfer');

INSERT INTO order_items
(order_id, product_id, quantity, unit_price, discount, subtotal)
VALUES
(1, 1, 1, 1499.99, 50.00, 1449.99),
(1, 6, 2, 99.99, 0.00, 199.98),
(2, 4, 1, 899.99, 0.00, 899.99),
(2, 6, 2, 99.99, 0.00, 199.98),
(3, 5, 1, 349.99, 0.00, 349.99),
(3, 7, 2, 49.99, 0.00, 99.98),
(4, 2, 1, 1999.99, 100.00, 1899.99),
(4, 8, 1, 299.99, 0.00, 299.99),
(5, 1, 2, 1499.99, 100.00, 2799.98),
(5, 5, 2, 349.99, 0.00, 699.98);

INSERT INTO shipments
(order_id, warehouse_id, shipment_date, carrier, tracking_number, estimated_delivery, actual_delivery)
VALUES
(1, 1, '2024-01-16 08:00:00', 'FedEx', 'FDX123456789', '2024-01-20', '2024-01-19'),
(2, 2, '2024-01-21 09:30:00', 'UPS', 'UPS987654321', '2024-01-25', '2024-01-24'),
(3, 2, '2024-01-26 10:15:00', 'USPS', 'USPS456789123', '2024-01-30', NULL);

INSERT INTO reviews
(product_id, customer_id, order_id, rating, review_text, helpful_count)
VALUES
(1, 1, 1, 5, 'Excellent laptop! Fast delivery and great performance.', 12),
(6, 1, 1, 4, 'Good mouse, but a bit pricey.', 5),
(4, 2, 2, 5, 'Love this phone! Best upgrade ever.', 8),
(5, 1, 3, 5, 'Amazing sound quality. Worth every penny!', 15);















