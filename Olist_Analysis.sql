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
SELECT COUNT(*) FROM orders;

-- STEP 2: Check if there are duplicates.

SELECT COUNT(DISTINCT order_id) FROM orders;

-- 2. 

SELECT 
    order_status,
    ((COUNT(order_id) / (SELECT COUNT(order_id) FROM orders)) * 100) AS percentage_of_orders
FROM
    orders
GROUP BY order_status
ORDER BY percentage_of_orders DESC;

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

SELECT COUNT(*) FROM items;

-- 2.

/* On Kaggle datacard(https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce),
it is mentioned that 'order_dataset' has 99441 unique order_id.
However, it also mentions that 'order_items_dataset' has 98666 unique order_id.
This is because order_items_dataset does NOT have details of 775 order_id that have order_status as 'canceled' or 'unavailable'. */

-- STEP 1: finding order_id present in order_dataset that are not present in order_items_dataset; and its respective order_status.

SELECT 
    o.order_id AS order_dataset_order_id,
    i.order_id AS order_items_dataset_order_id,
    i.order_item_id,
    o.order_status
FROM
    orders o
    LEFT JOIN
    items i
    ON o.order_id = i.order_id
WHERE
    i.order_item_id = 0
	OR
    i.order_item_id IS NULL;

-- STEP 2: number of  order_id that have status as 'unavailable' or 'canceled' and are not present in 'order_items_dataset'

WITH cte AS (
         SELECT o.order_id AS order_dataset_order_id,
                i.order_id AS order_items_dataset_order_id,
                i.order_item_id,
                o.order_status
         FROM
             orders o
		     LEFT JOIN items i
		     ON o.order_id = i.order_id
         WHERE  
             i.order_item_id = 0
			 OR
             i.order_item_id IS NULL)
SELECT Count(*) AS number_of_unavailable_canceled_order_id
FROM   cte; 


-- 3 . 

-- STEP 1

SELECT 
    order_id,
    COUNT(DISTINCT seller_id) AS number_of_sellers
FROM
    items
GROUP BY order_id
HAVING number_of_sellers > 1;

-- STEP 2

SELECT *
FROM items
WHERE order_id = '002f98c0f7efd42638ed6100ca699b42';

-- C. ABOUT CUSTOMERS

/* 
1. There are 99441 entries in the customers dataset. 
2. 99441 orders (customer_id) were placed by 96096 customers (customer_unique_id).
*/


-- 1. 
SELECT COUNT(*)
FROM customers;

-- 2. 

SELECT COUNT(DISTINCT customer_unique_id) AS number_of_customers
FROM customers;


-- D. ABOUT PAYMENTS

/* 
1. There are 99440 unique order_id associated with payment value.
2. This table misses payment information regarding
 order_id 'bfbd0f9bdef84302105ad712db648a6c' present it orders_dataset and order_items_dataset, even though its order_status is delivered.
 3. The payment_value is in correspondence to each order and not to each item in the order. Thus, we can not find details of revenue generated from a particular product_category or seller.
 */ 

-- 1.

SELECT COUNT(DISTINCT order_id)
FROM payments;

-- 2.

SELECT 
    o.order_id, p.order_id,
    o.order_status
FROM
    orders o
	LEFT JOIN
    payments p
    USING (order_id)
WHERE
    p.order_id IS NULL;
 
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

WITH ORDER_PLACED AS (
         SELECT YEAR(purchase_timestamp)  AS YEAR,
                MONTH(purchase_timestamp) AS MONTH,
                COUNT(order_id)           AS number_of_orders_placed
         FROM   
                orders
         GROUP  BY
				YEAR(purchase_timestamp),
				MONTH(purchase_timestamp)
         ORDER  BY
                YEAR(purchase_timestamp) ASC,
				MONTH(purchase_timestamp) ASC)
SELECT *,
       SUM(number_of_orders_placed) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_orders_placed_till_this_period
FROM   ORDER_PLACED; 


-- 3. Total number of items delivered is 110197. 

SELECT 
    COUNT(i.order_item_id) AS number_of_items_delivered
FROM
    items i
	INNER JOIN
    orders o
    USING (order_id)
WHERE
    o.order_status = 'delivered';

