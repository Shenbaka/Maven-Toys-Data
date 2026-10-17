CREATE DATABASE Maven_Toys;
use Maven_Toys;

-- Create Tables
-- Products
CREATE TABLE products(
Product_ID INT primary key,
Product_Name varchar(100) not null,
Product_Category varchar(50) not null,
Product_Cost decimal(10,2) not null,
Product_Price decimal(10,2) not null);

-- Stores
CREATE TABLE stores(
Store_ID INT primary key,
Store_Name varchar(100) not null,
Store_City varchar(50) not null,
Store_Location varchar(50),
Store_Open_Date date);

-- Calendar
CREATE TABLE calendar(
Date DATE primary key);

-- Sales
CREATE TABLE sales(
Sale_ID INT primary key,
Sales_Date DATE not null,
Store_ID INT not null,
Product_ID INT not null,
Units INT not null,

FOREIGN KEY(Sales_Date)
REFERENCES calendar(Date),

FOREIGN KEY(Store_ID)
REFERENCES Stores(Store_ID),

FOREIGN KEY(Product_ID)
REFERENCES Products(Product_ID)
);

-- Inventory
CREATE TABLE inventory(
Store_ID INT,
Product_ID INT,
Stock_On_Hand INT not null,

PRIMARY KEY(Store_ID,Product_ID),

FOREIGN KEY(Store_ID)
REFERENCES Stores(Store_ID),

FOREIGN KEY(Product_ID)
REFERENCES Products(Product_ID)
);

SHOW TABLES;
Desc products;
Desc Stores;
Desc Sales;
Desc inventory;
Desc calendar;



SELECT * FROM products;

-- Level 1 - SELECT, WHERE, ORDER BY 
-- Display all products with their product name and category.
select Product_Name, Product_Category
from products;
-- Display all stores located in Mexico.
SELECT Store_Name
from stores
where Store_City= "Mexicali";
-- Find all products whose cost is greater than 20.
select Product_Name,Product_Cost from products
where  Product_Cost > 20;
-- Display products sorted by retail price in descending order.
select Product_Name,Product_Price from products
order by Product_Price desc;
-- Find all products belonging to either the "Toys" or "Electronics" category.
select Product_Name,Product_Category from products
where Product_Category IN ("Toys", "Electronics");

-- Level 2 - Aggregate Functions
-- Find the total number of products.
select count(*) as total_products from products;
-- Find the average product cost.
select avg(Product_cost) from products;
-- Find the maximum and minimum retail price.
select max(Product_Price) as Maximum_Retail_Price,
min(Product_Price) as Minimum_Retail_Price
from products;
-- Find the total inventory quantity available.
select sum(Stock_On_Hand) as Total_Quantity from inventory;

-- Level 3 - GROUP BY & HAVING
-- Find the number of products in each category.
select product_Category, count(*) from products
group by product_Category;
-- Find the average retail price for every category.
select product_Category, avg(Product_Price) from products
group by product_Category;
-- Show categories having more than 5 products.
select product_Category, count(*) from products
group by product_Category
having count(*) > 5;
-- Find stores where total inventory is greater than 500.
select Store_ID, sum(Stock_On_Hand) AS Total_Inventory from inventory
group by Store_ID
having Total_Inventory > 500;

-- Level 4 - JOINS
-- Display product name along with its inventory quantity.
select p.product_ID, p.product_name, sum(i.Stock_On_Hand) as inventory_quantity
from products p
inner join  inventory i
on p.product_ID = i.product_id
group by p.product_id,p.product_name;
-- Display sales along with product names.
select s.Sale_ID, p.product_name
from sales s
inner join  products p
on s.product_ID = p.product_id;

-- Display sales along with store city.
select s.Sale_ID, st.store_city
from sales s
inner join  stores st
on s.store_ID = st.Store_ID;

-- Display product name, store name, and stock quantity.
select p.product_name, s.store_name, i.Stock_On_Hand
from products p
inner join inventory i
on p.Product_ID = i.Product_ID
inner join stores s
on s.Store_Id = i. Store_ID;

-- Find all products that have never been sold.
select p.* from products p
Left join sales s
on p.product_id = s.product_id
where s.product_id IS NULL;

-- OR   using not exists
select P.* from products p
where not exists
(select 1 from sales s
where s. product_ID = p.Product_ID);

