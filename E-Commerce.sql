CREATE DATABASE ecommerce_mgmt;
USE ecommerce_mgmt;

CREATE TABLE users(
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50),
  email VARCHAR(50) UNIQUE,
  password VARCHAR(50)
);
CREATE TABLE categories(
  category_id INT PRIMARY KEY AUTO_INCREMENT,
  category_name VARCHAR(50)
);

CREATE TABLE products(
  product_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  price DECIMAL(10,2),
  stock INT,
  category_id INT,
  FOREIGN KEY(category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders(
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT,
  total DECIMAL(10,2),
  order_date DATE,
  status ENUM('Pending','Paid','Cancelled') DEFAULT 'Pending',
  FOREIGN KEY(user_id) REFERENCES users(user_id)
);

CREATE TABLE order_items(
  item_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT,
  product_id INT,
  qty INT,
  price DECIMAL(10,2),
  FOREIGN KEY(order_id) REFERENCES orders(order_id),
  FOREIGN KEY(product_id) REFERENCES products(product_id)
);

SELECT o.order_id, u.name, p.name AS product, oi.qty, oi.price, o.total
FROM orders o
JOIN users u ON o.user_id=u.user_id
JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id;