-- 4. Total payment_value in each month and total payment_value generated from orders placed on Olist from beginning till that month.
 
 /*
 Total revenue generated from orders is 16008872.120054841
 Total highest payment_value was generated in Novemeber 2017, April 2018, March 2018. 
 It includes details of all orders made with all types of order_status.
 It does not contain detail of payment_value for order_id "bfbd0f9bdef84302105ad712db648a6c"
 */
 
 WITH PAYMENT_INFO AS (
         SELECT 
                YEAR(o.purchase_timestamp)  AS YEAR,
                MONTH(o.purchase_timestamp) AS MONTH,
                SUM(p.payment_value)        AS payment_value
         FROM   
                orders o
                INNER JOIN payments p
                USING (order_id)
         GROUP  BY
                   YEAR,
                   MONTH
         ORDER  BY 
                   YEAR ASC,
                   MONTH ASC)
SELECT *,
       SUM(payment_value) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_payment_made_by_this_period
FROM   PAYMENT_INFO; 

-- 5. Total number of distinct customers acquired each month and total number of distinct customers acquired from beginning till that month.

/* 
A. Highest number of distinct customers were acquired in November 2017, Jan 2018, March 2018. 
B. Total number of distinct customers is 96096. */

WITH CUSTOMER_GROWTH AS (
     (WITH CUSTOMER_EVERY_MONTH AS (
                   SELECT 
                          c.customer_unique_id,
                          MIN(o.purchase_timestamp) AS first_order
                   FROM   
                          customers c
                          INNER JOIN orders o USING (customer_id)
                   GROUP  BY
						  c.customer_unique_id)
          SELECT 
				 YEAR(first_order)         AS YEAR,
                 MONTH(first_order)        AS MONTH,
                 COUNT(customer_unique_id) AS number_of_customers
           FROM   
				 CUSTOMER_EVERY_MONTH
           GROUP  BY
				 YEAR,
				 MONTH
           ORDER  BY
                 YEAR ASC,
                     MONTH ASC))
SELECT *,
       SUM(number_of_customers) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_customers_by_this_period
FROM   CUSTOMER_GROWTH
ORDER  BY number_of_customers DESC; 
 
-- 6.  Total number of distinct sellers who received an order each month and total number of distinct sellers from beginning till that month.

/* A. Total number of distinct sellers is 3095.
B. Highest number of distinct sellers who received an order were in February 2017, April 2018, June 2018.
Note: The order_status of sellers here is not 'canceled' or 'unavailabe'  */    

-- A. 

SELECT COUNT(DISTINCT seller_id) AS number_of_sellers
FROM sellers;

-- B. 

WITH SELLER_GROWTH_DETAILS AS (
     WITH SELLER_DETAILS AS (
                  SELECT
                         i.seller_id,
                         MIN(o.purchase_timestamp) AS first_order_received
                  FROM   
                         items i
                         INNER JOIN orders o USING(order_id)
                  GROUP  BY
                         i.seller_id)
         SELECT 
			   YEAR(first_order_received)  AS YEAR,
			   MONTH(first_order_received) AS MONTH,
			   COUNT(seller_id)            AS number_of_sellers
          FROM   
			   SELLER_DETAILS
          GROUP  BY
			   YEAR,
			   MONTH
          ORDER  BY
               YEAR ASC,
			   MONTH ASC)
SELECT *,
       SUM(number_of_sellers) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_sellers_by_this_period
FROM   SELLER_GROWTH_DETAILS; 

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 3: Geographic data

-- 1. ORDERS: 

-- 1A. Cities
/* Highest number of orders were placed in these cities.  
sao paulo, rio de janeiro, belo horizonte, brasilia, curitiba, campinas, porto alegre, salvador, guarulhos
All other cities had less than 1000 orders placed. */

SELECT 
    c.customer_city AS city,
    COUNT(o.order_id) AS number_of_orders
FROM
    customers c
	INNER JOIN
    orders o
    USING (customer_id)
GROUP BY
	c.customer_city
ORDER BY
    COUNT(o.order_id) DESC
LIMIT 9;

 -- 1B. States
 /* Highest number of orders were placed from states SP, RJ, MG.
 All other states had less than 5500 orders. */


SELECT 
    c.customer_state AS state,
    COUNT(o.order_id) AS number_of_orders
FROM
    customers c
	INNER JOIN
    orders o
    USING (customer_id)
GROUP BY
    c.customer_state
ORDER BY
    COUNT(o.order_id) DESC;

-- 2. Customers

-- 2A. Cities
/* Highest number of customers belong to sao paulo, rio de janeiro, belo horizonte, brasília.
Less than 1,500 customers present in each of the other cities. */

SELECT 
    customer_city,
    COUNT(DISTINCT customer_unique_id) AS number_of_customers
FROM
    customers
GROUP BY
    customer_city
ORDER BY
    number_of_customers DESC;

-- 2B. States
/* Highest number of customers belong to the state of SP, RJ, MG. Each of the other states have less than 5500 customers.  */

