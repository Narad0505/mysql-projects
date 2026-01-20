CREATE DATABASE lms_db;
USE lms_db;

CREATE TABLE users(
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  email VARCHAR(80) UNIQUE NOT NULL,
  role ENUM('Student','Instructor') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses(
  course_id INT PRIMARY KEY AUTO_INCREMENT,
  instructor_id INT,
  title VARCHAR(120) NOT NULL,
  description VARCHAR(300),
  price DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(instructor_id) REFERENCES users(user_id)
);

CREATE TABLE lessons(
  lesson_id INT PRIMARY KEY AUTO_INCREMENT,
  course_id INT,
  lesson_title VARCHAR(120),
  content VARCHAR(500),
  lesson_order INT,
  FOREIGN KEY(course_id) REFERENCES courses(course_id)
);

CREATE TABLE enrollments(
  enroll_id INT PRIMARY KEY AUTO_INCREMENT,
  course_id INT,
  student_id INT,
  enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('Active','Completed') DEFAULT 'Active',
  UNIQUE(course_id, student_id),
  FOREIGN KEY(course_id) REFERENCES courses(course_id),
  FOREIGN KEY(student_id) REFERENCES users(user_id)
);

CREATE TABLE lesson_progress(
  progress_id INT PRIMARY KEY AUTO_INCREMENT,
  enroll_id INT,
  lesson_id INT,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP NULL,
  UNIQUE(enroll_id, lesson_id),
  FOREIGN KEY(enroll_id) REFERENCES enrollments(enroll_id),
  FOREIGN KEY(lesson_id) REFERENCES lessons(lesson_id)
);

CREATE TABLE quizzes(
  quiz_id INT PRIMARY KEY AUTO_INCREMENT,
  course_id INT,
  quiz_title VARCHAR(100),
  FOREIGN KEY(course_id) REFERENCES courses(course_id)
);

CREATE VIEW v_course_progress AS
SELECT 
  e.enroll_id,
  e.course_id,
  e.student_id,
  ROUND( (SUM(lp.completed=TRUE) / COUNT(lp.lesson_id)) * 100 , 2) AS completion_percent
FROM enrollments e
JOIN lessons l ON e.course_id=l.course_id
LEFT JOIN lesson_progress lp ON lp.enroll_id=e.enroll_id AND lp.lesson_id=l.lesson_id
GROUP BY e.enroll_id, e.course_id, e.student_id;

DELIMITER //

CREATE PROCEDURE mark_lesson_complete(
  IN p_course_id INT,
  IN p_student_id INT,
  IN p_lesson_id INT
)
BEGIN
  DECLARE v_enroll_id INT;

  SELECT enroll_id INTO v_enroll_id
  FROM enrollments
  WHERE course_id=p_course_id AND student_id=p_student_id;

  INSERT INTO lesson_progress(enroll_id,lesson_id,completed,completed_at)
  VALUES(v_enroll_id,p_lesson_id,TRUE,NOW())
  ON DUPLICATE KEY UPDATE completed=TRUE, completed_at=NOW();
END//

DELIMITER ;

-- Users
INSERT INTO users(name,email,role) VALUES
('Aman','aman@gmail.com','Student'),
('Riya','riya@gmail.com','Student'),
('Teacher1','teach1@gmail.com','Instructor');

-- Course
INSERT INTO courses(instructor_id,title,description,price)
VALUES (3,'MySQL Mastery','Complete MySQL Course',499);

-- Lessons
INSERT INTO lessons(course_id,lesson_title,content,lesson_order) VALUES
(1,'Intro','Welcome',1),
(1,'Tables','Create Tables',2),
(1,'Joins','Learn Joins',3);

-- Enrollment
INSERT INTO enrollments(course_id,student_id) VALUES (1,1);

-- Mark 2 lessons complete
CALL mark_lesson_complete(1,1,1);
CALL mark_lesson_complete(1,1,2);

-- Quiz + score
INSERT INTO quizzes(course_id,quiz_title) VALUES (1,'SQL Basics Test');
INSERT INTO quiz_scores(quiz_id,student_id,score) VALUES (1,1,85);

-- Student progress %
SELECT * FROM v_course_progress;

-- Course lessons list
SELECT c.title, l.lesson_title, l.lesson_order
FROM courses c
JOIN lessons l ON c.course_id=l.course_id
ORDER BY l.lesson_order;

-- Leaderboard
SELECT u.name, AVG(s.score) AS avg_score
FROM quiz_scores s
JOIN users u ON s.student_id=u.user_id
GROUP BY u.name
ORDER BY avg_score DESC;