-- Level 5 - Subqueries
-- Find products whose retail price is greater than the average retail price.
select  product_name, product_price from products
where product_price >
(select avg(product_price) from
products);

-- Find stores whose total inventory is greater than the average total inventory across all stores.
select Store_ID,sum(Stock_on_hand) as total_inventory
from inventory
group by store_id
having sum(Stock_on_hand)  >
(select avg(store_total)
from
(
select sum(Stock_on_hand) as store_total
from inventory
group by store_id
) t
);

-- Find the most expensive product.
select product_name, product_price from products
where product_price =
(select max(product_price) from products);


-- Find customers (or stores if no customer table exists) that generated sales greater than the average sales amount.
select s.Store_id, sum(s.units * p.product_price) as total_sales
from sales s
inner join products p
on s.Product_id = p.product_id
group by s.store_id
having sum(s.units * p.product_price) >
(select avg(store_sales)
from
(
select sum(s.units * p.product_price) as store_sales
from sales s
inner join products p
on s.Product_id = p.product_id
group by s.store_id
) as avg_sales);

-- Level 6 - CTE(Common Table Expressions)
-- Using a CTE, calculate total sales for every product.
With cte1 as (
select p.product_id, p.product_name, sum(s.units * p.product_price) as total_sales
from sales s
inner join products p
on s.Product_id = p.product_id
group by p.product_id, p.product_name)

select * from cte1;

-- Using a CTE, display the top 5 products with highest revenue.
With cte1 as (
select p.product_id, p.product_name, sum(s.units * p.product_price) as total_revenue
from sales s
inner join products p
on s.Product_id = p.product_id
group by p.product_id, p.product_name)

select * from cte1
order by total_revenue desc
Limit 5;


-- Level 7 - Window Functions
-- Rank products based on total revenue.
select  p.product_id, sum(s.units * p.product_price) as total_revenue, dense_rank() over(order by sum(s.units * p.product_price) desc) as sales_rank
from sales s
inner join products p
on s.Product_id = p.product_id
group by p.product_id;

-- Show each sale along with cumulative sales by date.
select  s.sale_id,s.sales_date ,(s.units * p.product_price)  as sale_amount,
sum(s.units * p.product_price) over(order by s.sales_date, s.sale_id desc) as cummulative_sale
from sales s
inner join products p
on s.Product_id = p.product_id
group by s.sale_id,s.sales_date;

-- Find previous day's sales using
select  s.sale_id,s.sales_date ,
Lag(s.units * p.product_price) over(order by s.sales_date, s.sale_id) as previous_day,(s.units * p.product_price)  as sale_amount
from sales s
inner join products p
on s.Product_id = p.product_id
group by s.sale_id,s.sales_date;

-- Level 8 - View
-- Create a view that displays:
-- Product Name, Store Name ,Quantity Sold, Revenue
-- Then query the view.

CREATE VIEW sales_view AS
select st.store_name,p.product_name,s.units as quantity_sold, (s.units * p.product_price) as revenue
from sales s
inner join products p
on s.Product_id = p.product_id
inner join stores st on
s.store_id = st.store_id;

select * from sales_view;


-- Level 9 - Stored Procedure
-- Create a stored procedure that accepts a category name and returns:
-- Product Name, Cost, Retail Price

DELIMITER //
CREATE PROCEDURE GetProductsByCategory(IN category varchar(50))
BEGIN
select product_Name, product_cost,Product_price from products
where product_category = category;
END //
DELIMITER ;

call GetProductsByCategory('Games');

-- Level 10 - Trigger (30)
-- Create a trigger such that whenever a new sale is inserted:
-- Inventory quantity automatically decreases.
DELIMITER //
CREATE TRIGGER trg_update_inventory
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
	update inventory
    SET Stock_on_hand = Stock_On_Hand - NEW.Units
    WHERE Store_ID = NEW.Store_ID AND Product_ID = NEW.Product_ID;
END //
DELIMITER ;


INSERT INTO sales(Sale_Id,Sales_Date,Store_ID, Product_ID,units) values(829263, "2022-01-02",46,6, 5);
select * from inventory
where product_id = 6 AND STORE_iD = 46;

select sale_ID from sales
order by Sale_ID asc;


SELECT
    MIN(Sale_ID) AS MinSaleID,
    MAX(Sale_ID) AS MaxSaleID,
    COUNT(*) AS TotalRows
FROM sales;