SELECT 
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS number_of_customers
FROM
    customers
GROUP BY
    customer_state
ORDER BY
    COUNT(DISTINCT customer_unique_id) DESC;

-- 3. Sellers

-- 3A. Cities
/* sao paulo, curitiba, rio de janeiro, belo horizonte, ribeirao preto have highest number of sellers.
Each of the other cities has 50 or less sellers. */

SELECT 
    seller_city, COUNT(DISTINCT seller_id) AS number_of_sellers
FROM
    sellers
GROUP BY
    seller_city
ORDER BY
    COUNT(DISTINCT seller_id) DESC;

-- 3B. States
/* SP, PR, MG have the highest number of sellers. Each of the other states have less than 200 sellers. */

SELECT 
    seller_state, COUNT(DISTINCT seller_id) AS number_of_sellers
FROM
    sellers
GROUP BY
    seller_state
ORDER BY
    COUNT(DISTINCT seller_id) DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 4: When were orders placed?

-- 1. Highest number of orders, i.e. 1176 orders, were placed on 2017-11-24. 

SELECT 
    COUNT(order_id), DATE(purchase_timestamp)
FROM
    orders
GROUP BY
    DATE(purchase_timestamp)
ORDER BY
    COUNT(order_id) DESC;

-- 2. Week of month
/* Dividing days of a month as weeks with 1st to 7th as week 1, 8th to 14th as week 2, 15th to 21st as week 3,
 22nd to 28th as week 4, and remaining days as week 5 -
 we observe that the highest number of orders were placed in week 3, i.e. from 15th to 21st of a month. */
 
 SELECT 
    (CASE
        WHEN DAYOFMONTH(purchase_timestamp) < 8
        THEN 'week 1'
        WHEN
            DAYOFMONTH(purchase_timestamp) >= 8
			AND DAYOFMONTH(purchase_timestamp) < 15
        THEN
            'week 2'
        WHEN
            DAYOFMONTH(purchase_timestamp) >= 15
			AND DAYOFMONTH(purchase_timestamp) < 22
        THEN
            'week 3'
        WHEN
            DAYOFMONTH(purchase_timestamp) >= 22
			AND DAYOFMONTH(purchase_timestamp) < 29
        THEN
            'week 4'
        ELSE 'week 5'
    END) AS week_of_month,
    COUNT(order_id) AS number_of_orders
FROM
    orders
GROUP BY week_of_month
ORDER BY number_of_orders DESC;

-- 3. Weekday
/* Considering weekdays, the highest number of orders are placed on Monday and keeps reducing thereon.
The lease number of orders are placed on Saturday and Sunday. */

SELECT 
    DAYNAME(purchase_timestamp) AS day_of_week,
    COUNT(order_id) AS number_of_orders
FROM orders
GROUP BY DAYNAME(purchase_timestamp)
ORDER BY COUNT(order_id) DESC;

-- 4 . Time (Hourly basis)
/* 4.	Considering the 24 hours during a day, the most orders, i.e. more than 6000 total orders in each hour,
 are placed at 10, 11,  13, 14, 15, 16, 17,  20, 21 hours.
 Lowest number of orders, i.e. less than 550 total orders during each hour are placed from 2 a.m. to 6 a.m. */
 
SELECT 
    HOUR(purchase_timestamp) AS time_of_day,
    COUNT(order_id) AS number_of_orders
FROM
    orders
GROUP BY HOUR(purchase_timestamp)
ORDER BY COUNT(order_id) DESC;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 5: CUSTOMERS

-- 1. Repeat customers and non-repeat customers
/* 3.1188% customers are repeat customers, i.e. made more than one order from Olist. */

WITH REPEAT_CUSTOMERS_CTE AS(
         SELECT   CUSTOMER_UNIQUE_ID,
                  Count(CUSTOMER_ID) AS NUMBER_OF_ORDERS
         FROM     CUSTOMERS
         GROUP BY CUSTOMER_UNIQUE_ID
         ORDER BY Count(CUSTOMER_ID) DESC)
SELECT 
       (((
              SELECT Count(CUSTOMER_UNIQUE_ID)
              FROM   REPEAT_CUSTOMERS_CTE
              WHERE  NUMBER_OF_ORDERS > 1)/(
              SELECT Count(CUSTOMER_UNIQUE_ID)
              FROM   REPEAT_CUSTOMERS_CTE))*100) AS REPEAT_CUSTOMERS,
       (((
              SELECT Count(CUSTOMER_UNIQUE_ID)
              FROM   REPEAT_CUSTOMERS_CTE
              WHERE  NUMBER_OF_ORDERS <= 1)/(
              SELECT Count(CUSTOMER_UNIQUE_ID)
              FROM   REPEAT_CUSTOMERS_CTE))*100) AS NON_REPEAT_CUSTOMERS
