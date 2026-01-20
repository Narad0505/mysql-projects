CREATE DATABASE marketplace_db;
USE marketplace_db;
CREATE TABLE users (
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  email VARCHAR(80) UNIQUE NOT NULL,
  phone VARCHAR(15),
  role ENUM('Customer','Seller','Admin') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE sellers (
  seller_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT UNIQUE,
  shop_name VARCHAR(100) NOT NULL,
  commission_percent DECIMAL(5,2) DEFAULT 10.00,
  status ENUM('Active','Blocked') DEFAULT 'Active',
  FOREIGN KEY(user_id) REFERENCES users(user_id)
);
CREATE TABLE categories (
  category_id INT PRIMARY KEY AUTO_INCREMENT,
  category_name VARCHAR(80) NOT NULL
);
CREATE TABLE products (
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  category_id INT,
  product_name VARCHAR(120) NOT NULL,
  brand VARCHAR(60),
  description VARCHAR(300),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(category_id) REFERENCES categories(category_id)
);
CREATE TABLE product_variants (
  variant_id INT PRIMARY KEY AUTO_INCREMENT,
  product_id INT,
  sku VARCHAR(50) UNIQUE NOT NULL,
  color VARCHAR(30),
  size VARCHAR(30),
  mrp DECIMAL(10,2) NOT NULL,
  FOREIGN KEY(product_id) REFERENCES products(product_id)
);
CREATE TABLE inventory (
  inv_id INT PRIMARY KEY AUTO_INCREMENT,
  seller_id INT,
  variant_id INT,
  price DECIMAL(10,2) NOT NULL,
  stock INT DEFAULT 0,
  UNIQUE(seller_id, variant_id),
  FOREIGN KEY(seller_id) REFERENCES sellers(seller_id),
  FOREIGN KEY(variant_id) REFERENCES product_variants(variant_id)
);
CREATE TABLE coupons (
  coupon_id INT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(20) UNIQUE NOT NULL,
  discount_type ENUM('Flat','Percent') NOT NULL,
  discount_value DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);
CREATE TABLE orders (
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT,
  coupon_id INT NULL,
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('Placed','Packed','Shipped','Delivered','Cancelled') DEFAULT 'Placed',
  total_amount DECIMAL(12,2) DEFAULT 0,
  discount_amount DECIMAL(12,2) DEFAULT 0,
  payable_amount DECIMAL(12,2) DEFAULT 0,
  FOREIGN KEY(customer_id) REFERENCES users(user_id),
  FOREIGN KEY(coupon_id) REFERENCES coupons(coupon_id)
);
CREATE TABLE order_items (
  oi_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT,
  seller_id INT,
  variant_id INT,
  qty INT NOT NULL,
  selling_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY(order_id) REFERENCES orders(order_id),
  FOREIGN KEY(seller_id) REFERENCES sellers(seller_id),
  FOREIGN KEY(variant_id) REFERENCES product_variants(variant_id)
);
CREATE TABLE payments (
  payment_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT UNIQUE,
  method ENUM('UPI','Card','COD') DEFAULT 'UPI',
  payment_status ENUM('Pending','Success','Failed') DEFAULT 'Pending',
  amount DECIMAL(12,2) NOT NULL,
  paid_at TIMESTAMP NULL,
  FOREIGN KEY(order_id) REFERENCES orders(order_id)
);
CREATE TABLE seller_payouts (
  payout_id INT PRIMARY KEY AUTO_INCREMENT,
  seller_id INT,
  order_id INT,
  gross_amount DECIMAL(12,2),
  commission_amount DECIMAL(12,2),
  net_amount DECIMAL(12,2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(seller_id) REFERENCES sellers(seller_id),
  FOREIGN KEY(order_id) REFERENCES orders(order_id)
);
DELIMITER //

CREATE TRIGGER trg_reduce_stock
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
  UPDATE inventory
  SET stock = stock - NEW.qty
  WHERE seller_id = NEW.seller_id AND variant_id = NEW.variant_id;
END//

DELIMITER ;

DELIMITER //

CREATE PROCEDURE create_payouts_for_order(IN p_order_id INT)
BEGIN
  INSERT INTO seller_payouts (seller_id, order_id, gross_amount, commission_amount, net_amount)
  SELECT 
    oi.seller_id,
    oi.order_id,
    SUM(oi.qty * oi.selling_price) AS gross,
    SUM(oi.qty * oi.selling_price) * (s.commission_percent/100) AS commission,
    SUM(oi.qty * oi.selling_price) - (SUM(oi.qty * oi.selling_price) * (s.commission_percent/100)) AS net
  FROM order_items oi
  JOIN sellers s ON oi.seller_id = s.seller_id
  WHERE oi.order_id = p_order_id
  GROUP BY oi.seller_id, oi.order_id;
END//

DELIMITER ;

CREATE VIEW v_seller_sales AS
SELECT seller_id,
       SUM(qty*selling_price) AS total_sales
FROM order_items
GROUP BY seller_id;

CREATE VIEW v_daily_revenue AS
SELECT DATE(order_date) AS day,
       SUM(payable_amount) AS revenue
FROM orders
WHERE status='Delivered'
GROUP BY DATE(order_date);

INSERT INTO users(name,email,phone,role) VALUES
('Aman','aman@gmail.com','9991112222','Customer'),
('Riya','riya@gmail.com','8882223333','Customer'),
('Seller One','seller1@gmail.com','7770001111','Seller'),
('Admin','admin@gmail.com','7000000000','Admin');

-- Seller profile
INSERT INTO sellers(user_id,shop_name,commission_percent) VALUES
(3,'SellerOne Store',12.00);

-- Categories
INSERT INTO categories(category_name) VALUES ('Mobiles'),('Clothes');

-- Products + variants
INSERT INTO products(category_id,product_name,brand,description)
VALUES (1,'Smartphone X','BrandX','5G phone');

INSERT INTO product_variants(product_id,sku,color,size,mrp)
VALUES (1,'SKU-X-BLACK','Black','128GB',30000);

-- Inventory
INSERT INTO inventory(seller_id,variant_id,price,stock)
VALUES (1,1,28000,50);

-- Coupon
INSERT INTO coupons(code,discount_type,discount_value,min_order_amount)
VALUES ('NEW100','Flat',100,500);

-- Create order
INSERT INTO orders(customer_id,coupon_id,status,total_amount,discount_amount,payable_amount)
VALUES (1,1,'Placed',0,0,0);

-- Add item (trigger reduces stock)
INSERT INTO order_items(order_id,seller_id,variant_id,qty,selling_price)
VALUES (1,1,1,2,28000);

-- Update totals
UPDATE orders
SET total_amount = (SELECT SUM(qty*selling_price) FROM order_items WHERE order_id=1),
    discount_amount = 100,
    payable_amount = (SELECT SUM(qty*selling_price) FROM order_items WHERE order_id=1) - 100
WHERE order_id=1;
 
 -- Payment
INSERT INTO payments(order_id,method,payment_status,amount,paid_at)
VALUES (1,'UPI','Success',(SELECT payable_amount FROM orders WHERE order_id=1), NOW());

-- Delivered
UPDATE orders SET status='Delivered' WHERE order_id=1;

-- Create payout
CALL create_payouts_for_order(1);

-- Full order summary
SELECT o.order_id, u.name AS customer, o.status, o.payable_amount, p.payment_status
FROM orders o
JOIN users u ON o.customer_id=u.user_id
LEFT JOIN payments p ON o.order_id=p.order_id;

-- Remaining stock
SELECT s.shop_name, pv.sku, i.stock
FROM inventory i
JOIN sellers s ON i.seller_id=s.seller_id
JOIN product_variants pv ON i.variant_id=pv.variant_id;

-- Seller payouts
SELECT * FROM seller_payouts;