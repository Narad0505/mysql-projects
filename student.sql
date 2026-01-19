CREATE DATABASE student_mgmt;
USE student_mgmt;

CREATE TABLE students (
  student_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  dob DATE,
  class VARCHAR(10),
  section VARCHAR(5),
  phone VARCHAR(15)
);
CREATE TABLE subjects (
  subject_id INT PRIMARY KEY AUTO_INCREMENT,
  subject_name VARCHAR(50) NOT NULL
);
CREATE TABLE marks (
  mark_id INT PRIMARY KEY AUTO_INCREMENT,
  student_id INT,
  subject_id INT,
  marks INT CHECK (marks BETWEEN 0 AND 100),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);
CREATE TABLE attendance (
  att_id INT PRIMARY KEY AUTO_INCREMENT,
  student_id INT,
  date DATE,
  status ENUM('Present','Absent') DEFAULT 'Present',
  FOREIGN KEY (student_id) REFERENCES students(student_id)
);
INSERT INTO students(name,dob,class,section,phone)
VALUES ('Aman','2006-02-10','10','A','9991112222');

INSERT INTO subjects(subject_name)
VALUES ('Math'), ('Science');

INSERT INTO marks(student_id,subject_id,marks)
VALUES (1,1,85);

INSERT INTO attendance(student_id,date,status)
VALUES (1,'2026-01-01','Present');

SELECT s.name, sub.subject_name, m.marks
FROM marks m
JOIN students s ON m.student_id = s.student_id
JOIN subjects sub ON m.subject_id = sub.subject_id;
