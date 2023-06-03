CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- 1. What is the total amount each customer spent at the restaurant?
select sales.customer_id, sum(menu.price) as total_amount
from dannys_diner.sales as sales join dannys_diner.menu as menu
on sales.product_id = menu.product_id
group by sales.customer_id
order by sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as num_days
from dannys_diner.sales
group by customer_id
order by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with first_item as (select customer_id, s.product_id, product_name, row_number() over(partition by customer_id order by order_date) as rank
             from dannys_diner.sales as s join dannys_diner.menu as m 
            on s.product_id = m.product_id)

select customer_id, product_name 
from first_item
where rank = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) as most_purchased
from dannys_diner.sales as s join dannys_diner.menu as m
on s.product_id = m.product_id
group by m.product_name
order by most_purchased desc
limit 1
