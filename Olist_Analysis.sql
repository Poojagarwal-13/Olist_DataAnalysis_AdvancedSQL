-- SECTION 1: ABOUT THE DATASET

-- A. ABOUT OLIST_ORDERS_DATASET

/*
1. There are 99441 entries in the table. 99441 is the total number of orders placed on Olist.
2. The order_statust of orders can be: delivered, shipped, canceled, unavailable, invoiced, processing, created, approved.  
0.62% of orders were cancelled. Note: There are no returns. 
3. The columns 'order_status, approved_at, order_delivered_carrier_date,  
order_delivered_customer_date, estimated_delivery_date' should have been present in ORDERS_ITEMS_DATASET instead of ORDERS_DATSET. 
*/
	

-- 1. 

-- STEP 1: Check total number of entries
SELECT count(*) from orders;

-- STEP 2: Check if there are duplicates.

SELECT count(distinct order_id) from orders;

-- 2. 

SELECT order_status, 
((count(order_id)/(select count(order_id) from orders))*100) as percentage_of_orders
from orders
group by  order_status
order by percentage_of_orders desc;

-- B. ABOUT ORDER_ITEMS_DATASET

/*
1. This dataset has 112650 entries.
 These are the total number of items that all orders in 'order_items_dataset' contain.
2. The dataset has details of 98666 orders whose order_status is NOT ‘canceled’ or ‘unavailable’. 
3. Each order (order_id) might have multiple items (order_item_id - sequential number identifying number of items included in the same order).
 Each item can belong to a distinct product category (has different product_id) and might be fulfilled by a distinct seller (seller_id).
4. The columns 'order_status, approved_at, order_delivered_carrier_date,  order_delivered_customer_date,
estimated_delivery_date' should have been present in ORDERS_ITEMS_DATASET instead of ORDERS_DATSET.
This would have helped in getting an accurate understanding of average delivery time,
and average delivery time between customer’s city or state and seller’s city or state. 
However, for this project, we assume that the details of these columns are same for all items in an order. 
*/

-- 1. 

select count(*) from items;

-- 2.

/* On Kaggle datacard(https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce),
it is mentioned that 'order_dataset' has 99441 unique order_id.
However, it also mentions that 'order_items_dataset' has 98666 unique order_id.
This is because order_items_dataset does NOT have details of 775 order_id that have order_status as 'canceled' or 'unavailable'. */

-- STEP 1: finding order_id present in order_dataset that are not present in order_items_dataset; and its respective order_status.

SELECT o.order_id as order_dataset_order_id, i.order_id as order_items_dataset_order_id, i.order_item_id, o.order_status
from orders o
left join items i
on o.order_id = i.order_id
where i.order_item_id = 0 or i.order_item_id is null;

-- STEP 2: number of  order_id that have status as 'unavailable' or 'canceled' and are not present in 'order_items_dataset'

with cte as (
SELECT o.order_id as order_dataset_order_id, i.order_id as order_items_dataset_order_id, i.order_item_id, o.order_status
from orders o
left join items i
on o.order_id = i.order_id
where i.order_item_id = 0 or i.order_item_id is null)
select count(*) as number_of_unavailable_canceled_order_id from cte;


-- 3 . 

-- STEP 1

select order_id, count(distinct seller_id) as number_of_sellers
from items
group by order_id
having number_of_sellers > 1;

-- STEP 2

select *
from items
where order_id = '002f98c0f7efd42638ed6100ca699b42';

-- C. ABOUT CUSTOMERS

/* 
1. There are 99441 entries in the customers dataset. 
2. 99441 orders (customer_id) were placed by 96096 customers (customer_unique_id).
*/


-- 1. 
SELECT count(*) from customers;

-- 2. 

SELECT count(distinct customer_unique_id) as number_of_customers
from customers;


-- D. ABOUT PAYMENTS

/* 
1. There are 99440 unique order_id associated with payment value.
2. This table misses payment information regarding
 order_id 'bfbd0f9bdef84302105ad712db648a6c' present it orders_dataset and order_items_dataset, even though its order_status is delivered.
 3. The payment_value is in correspondence to each order and not to each item in the order. Thus, we can not find details of revenue generated from a particular product_category or seller.
 */ 

-- 1.

SELECT COUNT(distinct order_id) from payments;

