-- Dropping tables if they exist

DROP TABLE pilot CASCADE CONSTRAINTS;
DROP TABLE flight CASCADE CONSTRAINTS;
DROP TABLE airplane CASCADE CONSTRAINTS;
DROP TABLE employee CASCADE CONSTRAINTS;
DROP TABLE flight_staff CASCADE CONSTRAINTS;
DROP TABLE ticket CASCADE CONSTRAINTS;
DROP TABLE passenger CASCADE CONSTRAINTS;
DROP TABLE emp_type CASCADE CONSTRAINTS;
DROP TABLE location CASCADE CONSTRAINTS;
DROP TABLE luggage CASCADE CONSTRAINTS;
DROP SEQUENCE passenger_seq;
DROP SEQUENCE flight_seq;
DROP SEQUENCE pilot_seq;
DROP SEQUENCE airplane_seq;
DROP FUNCTION get_flight_time;
DROP INDEX idx_passenger_email;
DROP INDEX idx_employee_last_name;
DROP INDEX idx_flight_staff_flight_id;
DROP TRIGGER trg_employee_full_name;
DROP TRIGGER trg_new_location;
DROP PROCEDURE insert_flight_data;

DROP PROCEDURE get_base_ticket_price;
DROP FUNCTION check_additional_charge;
DROP PROCEDURE calculate_total_price;
DROP PROCEDURE print_price_details;
DROP PACKAGE ticket_pricing_pkg;
DROP PACKAGE BODY ticket_pricing_pkg;

-- Table creation
CREATE TABLE location (
    locationCode CHAR(3),
    locationDesc VARCHAR(50),
    utcOffset NUMBER(2),
    latitude NUMBER(9, 6),
    longitude NUMBER(9, 6),
    CONSTRAINT location_locationCode_pk PRIMARY KEY ( locationCode )
);

CREATE TABLE emp_type (
    employeeID NUMBER(5),
    jobDescription VARCHAR2(50),
    CONSTRAINT emp_type_employeeID_pk PRIMARY KEY (employeeID)
);

CREATE TABLE employee (
    employee#     NUMBER(3),
    first_name    VARCHAR2(26),
    last_name     VARCHAR2(26),
    CONSTRAINT employee_employee#_pk PRIMARY KEY ( employee# )
);

