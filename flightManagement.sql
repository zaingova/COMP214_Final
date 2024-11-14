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
DROP SEQUENCE ticket_seq;
DROP FUNCTION get_flight_time;
DROP INDEX idx_passenger_email;

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
    CONSTRAINT flight_arrival_date_ck CHECK ( arrival_date >= departure_date ),
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
    CONSTRAINT flight_staff_staff_id_pk PRIMARY KEY ( staff_id ),
    CONSTRAINT flight_staff_employee#_fk FOREIGN KEY ( employee# )
        REFERENCES employee ( employee# ),
    CONSTRAINT flight_staff_flight_id_fk FOREIGN KEY ( flight_id )
        REFERENCES flight ( flight_id ),
    CONSTRAINT flight_staff_employee#_uk UNIQUE ( employee# )
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

/*CREATE TABLE luggage (
    luggage_id NUMBER(10) PRIMARY KEY,
    passenger_id NUMBER(10) NOT NULL,
    flight_id NUMBER(10) NOT NULL,
    weight NUMBER(5, 2) NOT NULL,
    description VARCHAR2(100),
    CONSTRAINT luggage_passenger_id_fk FOREIGN KEY (passenger_id) REFERENCES passenger(passenger_id),
    CONSTRAINT luggage_flight_id_fk FOREIGN KEY (flight_id) REFERENCES flight(flight_id)
);
*/

CREATE TABLE luggage (
    luggage_id    NUMBER(10) PRIMARY KEY,
    passenger_id  NUMBER(10) NOT NULL,
    flight_id     NUMBER(10) NOT NULL,
    weight        NUMBER(5, 2) NOT NULL,
    description   VARCHAR2(100),
    CONSTRAINT luggage_passenger_id_fk FOREIGN KEY (passenger_id, flight_id)
        REFERENCES ticket (passenger_id, flight_id)
);

-- Creating sequences for ticket and passenger IDs
/*CREATE SEQUENCE ticket_seq
START WITH 1001
INCREMENT BY 1;
*/

CREATE SEQUENCE passenger_seq
START WITH 100
INCREMENT BY 1;

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

INSERT INTO emp_type VALUES (1, 'Pilot');
INSERT INTO emp_type VALUES (2, 'Flight Staff');
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

INSERT INTO pilot VALUES (1,001,1001);
INSERT INTO pilot VALUES (2,003,1002);
INSERT INTO pilot VALUES (3,011,1003);
INSERT INTO pilot VALUES (4,012,1004);

INSERT INTO airplane VALUES (2536,'AB9735','Air Bus 25','Air Hawk');
INSERT INTO airplane VALUES (6475,'BN3749','Boeing32','Aerial Crusaders');
INSERT INTO airplane VALUES (9874,'CF9949','Boeing747','West Jet');
INSERT INTO airplane VALUES (9072,'GH0124','Boeing747','Sun Wing');

INSERT INTO flight VALUES (001, 2536, 1, 'LAX', 'CDG', TO_DATE('2023-08-02', 'YYYY-MM-DD'), '12:30 PM', TO_DATE('2023-08-02', 'YYYY-MM-DD'), '5:00 PM');
INSERT INTO flight VALUES (002, 6475, 2, 'JFK', 'BKK', TO_DATE('2023-08-02', 'YYYY-MM-DD'), '11:00 PM', TO_DATE('2023-08-03', 'YYYY-MM-DD'), '2:30 AM');
INSERT INTO flight VALUES (003, 9874, 3, 'FRA', 'SYD', TO_DATE('2023-08-04', 'YYYY-MM-DD'), '8:00 AM', TO_DATE('2023-08-04', 'YYYY-MM-DD'), '2:30 PM');
INSERT INTO flight VALUES (004, 9072, 4, 'ORD', 'CDG', TO_DATE('2023-08-08', 'YYYY-MM-DD'), '11:30 PM', TO_DATE('2023-08-09', 'YYYY-MM-DD'), '3:20 AM');

INSERT INTO flight_staff VALUES (1, 002, 001);
INSERT INTO flight_staff VALUES (2, 004, 002);

INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Alice', 'Williams', 'alice.williams@example.com', '123-456-7890', '123 Main St, New York, NY');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'David', 'Taylor', 'david.taylor@example.com', '987-654-3210', '456 Elm St, Chicago, IL');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Bob', 'Johnson', 'bob.johnson@example.com', '234-567-8901', '456 Elm St, San Francisco, CA');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Charlie', 'Brown', 'charlie.brown@example.com', '345-678-9012', '789 Pine St, Los Angeles, CA');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'David', 'Davis', 'david.davis@example.com', '456-789-0123', '101 Maple Ave, Chicago, IL');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Eva', 'Miller', 'eva.miller@example.com', '567-890-1234', '202 Oak Rd, Miami, FL');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Frank', 'Wilson', 'frank.wilson@example.com', '678-901-2345', '303 Birch Blvd, Houston, TX');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Grace', 'Taylor', 'grace.taylor@example.com', '789-012-3456', '404 Cedar Dr, Phoenix, AZ');
INSERT INTO passenger VALUES (passenger_seq.NEXTVAL, 'Hannah', 'Anderson', 'hannah.anderson@example.com', '890-123-4567', '505 Fir Ln, Dallas, TX');

INSERT INTO luggage VALUES (1, 101, 001, 23.5, 'Blue suitcase with four wheels decorated by a red ribbon');
INSERT INTO luggage VALUES (2, 102, 001, 18.0, 'Black backpack with a small dog stuff toy hanging at the side');

INSERT INTO ticket VALUES (101, 001, 'Economy');
INSERT INTO ticket VALUES (102, 001, 'Economy');

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

-- Test function
SELECT get_flight_time('LAX', 'JFK') AS "Flight Time (h)" FROM dual;

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