use Maven_Toys;
-- 1. Which are the top 10 best-selling products by revenue?
select p.product_name, SUM(s.units * p.product_price) as total_revenue
from products p
join sales s
on p.product_id = s.product_id
group by p.product_name
order by total_revenue desc
limit 10;

-- 2. Which products sold the highest number of units?
select * from sales;
select p.product_id,p.product_name, sum(s.units) as total_units
from products p
join sales s
on p.product_id = s.product_id
group by p.product_id,p.product_name
order by total_units desc;

-- 3. Which stores generated the highest revenue?
select * from stores; 
select st.store_name, SUM(s.units * p.product_price) as total_revenue
from products p
join sales s
on p.product_id = s.product_id
join stores st
on s.store_ID = st.store_ID
group by st.store_name
order by total_revenue desc;

-- 4. Which product category generated the highest revenue?
select p.product_category, SUM(s.units * p.product_price) as total_revenue
from products p
join sales s
on p.product_id = s.product_id
group by p.product_category
order by total_revenue desc
limit 1;

-- 5. What is the total revenue for each month?
select YEAR(s.sales_date) as sales_year, MONTH(s.sales_date) as sales_month, MONTHNAME(s.sales_date) as month_name, 
SUM(s.units * p.product_price) as total_revenue
from sales s
join products p
on s.product_id = p.product_id
group by YEAR(s.sales_date), MONTH(s.sales_date),MONTHNAME(s.sales_date) 
order by sales_year,sales_month;

-- 6. Which products have inventory less than 20 units?
select * from inventory;
select p.product_id,p.product_name, i.stock_on_hand
from products p
inner join inventory i
on p.product_id = i.product_id
where i.stock_on_hand < 20
order by i.stock_on_hand;

-- 7. Which stores have the highest remaining inventory?
select * from inventory;
select st.store_name, sum(i.stock_on_hand) as total_inventory
from stores st
inner join inventory i
on st.store_id = i.store_id
group by st.store_name
order by total_inventory desc;

-- 8. Which products have never been sold but still have inventory?
select p.product_id,p.product_name, i.stock_on_hand
from products p
left join sales s
on p.product_id = s.product_id
join inventory i
on p.product_id = i.product_id
where s.product_id IS NULL   AND i.Stock_On_Hand > 0;

-- 9. Find products that are out of stock in at least one store.
select p.product_name, stock_on_hand, st.store_name
from products p
inner join inventory i
on p.product_id = i.product_id
inner join stores st
on i.store_id = st.store_id
where stock_on_hand = 0;

-- 10. Which stores need inventory replenishment?
select st.store_name, sum(i.stock_on_hand) as total_inventory
from stores st
inner join inventory i
on st.store_id = i.store_id
group by st.store_name
having total_inventory < 500;

-- 11. Find the average revenue generated per sale.
select avg(s.units * p.product_price)  as avg_revenue
from sales s
join products p
on s.product_id = p.product_id;

-- 12. Find the average selling price of each product.
select product_name, avg(product_price) as average_selling_price
from products
group by product_name;

-- 13. Find the top-selling product in every store.
with product_sales AS
(
select st.store_ID, st.store_name, p.product_id, p.product_name, sum(s.units) as total_units_sold
from sales s
join products p
on s.product_id = p.product_id
inner join stores st
on s.store_id = st.store_id
group by st.store_ID, st.store_name, p.product_id, p.product_name
),
Ranked_products AS
(
select *,
dense_rank() over(partition by store_id order by total_units_sold desc) as rankk
from product_sales
)

select store_name, product_name, total_units_sold
from Ranked_products
where rankk = 1;




-- 14. Find the second highest revenue-generating product.
with cte AS
(select p.product_name, SUM(s.units * p.product_price) as total_revenue
from products p
join sales s
on p.product_id = s.product_id
group by p.product_name
),
rankk AS
(
select * , dense_rank() over(order by total_revenue desc) as rnk
from cte
)

select product_name, total_revenue
from rankk
where rnk = 2;


-- 15. Find the top 3 products by revenue in each category.
with product_revenue AS
(
select p.product_id,p.product_name, p.product_category, SUM(s.units * p.product_price) as total_revenue
from sales s
join products p
on s.product_id = p.product_id
group by p.product_id, p.product_name,p.product_category
),
Ranked_products AS
(
select *,
dense_rank() over(partition by product_category order by total_revenue desc) as rankk
from product_revenue
)

select product_category, product_name,total_revenue
from Ranked_products
where rankk <= 3
order by product_category, rankk;

-- 16. Calculate cumulative revenue by sale date.
with cte AS
(
select s.sales_date, SUM(s.units * p.product_price) as total_revenue
from sales s
join products p
on s.product_id = p.product_id
group by s.sales_date
)
select *, SUM(total_revenue) over(order by sales_date) as cummulative_revenue
from cte;

-- 17. Compare today's revenue with the previous sale date.
with cte AS
(
select s.sales_date, SUM(s.units * p.product_price) as total_revenue
from sales s
join products p
on s.product_id = p.product_id
group by s.sales_date
)
select *, LAG(total_revenue) over(order by sales_date) as previous_day_revenue,
(total_revenue - LAG(total_revenue) over(order by sales_date)) as revenue_diff
from cte;

-- 18. Find month-over-month revenue growth.
with cte AS
(
select YEAR(s.sales_date) as sales_year , MONTH(s.sales_date) as sales_month, MONTHNAME(s.sales_date) as month_name, SUM(s.units * p.product_price) as total_revenue
from sales s
join products p
on s.product_id = p.product_id
group by YEAR(s.sales_date), MONTH(s.sales_date),MONTHNAME(s.sales_date)
)
select *, LAG(total_revenue) over(order by sales_year,sales_month) as previous_day_revenue,
(total_revenue - LAG(total_revenue) over(order by sales_year,sales_month)) as revenue_growth
from cte;

-- 19. Which stores perform above the company's average revenue?
with cte AS
(
select st.store_name, SUM(s.units * p.product_price) as total_revenue
from sales s
join products p
on s.product_id = p.product_id
join stores st
on s.store_id = st.store_id
group by st.store_name
)

select * from cte
where total_revenue > 
(select AVG(total_revenue)
from cte);


-- 20. Build a Store Performance Report containing:
-- Store Name, Total Revenue, Total Units Sold, Number of Products Sold, Average Revenue per Sale, Revenue Rank
With cte AS
(
select st.store_name, SUM(s.units * p.product_price) as total_revenue, sum(s.units) as total_units, COUNT(DISTINCT(p.product_ID)) as number_of_products_sold,
AVG(s.units * p.product_price) as Average_revenue_per_sale
from sales s
join products p
on s.product_id = p.product_id
join stores st
on s.store_id = st.store_id
group by st.store_name 
)
Select *, dense_rank() over(order by total_revenue desc) as revenue_rank
from cte;
