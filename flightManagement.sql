---------- DROPPING TABLES -----------------------------------------------------

DROP TABLE pilot CASCADE CONSTRAINTS;
DROP TABLE flight CASCADE CONSTRAINTS;
DROP TABLE airplane CASCADE CONSTRAINTS;
DROP TABLE employee CASCADE CONSTRAINTS;
DROP TABLE flight_staff CASCADE CONSTRAINTS;
DROP TABLE ticket CASCADE CONSTRAINTS;
DROP TABLE passenger CASCADE CONSTRAINTS;
DROP TABLE emp_type CASCADE CONSTRAINTS;
DROP TABLE location CASCADE CONSTRAINTS NOWAIT;

---------- CREATING AND POPULATING LOCATION LOOKUP -----------------------------

CREATE TABLE LOCATION (
    locationCode CHAR(3),
    locationDesc VARCHAR(50),
    utcOffset NUMBER(2),
    latitude NUMBER(9, 6),
    longitude NUMBER(9, 6),
    CONSTRAINT location_locationCode_pk PRIMARY KEY ( locationCode )
)

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

select * from location;

SELECT get_flight_time('LAX', 'DXB') AS "Flight Time (h)" FROM dual;
SELECT * FROM LOCATION WHERE locationCode IN ('LAX', 'JFK');

---------- CREATING AND POPULATING EMP-LOOKUP ----------------------------------

CREATE TABLE emp_type (
    employeeID NUMBER(1),
    jobDescription VARCHAR2(20),
    CONSTRAINT emp_type_employeeID_pk PRIMARY KEY (employeeID)
)

INSERT INTO emp_type
VALUES (1, 'Pilot');
INSERT INTO emp_type
VALUES (2, 'Flight Staff');

select * from emp_type;

---------- CREATING AND POPULATING EMPLOYEE ------------------------------------

CREATE TABLE employee (
    employee#     NUMBER(10),
    first_name    VARCHAR2(26),
    last_name     VARCHAR2(26),
    employee_type NUMBER(1),
    CONSTRAINT employee_employee#_pk PRIMARY KEY ( employee# )
);

INSERT INTO employee
VALUES (001,'John','Doe',1);
INSERT INTO employee
VALUES (002,'Jane','Smith',2);
INSERT INTO employee
VALUES (003,'Robert','Brown',1);
INSERT INTO employee
VALUES (004,'Emily','Johnson', 2);
INSERT INTO employee
VALUES (005,'Paul','Delores', 2);
INSERT INTO employee
VALUES (006,'Channing','Bosum',2);
INSERT INTO employee
VALUES (007,'Shaun','Jacobson',2);
INSERT INTO employee
VALUES (008,'Lauren','Moser',2);
INSERT INTO employee
VALUES (009,'Tina','Shaw',2);
INSERT INTO employee
VALUES (010,'Pradeep','Singh',2);
INSERT INTO employee
VALUES (011,'Farukh','Khan',1);
INSERT INTO employee
VALUES (012,'Lin','Miyazaki',1);

SELECT * FROM EMPLOYEE ORDER BY EMPLOYEE#;

---------- CREATING AND POPULATING PILOT ---------------------------------------

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

INSERT INTO pilot
VALUES (1,001,1001);
INSERT INTO pilot
VALUES (2,003,1002);
INSERT INTO pilot
VALUES (3,011,1003);
INSERT INTO pilot
VALUES (4,012,1004);

SELECT * FROM PILOT;

---------- CREATING AND POPULATING AIRPLANE ------------------------------------

CREATE TABLE airplane (
    airplane_id   NUMBER(10),
    model#        VARCHAR2(20),
    airplane_name VARCHAR2(50),
    company       VARCHAR2(50),
    CONSTRAINT airplane_airplane_id_pk PRIMARY KEY ( airplane_id )
);

INSERT INTO airplane
VALUES (2536,'AB9735','Air Bus 25','Air Hawk');
INSERT INTO airplane
VALUES (6475,'BN3749','Boeing32','Aerial Crusaders');
INSERT INTO airplane
VALUES (9874,'CF9949','Boeing747','West Jet');
INSERT INTO airplane
VALUES (9072,'GH0124','Boeing747','Sun Wing');

SELECT * FROM AIRPLANE;

---------- CREATING AND POPULATING FLIGHT --------------------------------------