FROM   
     REPEAT_CUSTOMERS_CTE
LIMIT 1;

-- 2. Number of orders placed by each customer
/* Customer with customer_unique_id 8d50f5eadf50201ccdcedfb9e2ac8455 placed the highest number of orders, i.e. 17 orders. */

SELECT 
    customer_unique_id,
    COUNT(customer_id) AS number_of_orders
FROM 
	customers
GROUP BY customer_unique_id
ORDER BY COUNT(customer_id) DESC;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 6: PRODUCT CATEGORIES

-- 1. Number of items ordered in each category

/* Highest number of items were ordered in these categories:
bed_bath_table, health_beauty, sports_leisure,  furniture_decor, computers_accessories 
Less than 7000 items were ordered in each of the other categories. */

SELECT 
    pe.product_category_name_english AS product_category,
    COUNT(product_id) AS number_of_items
FROM
    items i
	INNER JOIN
    products p
    USING (product_id)
	LEFT JOIN
    product_category_name_translation 
    ON p.product_name = pe.product_category_name
GROUP BY pe.product_category_name_english
ORDER BY number_of_items DESC;

-- 2. Top 3 ranked sellers in each category on the basis of number of items fulfilled by them in that category.

-- STEP 1: Create view for Top 3 ranked sellers of all categories.

CREATE VIEW TOP_3_SELLERS_IN_ALL_CATEGORIES AS(
  WITH TOP_SELLERS AS (
           SELECT 
                  TRIM(BOTH ' ' FROM pe.product_category_name_english)                       AS product_category,
                  i.seller_id,
                  COUNT(pe.product_category_name_english)                                    AS number_of_items,
                  DENSE_RANK () OVER (PARTITION BY pe.product_category_name_english
									  ORDER BY COUNT(pe.product_category_name_english) DESC) AS seller_rank
           FROM   
                  items i
                  INNER JOIN products p USING(product_id)
                  LEFT JOIN product_category_name_translation pe
				  ON p.product_name = pe.product_category_name
           GROUP  BY 
				  pe.product_category_name_english,
				  i.seller_id
           ORDER  BY
				  product_category DESC,
				  number_of_items DESC,
				  i.seller_id DESC)
  SELECT *
   FROM   TOP_SELLERS
   WHERE  seller_rank IN ( 1, 2, 3 )); 



-- STEP 2:  Find top 3 sellers of all categories

SELECT *
FROM top_3_sellers_in_all_categories;


-- STEP 3: Create stored procedure to find top 3 sellers of any category.

DELIMITER $$

CREATE PROCEDURE top_3_sellers (category_name VARCHAR (1000))

BEGIN

SELECT *
FROM top_3_sellers_in_all_categories
WHERE product_category LIKE category_name;

END $$

DELIMITER ;


-- Step 4:
/* Find top 3 sellers of any category.
Example:  Find top 3 sellers of 'bed_bath_table' , 'health_beauty' , 'sports_leisure' */

CALL top_3_sellers ('%bed_bath_table%');

/* Top 3 sellers of 'bed_bath_table' category are : 
4a3ca9315b744ce9f8e9374361493884	1572
da8622b14eb17ae2831f4ac5b9dab84a	1277
d2374cbcbb3ca4ab1086534108cc3ab7	597
*/

CALL top_3_sellers ('%health_beauty%');

/* Top 3 sellers of 'health_beauty' category are :
cc419e0650a3c5ba77189a1882b7556a	1091
620c87c171fb2a6dd6e8bb4dec959fc6	414
06a2c3af7b3aee5d69171b0e14f0ee87	405
*/

CALL top_3_sellers ('%sports_leisure%');

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

CREATE VIEW seller_and_number_of_categories AS
    (SELECT 
        i.seller_id,
        COUNT(DISTINCT pe.product_category_name_english) AS number_of_categories
    FROM
        items i
		INNER JOIN
        products p ON i.product_id = p.product_id
		LEFT JOIN
        product_category_name_translation pe
        ON p.product_name = pe.product_category_name
    GROUP BY
		i.seller_id
    ORDER BY
        number_of_categories DESC);
 
 -- 1A. 
 /*
 -- There are sellers who sell items in more than one product category
 -- Seller with seller_id 'b2ba3715d723d245138f291a6fe42594' tops in
 ‘items sold in highest number of categories’ by selling items in 27 categories.
 */
 
 SELECT *
FROM seller_and_number_of_categories;