CREATE TABLE pilot (
    pilot_id  NUMBER(10),
    employee# NUMBER(10),
    license#  NUMBER(10),
    CONSTRAINT pilot_pilot_id_pk PRIMARY KEY ( pilot_id ),
    CONSTRAINT pilot_pilot_id_ck CHECK ( pilot_id >= 1 ),
    CONSTRAINT pilot_employee#_fk FOREIGN KEY ( employee# )
        REFERENCES employee ( employee# ),
    CONSTRAINT pilot_employee#_uk UNIQUE ( employee# ),
    CONSTRAINT pilot_employee#_ck CHECK ( employee# >= 1 ),
    CONSTRAINT pilot_license#_uk UNIQUE ( license# ),
    CONSTRAINT pilot_license#_ck CHECK ( license# >= 1 )
);

CREATE TABLE airplane (
    airplane_id   NUMBER(10),
    model#        VARCHAR2(20),
    airplane_name VARCHAR2(50),
    company       VARCHAR2(50),
    CONSTRAINT airplane_airplane_id_pk PRIMARY KEY ( airplane_id )
);

CREATE TABLE flight (
    flight_id      NUMBER(10),
    airplane_id    NUMBER(10),
    pilot_id       NUMBER(10),
    origin         CHAR(3),
    destination    CHAR(3),
    departure_date TIMESTAMP(1),
    arrival_date   TIMESTAMP(1),
    CONSTRAINT flight_flight_id_pk PRIMARY KEY ( flight_id ),
    CONSTRAINT flight_airplane_id_fk FOREIGN KEY ( airplane_id )
        REFERENCES airplane ( airplane_id ),
    CONSTRAINT flight_airplane_id_uk UNIQUE ( airplane_id ),
    CONSTRAINT flight_pilot_id_fk FOREIGN KEY ( pilot_id )
        REFERENCES pilot ( pilot_id ),
    CONSTRAINT flight_pilot_id_uk UNIQUE ( pilot_id ),
    CONSTRAINT flight_origin_fk FOREIGN KEY (origin)
        REFERENCES location (locationCode),
    CONSTRAINT flight_destination_fk FOREIGN KEY (destination)
        REFERENCES location (locationCode),
    CONSTRAINT flight_origin_dest_diff_ck
        CHECK (origin != destination)
);

CREATE TABLE passenger (
    passenger_id NUMBER(10),
    first_name   VARCHAR2(26),
    last_name    VARCHAR2(26),
    email        VARCHAR2(50),
    phone        VARCHAR2(15),
    address      VARCHAR2(100),
    CONSTRAINT passenger_passenger_id_pk PRIMARY KEY ( passenger_id )
);

CREATE TABLE flight_staff (
    staff_id  NUMBER(10),
    employee# NUMBER(10),
    flight_id NUMBER(10),
    --  designation between 1 and 5 becuase
    designation NUMBER(1),
    CONSTRAINT flight_staff_staff_id_pk PRIMARY KEY ( staff_id ),
    CONSTRAINT flight_staff_employee#_fk FOREIGN KEY ( employee# )
        REFERENCES employee ( employee# ),
    CONSTRAINT flight_staff_flight_id_fk FOREIGN KEY ( flight_id )
        REFERENCES flight ( flight_id ),
    CONSTRAINT flight_staff_employee#_uk UNIQUE ( employee# ),
    CONSTRAINT designation_ck
        CHECK (designation BETWEEN 2 AND 5)
);

CREATE TABLE ticket (
    passenger_id  NUMBER(10),
    flight_id     NUMBER(10),
    seating_class VARCHAR2(15),
    CONSTRAINT ticket_ticket_id_pk PRIMARY KEY ( passenger_id, flight_id ),
    CONSTRAINT ticket_passenger_id_fk FOREIGN KEY ( passenger_id )
        REFERENCES passenger ( passenger_id ),
    CONSTRAINT ticket_flight_id_fk FOREIGN KEY ( flight_id )
        REFERENCES flight ( flight_id )
);

CREATE TABLE luggage (
    luggage_id    NUMBER(10) PRIMARY KEY,
    passenger_id  NUMBER(10) NOT NULL,
    flight_id     NUMBER(10) NOT NULL,
    weight        NUMBER(5, 2) NOT NULL,
    description   VARCHAR2(100),
    -- Uses a composite key to ensure luggage ends up on the same flight that passengers are booked on
    CONSTRAINT luggage_passenger_id_fk FOREIGN KEY (passenger_id, flight_id)
        REFERENCES ticket (passenger_id, flight_id)
);


-- PL/SQL function/procedure declaration
CREATE OR REPLACE FUNCTION get_flight_time(
    p_from_location IN CHAR,
    p_to_location IN CHAR
) RETURN NUMBER IS
    v_latitude_from NUMBER(9,6);
    v_longitude_from NUMBER(9,6);
    v_latitude_to NUMBER(9,6);
    v_longitude_to NUMBER(9,6);
    v_flight_time NUMBER;

BEGIN
    BEGIN
        SELECT latitude, longitude
        INTO v_latitude_from, v_longitude_from
        FROM LOCATION
        WHERE locationCode = p_from_location;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No data found for From location: ' || p_from_location);
            RETURN NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error fetching From location: ' || SQLERRM);
            RETURN NULL;
    END;

    BEGIN
        SELECT latitude, longitude
        INTO v_latitude_to, v_longitude_to
        FROM LOCATION
        WHERE locationCode = p_to_location;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No data found for To location: ' || p_to_location);
            RETURN NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error fetching To location: ' || SQLERRM);
            RETURN NULL;
    END;

    DBMS_OUTPUT.PUT_LINE('From location (' || p_from_location || '): Lat=' || v_latitude_from || ', Lon=' || v_longitude_from);
    DBMS_OUTPUT.PUT_LINE('To location (' || p_to_location || '): Lat=' || v_latitude_to || ', Lon=' || v_longitude_to);

    v_flight_time := ROUND(6371 * 2 * ASIN(
                        SQRT(
                            SIN((v_latitude_to - v_latitude_from) * 3.1415 / 180 / 2) * SIN((v_latitude_to - v_latitude_from) * 3.1415 / 180 / 2) +
                            COS(v_latitude_from * 3.1415 / 180) * COS(v_latitude_to * 3.1415 / 180) *
                            SIN((v_longitude_to - v_longitude_from) * 3.1415 / 180 / 2) * SIN((v_longitude_to - v_longitude_from) * 3.1415 / 180 / 2)
                        ) / 800
                    ), 2);

    RETURN v_flight_time;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
        RETURN NULL;
END get_flight_time;

-- Passenger ID sequence
CREATE SEQUENCE passenger_seq
START WITH 100
INCREMENT BY 1;

-- FLight ID sequence
CREATE SEQUENCE flight_seq
START with 1000
INCREMENT BY 1;

-- Airplane ID sequence
CREATE SEQUENCE airplane_seq
START WITH 9000
INCREMENT BY 10;

-- Pilot id sequence (used for procedure)
CREATE SEQUENCE pilot_seq
START WITH 1
INCREMENT BY 1;

-- Procedure for calculating and inserting flight data
CREATE OR REPLACE PROCEDURE insert_flight_data(
    p_origin IN CHAR,
    p_destination IN CHAR,
    p_departure_date IN TIMESTAMP
) IS
    lv_flight_time NUMBER;
    lv_arrival_date TIMESTAMP;
    lv_airplane_id NUMBER;
    
    -- define cursor for pulling airplane and pilot IDs from respective tables
    CURSOR airplane_cursor IS
        SELECT airplane_id
        FROM airplane;
BEGIN
        -- Calculate the flight time and arrival date
        lv_flight_time := get_flight_time(p_origin, p_destination);
        lv_arrival_date := p_departure_date + (lv_flight_time / 24);
        lv_airplane_id := airplane_seq.NEXTVAL;
        
        -- Insert into the flight table
        INSERT INTO flight (
            flight_id,
            airplane_id,
            pilot_id,
            origin,
            destination,
            departure_date,
            arrival_date
        ) VALUES (
            flight_seq.NEXTVAL,
            lv_airplane_id,
            pilot_seq.NEXTVAL,
            p_origin,
            p_destination,
            p_departure_date,
            lv_arrival_date
        );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END insert_flight_data;

-- Creating index to search passengers by last name
CREATE UNIQUE INDEX idx_passenger_email
ON PASSENGER (email);

-- Inserting data
INSERT INTO LOCATION 
VALUES ('LAX', 'Los Angeles International Airport', -8, 33.9416, -118.4085);
INSERT INTO LOCATION 
VALUES ('JFK', 'John F. Kennedy International Airport', -5, 40.6413, -73.7781);
INSERT INTO LOCATION 
VALUES ('LHR', 'London Heathrow Airport', 0, 51.5074, -0.1278);
INSERT INTO LOCATION 
VALUES ('ORD', 'O''Hare International Airport', -6, 41.9744, -87.9071);
INSERT INTO LOCATION 
VALUES ('CDG', 'Charles de Gaulle Airport', 1, 49.0097, 2.5479);
INSERT INTO LOCATION 
VALUES ('SYD', 'Sydney Kingsford Smith Airport', 10, -33.8688, 151.2093);
INSERT INTO LOCATION 
VALUES ('HKG', 'Hong Kong International Airport', 8, 22.3080, 113.9141);
INSERT INTO LOCATION 
VALUES ('BKK', 'Suvarnabhumi Airport', 7, 13.6897, 100.7501);
INSERT INTO LOCATION 
VALUES ('DXB', 'Dubai International Airport', 4, 25.276987, 55.396999);
INSERT INTO LOCATION 
VALUES ('FRA', 'Frankfurt Airport', 1, 50.1109, 8.6821);

INSERT INTO emp_type VALUES (1, 'Airplane Cleaner');
INSERT INTO emp_type VALUES (2, 'Flight Attendant');
INSERT INTO emp_type VALUES (3, 'Mechanic');
INSERT INTO emp_type VALUES (4, 'Baggage Handler');
INSERT INTO emp_type VALUES (5, 'Aircraft Fueler');

INSERT INTO employee VALUES (001,'John','Doe');
INSERT INTO employee VALUES (002,'Jane','Smith');
INSERT INTO employee VALUES (003,'Robert','Brown');
INSERT INTO employee VALUES (004,'Emily','Johnson');
INSERT INTO employee VALUES (005,'Paul','Delores');
INSERT INTO employee VALUES (006,'Channing','Bosum');
INSERT INTO employee VALUES (007,'Shaun','Jacobson');
INSERT INTO employee VALUES (008,'Lauren','Moser');
INSERT INTO employee VALUES (009,'Tina','Shaw');
INSERT INTO employee VALUES (010,'Pradeep','Singh');
INSERT INTO employee VALUES (011,'Farukh','Khan');
INSERT INTO employee VALUES (012,'Lin','Miyazaki');
INSERT INTO employee VALUES (013, 'Alice', 'Johnson');
INSERT INTO employee VALUES (014, 'Bob', 'Smith');
INSERT INTO employee VALUES (015, 'Charlie', 'Brown');
INSERT INTO employee VALUES (016, 'David', 'Wilson');
INSERT INTO employee VALUES (017, 'Eve', 'Davis');
INSERT INTO employee VALUES (018, 'Frank', 'Moore');
INSERT INTO employee VALUES (019, 'Grace', 'Taylor');
INSERT INTO employee VALUES (020, 'Hannah', 'Anderson');

INSERT INTO pilot VALUES (1, 001, 1001);
INSERT INTO pilot VALUES (2, 002, 1002);
INSERT INTO pilot VALUES (3, 003, 1003);
INSERT INTO pilot VALUES (4, 004, 1004);
INSERT INTO pilot VALUES (5, 005, 1005);
INSERT INTO pilot VALUES (6, 006, 1006);
INSERT INTO pilot VALUES (7, 007, 1007);
INSERT INTO pilot VALUES (8, 008, 1008);
INSERT INTO pilot VALUES (9, 009, 1009);
INSERT INTO pilot VALUES (10, 010, 1010);

INSERT INTO airplane VALUES (9000,'AB9735','Air Bus 25','Air Hawk');
INSERT INTO airplane VALUES (9010,'BN3749','Boeing32','Aerial Crusaders');
INSERT INTO airplane VALUES (9020,'CF9949','Boeing747','West Jet');
INSERT INTO airplane VALUES (9030,'GH0124','Boeing747','Sun Wing');
INSERT INTO airplane VALUES (9040, 'GH0125', 'Airbus A320', 'Delta Airlines');
INSERT INTO airplane VALUES (9050, 'GH0126', 'Boeing 777', 'American Airlines');
INSERT INTO airplane VALUES (9060, 'GH0127', 'Boeing 787', 'United Airlines');
INSERT INTO airplane VALUES (9070, 'GH0128', 'Airbus A350', 'Lufthansa');
INSERT INTO airplane VALUES (9080, 'GH0129', 'Boeing 737', 'Southwest Airlines');
INSERT INTO airplane VALUES (9090, 'GH0130', 'McDonnell Douglas MD-11', 'FedEx');

-- inserting flight data using procedure
BEGIN
    insert_flight_data('FRA', 'JFK', TO_TIMESTAMP('2024-11-19 08:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('LHR', 'ORD', TO_TIMESTAMP('2024-11-19 10:30:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('SYD', 'DXB', TO_TIMESTAMP('2024-11-19 12:45:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('BKK', 'CDG', TO_TIMESTAMP('2024-11-19 14:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('LAX', 'HKG', TO_TIMESTAMP('2024-11-19 16:30:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('ORD', 'LAX', TO_TIMESTAMP('2024-11-19 18:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('JFK', 'LHR', TO_TIMESTAMP('2024-11-19 20:15:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('DXB', 'SYD', TO_TIMESTAMP('2024-11-20 09:00:00', 'YYYY-MM-DD HH24:MI:SS'));
    insert_flight_data('FRA', 'BKK', TO_TIMESTAMP('2024-11-20 11:30:00', 'YYYY-MM-DD HH24:MI:SS'));
END;

select * from flight;

INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Alice', 'Williams', 'alice.williams@example.com', '123-456-7890', '123 Main St, New York, NY');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'David', 'Taylor', 'david.taylor@example.com', '987-654-3210', '456 Elm St, Chicago, IL');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Bob', 'Johnson', 'bob.johnson@example.com', '234-567-8901', '456 Elm St, San Francisco, CA');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Charlie', 'Brown', 'charlie.brown@example.com', '345-678-9012', '789 Pine St, Los Angeles, CA');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'David', 'Davis', 'david.davis@example.com', '456-789-0123', '101 Maple Ave, Chicago, IL');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Eva', 'Miller', 'eva.miller@example.com', '567-890-1234', '202 Oak Rd, Miami, FL');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Frank', 'Wilson', 'frank.wilson@example.com', '678-901-2345', '303 Birch Blvd, Houston, TX');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Grace', 'Taylor', 'grace.taylor@example.com', '789-012-3456', '404 Cedar Dr, Phoenix, AZ');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Hannah', 'Anderson', 'hannah.anderson@example.com', '890-123-4567', '505 Fir Ln, Dallas, TX');

insert into flight values(001, 2536, 1, 'LAX', 'JFK', '2023-08-02 14:30:00', '2023-08-02 14:30:00');
insert into flight values(004, 7820, 2, 'LAX', 'JFK', '2023-08-02 14:30:00', '2023-08-02 14:30:00');

INSERT INTO flight_staff VALUES (1, 001, 001, 2);
INSERT INTO flight_staff VALUES (2, 004, 004, 2);

INSERT INTO ticket VALUES (101, 001, 'Economy');
INSERT INTO ticket VALUES (102, 001, 'Economy');
INSERT INTO ticket VALUES (103, 004, 'Business');

INSERT INTO luggage VALUES (1, 101, 001, 23.5, 'Blue suitcase with four wheels decorated by a red ribbon');
INSERT INTO luggage VALUES (2, 102, 001, 18.0, 'Black backpack with a small dog stuff toy hanging at the side');
INSERT INTO luggage VALUES (3, 103, 004, 35.7, 'Red suitcase with a combination lock');

-- Test function
SELECT get_flight_time('LAX', 'JFK') AS "Flight Time (h)" FROM dual;

-- This update use the sequence passenger_seq to add ref id to the address.
-- We are only updating one passenger .
-- It show how sequence can be used in update, not just insert.
UPDATE passenger
SET address = address || ' (Ref ID: ' || passenger_seq.NEXTVAL || ')'
WHERE passenger_id = 100;

--  an index on the last_name column in the employee table that makes it easy to search for employee
CREATE INDEX idx_employee_last_name
ON employee (last_name);

--  this one is the tes index which we created index only help to get this data quickly it might not be noticeable here but for big data base it is 
SELECT * 
FROM employee
WHERE last_name = 'Smith';

select * from flight;

-- an index on the flight_id column in the flight_staff table
CREATE INDEX idx_flight_staff_flight_id
ON flight_staff (flight_id);

-- this one is the test index which we created index only help to get this data quickly it might not be noticeable here but for big data base it is 
SELECT * 
FROM flight_staff
WHERE flight_id = 1;

-- Trigger to log the full name after an insert or update on employee table , when we bring any changes to employess it displays first the full name of that
CREATE OR REPLACE TRIGGER trg_employee_full_name
AFTER INSERT OR UPDATE OF first_name, last_name ON employee
FOR EACH ROW
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('Employee Full Name: ' || :NEW.first_name || ' ' || :NEW.last_name);
END trg_employee_full_name;

-- i tested the trigger after inserting new employess
SET SERVEROUTPUT ON;
INSERT INTO employee (employee#, first_name, last_name)
VALUES (21, 'Michael', 'Scott');

-- it tested the trigger after update the table
UPDATE employee
SET first_name = 'Jim', last_name = 'Halpert'
WHERE employee# = 21;

-- trigger 2
-- here we create a trigger,This one is not so complicated.
-- It will work on the location table.
-- This trigger is fired after we insert a new row into the location table.
-- Like, if we add a new airport or something, it will trigger and print a message.

CREATE OR REPLACE TRIGGER trg_new_location
-- AFTER INSERT means it will do its work after the data is added.
AFTER INSERT ON location
-- FOR EACH ROW means, it runs for every new row we add to the table.
FOR EACH ROW
BEGIN
    -- Here we use DBMS_OUTPUT.PUT_LINE to print out a simple message.
    DBMS_OUTPUT.PUT_LINE('New Location Added: Code = ' || :NEW.locationCode || ', Description = ' || :NEW.locationDesc);
END trg_new_location;

SET SERVEROUTPUT ON;
-- We add a new row to the location table, something like this:
INSERT INTO location 
VALUES ('SIN', 'Singapore Changi Airport', 8, 1.3644, 103.9915);

-- It will print: New Location Added: Code = SIN, Description = Singapore Changi Airport
-- So, every time we insert a new location, this will happen.

--Select tests
SELECT * FROM pilot;
SELECT * FROM flight;
SELECT * FROM airplane;
SELECT * FROM employee;
SELECT * FROM flight_staff;
SELECT * FROM ticket;
SELECT * FROM passenger;
SELECT * FROM emp_type;
SELECT * FROM location;
SELECT * FROM luggage;

-- Add airbus_membership column to passenger table (values = member vs non_member)
--membership discount = 5% from the overall cost
ALTER TABLE passenger
ADD airbus_membership VARCHAR2(20);

-- Add flight_type column to flight table (values = domestic vs international)
--ECONOMY CLASS == Domestic ticket = $400, Internationsl ticket = $1200
ALTER TABLE flight
ADD flight_type VARCHAR2(20);

--BUSINESS CLASS == Domestic ticket = $1300, Internationsl ticket = $6900
--checked bag limit weight = 32kg , overcharge = $3 per kg

--add ticket_id to ticket table
ALTER TABLE ticket
ADD ticket_id NUMBER(10);

--new values to test the following tasks:
-- Insert data into location table
-- Insert data into location table
INSERT INTO location (locationCode, locationDesc, utcOffset, latitude, longitude) VALUES ('SIN', 'Singapore Changi Airport', 8, 1.3644, 103.9915);
INSERT INTO location (locationCode, locationDesc, utcOffset, latitude, longitude) VALUES ('JFK', 'John F. Kennedy International Airport', -5, 40.6413, -73.7781);
INSERT INTO location (locationCode, locationDesc, utcOffset, latitude, longitude) VALUES ('LAX', 'Los Angeles International Airport', -8, 33.9416, -118.4085);
INSERT INTO location (locationCode, locationDesc, utcOffset, latitude, longitude) VALUES ('HND', 'Tokyo Haneda Airport', 9, 35.5494, 139.7798);
INSERT INTO location (locationCode, locationDesc, utcOffset, latitude, longitude) VALUES ('DXB', 'Dubai International Airport', 4, 25.2532, 55.3657);

-- Insert data into pilot table
-- INSERT INTO pilot (pilot_id, first_name, last_name) VALUES (1, 'John', 'Doe');
-- INSERT INTO pilot (pilot_id, first_name, last_name) VALUES (2, 'Jane', 'Smith');
-- INSERT INTO pilot (pilot_id, first_name, last_name) VALUES (3, 'Mike', 'Johnson');
-- INSERT INTO pilot (pilot_id, first_name, last_name) VALUES (4, 'Emily', 'Davis');
-- INSERT INTO pilot (pilot_id, first_name, last_name) VALUES (5, 'Chris', 'Brown');

-- Insert data into airplane table
-- INSERT INTO airplane (airplane_id, model, capacity) VALUES (1, 'Boeing 737', 180);
-- INSERT INTO airplane (airplane_id, model, capacity) VALUES (2, 'Airbus A320', 150);
-- INSERT INTO airplane (airplane_id, model, capacity) VALUES (3, 'Boeing 777', 300);
-- INSERT INTO airplane (airplane_id, model, capacity) VALUES (4, 'Airbus A380', 500);
-- INSERT INTO airplane (airplane_id, model, capacity) VALUES (5, 'Boeing 787', 250);

-- Insert data into employee table
-- INSERT INTO employee (employee#, first_name, last_name) VALUES (1, 'Alice', 'Williams');
-- INSERT INTO employee (employee#, first_name, last_name) VALUES (2, 'Bob', 'Miller');
-- INSERT INTO employee (employee#, first_name, last_name) VALUES (3, 'Charlie', 'Wilson');
-- INSERT INTO employee (employee#, first_name, last_name) VALUES (4, 'David', 'Moore');
-- INSERT INTO employee (employee#, first_name, last_name) VALUES (5, 'Eve', 'Taylor');

-- Insert data into flight_staff table
INSERT INTO flight_staff (staff_id, employee#, flight_id, designation) VALUES (1, 1, 1, 2);
INSERT INTO flight_staff (staff_id, employee#, flight_id, designation) VALUES (2, 2, 2, 3);
INSERT INTO flight_staff (staff_id, employee#, flight_id, designation) VALUES (3, 3, 3, 4);
INSERT INTO flight_staff (staff_id, employee#, flight_id, designation) VALUES (4, 4, 4, 5);
INSERT INTO flight_staff (staff_id, employee#, flight_id, designation) VALUES (5, 5, 5, 2);

-- Insert data into ticket table
INSERT INTO ticket (ticket_id, passenger_id, flight_id, seating_class) VALUES (1, 1, 1, 'ECONOMY');
INSERT INTO ticket (ticket_id, passenger_id, flight_id, seating_class) VALUES (2, 2, 2, 'BUSINESS');
INSERT INTO ticket (ticket_id, passenger_id, flight_id, seating_class) VALUES (3, 3, 3, 'ECONOMY');
INSERT INTO ticket (ticket_id, passenger_id, flight_id, seating_class) VALUES (4, 4, 4, 'BUSINESS');
INSERT INTO ticket (ticket_id, passenger_id, flight_id, seating_class) VALUES (5, 5, 5, 'ECONOMY');

-- Insert data into passenger table
INSERT INTO passenger (passenger_id, first_name, last_name, email, phone, address, airbus_membership) VALUES (1, 'Tom', 'Hanks', 'tom@example.com', '1234567890', '123 Main St', 'MEMBER');
INSERT INTO passenger (passenger_id, first_name, last_name, email, phone, address, airbus_membership) VALUES (2, 'Jerry', 'Seinfeld', 'jerry@example.com', '0987654321', '456 Elm St', 'NON_MEMBER');
INSERT INTO passenger (passenger_id, first_name, last_name, email, phone, address, airbus_membership) VALUES (3, 'Bruce', 'Wayne', 'bruce@example.com', '1112223333', '789 Oak St', 'MEMBER');
INSERT INTO passenger (passenger_id, first_name, last_name, email, phone, address, airbus_membership) VALUES (4, 'Clark', 'Kent', 'clark@example.com', '4445556666', '101 Pine St', 'NON_MEMBER');
INSERT INTO passenger (passenger_id, first_name, last_name, email, phone, address, airbus_membership) VALUES (5, 'Diana', 'Prince', 'diana@example.com', '7778889999', '202 Maple St', 'MEMBER');

-- Insert data into emp_type table
-- INSERT INTO emp_type (emp_type_id, emp_type_desc) VALUES (1, 'Pilot');
-- INSERT INTO emp_type (emp_type_id, emp_type_desc) VALUES (2, 'Co-Pilot');
-- INSERT INTO emp_type (emp_type_id, emp_type_desc) VALUES (3, 'Flight Attendant');
-- INSERT INTO emp_type (emp_type_id, emp_type_desc) VALUES (4, 'Ground Staff');
-- INSERT INTO emp_type (emp_type_id, emp_type_desc) VALUES (5, 'Maintenance');

-- Insert data into flight table
-- Insert data into flight table
INSERT INTO flight (flight_id, airplane_id, pilot_id, origin, destination, departure_date, arrival_date, flight_type) 
VALUES (1, 9010, 1, 'SIN', 'JFK', TO_DATE('2023-11-01 08:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2023-11-01 20:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'INTERNATIONAL');

INSERT INTO flight (flight_id, airplane_id, pilot_id, origin, destination, departure_date, arrival_date, flight_type) 
VALUES (2, 9020, 2, 'JFK', 'LAX', TO_DATE('2023-11-02 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2023-11-02 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DOMESTIC');

INSERT INTO flight (flight_id, airplane_id, pilot_id, origin, destination, departure_date, arrival_date, flight_type) 
VALUES (3, 9030, 3, 'LAX', 'HND', TO_DATE('2023-11-03 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2023-11-04 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'INTERNATIONAL');

INSERT INTO flight (flight_id, airplane_id, pilot_id, origin, destination, departure_date, arrival_date, flight_type) 
VALUES (4, 9040, 4, 'HND', 'DXB', TO_DATE('2023-11-04 15:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2023-11-04 23:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'INTERNATIONAL');

INSERT INTO flight (flight_id, airplane_id, pilot_id, origin, destination, departure_date, arrival_date, flight_type) 
VALUES (5, 9050, 5, 'DXB', 'SIN', TO_DATE('2023-11-05 16:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('2023-11-06 02:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'INTERNATIONAL');

-- Insert data into luggage table
-- Insert data into luggage table
INSERT INTO luggage (luggage_id, passenger_id, flight_id, weight, description) VALUES (1, 1, 1, 30, 'Checked baggage');
INSERT INTO luggage (luggage_id, passenger_id, flight_id, weight, description) VALUES (2, 2, 2, 35, 'Checked baggage');
INSERT INTO luggage (luggage_id, passenger_id, flight_id, weight, description) VALUES (3, 3, 3, 28, 'Carry-on baggage');
INSERT INTO luggage (luggage_id, passenger_id, flight_id, weight, description) VALUES (4, 4, 4, 40, 'Checked baggage');
INSERT INTO luggage (luggage_id, passenger_id, flight_id, weight, description) VALUES (5, 5, 5, 25, 'Carry-on baggage');

--Task 1: Procedure to Get the Flight Type and Seating Class to Calculate the Base Ticket Price
SELECT * FROM flight;
select * from ticket;
CREATE OR REPLACE PROCEDURE get_base_ticket_price (
    p_flight_id IN NUMBER,
    p_ticket_id IN NUMBER,
    p_base_price OUT NUMBER
) AS
    lv_flight_type VARCHAR2(20);
    lv_seating_class VARCHAR2(20);
BEGIN
    -- Get flight type
    SELECT UPPER(flight_type) INTO lv_flight_type
    FROM flight
    WHERE flight_id = p_flight_id;

    -- Get seating class from ticket table
    SELECT UPPER(seating_class) INTO lv_seating_class
    FROM ticket
    WHERE ticket_id = p_ticket_id;

    -- Determine base price based on seating class and flight type
    IF lv_seating_class = 'ECONOMY' THEN
        IF lv_flight_type = 'DOMESTIC' THEN
            p_base_price := 400;
        ELSIF lv_flight_type = 'INTERNATIONAL' THEN
            p_base_price := 1200;
        END IF;
    ELSIF lv_seating_class = 'BUSINESS' THEN
        IF lv_flight_type = 'DOMESTIC' THEN
            p_base_price := 1300;
        ELSIF lv_flight_type = 'INTERNATIONAL' THEN
            p_base_price := 6900;
        END IF;
    END IF;
END;

-- Test Task 1: Procedure to Get the Flight Type and Seating Class to Calculate the Base Ticket Price
DECLARE
    lv_base_price NUMBER;
BEGIN
    get_base_ticket_price(1, 1, lv_base_price); -- Assuming flight_id = 1 and ticket_id = 1
    DBMS_OUTPUT.PUT_LINE('Base Ticket Price: ' || lv_base_price);
END;

--Task 2: Function to Check Additional Charge Based on the Luggage Weight
CREATE OR REPLACE FUNCTION check_additional_charge (
    p_luggage_weight IN NUMBER
) RETURN NUMBER AS
    lv_overcharge NUMBER := 0;
BEGIN
    IF p_luggage_weight > 32 THEN
        lv_overcharge := (p_luggage_weight - 32) * 3;
    END IF;
    RETURN lv_overcharge;
END;

-- Test Task 2: Function to Check Additional Charge Based on the Luggage Weight
DECLARE
    lv_overcharge NUMBER;
BEGIN
    lv_overcharge := check_additional_charge(35);
    DBMS_OUTPUT.PUT_LINE('Additional Charge: ' || lv_overcharge);
END;

--Task 3: Procedure or Function to Calculate the Ticket Base Price with Additional Charges and Applies the Discount Based on Membership
CREATE OR REPLACE PROCEDURE calculate_total_price (
    p_flight_id IN NUMBER,
    p_ticket_id IN NUMBER,
    p_luggage_weight IN NUMBER,
    p_passenger_id IN NUMBER,
    p_total_price OUT NUMBER
) AS
    lv_base_price NUMBER;
    lv_additional_charge NUMBER;
    lv_membership VARCHAR2(20);
BEGIN
    -- Get base ticket price
    get_base_ticket_price(p_flight_id, p_ticket_id, lv_base_price);

    -- Calculate additional charge
    lv_additional_charge := check_additional_charge(p_luggage_weight);

    -- Get membership status
    SELECT UPPER(airbus_membership) INTO lv_membership
    FROM passenger
    WHERE passenger_id = p_passenger_id;

    -- Calculate total price
    p_total_price := lv_base_price + lv_additional_charge;

    -- Apply discount if member
    IF lv_membership = 'MEMBER' THEN
        p_total_price := p_total_price * 0.95;
    END IF;
END;

-- Test Task 3: Procedure to Calculate the Ticket Base Price with Additional Charges and Applies the Discount Based on Membership
DECLARE
    lv_total_price NUMBER;
BEGIN
    calculate_total_price(1, 1, 35, 1, lv_total_price); -- Assuming flight_id = 1, ticket_id = 1, luggage_weight = 35, passenger_id = 1
    DBMS_OUTPUT.PUT_LINE('Total Price: ' || lv_total_price);
END;



--Task 4: Procedure to Print All the Dropdown Lists of Prices and Total from Tasks 1, 2, and 3

CREATE OR REPLACE PROCEDURE print_price_details (
    p_flight_id IN NUMBER,
    p_ticket_id IN NUMBER,
    p_luggage_weight IN NUMBER,
    p_passenger_id IN NUMBER
) AS
    lv_base_price NUMBER;
    lv_additional_charge NUMBER;
    lv_total_price NUMBER;
    lv_membership VARCHAR2(20);
    lv_discount NUMBER := 0;
    lv_exceeding_weight NUMBER;
BEGIN
    -- Get base ticket price
    get_base_ticket_price(p_flight_id, p_ticket_id, lv_base_price);
    DBMS_OUTPUT.PUT_LINE('Base Ticket Price: ' || ROUND(lv_base_price, 2));

    -- Calculate additional charge
    lv_additional_charge := check_additional_charge(p_luggage_weight);
    DBMS_OUTPUT.PUT_LINE('Additional Charge: ' || ROUND(lv_additional_charge, 2));

    -- Show reason for additional charge
    IF lv_additional_charge > 0 THEN
        lv_exceeding_weight := p_luggage_weight - 32;
        DBMS_OUTPUT.PUT_LINE('Reason for Additional Charge: Luggage weight exceeds 32kg by ' || lv_exceeding_weight || 'kg. Additional $3 per kg charged.');
    END IF;

    -- Get membership status
    SELECT UPPER(airbus_membership) INTO lv_membership
    FROM passenger
    WHERE passenger_id = p_passenger_id;

    -- Calculate total price
    calculate_total_price(p_flight_id, p_ticket_id, p_luggage_weight, p_passenger_id, lv_total_price);

    -- Apply discount if member
    IF lv_membership = 'MEMBER' THEN
        lv_discount := lv_total_price * 0.05;
        lv_total_price := lv_total_price * 0.95;
        DBMS_OUTPUT.PUT_LINE('Discount Percentage: 5%');
        DBMS_OUTPUT.PUT_LINE('Total Discount Amount: ' || ROUND(lv_discount, 2));
    END IF;

    DBMS_OUTPUT.PUT_LINE('Total Price after Discount: ' || ROUND(lv_total_price, 2));
END;

-- Test Task 4: Procedure to Print All the Dropdown Lists of Prices and Total from Tasks 1, 2, and 3
BEGIN
    print_price_details(1, 1, 35, 1); -- Assuming flight_id = 1, ticket_id = 1, luggage_weight = 35, passenger_id = 1
END;




--Task 5: a package to combine all 4 tasks
CREATE OR REPLACE PACKAGE ticket_pricing_pkg AS
    PROCEDURE get_base_ticket_price (
        pv_flight_id IN NUMBER,
        pv_seating_class IN VARCHAR2,
        pv_base_price OUT NUMBER
    );

    FUNCTION check_additional_charge (
        pv_luggage_weight IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE calculate_total_price (
        pv_flight_id IN NUMBER,
        pv_seating_class IN VARCHAR2,
        pv_luggage_weight IN NUMBER,
        pv_passenger_id IN NUMBER,
        pv_total_price OUT NUMBER
    );

    PROCEDURE print_price_details (
        pv_flight_id IN NUMBER,
        pv_ticket_id IN NUMBER,
        pv_luggage_weight IN NUMBER,
        pv_passenger_id IN NUMBER
    );
END ticket_pricing_pkg;

CREATE OR REPLACE PACKAGE BODY ticket_pricing_pkg AS
    PROCEDURE get_base_ticket_price (
        pv_flight_id IN NUMBER,
        pv_seating_class IN VARCHAR2,
        pv_base_price OUT NUMBER
    ) AS
        lv_flight_type VARCHAR2(20);
    BEGIN
        SELECT UPPER(flight_type) INTO lv_flight_type
        FROM flight
        WHERE flight_id = pv_flight_id;

        IF UPPER(pv_seating_class) = 'ECONOMY' THEN
            IF lv_flight_type = 'DOMESTIC' THEN
                pv_base_price := 400;
            ELSIF lv_flight_type = 'INTERNATIONAL' THEN
                pv_base_price := 1200;
            END IF;
        ELSIF UPPER(pv_seating_class) = 'BUSINESS' THEN
            IF lv_flight_type = 'DOMESTIC' THEN
                pv_base_price := 1300;
            ELSIF lv_flight_type = 'INTERNATIONAL' THEN
                pv_base_price := 6900;
            END IF;
        END IF;
    END get_base_ticket_price;

    FUNCTION check_additional_charge (
        pv_luggage_weight IN NUMBER
    ) RETURN NUMBER AS
        lv_overcharge NUMBER := 0;
    BEGIN
        IF pv_luggage_weight > 32 THEN
            lv_overcharge := (pv_luggage_weight - 32) * 3;
        END IF;
        RETURN lv_overcharge;
    END check_additional_charge;

    PROCEDURE calculate_total_price (
        pv_flight_id IN NUMBER,
        pv_seating_class IN VARCHAR2,
        pv_luggage_weight IN NUMBER,
        pv_passenger_id IN NUMBER,
        pv_total_price OUT NUMBER
    ) AS
        lv_base_price NUMBER;
        lv_additional_charge NUMBER;
        lv_membership VARCHAR2(20);
    BEGIN
        -- Get base ticket price
        get_base_ticket_price(pv_flight_id, UPPER(pv_seating_class), lv_base_price);

        -- Calculate additional charge
        lv_additional_charge := check_additional_charge(pv_luggage_weight);

        -- Get membership status
        SELECT UPPER(airbus_membership) INTO lv_membership
        FROM passenger
        WHERE passenger_id = pv_passenger_id;

        -- Calculate total price
        pv_total_price := lv_base_price + lv_additional_charge;

        -- Apply discount if member
        IF lv_membership = 'MEMBER' THEN
            pv_total_price := pv_total_price * 0.95;
        END IF;
    END calculate_total_price;

    PROCEDURE print_price_details (
        pv_flight_id IN NUMBER,
        pv_ticket_id IN NUMBER,
        pv_luggage_weight IN NUMBER,
        pv_passenger_id IN NUMBER
    ) AS
        lv_base_price NUMBER;
        lv_additional_charge NUMBER;
        lv_total_price NUMBER;
        lv_membership VARCHAR2(20);
        lv_discount NUMBER := 0;
        lv_exceeding_weight NUMBER;
    BEGIN
        -- Get base ticket price
        get_base_ticket_price(pv_flight_id, pv_ticket_id, lv_base_price);
        DBMS_OUTPUT.PUT_LINE('Base Ticket Price: ' || ROUND(lv_base_price, 2));

        -- Calculate additional charge
        lv_additional_charge := check_additional_charge(pv_luggage_weight);
        DBMS_OUTPUT.PUT_LINE('Additional Charge: ' || ROUND(lv_additional_charge, 2));

        -- Show reason for additional charge
        IF lv_additional_charge > 0 THEN
            lv_exceeding_weight := pv_luggage_weight - 32;
            DBMS_OUTPUT.PUT_LINE('Reason for Additional Charge: Luggage weight exceeds 32kg by ' || lv_exceeding_weight || 'kg. Additional $3 per kg charged.');
        END IF;

        -- Get membership status
        SELECT UPPER(airbus_membership) INTO lv_membership
        FROM passenger
        WHERE passenger_id = pv_passenger_id;

        -- Calculate total price
        calculate_total_price(pv_flight_id, pv_ticket_id, pv_luggage_weight, pv_passenger_id, lv_total_price);

        -- Apply discount if member
        IF lv_membership = 'MEMBER' THEN
            lv_discount := lv_total_price * 0.05;
            lv_total_price := lv_total_price * 0.95;
            DBMS_OUTPUT.PUT_LINE('Discount Percentage: 5%');
            DBMS_OUTPUT.PUT_LINE('Total Discount Amount: ' || ROUND(lv_discount, 2));
        END IF;

        DBMS_OUTPUT.PUT_LINE('Total Price after Discount: ' || ROUND(lv_total_price, 2));
    END print_price_details;
END ticket_pricing_pkg;

--Testing the package
-- Task 1: get_base_ticket_price
DECLARE
    lv_base_price NUMBER;
BEGIN
    ticket_pricing_pkg.get_base_ticket_price(1, UPPER('economy'), lv_base_price);
    DBMS_OUTPUT.PUT_LINE('Base Ticket Price: ' || lv_base_price);
END;


-- Task 2: check_additional_charge
DECLARE
    lv_overcharge NUMBER;
BEGIN
    lv_overcharge := ticket_pricing_pkg.check_additional_charge(35);
    DBMS_OUTPUT.PUT_LINE('Additional Charge: ' || lv_overcharge);
END;


-- Task 3: calculate_total_price
DECLARE
    lv_total_price NUMBER;
BEGIN
    ticket_pricing_pkg.calculate_total_price(1, UPPER('economy'), 35, 1, lv_total_price);
    DBMS_OUTPUT.PUT_LINE('Total Price: ' || lv_total_price);
END;


-- Task 4: print_price_details
BEGIN
    ticket_pricing_pkg.print_price_details(1, 1, 35, 1); -- Assuming flight_id = 1, ticket_id = 1, luggage_weight = 35, passenger_id = 1
END;
