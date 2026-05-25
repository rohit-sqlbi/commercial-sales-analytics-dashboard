CREATE DATABASE IF NOT EXISTS delivery_partner;
USE delivery_partner;
select * from customers;
select * from delivery_performance;
select * from order_items;
select * from orders;
select * from products;

-- null check --
select * from customers
where customer_name is null 
or city is null 
or age is null 
or gender is null 
or signup_date is null;

select * from delivery_performance
where  delivery_time_mins is null
   or delivery_status is null
   or rider_rating is null;

select * from order_items
where  quantity is null
   or selling_price is null
   or discount is null;
   
   select * from orders
where order_date is null
   or delivery_partner is null
   or payment_mode is null 
   or city is null;

select * from products
where product_name is null 
   or category is null 
   or brand is null 
   or mrp is null 
   or cost_price is null;
   -- duplicate check --
select customer_id,count(*) from customers
group by customer_id
having count(*)>1;

select delivery_id,count(*)
from delivery_performance
group by delivery_id
having count(*) > 1;

select order_item_id,count(*)
from order_items
group by order_item_id
having count(*) > 1;

select order_id,count(*)
from orders
group by  order_id
having count(*) > 1;

select product_id,count(*)
from products
group by product_id
having count(*)> 1;

-- check invalid sales --
SELECT *
FROM order_items
WHERE quantity <= 0;
SELECT *
FROM order_items
WHERE selling_price <= 0;

-- 1. total sales -- 

DROP VIEW total_sales;
CREATE VIEW total_sales AS

select sum(quantity * selling_price) as total_sales 
from order_items;
-- 2. total cost  --
CREATE VIEW total_cost AS

select sum(oi.quantity * p.cost_price)as total_cost from 
order_items oi
join products p 
on oi.product_id = p.product_id;
-- 3. top 10 selling products -- 
CREATE VIEW top_selling_products AS

select p.product_id,p.product_name,
sum(oi.quantity * oi.selling_price) as total_sales
 from products  p 
 join order_items oi 
 on p.product_id = oi.product_id
group by product_id,product_name;

-- 4. top city by sales -- 
 CREATE VIEW city_sales AS

select o.city,
sum(oi.quantity * oi.selling_price) as total_sales
from order_items oi 
join orders o 
on oi.order_id = o.order_id
group by o.city;

-- 5. most used payment_mode --
CREATE VIEW payment_mode AS

select payment_mode,count(order_id)as total_order 
from orders 
group by payment_mode;

-- 6. monthly sales trend --
CREATE VIEW monthly_sales AS

select month(o.order_date) as month_no,
sum(oi.quantity * oi.selling_price) as total_sales
from orders o
join order_items oi 
on o.order_id = oi.order_id
group by month(o.order_date);

-- 7. repeat customer --
CREATE VIEW repeat_customers AS

select customer_id,count(order_id) as total_orders
from orders
group by customer_id
having count(order_id)>1;
-- 8. high value customers --
CREATE VIEW high_value_customer AS

select c.customer_id,c.customer_name,
sum(oi.quantity * oi.selling_price) as total_sales
from customers c
join orders o 
on c.customer_id = o.customer_id
join order_items oi 
on o.order_id = oi.order_id
group by c.customer_id,c.customer_name;

-- 9. find top selling product in each category -- 
CREATE VIEW product_each_category AS

select * from(
select p.category,p.product_name,
sum(oi.quantity * oi.selling_price) as total_sales,
row_number() over(partition by p.category
order by sum(oi.quantity * oi.selling_price) desc) as rn
from products p 
join order_items oi 
on p.product_id = oi.product_id
group by p.category,p.product_name
)r
where rn
 = 1;
-- 10. rank customers based on total spending -- 
CREATE VIEW customer_total_spend AS

select c.customer_id,c.customer_name,
sum(oi.quantity * oi.selling_price) as total_sales,
rank() over(order by 
sum(oi.quantity * oi.selling_price) desc) as customer_rank
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi 
on o.order_id = oi.order_id
group by c.customer_id,c.customer_name;

-- 11. find products wose selling price is greater than the avg selling price --
 CREATE VIEW products_above_avg_selling_price AS

select
    p.product_id,
    p.product_name,
    oi.selling_price
from order_items oi
join products p
on oi.product_id = p.product_id
where oi.selling_price >
(select avg(selling_price)
    from order_items
);


-- 12. find customers whose total orders are greater than the avg orders of all customers --
CREATE VIEW customers_with_above_avg_orders AS

select c.customer_id,c.customer_name from customers c
where (select count(order_id) from orders o
where o.customer_id  = c.customer_id  )>(
select avg(total_order) from(
select c2.customer_id,c2.customer_name,count(o2.order_id) as total_order from customers c2
join orders o2
on c2.customer_id = o2.customer_id
group by c2.customer_id,c2.customer_name
)t
);

