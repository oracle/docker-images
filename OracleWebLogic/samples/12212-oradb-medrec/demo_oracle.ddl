-- DDL for BEA WebLogic Server 9.0 Examples

-- START
-- jdbc.multidatasource, wlst.online
DROP TABLE systables;
CREATE TABLE systables (test  varchar(15));

-- START
-- resadapter.simple, ejb20.sequence, ejb20.basic
DROP TABLE ejbAccounts;
CREATE TABLE ejbAccounts (id varchar(15), bal float, type varchar(15));
INSERT INTO ejbAccounts (id,bal,type) VALUES ('10000',1000,'Checking');
INSERT INTO ejbAccounts (id,bal,type) VALUES ('10005',1000,'Savings');

DROP TABLE ejb21Accounts;
CREATE TABLE ejb21Accounts (id varchar(15), bal float, type varchar(15));

-- DROP TABLE ejbTransLog;
-- CREATE TABLE ejbTransLog (transId VARCHAR(32), transCommitDate DATE);

DROP TABLE idGenerator;
CREATE TABLE idGenerator (tablename varchar(32), maxkey int);

DROP TABLE CUSTOMER;
CREATE TABLE customer(
   custid     int not null,
   name       varchar(30),
   address    varchar(30),
   city       varchar(30),
   state      varchar(2),
   zip        varchar(5),
   area       varchar(3),
   phone      varchar(8));

insert into customer values
   (100,'Jackson','100 First St.','Pleasantville','CA','95404','707','555-1234');
insert into customer values
   (101,'Elliott','Arbor Lane, #3','Centre Town','CA','96539','415','787-5467');
insert into customer values
   (102,'Avery','14 Main','Arthur','CA','97675','510','834-7476');


-- DROP TABLE emp;
-- CREATE TABLE emp (
-- empno      int not null,
-- ename      varchar(10),
-- job        varchar(9),
-- mgr        int,
-- hiredate   date,
-- sal        float,
-- comm       float,
-- deptno     int);

-- create unique index empno on emp(empno);
-- insert into emp values
--  (7369,'SMITH','CLERK',7902,DATE'1980-12-17',800,NULL,20);

-- webapp.pubsub.stock
DROP TABLE StockTable;
create table StockTable(
   symbol      varchar(10),
   price       float,
   yearHigh    float,
   yearLow     float,
   volume      int);

-- START
-- ejb20.basic.beanManaged, ejb20.basic.containerManaged
DROP TABLE Accounts;
create table Accounts (
   acct_id varchar(50) constraint pk_acct primary key, 
   bal numeric, 
   type varchar(50), 
   cust_name varchar(50));

DROP TABLE Customers;
create table Customers (
   cust_name varchar(50) constraint pk_cust primary key, 
   acct_id varchar(50), 
   cust_age integer, 
   cust_level integer, 
   cust_last date);
-- END

-- START 
--  ejb20.relationships, ejb20.ejbgen
DROP TABLE fanclubs;

DROP TABLE recordings;

DROP TABLE band_artist;

DROP TABLE artist_sequence;

ALTER TABLE artists DROP CONSTRAINT artists_pk;
DROP TABLE artists;

ALTER TABLE bands DROP CONSTRAINT bands_pk;
DROP TABLE bands;

CREATE TABLE bands (
   name VARCHAR(50),
   founder VARCHAR(50),
   startDate date,
   CONSTRAINT bands_pk PRIMARY KEY
     (name, founder));

CREATE TABLE recordings (
   title VARCHAR(50),
   bandName VARCHAR(50),
   bandFounder VARCHAR(50),
   numberSold INT,
   sales NUMERIC(10, 2),
   recordingDate DATE,
   CONSTRAINT recordings_pk PRIMARY KEY
     (title, bandName, bandFounder),
   CONSTRAINT recordings_fk FOREIGN KEY
     (bandName, bandFounder)
     REFERENCES bands(name, founder) ON DELETE CASCADE);

CREATE TABLE fanclubs (
   text VARCHAR(1024),
   bandName VARCHAR(50),
   bandFounder VARCHAR(50),
   memberCount INT,
   CONSTRAINT fanclubs_pk PRIMARY KEY
     (bandName, bandFounder),
   CONSTRAINT fanclubs_fk FOREIGN KEY
     (bandName, bandFounder)
     REFERENCES bands(name, founder) ON DELETE CASCADE);

CREATE TABLE artists (
   name VARCHAR(50), 
   id INT CONSTRAINT artists_pk PRIMARY KEY);