-- 1B. 42.1648% sellers sold items in more than 1 category.

SELECT 
    (((SELECT COUNT(seller_id)
        FROM seller_and_number_of_categories
        WHERE number_of_categories > 1) /
        (SELECT COUNT(seller_id)
        FROM seller_and_number_of_categories)) * 100)  AS percentage_of_sellers_with_more_than_1category
FROM
    seller_and_number_of_categories
LIMIT 1;
 
 -- 2.
 /*
Top sellers based on highest ‘total number of items in all orders received by the seller’
(order_status is not 'canceled' or 'unavailable', and in all product categories) are:
6560211a19b47992c3666cc44a7e94c0 -- 2033 items
4a3ca9315b744ce9f8e9374361493884 -- 1987 items
1f50f920176fa81dab994f9023523100 – 1931 items
Each of the other sellers sold less than 1800 items.
*/

SELECT 
    seller_id,
    COUNT(product_id) AS number_of_items
FROM
    items
GROUP BY
    seller_id
ORDER BY
	number_of_items DESC; 

-- 3.
/*
Highest payment_value generated was by orders for items of these sellers 
(order_status is not canceled or unavailable).
7c67e1448b00f6e969d365cea6b010ab  --  507166.9073021412
1025f0e2d44d7041d6cf58b6550e0bfa  --  308222.0398402214
4a3ca9315b744ce9f8e9374361493884  --  301245.26976528764
*/

SELECT 
    i.seller_id,
    SUM(p.payment_value) AS total_payment_value
FROM
    items i
	INNER JOIN
    orders o
    USING (order_id)
	INNER JOIN
    payments p
    USING (order_id)
GROUP BY i.seller_id
ORDER BY total_payment_value DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 8: Payments

-- 1. 2.9777% of payments that were made in more than 1 instalments 

WITH payment_installments_details AS (
         SELECT   order_id,
                  Count(payment_installments) AS payment_installments
         FROM     payments
         GROUP BY order_id
         ORDER BY payment_installments DESC)
SELECT (((
              SELECT Count(*)
              FROM   payment_installments_details
              WHERE  payment_installments > 1)/(
              SELECT Count(*)
              FROM   payment_installments_details))*100) AS perecent_payment_installment_more_than_1
FROM   payment_installments_details
LIMIT 1;

-- 2. Number of times each payment type is used. 
-- Most used payment type is credit card – 76795 times.

SELECT 
    payment_type,
    COUNT(payment_type) AS number_of_times_used
FROM
    payments
GROUP BY payment_type
ORDER BY number_of_times_used DESC;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- SECTION 9: Average delivery time bewteen each customer city and each seller city.

/* STEP 1: Create view to store average number of days between purchase_timestamp and order_delivered_customer_date between
 each customer_city and each seller_city. */

CREATE VIEW avg_delivery_days_between_all_customer_city_and_seller_city AS
  (SELECT c.customer_city,
          s.seller_city,
          AVG(DATEDIFF(o.order_delivered_customer_date, o.purchase_timestamp)) over (PARTITION BY seller_city, customer_city) AS avg_time_in_days
   FROM   sellers s
          inner join items i USING (seller_id)
          inner join orders o USING (order_id)
          inner join customers c USING (customer_id)
   WHERE  o.order_status = 'delivered'
   GROUP  BY c.customer_city,
             s.seller_city
   ORDER  BY c.customer_city ASC,
             s.seller_city ASC,
             avg_time_in_days ASC); 

-- STEP 2: Find average number of days between purchase_timestamp and order_delivered_customer_date between each customer_city and each seller_city.

SELECT *
FROM avg_delivery_days_between_all_customer_city_and_seller_city; 
 
 -- STEP3: Create stored procedure to extract average number of days between purchase_timestamp and order_delivered_customer_date between any customer_city and any all seller_city.


DELIMITER $$

CREATE PROCEDURE avg_delivery_days_between_customer_city_and_seller_city (cutomer_city_name VARCHAR (1000), seller_city_name VARCHAR (1000))

BEGIN

SELECT *
FROM 
       avg_delivery_days_between_all_customer_city_and_seller_city
WHERE
       (customer_city LIKE cutomer_city_name)
	   AND 
       (seller_city LIKE seller_city_name);

END $$

DELIMITER ;

-- STEP4: Find average  number of days between purchase_timestamp and order_delivered_customer_date between any customer_city and any all seller_city.
-- Example: Between customer_city 'brasilia' and seller_city 'sao paulo'

CALL avg_delivery_days_between_customer_city_and_seller_city ('brasilia', 'sao paulo');

-- The avergae number of days for delivery is 11.