CREATE TABLE flight (
    flight_id      NUMBER(10),
    airplane_id    NUMBER(10),
    pilot_id       NUMBER(10),
    origin         CHAR(3),
    destination    CHAR(3),
    departure_date DATE,
    departure_time VARCHAR2(10),
    arrival_date   DATE,
    arrival_time   VARCHAR2(10),
    CONSTRAINT flight_flight_id_pk PRIMARY KEY ( flight_id ),
    CONSTRAINT flight_airplane_id_fk FOREIGN KEY ( airplane_id )
        REFERENCES airplane ( airplane_id ),
    CONSTRAINT flight_airplane_id_uk UNIQUE ( airplane_id ),
    CONSTRAINT flight_pilot_id_fk FOREIGN KEY ( pilot_id )
        REFERENCES pilot ( pilot_id ),
    CONSTRAINT flight_pilot_id_uk UNIQUE ( pilot_id ),
    CONSTRAINT flight_arrival_date_ck CHECK ( arrival_date >= departure_date )
);

INSERT INTO flight
VALUES (001, 2536, 1, 'LAX', 'CDG', TO_DATE('2023-08-02', 'YYYY-MM-DD'), '12:30 PM', TO_DATE('2023-08-02', 'YYYY-MM-DD'), '5:00 PM');
INSERT INTO flight
VALUES (002, 6475, 2, 'JFK', 'BKK', TO_DATE('2023-08-02', 'YYYY-MM-DD'), '11:00 PM', TO_DATE('2023-08-03', 'YYYY-MM-DD'), '2:30 AM');
INSERT INTO flight
VALUES (003, 9874, 3, 'FRA', 'SYD', TO_DATE('2023-08-04', 'YYYY-MM-DD'), '8:00 AM', TO_DATE('2023-08-04', 'YYYY-MM-DD'), '2:30 PM');
INSERT INTO flight
VALUES (004, 9072, 4, 'ORD', 'CDG', TO_DATE('2023-08-08', 'YYYY-MM-DD'), '11:30 PM', TO_DATE('2023-08-09', 'YYYY-MM-DD'), '3:20 AM');

SELECT * FROM FLIGHT;

---------- CREATING AND POPULATING FLIGHT STAFF --------------------------------