CREATE TABLE band_artist (
   band_name VARCHAR(50),
   band_founder VARCHAR(50),
   artist_id INT,
   CONSTRAINT band_artist_fk FOREIGN KEY
     (band_name, band_founder)
     REFERENCES bands(name, founder) ON DELETE CASCADE,
   CONSTRAINT band_artist_fk2 FOREIGN KEY
     (artist_id)
     REFERENCES artists(id) ON DELETE CASCADE);

CREATE TABLE artist_sequence (sequence INT);

INSERT INTO artist_sequence VALUES (1);
-- END

-- START
--  ejb20.multitable
-- DROP TABLE user_profile;
-- DROP TABLE user_login;

-- CREATE TABLE user_login (
--   username VARCHAR(50),
--   password VARCHAR(50),
--   CONSTRAINT user_pk PRIMARY KEY
--     (username));

-- CREATE TABLE user_profile (
--   username VARCHAR(50),
--   street VARCHAR(50),
--   city VARCHAR(50),
--  state VARCHAR(50),
--   zip VARCHAR(10),
--   CONSTRAINT user_profile_pk PRIMARY KEY
--     (username));
-- END

-- START
-- ejb20.embeddedkey
--drop table ORDERSKEYTABLE;
-- create table ORDERSKEYTABLE (sequence INTEGER);
-- insert into ORDERSKEYTABLE VALUES (0);
-- END  ejb20.embeddedkey

-- START
-- ejb20.sequence.userDesignated
drop table NAMED_SEQUENCE_TABLE;
create table NAMED_SEQUENCE_TABLE(SEQUENCE integer);
insert into NAMED_SEQUENCE_TABLE values (100);
-- END  ejb20.sequence.userDesignated

-- START
-- MedRec data used by API Examples
-- Drop sequences

DROP TABLE patient_seq;

-- Drop Medrec tables
DROP TABLE address;
DROP TABLE groups;
DROP TABLE patient;
DROP TABLE physician;
DROP TABLE prescription;
DROP TABLE record;
-- DROP TABLE vital_signs;
-- Create sequence
CREATE TABLE patient_seq (sequence INTEGER);

-- Create Medrec tables
CREATE TABLE address    (
 id INTEGER NOT NULL CONSTRAINT address_pk PRIMARY KEY,
 street1    VARCHAR(60) NOT NULL,
 street2    VARCHAR(60),
 city   VARCHAR(60) NOT NULL,
 state  VARCHAR(2) NOT NULL,
 zip    VARCHAR(10) NOT NULL,
 country VARCHAR(50) NOT NULL
);

CREATE TABLE groups (
 username   VARCHAR(60) NOT NULL,
 group_name VARCHAR(60) NOT NULL
);


CREATE TABLE patient    (
  id INTEGER CONSTRAINT patient_pk PRIMARY KEY,
  first_name    VARCHAR(60) NOT NULL,
  middle_name   VARCHAR(60),
  last_name VARCHAR(60) NOT NULL,
  dob   DATE NOT NULL,
  gender    VARCHAR(6) NOT NULL,
  ssn   VARCHAR(9) NOT NULL,
  address_id INTEGER NOT NULL,
  phone VARCHAR(15),
  email VARCHAR(60) NOT NULL
);

CREATE TABLE physician  (
 id INT NOT NULL CONSTRAINT physician_pk PRIMARY KEY,
 first_name VARCHAR(60) NOT NULL,
 middle_name    VARCHAR(60),
 last_name  VARCHAR(60) NOT NULL,
 phone  VARCHAR(15),
 email  VARCHAR(60)
);

CREATE TABLE prescription   (
 id INTEGER NOT NULL CONSTRAINT prescription_pk PRIMARY KEY,
 pat_id INTEGER NOT NULL,
 date_prescribed DATE NOT NULL,
 drug   VARCHAR(80) NOT NULL,
 record_id INTEGER  NOT NULL,
 dosage VARCHAR(30) NOT NULL,
 frequency  VARCHAR(30),
 refills_remaining  INTEGER,
 instructions   VARCHAR(255)
);

CREATE TABLE record (
 id INTEGER NOT NULL CONSTRAINT record_pk PRIMARY KEY,
 pat_id INTEGER NOT NULL,
 phys_id    INTEGER NOT NULL,
 record_date    DATE NOT NULL,
 vital_id INTEGER  NOT NULL,
 symptoms   VARCHAR(255) NOT NULL,
 diagnosis  VARCHAR(255),
 notes  VARCHAR(255)
);

-- CREATE TABLE vital_signs    (
-- id INTEGER NOT NULL CONSTRAINT vital_signs_pk PRIMARY KEY,
-- temperature VARCHAR(4),
-- blood_pressure VARCHAR(10),
-- pulse  VARCHAR(10),
-- weight INTEGER,
-- height INTEGER
--);

