CREATE DATABASE banking_db;
USE banking_db;

CREATE TABLE customers(
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  phone VARCHAR(15),
  kyc_status ENUM('Pending','Verified') DEFAULT 'Pending'
);

CREATE TABLE accounts(
  account_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT,
  account_type ENUM('Saving','Current') DEFAULT 'Saving',
  balance DECIMAL(12,2) DEFAULT 0,
  status ENUM('Active','Blocked') DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE transactions(
  txn_id INT PRIMARY KEY AUTO_INCREMENT,
  account_id INT,
  txn_type ENUM('Credit','Debit') NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  txn_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  remarks VARCHAR(150),
  FOREIGN KEY(account_id) REFERENCES accounts(account_id)
);

CREATE TABLE fraud_alerts(
  alert_id INT PRIMARY KEY AUTO_INCREMENT,
  txn_id INT UNIQUE,
  reason VARCHAR(200),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(txn_id) REFERENCES transactions(txn_id)
);

DELIMITER //

CREATE PROCEDURE do_transaction(
  IN p_account_id INT,
  IN p_type ENUM('Credit','Debit'),
  IN p_amount DECIMAL(12,2),
  IN p_remarks VARCHAR(150)
)
BEGIN
  DECLARE current_balance DECIMAL(12,2);

  SELECT balance INTO current_balance FROM accounts WHERE account_id = p_account_id;

  IF p_type='Debit' AND current_balance < p_amount THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Insufficient balance';
  ELSE
    -- Insert transaction
    INSERT INTO transactions(account_id,txn_type,amount,remarks)
    VALUES (p_account_id,p_type,p_amount,p_remarks);

    -- Update balance
    IF p_type='Credit' THEN
      UPDATE accounts SET balance = balance + p_amount WHERE account_id=p_account_id;
    ELSE
      UPDATE accounts SET balance = balance - p_amount WHERE account_id=p_account_id;
    END IF;
  END IF;
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_fraud_check
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  IF NEW.amount > 50000 THEN
    INSERT INTO fraud_alerts(txn_id,reason)
    VALUES(NEW.txn_id,'High value transaction detected');
  END IF;
END//

DELIMITER ;

INSERT INTO customers(name,phone,kyc_status)
VALUES ('Aman','9991112222','Verified');

INSERT INTO accounts(customer_id,account_type,balance)
VALUES (1,'Saving',100000);

-- Credit
CALL do_transaction(1,'Credit',2000,'Salary Bonus');

-- Debit
CALL do_transaction(1,'Debit',500,'ATM Withdraw');

-- High debit triggers fraud alert
CALL do_transaction(1,'Debit',60000,'Large Transfer');

-- All transactions
SELECT * FROM transactions;

-- Fraud alerts list
SELECT f.alert_id, t.account_id, t.amount, f.reason, f.created_at
FROM fraud_alerts f
JOIN transactions t ON f.txn_id=t.txn_id;

-- Account summary
SELECT c.name, a.account_type, a.balance, a.status
FROM accounts a
JOIN customers c ON a.customer_id=c.customer_id;