-- 2.

select o.order_id, p.order_id, o.order_status
from orders o
left join payments p
using (order_id)
where  p.order_id is null;
 
-- E. ABOUT REVIEWS

/* There is a problem in the data construction in the olist_order_reviews_dataset.
Check here:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/discussion/71650
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/discussion/71716
Thus, this dataset isn't used for the project. 
*/
 
 -- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
 -- SECTION 2: Growth of Olist
 
 -- 1 . Database contains details of orders made between September 2016 and October 2018, i.e. data from 2.12 years.

SELECT 
    CAST(MIN(purchase_timestamp) AS DATE) AS Date_first_order,
    CAST(MAX(purchase_timestamp) AS DATE) AS Date_last_order,
    ROUND(DATEDIFF(MAX(purchase_timestamp),MIN(purchase_timestamp)) / 365,2) AS Years
FROM orders; 

-- 2. Total number of orders placed every month and total number of orders placed on Olist from beginning till that month.

/* Months that had the highest number of orders placed are
November 2017, Jan 2018, March 2018, i.e. more than 7000 orders were placed. */

with order_placed as (
SELECT year(purchase_timestamp) as year, month(purchase_timestamp) as month,
 count(order_id) as number_of_orders_placed
from orders
group by year(purchase_timestamp), month(purchase_timestamp)
order by year(purchase_timestamp) asc, month(purchase_timestamp) asc)
Select *,
sum(number_of_orders_placed) over (rows between unbounded preceding and current row)
  as total_orders_placed_till_this_period 
from order_placed;


-- 3. Total number of items delivered is 110197. 

select count(i.order_item_id) as number_of_items_delivered
from items i
inner join orders o
using (order_id)
where o.order_status = 'delivered';

-- 4. Total payment_value in each month and total payment_value generated from orders placed on Olist from beginning till that month.
 
 /*
 Total revenue generated from orders is 16008872.120054841
 Total highest payment_value was generated in Novemeber 2017, April 2018, March 2018. 
 It includes details of all orders made with all types of order_status.
 It does not contain detail of payment_value for order_id "bfbd0f9bdef84302105ad712db648a6c"
 */
 
 with payment_info as (
select year(o.purchase_timestamp) as year, month(o.purchase_timestamp) as month,
sum(p.payment_value) as payment_value
from orders o
inner join payments p
using (order_id)
group by year, month
order by year asc, month asc)
select *,
sum(payment_value) over (rows between unbounded preceding and current row) as total_payment_made_by_this_period
from payment_info;

-- 5. Total number of distinct customers acquired each month and total number of distinct customers acquired from beginning till that month.

/* 
A. Highest number of distinct customers were acquired in November 2017, Jan 2018, March 2018. 
B. Total number of distinct customers is 96096. */

with customer_growth as (
(with customer_every_month as(
SELECT c.customer_unique_id, min(o.purchase_timestamp) as first_order
from customers c
inner join orders o
using (customer_id)
group by c.customer_unique_id)
select year(first_order) as year, month(first_order) as month,
 count(customer_unique_id) as number_of_customers
 from customer_every_month
 group by year, month
 order by year asc, month asc))
 select *,
 sum(number_of_customers) over (rows between unbounded preceding and current row) as total_customers_by_this_period
 from customer_growth
 order by number_of_customers desc;
 
-- 6.  Total number of distinct sellers who received an order each month and total number of distinct sellers from beginning till that month.

/* A. Total number of distinct sellers is 3095.
B. Highest number of distinct sellers who received an order were in February 2017, April 2018, June 2018.
Note: The order_status of sellers here is not 'canceled' or 'unavailabe'  */    

-- A. 

SELECT count(distinct seller_id) as number_of_sellers 
from sellers;

-- B. 

with seller_growth_details as(
with seller_details as(
SELECT i.seller_id, min(o.purchase_timestamp) as first_order_received
from items i
inner join orders o 
using(order_id)
group by i.seller_id)
SELECT year(first_order_received) as year, month(first_order_received) as month,
count(seller_id) as number_of_sellers
from seller_details
group by year, month
order by year asc, month asc)
select *,
sum(number_of_sellers) over (rows between unbounded preceding and current row) as total_sellers_by_this_period
from seller_growth_details;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 3: Geographic data

