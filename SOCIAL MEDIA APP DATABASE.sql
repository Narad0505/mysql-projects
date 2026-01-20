CREATE DATABASE social_app_db;
USE social_app_db;

CREATE TABLE users(
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(40) UNIQUE NOT NULL,
  bio VARCHAR(200),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts(
  post_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT,
  content VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(user_id) REFERENCES users(user_id)
);

CREATE TABLE follows(
  follower_id INT,
  following_id INT,
  followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(follower_id, following_id),
  FOREIGN KEY(follower_id) REFERENCES users(user_id),
  FOREIGN KEY(following_id) REFERENCES users(user_id)
);

CREATE TABLE likes(
  user_id INT,
  post_id INT,
  liked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(user_id, post_id),
  FOREIGN KEY(user_id) REFERENCES users(user_id),
  FOREIGN KEY(post_id) REFERENCES posts(post_id)
);

CREATE TABLE comments(
  comment_id INT PRIMARY KEY AUTO_INCREMENT,
  post_id INT,
  user_id INT,
  comment_text VARCHAR(300),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(post_id) REFERENCES posts(post_id),
  FOREIGN KEY(user_id) REFERENCES users(user_id)
);

INSERT INTO users(username,bio) VALUES
('aman','Coder'),
('riya','Student'),
('rahul','Gamer');

INSERT INTO posts(user_id,content) VALUES
(1,'Hello World!'),
(2,'My first post'),
(3,'Gaming tonight');

INSERT INTO follows(follower_id,following_id) VALUES
(1,2),(1,3);

INSERT INTO likes(user_id,post_id) VALUES
(1,2),(2,1);

INSERT INTO comments(post_id,user_id,comment_text) VALUES
(2,1,'Nice post!'),
(1,2,'Welcome!');

SELECT p.post_id, u.username, p.content, p.created_at
FROM posts p
JOIN follows f ON p.user_id = f.following_id
JOIN users u ON u.user_id = p.user_id
WHERE f.follower_id = 1
ORDER BY p.created_at DESC;

SELECT p.post_id, p.content, COUNT(l.user_id) AS total_likes
FROM posts p
LEFT JOIN likes l ON p.post_id=l.post_id
GROUP BY p.post_id, p.content
ORDER BY total_likes DESC;

SELECT u.username, c.comment_text, c.created_at
FROM comments c
JOIN users u ON c.user_id=u.user_id
WHERE c.post_id=2;