CREATE TABLE flight_staff (
    staff_id  NUMBER(10),
    employee# NUMBER(10),
    flight_id NUMBER(10),
    CONSTRAINT flight_staff_staff_id_pk PRIMARY KEY ( staff_id ),
    CONSTRAINT flight_staff_employee#_fk FOREIGN KEY ( employee# )
        REFERENCES employee ( employee# ),
    CONSTRAINT flight_staff_flight_id_fk FOREIGN KEY ( flight_id )
        REFERENCES flight ( flight_id ),
    CONSTRAINT flight_staff_employee#_uk UNIQUE ( employee# )
);

INSERT INTO flight_staff
VALUES (1, 002, 001);
INSERT INTO flight_staff
VALUES (2, 004, 002);

SELECT * FROM FLIGHT_STAFF;

---------- CREATING AND POPULATING PASSENGER -----------------------------------

CREATE TABLE passenger (
    passenger_id NUMBER(10),
    first_name   VARCHAR2(26),
    last_name    VARCHAR2(26),
    email        VARCHAR2(50),
    phone        VARCHAR2(15),
    address      VARCHAR2(100),
    CONSTRAINT passenger_passenger_id_pk PRIMARY KEY ( passenger_id )
);

INSERT INTO passenger
VALUES (101, 'Alice', 'Williams', 'alice.williams@example.com', '123-456-7890', '123 Main St, New York, NY');
INSERT INTO passenger
VALUES (102, 'David', 'Taylor', 'david.taylor@example.com', '987-654-3210', '456 Elm St, Chicago, IL');
INSERT INTO passenger
VALUES (103, 'James', 'Anderson', 'james.anderson@example.com', '234-567-8901', '789 Pine St, Los Angeles, CA');
INSERT INTO passenger
VALUES (104, 'Mary', 'Thomas', 'mary.thomas@example.com', '345-678-9012', '321 Oak St, Miami, FL');
INSERT INTO passenger
VALUES (105, 'Patricia', 'Jackson', 'patricia.jackson@example.com', '456-789-0123', '654 Maple St, Dallas, TX');
INSERT INTO passenger
VALUES (106, 'Robert', 'White', 'robert.white@example.com', '567-890-1234', '987 Birch St, Seattle, WA');
INSERT INTO passenger
VALUES (107, 'Linda', 'Harris', 'linda.harris@example.com', '678-901-2345', '111 Cedar St, Boston, MA');
INSERT INTO passenger
VALUES (108, 'Michael', 'Martin', 'michael.martin@example.com', '789-012-3456', '222 Spruce St, Denver, CO');
INSERT INTO passenger
VALUES (109, 'Barbara', 'Thompson', 'barbara.thompson@example.com', '890-123-4567', '333 Fir St, San Francisco, CA');
INSERT INTO passenger
VALUES (110, 'William', 'Garcia', 'william.garcia@example.com', '901-234-5678', '444 Redwood St, Portland, OR');
INSERT INTO passenger
VALUES (111, 'Elizabeth', 'Martinez', 'elizabeth.martinez@example.com', '012-345-6789', '555 Willow St, San Diego, CA');
INSERT INTO passenger
VALUES (112, 'Richard', 'Rodriguez', 'richard.rodriguez@example.com', '123-456-7891', '666 Cypress St, Las Vegas, NV');
INSERT INTO passenger
VALUES (113, 'Susan', 'Clark', 'susan.clark@example.com', '234-567-8902', '777 Pine St, Phoenix, AZ');
INSERT INTO passenger
VALUES (114, 'Joseph', 'Lewis', 'joseph.lewis@example.com', '345-678-9013', '888 Oak St, Austin, TX');

SELECT * FROM PASSENGER;

---------- CREATING AND POPULATING TICKET --------------------------------------

CREATE TABLE ticket (
    ticket_id     NUMBER(10),
    passenger_id  NUMBER(10),
    flight_id     NUMBER(10),
    seating_class VARCHAR2(15),
    CONSTRAINT ticket_ticket_id_pk PRIMARY KEY ( ticket_id ),
    CONSTRAINT ticket_passenger_id_fk FOREIGN KEY ( passenger_id )
        REFERENCES passenger ( passenger_id ),
    CONSTRAINT ticket_flight_id_fk FOREIGN KEY ( flight_id )
        REFERENCES flight ( flight_id )
);
                     
INSERT INTO ticket
VALUES (1001, 101, 001, 'Economy');
INSERT INTO ticket
VALUES (1002, 102, 001, 'Business');
INSERT INTO ticket
VALUES (1003, 103, 001, 'Business');
INSERT INTO ticket
VALUES (1004, 104, 001, 'Economy');
INSERT INTO ticket
VALUES (1005, 105, 001, 'Economy');
INSERT INTO ticket
VALUES (1006, 106, 001, 'Economy');
INSERT INTO ticket
VALUES (1007, 107, 001, 'Economy');
INSERT INTO ticket
VALUES (1008, 108, 002, 'Business');
INSERT INTO ticket
VALUES (1009, 109, 002, 'Economy');
INSERT INTO ticket
VALUES (1010, 110, 002, 'Business');
INSERT INTO ticket
VALUES (1011, 111, 002, 'Economy');
INSERT INTO ticket
VALUES (1012, 112, 002, 'First Class');
INSERT INTO ticket
VALUES (1013, 113, 002, 'First Class');
INSERT INTO ticket
VALUES (1014, 114, 002, 'Economy');

SELECT * FROM TICKET;

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
    -- Fetch the latitude and longitude for the "From" location
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

    -- Fetch the latitude and longitude for the "To" location
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

    -- Log the retrieved latitude and longitude for debugging purposes
    DBMS_OUTPUT.PUT_LINE('From location (' || p_from_location || '): Lat=' || v_latitude_from || ', Lon=' || v_longitude_from);
    DBMS_OUTPUT.PUT_LINE('To location (' || p_to_location || '): Lat=' || v_latitude_to || ', Lon=' || v_longitude_to);

    -- Calculate the flight time using the Haversine formula (assuming 6371 km radius for Earth)
    v_flight_time := ROUND(6371 * 2 * ASIN(
                        SQRT(
                            SIN((v_latitude_to - v_latitude_from) * 3.1415 / 180 / 2) * SIN((v_latitude_to - v_latitude_from) * 3.1415 / 180 / 2) +
                            COS(v_latitude_from * 3.1415 / 180) * COS(v_latitude_to * 3.1415 / 180) *
                            SIN((v_longitude_to - v_longitude_from) * 3.1415 / 180 / 2) * SIN((v_longitude_to - v_longitude_from) * 3.1415 / 180 / 2)
                        ) / 800
                    ), 2);

    -- Return the calculated flight time in hours
    RETURN v_flight_time;

EXCEPTION
    WHEN OTHERS THEN
        -- General error handling
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
        RETURN NULL;
END get_flight_time;

