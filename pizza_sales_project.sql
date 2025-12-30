create database pizza;
use pizza;
CREATE TABLE order_details (
    order_details_id INT,
    order_id INT,
    pizza_id VARCHAR(50),
    quantity INT
);
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE
"C:/Users/lenovo/Downloads/pizza_sales/pizza_sales/order_details.csv"
INTO TABLE order_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    order_time TIME
);
LOAD DATA LOCAL INFILE
"C:/Users/lenovo/Downloads/pizza_sales/pizza_sales/orders.csv"
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ingredients TEXT NOT NULL
);

LOAD DATA LOCAL INFILE
"C:/Users/lenovo/Downloads/pizza_sales/pizza_sales/pizza_types.csv"
INTO TABLE pizza_types
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

select * from pizza_types;

CREATE TABLE pizzas (
    pizza_id VARCHAR(50) ,
    pizza_type_id VARCHAR(50) NOT NULL,
    size CHAR(1) NOT NULL,
    price DECIMAL(5,2) NOT NULL,
    
    CONSTRAINT fk_pizza_type
        FOREIGN KEY (pizza_type_id)
        REFERENCES pizza_types(pizza_type_id)
);

LOAD DATA LOCAL INFILE
"C:/Users/lenovo/Downloads/pizza_sales/pizza_sales/pizzas.csv"
INTO TABLE pizzas
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Retrieve the total number of orders placed.
select count(*) as total_no_of_orders from orders;

-- Calculate the total revenue generated from pizza sales

select sum(price) from order_details t1
join pizzas t2
using(pizza_id);

-- Identify the highest-priced pizza.
select t2.name,t1.price from pizzas t1
join pizza_types t2
using(pizza_type_id)
where price=(select max(price) from pizzas);

-- Identify the most common pizza size ordered.
select size as most_common_pizza_size from order_details
join pizzas
using(pizza_id)
group by size
order by count(*) desc
limit 1;

-- List the top 5 most ordered pizza types along with their quantities.
select name,sum(quantity),count(*) as no_of_times_ordered from order_details
join pizzas
using (pizza_id)
join pizza_types
using(pizza_type_id)
group by name
order by count(*) desc
limit  5;

-- Intermediate:

-- Join the necessary tables to find the total quantity of each pizza category ordered;
select t3.category,sum(quantity) as total_quantity from order_details t1
join pizzas t2
using(pizza_id)
join pizza_types t3
using(pizza_type_id)
group by t3.category;

-- Determine the distribution of orders by hour of the day
SELECT
    HOUR(order_time) AS order_hour,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;
-- Group the orders by date and calculate the average number of pizzas ordered per day.
with cte as (select order_date,count(*) no_of_orders from orders
join order_details
using(order_id)
group by order_date)
select round(avg(no_of_orders),0) as average_no_of_pizzas_ordered_per_day from cte;

-- Join relevant tables to find the category-wise distribution of pizzas.
select category,count(*) no_of_ordered_pizzas from order_details
join pizzas
using(pizza_id)
join pizza_types
using(pizza_type_id)
group by category;

-- Determine the top 3 most ordered pizza types based on revenue.

select name,sum(price*quantity) as revanue from order_details
join pizzas
using(pizza_id)
join pizza_types
using(pizza_type_id)
group by name
order by revanue desc
limit 3;
-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.
with cte as (select name,sum(price) as amount from order_details
join pizzas
using(pizza_id)
join pizza_types
using(pizza_type_id)
group by name)
 (select name,(amount/sum(amount) over())*100 as percentage_of_contribution from cte);
 
 -- Analyze the cumulative revenue generated over time.
with cte as (select order_date,sum(price*quantity) as revenue from order_details
join pizzas
using(pizza_id)
join orders
using(order_id)
group by order_date)
select *,sum(revenue) over(rows between unbounded preceding and current row) as cumulative_revenue from cte;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with cte as (select t3.category,t3.name,sum(t2.price*quantity) as revenue from order_details t1
join pizzas t2
using(pizza_id)
join pizza_types t3
using(pizza_type_id)
group by t3.category,t3.name)
select * from (select *,rank() over(partition by category order by revenue desc) ranks from cte) t
where t.ranks<=3;












