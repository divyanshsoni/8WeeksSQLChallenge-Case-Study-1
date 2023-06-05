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

-- 5. Which item was the most popular for each customer?
with popular_item as (
  select customer_id, s.product_id, m.product_name,  
  dense_rank() over(partition by customer_id order by count(s.product_id) desc) as product_rank 
  from dannys_diner.sales as s join dannys_diner.menu as m 
  on s.product_id = m.product_id
  group by customer_id, s.product_id, m.product_name)

select customer_id, product_name 
from popular_item
where product_rank = 1

-- 6. Which item was purchased first by the customer after they became a member?
with orders_after_membership as (select s.customer_id, s.order_date, s.product_id, m.join_date, row_number() over(partition by s.customer_id order by s.product_id) as product_rank
from dannys_diner.sales as s join dannys_diner.members as m 
on s.customer_id = m.customer_id
            where s.order_date >= m.join_date)

select customer_id, product_name
from orders_after_membership as o join dannys_diner.menu as m
on o. product_id = m.product_id
where product_rank = 1
order by customer_id

-- 7. Which item was purchased just before the customer became a member?
with orders_before_membership as (select s.customer_id, s.order_date, s.product_id, m.join_date, dense_rank() over(partition by s.customer_id order by order_date desc) as product_rank
from dannys_diner.sales as s join dannys_diner.members as m 
on s.customer_id = m.customer_id
            where s.order_date < m.join_date)

select customer_id, product_name
from orders_before_membership as o join dannys_diner.menu as m
on o. product_id = m.product_id
where product_rank = 1
order by customer_id

-- 8. What is the total items and amount spent for each member before they became a member?
with cte as (select m.customer_id, s.order_date, s.product_id, m.join_date
from dannys_diner.sales as s join dannys_diner.members as m 
on s.customer_id = m.customer_id
            where s.order_date < m.join_date)

select customer_id, count(c.product_id) as total_list, sum(m.price) as total_amount
from cte as c join dannys_diner.menu as m
on c.product_id = m.product_id
group by customer_id
order by customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as (select customer_id, m.product_name, sum(m.price) as total_amount, 
case 
when m.product_name = 'sushi' then sum(m.price)*20
else sum(m.price)*10
end as points
from dannys_diner.sales as s join dannys_diner.menu as m
on s.product_id = m.product_id
group by customer_id, m.product_name
order by customer_id)

select customer_id, sum(points) as total_points
from cte
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do 
customer A and B have at the end of January?