-- COMMIT;

-- Create test data.
-- Caution: This script deletes all existing data.
-- Note: Sequence tables are created starting at 101.

DELETE FROM address;
DELETE FROM groups;
DELETE FROM patient;
DELETE FROM physician;
DELETE FROM prescription;
DELETE FROM record;
-- DELETE FROM vital_signs;
-- Address
INSERT INTO address (id,street1,street2,city,state,zip,country) VALUES (101,'1224 Post St','Suite 100','San Francisco','CA','94115','United States');
INSERT INTO address (id,street1,street2,city,state,zip,country) VALUES (102,'235 Montgomery St','Suite 15','Ponte Verde','FL','32301','United States');
INSERT INTO address (id,street1,street2,city,state,zip,country) VALUES (103,'1234 Market','','San Diego','CA','92126','United States');

-- Groups
INSERT INTO groups (username,group_name) VALUES ('fred@golf.com','MedRecPatients');
INSERT INTO groups (username,group_name) VALUES ('larry@bball.com','MedRecPatients');
INSERT INTO groups (username,group_name) VALUES ('charlie@star.com','MedRecPatients');
INSERT INTO groups (username,group_name) VALUES ('volley@ball.com','MedRecPatients');
INSERT INTO groups (username,group_name) VALUES ('page@fish.com','MedRecPatients');

-- Patient
INSERT INTO patient (id,first_name,middle_name,last_name,dob,gender,ssn,address_id,phone,email) VALUES (101,'Fred','I','Winner',DATE'1965-03-26','Male','123456789',101,'4151234564','fred@golf.com');
INSERT INTO patient (id,first_name,middle_name,last_name,dob,gender,ssn,address_id,phone,email) VALUES (102 ,'Larry','J','Parrot',DATE'1959-02-13','Male','777777777',101,'4151234564','larry@bball.com');
INSERT INTO patient (id,first_name,middle_name,last_name,dob,gender,ssn,address_id,phone,email) VALUES (103 ,'Charlie','E','Florida',DATE'1973-10-29','Male','444444444',102,'4151234564','charlie@star.com');
INSERT INTO patient (id,first_name,middle_name,last_name,dob,gender,ssn,address_id,phone,email) VALUES (104 ,'Gabrielle','H','Spiker',DATE'1971-08-17','Female','333333333',101,'4151234564','volley@ball.com');
INSERT INTO patient (id,first_name,middle_name,last_name,dob,gender,ssn,address_id,phone,email) VALUES (105 ,'Page','A','Trout',DATE'1972-02-18','Male','888888888',102,'4151234564','page@fish.com');

-- Physician
INSERT INTO physician (id,first_name,middle_name,last_name,phone,email) VALUES (101,'Mary','J','Blige','1234567812','maryj@dr.com');
INSERT INTO physician (id,first_name,middle_name,last_name,phone,email) VALUES (102 ,'Phil','B','Lance','1234567812','phil@syscon.com');
INSERT INTO physician (id,first_name,middle_name,last_name,phone,email) VALUES (103 ,'Kathy','E','Wilson','1234567812','kwilson@dr.com');

