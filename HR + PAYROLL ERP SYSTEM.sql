CREATE DATABASE hr_payroll_db;
USE hr_payroll_db;

CREATE TABLE departments(
  dept_id INT PRIMARY KEY AUTO_INCREMENT,
  dept_name VARCHAR(60) UNIQUE NOT NULL
);

CREATE TABLE employees(
  emp_id INT PRIMARY KEY AUTO_INCREMENT,
  dept_id INT,
  name VARCHAR(60) NOT NULL,
  phone VARCHAR(15),
  base_salary DECIMAL(12,2) NOT NULL,
  join_date DATE,
  status ENUM('Active','Resigned') DEFAULT 'Active',
  FOREIGN KEY(dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE emp_attendance(
  att_id INT PRIMARY KEY AUTO_INCREMENT,
  emp_id INT,
  att_date DATE,
  status ENUM('Present','Absent','Leave') DEFAULT 'Present',
  UNIQUE(emp_id, att_date),
  FOREIGN KEY(emp_id) REFERENCES employees(emp_id)
);

CREATE TABLE leave_requests(
  leave_id INT PRIMARY KEY AUTO_INCREMENT,
  emp_id INT,
  from_date DATE,
  to_date DATE,
  reason VARCHAR(150),
  status ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
  FOREIGN KEY(emp_id) REFERENCES employees(emp_id)
);

CREATE TABLE payroll(
  payroll_id INT PRIMARY KEY AUTO_INCREMENT,
  emp_id INT,
  month_year VARCHAR(7), -- YYYY-MM
  present_days INT DEFAULT 0,
  deductions DECIMAL(12,2) DEFAULT 0,
  net_salary DECIMAL(12,2) DEFAULT 0,
  generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(emp_id, month_year),
  FOREIGN KEY(emp_id) REFERENCES employees(emp_id)
);

DELIMITER //

CREATE PROCEDURE generate_payroll(
  IN p_emp_id INT,
  IN p_month_year VARCHAR(7)
)
BEGIN
  DECLARE total_present INT DEFAULT 0;
  DECLARE salary DECIMAL(12,2);

  SELECT base_salary INTO salary FROM employees WHERE emp_id=p_emp_id;

  SELECT COUNT(*) INTO total_present
  FROM emp_attendance
  WHERE emp_id=p_emp_id
    AND status='Present'
    AND DATE_FORMAT(att_date,'%Y-%m')=p_month_year;

  -- Simple deduction logic: 100 per absent day
  INSERT INTO payroll(emp_id,month_year,present_days,deductions,net_salary)
  VALUES(
    p_emp_id,
    p_month_year,
    total_present,
    (30-total_present)*100,
    salary - ((30-total_present)*100)
  )
  ON DUPLICATE KEY UPDATE
    present_days=total_present,
    deductions=(30-total_present)*100,
    net_salary=salary - ((30-total_present)*100);
END//

DELIMITER ;

INSERT INTO departments(dept_name) VALUES ('IT'),('HR');

INSERT INTO employees(dept_id,name,phone,base_salary,join_date)
VALUES (1,'Aman','9991112222',30000,'2025-06-01');

-- Attendance for Jan 2026
INSERT INTO emp_attendance(emp_id,att_date,status) VALUES
(1,'2026-01-01','Present'),
(1,'2026-01-02','Present'),
(1,'2026-01-03','Absent');

CALL generate_payroll(1,'2026-01');

-- Payroll report
SELECT e.name, p.month_year, p.present_days, p.deductions, p.net_salary
FROM payroll p
JOIN employees e ON p.emp_id=e.emp_id;

-- Attendance summary
SELECT e.name,
       SUM(a.status = 'Present') AS present_days,
       SUM(a.status = 'Absent')  AS absent_days,
       SUM(a.status = 'Leave')   AS leave_days
FROM emp_attendance a
JOIN employees e ON a.emp_id = e.emp_id
WHERE DATE_FORMAT(a.att_date, '%Y-%m') = '2026-01'
GROUP BY e.name;
