CREATE DATABASE logistics_db;
USE logistics_db;

CREATE TABLE drivers (
  driver_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  phone VARCHAR(15),
  status ENUM('Available','OnTrip','Inactive') DEFAULT 'Available'
);

CREATE TABLE vehicles (
  vehicle_id INT PRIMARY KEY AUTO_INCREMENT,
  vehicle_number VARCHAR(20) UNIQUE NOT NULL,
  vehicle_type ENUM('Bike','Van','Truck') NOT NULL,
  capacity_kg INT DEFAULT 0,
  status ENUM('Active','Maintenance') DEFAULT 'Active'
);

CREATE TABLE driver_vehicle (
  driver_id INT,
  vehicle_id INT,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(driver_id, vehicle_id),
  FOREIGN KEY(driver_id) REFERENCES drivers(driver_id),
  FOREIGN KEY(vehicle_id) REFERENCES vehicles(vehicle_id)
);

CREATE TABLE customers (
  customer_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(60),
  phone VARCHAR(15)
);

CREATE TABLE shipments (
  shipment_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT,
  pickup_address VARCHAR(200),
  drop_address VARCHAR(200),
  weight_kg INT,
  status ENUM('Created','Assigned','Picked','InTransit','Delivered','Cancelled') DEFAULT 'Created',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE trips (
  trip_id INT PRIMARY KEY AUTO_INCREMENT,
  shipment_id INT UNIQUE,
  driver_id INT,
  vehicle_id INT,
  start_time TIMESTAMP NULL,
  end_time TIMESTAMP NULL,
  trip_status ENUM('Assigned','Started','Completed') DEFAULT 'Assigned',
  FOREIGN KEY(shipment_id) REFERENCES shipments(shipment_id),
  FOREIGN KEY(driver_id) REFERENCES drivers(driver_id),
  FOREIGN KEY(vehicle_id) REFERENCES vehicles(vehicle_id)
);

CREATE TABLE tracking_events (
  event_id INT PRIMARY KEY AUTO_INCREMENT,
  shipment_id INT,
  event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  location VARCHAR(120),
  status ENUM('Picked','InTransit','Delivered'),
  FOREIGN KEY(shipment_id) REFERENCES shipments(shipment_id)
);

DELIMITER //

CREATE PROCEDURE assign_shipment(
  IN p_shipment_id INT,
  IN p_driver_id INT,
  IN p_vehicle_id INT
)
BEGIN
  -- create trip
  INSERT INTO trips(shipment_id,driver_id,vehicle_id,trip_status)
  VALUES(p_shipment_id,p_driver_id,p_vehicle_id,'Assigned');

  -- update shipment status
  UPDATE shipments SET status='Assigned'
  WHERE shipment_id=p_shipment_id;

  -- update driver status
  UPDATE drivers SET status='OnTrip' WHERE driver_id=p_driver_id;
END//

DELIMITER ;

DELIMITER //

CREATE TRIGGER trg_driver_available_after_delivery
AFTER INSERT ON tracking_events
FOR EACH ROW
BEGIN
  IF NEW.status='Delivered' THEN
    UPDATE shipments
    SET status='Delivered'
    WHERE shipment_id=NEW.shipment_id;

    UPDATE trips
    SET trip_status='Completed', end_time=NOW()
    WHERE shipment_id=NEW.shipment_id;

    UPDATE drivers
    SET status='Available'
    WHERE driver_id = (SELECT driver_id FROM trips WHERE shipment_id=NEW.shipment_id);
  END IF;
END//

DELIMITER ;

INSERT INTO drivers(name,phone) VALUES
('Rahul','9990001111'),
('Amit','8880002222');

INSERT INTO vehicles(vehicle_number,vehicle_type,capacity_kg) VALUES
('DL01AB1234','Van',300),
('DL02CD5678','Truck',1000);

INSERT INTO customers(name,phone) VALUES
('Aman','9991112222');

INSERT INTO shipments(customer_id,pickup_address,drop_address,weight_kg)
VALUES (1,'Delhi Warehouse','Noida Sector 62',20);

CALL assign_shipment(1,1,1);

INSERT INTO tracking_events(shipment_id,location,status)
VALUES (1,'Delhi','Picked'),
       (1,'Noida','InTransit'),
       (1,'Noida Sector 62','Delivered');

-- Shipment + driver + vehicle details
SELECT s.shipment_id, s.status, d.name AS driver, v.vehicle_number, v.vehicle_type
FROM shipments s
JOIN trips t ON s.shipment_id=t.shipment_id
JOIN drivers d ON t.driver_id=d.driver_id
JOIN vehicles v ON t.vehicle_id=v.vehicle_id;

-- Full tracking history
SELECT * FROM tracking_events WHERE shipment_id=1 ORDER BY event_time;