-- 1. ORDERS: 

-- 1A. Cities
/* Highest number of orders were placed in these cities.  
sao paulo, rio de janeiro, belo horizonte, brasilia, curitiba, campinas, porto alegre, salvador, guarulhos
All other cities had less than 1000 orders placed. */

SELECT c.customer_city as city, count(o.order_id) as number_of_orders
from customers c
inner join orders o
using (customer_id)
group by c.customer_city
order by count(o.order_id) desc
limit 9;

 -- 1B. States
 /* Highest number of orders were placed from states SP, RJ, MG.
 All other states had less than 5500 orders. */


SELECT c.customer_state as state, count(o.order_id) as number_of_orders
from customers c
inner join orders o
using (customer_id)
group by c.customer_state
order by count(o.order_id) desc;

-- 2. Customers

-- 2A. Cities
/* Highest number of customers belong to sao paulo, rio de janeiro, belo horizonte, brasília.
Less than 1,500 customers present in each of the other cities. */

SELECT customer_city, count(distinct customer_unique_id) as number_of_customers
from customers
group by customer_city
order by number_of_customers desc;

-- 2B. States
/* Highest number of customers belong to the state of SP, RJ, MG. Each of the other states have less than 5500 customers.  */

select customer_state, count(distinct customer_unique_id) as number_of_customers
from customers
group by customer_state
order by count(distinct customer_unique_id) desc;

-- 3. Sellers

-- 3A. Cities
/* sao paulo, curitiba, rio de janeiro, belo horizonte, ribeirao preto have highest number of sellers.
Each of the other cities has 50 or less sellers. */

SELECT seller_city, count(distinct seller_id) as number_of_sellers
from sellers
group by seller_city
order by count(distinct seller_id) desc;

-- 3B. States
/* SP, PR, MG have the highest number of sellers. Each of the other states have less than 200 sellers. */

SELECT seller_state, count(distinct seller_id) as number_of_sellers
from sellers
group by seller_state
order by count(distinct seller_id) desc;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 4: When were orders placed?

-- 1. Highest number of orders, i.e. 1176 orders, were placed on 2017-11-24. 

SELECT count(order_id), date(purchase_timestamp)
from orders
group by date(purchase_timestamp)
order by count(order_id) desc;

-- 2. Week of month
/* Dividing days of a month as weeks with 1st to 7th as week 1, 8th to 14th as week 2, 15th to 21st as week 3,
 22nd to 28th as week 4, and remaining days as week 5 -
 we observe that the highest number of orders were placed in week 3, i.e. from 15th to 21st of a month. */
 
 SELECT
(case 
when dayofmonth(purchase_timestamp) < 8 then 'week 1'
when dayofmonth(purchase_timestamp) >=8 and dayofmonth(purchase_timestamp) < 15 then 'week 2'
when dayofmonth(purchase_timestamp) >=15 and dayofmonth(purchase_timestamp) < 22 then 'week 3'
when dayofmonth(purchase_timestamp) >=22 and dayofmonth(purchase_timestamp) < 29 then 'week 4'
else 'week 5'
end) as week_of_month,
count(order_id) as number_of_orders
from orders
group by week_of_month
order by number_of_orders desc;

-- 3. Weekday
/* Considering weekdays, the highest number of orders are placed on Monday and keeps reducing thereon.
The lease number of orders are placed on Saturday and Sunday. */

SELECT dayname(purchase_timestamp) as day_of_week, 
count(order_id) as number_of_orders
from orders
group by dayname(purchase_timestamp)
order by count(order_id) desc;

-- 4 . Time (Hourly basis)
/* 4.	Considering the 24 hours during a day, the most orders, i.e. more than 6000 total orders in each hour,
 are placed at 10, 11,  13, 14, 15, 16, 17,  20, 21 hours.
 Lowest number of orders, i.e. less than 550 total orders during each hour are placed from 2 a.m. to 6 a.m. */
 
 SELECT hour(purchase_timestamp) as time_of_day, 
count(order_id) as number_of_orders
from orders
group by hour(purchase_timestamp)
order by count(order_id) desc;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 5: CUSTOMERS

-- 1. Repeat customers and non-repeat customers
/* 3.1188% customers are repeat customers, i.e. made more than one order from Olist. */

