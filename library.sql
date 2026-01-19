CREATE DATABASE library_mgmt;
USE library_mgmt;

CREATE TABLE books(
  book_id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(100),
  author VARCHAR(50),
  category VARCHAR(50),
  copies INT DEFAULT 1
);
CREATE TABLE members(
  member_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50),
  phone VARCHAR(15)
);
CREATE TABLE issue(
  issue_id INT PRIMARY KEY AUTO_INCREMENT,
  book_id INT,
  member_id INT,
  issue_date DATE,
  return_date DATE,
  status ENUM('Issued','Returned') DEFAULT 'Issued',
  FOREIGN KEY(book_id) REFERENCES books(book_id),
  FOREIGN KEY(member_id) REFERENCES members(member_id)
);
CREATE TABLE fine(
  fine_id INT PRIMARY KEY AUTO_INCREMENT,
  issue_id INT,
  amount INT DEFAULT 0,
  FOREIGN KEY(issue_id) REFERENCES issue(issue_id)
);
INSERT INTO issue(book_id,member_id,issue_date,status)
VALUES (1,1,'2026-01-01','Issued');

UPDATE issue SET status='Returned', return_date='2026-01-10'
WHERE issue_id=1;
