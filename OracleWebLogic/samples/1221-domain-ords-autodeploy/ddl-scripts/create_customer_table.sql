-- Create a sample schema with a simple table with some data on it
CREATE TABLE CUSTOMER
  (
    ID       NUMBER NOT NULL ,
    NAME     VARCHAR2(32) ,
    LASTNAME VARCHAR2(64) ,
    CONSTRAINT CUSTOMER_PK PRIMARY KEY ( ID ) ENABLE
  );

insert into CUSTOMER (ID,NAME,LASTNAME) values (1,'Smith','Liam');
insert into CUSTOMER (ID,NAME,LASTNAME) values (2,'Clerk','John');
insert into CUSTOMER (ID,NAME,LASTNAME) values (3,'Boguski','Marek');
commit;