with repeat_customers_cte as( 
SELECT customer_unique_id, count(customer_id) as number_of_orders
from customers
group by customer_unique_id
order by count(customer_id) desc)
select 
(((select count(customer_unique_id) from repeat_customers_cte where number_of_orders > 1)/
(select count(customer_unique_id) from repeat_customers_cte))*100) as repeat_customers,
(((select count(customer_unique_id) from repeat_customers_cte where number_of_orders <= 1)/
(select count(customer_unique_id) from repeat_customers_cte))*100) as non_repeat_customers
from repeat_customers_cte
limit 1;

-- 2. Number of orders placed by each customer
/* Customer with customer_unique_id 8d50f5eadf50201ccdcedfb9e2ac8455 placed the highest number of orders, i.e. 17 orders. */

SELECT customer_unique_id, count(customer_id) as number_of_orders
from customers
group by customer_unique_id
order by count(customer_id) desc;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 6: PRODUCT CATEGORIES

-- 1. Number of items ordered in each category

/* Highest number of items were ordered in these categories:
bed_bath_table, health_beauty, sports_leisure,  furniture_decor, computers_accessories 
Less than 7000 items were ordered in each of the other categories. */

SELECT pe.product_category_name_english as product_category,
count(product_id) as number_of_items
from items i
inner join  products p
using (product_id)
left join product_category_name_translation pe
on p.product_name = pe.product_category_name
group by pe.product_category_name_english
order by number_of_items desc;

-- 2. Top 3 ranked sellers in each category on the basis of number of items fulfilled by them in that category.

-- STEP 1: Create view for Top 3 ranked sellers of all categories.

CREATE VIEW  top_3_sellers_in_all_categories as( 
with top_sellers as (
SELECT trim(both ' ' from pe.product_category_name_english) as product_category,
i.seller_id,
count(pe.product_category_name_english) as number_of_items,
dense_rank () over (
   partition by pe.product_category_name_english
   order by count(pe.product_category_name_english) desc) as seller_rank
from items i
inner join products p
using(product_id)
left join product_category_name_translation pe
on p.product_name = pe.product_category_name
group by  pe.product_category_name_english, i.seller_id
order by product_category desc, number_of_items desc, i.seller_id desc)
select * 
from top_sellers
where seller_rank in (1,2,3));



-- STEP 2:  Find top 3 sellers of all categories

select * from top_3_sellers_in_all_categories;



-- STEP 3: Create stored procedure to find top 3 sellers of any category.

DELIMITER $$

CREATE PROCEDURE top_3_sellers (category_name varchar (1000))

BEGIN

select * from top_3_sellers_in_all_categories
where product_category like category_name;

END $$

DELIMITER ;


-- Step 4:
/* Find top 3 sellers of any category.
Example:  Find top 3 sellers of 'bed_bath_table' , 'health_beauty' , 'sports_leisure' */

call top_3_sellers ('%bed_bath_table%');

/* Top 3 sellers of 'bed_bath_table' category are : 
4a3ca9315b744ce9f8e9374361493884	1572
da8622b14eb17ae2831f4ac5b9dab84a	1277
d2374cbcbb3ca4ab1086534108cc3ab7	597
*/

call top_3_sellers ('%health_beauty%');

/* Top 3 sellers of 'health_beauty' category are :
cc419e0650a3c5ba77189a1882b7556a	1091
620c87c171fb2a6dd6e8bb4dec959fc6	414
06a2c3af7b3aee5d69171b0e14f0ee87	405
*/

call top_3_sellers ('%sports_leisure%');

/*
Top 3 sellers of 'sports_leisure' category are :
218d46b86c1881d022bce9c68a7d4b15	410
4d6d651bd7684af3fffabd5f08d12e5a	387
4c2b230173bb36f9b240f2b8ac11786e	345
*/

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 7: Sellers

-- 1 
-- 1A. Do sellers sell items in multiple product categories?
-- 1B. If yes, what percentage of sellers sell items in multiple product categories?