-- Record
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (101,101,102,DATE'1999-06-18',101,'Complains about chest pain.','Mild stroke.  Aspiran advised.','Patient needs to stop smoking.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (102,101,103,DATE'1993-05-30',101,'Sneezing, coughing, stuffy head.','Common cold. Prescribed codiene cough syrup.','Call back if not better in 10 days.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (103,101,102,DATE'1989-07-05',101,'Twisted knee while playing soccer.','Severely sprained interior ligament.  Surgery required.','Cast will be necessary before and after.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (104,103,103,DATE'2000-02-18',102,'Ya ya ya.','Blah, Blah, Blah.','Notes start here.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (105,105,101,DATE'1991-04-01',103,'Drowsy all day.','Allergic to coffee.  Drink tea.','No notes.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (106,105,102,DATE'1987-01-13',101,'Blurred vision.','Increased loss of vision due to recent car accident.','Admit patient to hospital.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (107,105,101,DATE'1990-09-09',102,'Sore throat.','Strep thoart culture taken.  Sleep needed.','Call if positive.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (108,102,102,DATE'2001-06-20',101,'Overjoyed with everything.','Patient is crazy.  Recommend politics.','');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (109,104,103,DATE'2002-11-03',101,'Sprained ankle.','Lite cast needed.','At least 20 sprained ankles since 15.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (110,103,103,DATE'1997-12-21',101,'Forgetful, short-term memory not as sharpe.','General old age.','Patient will someday be 120 years old.');
INSERT INTO record (id,pat_id,phys_id,record_date,vital_id,symptoms,diagnosis,notes) VALUES (111,104,102,DATE'2001-05-13',102,'Nothing is wrong.','This gal is fine.','Patient likes lobby magazines.');

-- Prescription
INSERT INTO prescription (id,pat_id,date_prescribed,drug,record_id,dosage,frequency,refills_remaining,instructions) VALUES (101,101,DATE'1999-06-18','Advil',101,'100 tbls','1/4hrs',0,'No instructions');
INSERT INTO prescription (id,pat_id,date_prescribed,drug,record_id,dosage,frequency,refills_remaining,instructions) VALUES (102,101,DATE'1999-06-18','Drixoral',101,'16 oz','1tspn/4hrs',0,'No instructions');
INSERT INTO prescription (id,pat_id,date_prescribed,drug,record_id,dosage,frequency,refills_remaining,instructions) VALUES (103,101,DATE'1993-05-30','Codeine',102,'10 oz','1/6hrs',1,'No instructions');
INSERT INTO prescription (id,pat_id,date_prescribed,drug,record_id,dosage,frequency,refills_remaining,instructions) VALUES (104,102,DATE'2001-06-20','Valium',108,'50 pills','1/day',3,'No instructions');

-- Vital Signs
--INSERT INTO vital_signs (id,temperature,blood_pressure,pulse,weight,height) VALUES (101,'98','125/85','75',180,70);
--INSERT INTO vital_signs (id,temperature,blood_pressure,pulse,weight,height) VALUES (102,'100','120/80','85',199,69);
--INSERT INTO vital_signs (id,temperature,blood_pressure,pulse,weight,height) VALUES (103,'98','110/75','95',300,76);

-- Insert sequence ids
INSERT INTO patient_seq VALUES (110);

-- COMMIT;
-- END  MedRec data used by API Examples

-- START jsf.basic
DROP TABLE CustomerTable;
CREATE TABLE CustomerTable(
   custid     int not null,
   name       varchar(30),
   address    varchar(30),
   city       varchar(30),
   state      varchar(2),
   zip        varchar(5),
   area       varchar(3),
   phone      varchar(8));

insert into CustomerTable values
   (100,'Jackson','100 First St.','Pleasantville','CA','95404','707','555-1234');
insert into CustomerTable values
   (101,'Elliott','Arbor Lane, #3','Centre Town','CA','96539','415','787-5467');
insert into CustomerTable values
   (102,'Avery','14 Main','Arthur','CA','97675','510','834-7476');
   
-- COMMIT;
-- END 

-- START javaee6.jca.stockTransaction
DROP TABLE bankaccount;
create table bankaccount (
    owner varchar(30) primary key,
    balance double precision not null
);
insert into bankaccount (owner,balance) values ('Howard',10000);
insert into bankaccount (owner,balance) values ('James',8000);

DROP TABLE stockinf;
create table stockinf (
    stockname varchar(30) primary key,
    price double precision not null
);
insert into stockinf (stockname,price) values ('Real Oil Corporation',80);
insert into stockinf (stockname,price) values ('Sunshine Food Company',20);

DROP TABLE stockholding;
create table stockholding (
    owner varchar(30) not null,
    stockname varchar(30) not null,
    quantity int default 0,
    primary key(owner, stockName)
);
insert into stockholding (owner, stockname, quantity) values ('Howard', 'Real Oil Corporation', 60);
insert into stockholding (owner, stockname, quantity) values ('Howard', 'Sunshine Food Company', 20);
insert into stockholding (owner, stockname, quantity) values ('James', 'Real Oil Corporation', 30);
insert into stockholding (owner, stockname, quantity) values ('James', 'Sunshine Food Company', 50);
   
-- COMMIT;
-- END 

-- START javaee6.cdi
DROP TABLE JAVAEE6_CDI_USER;
CREATE TABLE JAVAEE6_CDI_USER (
		USERID VARCHAR(50) NOT NULL,
		EMAIL VARCHAR(50),
		MOBILEPHONE VARCHAR(50),
		NAME VARCHAR(50),
		PASSWORD VARCHAR(50),
		SALARY VARCHAR(50),
    CONSTRAINT JAVAEE6_USER_pk PRIMARY KEY
     (USERID));

insert into JAVAEE6_CDI_USER (USERID,PASSWORD,NAME,SALARY) values ('001','111','Jack','6880');
insert into JAVAEE6_CDI_USER (USERID,PASSWORD,NAME,SALARY) values ('002','222','Lily','30');
insert into JAVAEE6_CDI_USER (USERID,PASSWORD,NAME,SALARY) values ('003','333','Tom','3912');

-- END 
