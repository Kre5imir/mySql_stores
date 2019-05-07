DROP SCHEMA IF EXISTS AmazonStores; 
-- Uncomment the DROP SCHEMA statement (above) to delete the DB and recreate each time the script runs

CREATE SCHEMA IF NOT EXISTS AmazonStores;
USE AmazonStores;

DROP TABLE IF EXISTS Buyer;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Purchuase;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Shippment;
DROP TABLE IF EXISTS Deliveries;
DROP TABLE IF EXISTS Seller;
CREATE TABLE seller(
	seller_id int UNIQUE,
    company_name varchar(50),
    email varchar(50),
    PRIMARY KEY(seller_id)
);
insert into seller (seller_id, company_name, email)
 values (111, 'nike', 'nike@gmail.com'),(112, 'addidas', 'addidas@gmail.com'),
 (113, 'nivea3', 'nivea3@gmail.com'),(114, 'dove', 'pantena@gmail.com');

CREATE TABLE products(
	product_id int auto_increment not null,
    title varchar(100),
    quantity int,
    price double,
    fk_seller_id int,
    foreign key (fk_seller_id)references seller(seller_id),
    PRIMARY KEY(product_id)
    );
insert into products ( title, quantity, price, fk_seller_id)
values ('soccerball', 22, 17.80, 111),( 'socks', 77, 0.30,111),('hoodies', 99, 11.40,111),
('soccerball', 56, 15.30,112),('socks', 99, 11.40,112),('hoodies', 99, 17.40,112),
('razor', 99, 12.40,113),('suncream', 99, 13.40,113),('soap', 99, 14.40,113),
('razor', 99, 3.40,114),('suncream', 99, 2.40,114),('soap', 99, 1.40,114);

CREATE TABLE Buyer (
	id int AUTO_INCREMENT NOT NULL,
   firstname varchar(50) NOT NULL,
   lastname varchar(50) NOT NULL,
   email varchar(150),
   PRIMARY KEY(id)
);
insert into Buyer (firstname, lastname, email)
values ('Jon', 'McCarthy', 'jon@dit.ie'),('Ivan', 'Haze', 'Ivan@dit.ie'),
('O', 'McDonald', 'McDonald@dit.ie'),('Martin', 'Hill', 'martin@dit.ie');

CREATE TABLE orders (
   order_id INT unique,
   cur_date date NOT NULL,
   fk_product int,
   fk_customer_id int,
   foreign key(fk_product)references products(product_id),
   foreign key(fk_customer_id)references Buyer(id),
   PRIMARY KEY(order_id)
);
insert into orders (order_id ,cur_date, fk_product, fk_customer_id)
values (1234,curdate(),1, 1),(1235,curdate(),1, 2),(1236,curdate(),3, 3),(1237,curdate(),4, 4);

 /*shippment_id is primary and foreign key uniqe, number is same as order id*/
CREATE TABLE shippment(
	shippment_id int unique,
    order_completed varchar(4),
    cur_date date,
    foreign key(shippment_id)references orders(order_id),
    primary key(shippment_id)
    );

insert into shippment(shippment_id,order_completed, cur_date)values(1234,'yes', '2019-07-05'),
(1235,'no', null),(1236,'yes', '2019-029-04'),(1237,'no', null);

CREATE TABLE purchase(
	PO_number INT UNIQUE,
    fk_order_id int,
    cur_date date,
    fk_seller int,
    foreign key(fk_seller)references seller(seller_id),
	foreign key (fk_order_id)references orders(order_id),
    PRIMARY KEY (PO_number)
    );
insert into purchase(PO_number,fk_order_id, cur_date, fk_seller)
values(30119,1234, curdate(),111),(30121,1235, curdate(), 112),
(30122,1236, curdate(),113),(30123,1237, curdate(),114);

CREATE TABLE deliveries(
	deliveries_id int unique,
    cur_date date,
	bay varchar(10),
    location int,
    foreign key(deliveries_id)references purchase(PO_number)
);
insert into deliveries(deliveries_id, cur_date, bay, location)values(30119, curdate(),'C',13),
( 30121, curdate(),'A', 17),(30122, curdate(),'E',13),( 30123,curdate(),'F', 31);

 -- to show tables join together creating information
select d.location, d.bay, p.PO_number, o.order_id, pr.title 
from deliveries d 
inner join purchase p on d.deliveries_id = p.PO_number 
inner join orders o on p.fk_order_id = o.order_id
inner join products pr on o.fk_product = pr.product_id
where p.PO_number like '%119';

-- query to find who orderd what and is the order completed
select B.firstname, O.order_id, pr.title, s.order_completed
from Buyer B, Orders O, products pr, shippment s 
where B.id = O.fk_customer_id and pr.product_id = O.fk_product and s.shippment_id = o.order_id;

-- select company name price and 
select se.company_name, pr.price, pr.title from seller se inner join products pr on pr.fk_seller_id = se.seller_id
where pr.title = 'suncream' and price < 22.50;

-- this view allow user to find item on physical location by order id 
drop view if exists stores;
CREATE VIEW stores AS SELECT d.location, d.bay, o.order_id from deliveries d inner join purchase pr on d.deliveries_id = pr.PO_number
inner join orders o on o.order_id = pr.fk_order_id;
select * from stores;

-- view limited for what is needed to compare prices from diffrent sellers
drop view if exists purchases;
CREATE VIEW purchases AS SELECT se.company_name, pr.title, pr.price from seller se 
inner join products pr on se.seller_id = pr.fk_seller_id;
select * from purchases;

-- function returns number of same product sold by diffrent companies
drop function if exists company_info;
DELIMITER //
CREATE function company_info(arg varchar(4)) returns int
BEGIN
	DECLARE num INT;
    SELECT count(se.company_name)
    INTO num 
    FROM seller se
    inner join products pr on se.seller_id = pr.fk_seller_id
    WHERE pr.title = arg;
    RETURN num;
END//
SELECT company_info('soap');

-- procedure to show if product is in store and is waiting to be shipped
drop temporary table if exists track_pack;
drop procedure if exists track_package;
DELIMITER //
CREATE procedure track_package()
LANGUAGE SQL
deterministic
sql security definer
COMMENT 'track product inside of company, delivery id can give us location'
BEGIN
	CREATE TEMPORARY TABLE IF NOT EXISTS track_pack 
    AS SELECT o.order_id, sh.order_completed, d.deliveries_id, d.cur_date 
	from orders o
	inner join shippment sh on o.order_id = sh.shippment_id 
	inner join purchase pu on o.order_id = pu.fk_order_id
	inner join deliveries d on pu.PO_number = d.deliveries_id;
	SELECT * FROM track_pack; 
END//
call track_package()