create view seller_and_number_of_categories as (
SELECT i.seller_id, count(distinct pe.product_category_name_english) as number_of_categories
 from items i
 inner join products p
 on i.product_id = p.product_id
 left join product_category_name_translation pe
 on p.product_name = pe.product_category_name
 group by i.seller_id
 order by number_of_categories desc);
 
 -- 1A. 
 /*
 -- There are sellers who sell items in more than one product category
 -- Seller with seller_id 'b2ba3715d723d245138f291a6fe42594' tops in
 ‘items sold in highest number of categories’ by selling items in 27 categories.
 */
 
 select * from seller_and_number_of_categories;

-- 1B. 42.1648% sellers sold items in more than 1 category.

SELECT 
 (((select count(seller_id) from seller_and_number_of_categories where number_of_categories > 1)/
 (select count(seller_id) from seller_and_number_of_categories))*100)
 as percentage_of_sellers_with_more_than_1category
 from seller_and_number_of_categories
 limit 1;
 
 -- 2.
 /*
Top sellers based on highest ‘total number of items in all orders received by the seller’
(order_status is not 'canceled' or 'unavailable', and in all product categories) are:
6560211a19b47992c3666cc44a7e94c0 -- 2033 items
4a3ca9315b744ce9f8e9374361493884 -- 1987 items
1f50f920176fa81dab994f9023523100 – 1931 items
Each of the other sellers sold less than 1800 items.
*/

SELECT seller_id, count(product_id) as number_of_items
from items
group by seller_id 
order by number_of_items desc; 

-- 3.
/*
Highest payment_value generated was by orders for items of these sellers 
(order_status is not canceled or unavailable).
7c67e1448b00f6e969d365cea6b010ab  --  507166.9073021412
1025f0e2d44d7041d6cf58b6550e0bfa  --  308222.0398402214
4a3ca9315b744ce9f8e9374361493884  --  301245.26976528764
*/

SELECT i.seller_id, sum(p.payment_value) as total_payment_value
from items i
inner join orders o
using (order_id)
inner join payments p
using (order_id)
group by i.seller_id
order by total_payment_value desc;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 8: Payments

-- 1. 2.9777% of payments that were made in more than 1 instalments 

with payment_installments_details as(
select order_id, count(payment_installments) as payment_installments
from payments
group by order_id
order by  payment_installments desc)
SELECT (((select count(*) from payment_installments_details where payment_installments > 1)/
(select count(*) from payment_installments_details))*100) as perecent_payment_installment_more_than_1
from payment_installments_details
limit 1;

-- 2. Number of times each payment type is used. 
-- Most used payment type is credit card – 76795 times.

select payment_type, count(payment_type) as number_of_times_used
from payments
group by payment_type
order by number_of_times_used desc;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 9: Average delivery time bewteen each customer city and each seller city.

/* STEP 1: Create view to store average number of days between purchase_timestamp and order_delivered_customer_date between
 each customer_city and each seller_city. */

CREATE VIEW avg_delivery_days_between_all_customer_city_and_seller_city AS ( 
select c.customer_city, s.seller_city, 
avg(datediff(o.order_delivered_customer_date, o.purchase_timestamp)) over (partition by seller_city, customer_city) as avg_time_in_days
from sellers s
inner join items i
using (seller_id)
inner join orders o
using (order_id)
inner join customers c
using (customer_id)
where o.order_status = 'delivered'
group by c.customer_city, s.seller_city
order by c.customer_city asc, s.seller_city asc, avg_time_in_days asc); 

-- STEP 2: Find average number of days between purchase_timestamp and order_delivered_customer_date between each customer_city and each seller_city.

select * from avg_delivery_days_between_all_customer_city_and_seller_city; 
 
 -- STEP3: Create stored procedure to extract average number of days between purchase_timestamp and order_delivered_customer_date between any customer_city and any all seller_city.


DELIMITER $$

CREATE PROCEDURE avg_delivery_days_between_customer_city_and_seller_city (cutomer_city_name varchar (1000), seller_city_name varchar (1000))

BEGIN

select * from avg_delivery_days_between_all_customer_city_and_seller_city
where (customer_city like cutomer_city_name) and (seller_city like seller_city_name);

END $$

DELIMITER ;

-- STEP4: Find average  number of days between purchase_timestamp and order_delivered_customer_date between any customer_city and any all seller_city.
-- Example: Between customer_city 'brasilia' and seller_city 'sao paulo'

CALL avg_delivery_days_between_customer_city_and_seller_city ('brasilia', 'sao paulo');

-- The avergae number of days for delivery is 11.