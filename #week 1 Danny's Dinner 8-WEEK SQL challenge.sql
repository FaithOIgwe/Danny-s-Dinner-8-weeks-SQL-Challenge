--CASE STUDY #1:  DANNY'S DINER--

--PROJECT BY FAITH iGWE
--TOOLS USED: MICROSOFT SQL SERVER MANAGEMENT STUDIO (MSSMS)


--creating the tables and inserting variables into it

INSERT INTO dbo.Dannys_sales
("customer_id", "order_date", "product_id")
VALUES 
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
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


CREATE TABLE Dannys_members (
	"customer_id" VARCHAR(1),
	"join_date" DATE);

INSERT INTO dbo.Dannys_members
("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

INSERT INTO dbo.Dannys_menu
("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');


  --CASE STUDY QUESTIONS AND CODE
  --1. WHAT IS THE TOTAL AMOUNT EACH CUSTOMER SPENT AT THE RESTAURANT?
  --To find the amount each customer spent at the restaurant, we will be joing the sales and menu columns together and grouping it by customer ID

  SELECT s.customer_id, SUM(price) AS total_sales
  FROM dbo.Dannys_sales AS s
  JOIN dbo.Dannys_menu AS m
  ON s.product_id = m.product_id
  GROUP BY customer_id;

  -- 2.	HOW MANY DAYS HAS EACH CUSTOMER VISITED THE RESTAURANT?
  --In this case we will be the count and distinct function to get number of times a customer visited and grouping the selection by cutsomer_id

  SELECT customer_id, COUNT(DISTINCT order_date) AS num_visited
  FROM dbo.Dannys_sales
  GROUP BY customer_id;

  --3. WHAT WAS THE FIRST ITEM FROM THE MENU PURCHASED BY EACH CUSTOMER?
  WITH first_order AS (
						SELECT customer_id, order_date, product_name,
						DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM dbo.Dannys_sales AS s
	JOIN dbo.Dannys_menu AS m
	ON s.product_id = m.product_id)
SELECT  customer_id, product_name
FROM first_order
WHERE rank = 1
GROUP BY customer_id, product_name;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 (COUNT(s.product_id)) AS most_purchased, product_name
FROM dbo.Dannys_sales AS s
JOIN dbo.Dannys_menu AS m
  ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY most_purchased DESC;

--5. WHICH ITEM IS THE MOST POPULAR FOR EACH CUSTOMER?

WITH fav_item_cte AS (
	SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS order_count,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM dbo.Dannys_menu AS m
JOIN dbo.Dannys_sales AS s
	ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM fav_item_cte 
WHERE rank = 1;

--6. Which item was purchased first by the customer after they became a member?

WITH member_first AS (
	SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS d_rank
	FROM dbo.Dannys_sales AS s
	JOIN dbo.Dannys_members AS m
	ON s.customer_id = m.customer_id
	WHERE s.order_date >= m.join_date)

SELECT 
  s.customer_id, 
  s.order_date, 
  m2.product_name 
FROM member_first AS s
JOIN dbo.Dannys_menu AS m2
	ON s.product_id = m2.product_id
WHERE d_rank = 1;

--7. WHICH ITEM WAS PURCHASED JUST BEFORE THE CUSTOMER BECAME A MEMBER?
WITH prior_member_purchased_cte AS 
(
  SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC)  AS rank
  FROM dbo.Dannys_sales AS s
	JOIN dbo.Dannys_members AS m
		ON s.customer_id = m.customer_id
	WHERE s.order_date < m.join_date
)

SELECT s.customer_id, s.order_date, m2.product_name 
FROM prior_member_purchased_cte AS s
JOIN dbo.Dannys_menu AS m2
	ON s.product_id = m2.product_id
WHERE rank = 1;

--8. WHAT IS THE TOTAL ITEMS AND AMOUNT SPENT FOR EACH MEMBER BEFORE THEY BECAME A MEMBER?

SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS unique_menu_item, 
  SUM(mm.price) AS total_sales
FROM dbo.Dannys_sales AS s
JOIN dbo.Dannys_members AS m
	ON s.customer_id = m.customer_id
JOIN dbo.Dannys_menu AS mm
	ON s.product_id = mm.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id

--9. IF EACH $1 SPENT EQUATES TO 10 POINTS AND SUSHI HAS A 2X POINTS  MULTIIPLIER
--HOW MANY POINTS WILL EACH CUSTOMER HAVE?
WITH price_points_cte AS
(SELECT *, 
		CASE WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10 END AS points
	FROM dbo.Dannys_menu
)

SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points_cte AS p
JOIN dbo.Dannys_sales AS s
	ON p.product_id = s.product_id
GROUP BY s.customer_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- 1. Find member validity date of each customer and get last date of January
-- 2. Use CASE WHEN to allocate points by date and product id
-- 3. SUM price and points

WITH dates_cte AS 
(SELECT *, DATEADD(DAY, 6, join_date) AS valid_date, EOMONTH('2021-01-31') AS last_date
	FROM dbo.Dannys_members AS m)

SELECT  d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price,
	SUM(CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
		WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
		ELSE 10 * m.price END) AS points
FROM dates_cte AS d
JOIN dbo.Dannys_sales AS s
	ON d.customer_id = s.customer_id
JOIN dbo.Dannys_menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price


--BONUS QUESTIONS-------
------------------------

-- Join All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT  s.customer_id, s.order_date,  m.product_name,  m.price,
	CASE WHEN mm.join_date > s.order_date THEN 'N'
	  WHEN mm.join_date <= s.order_date THEN 'Y'
	  ELSE 'N' END AS member
FROM dbo.Dannys_sales AS s
LEFT JOIN dbo.Dannys_menu AS m
	ON s.product_id = m.product_id
LEFT JOIN dbo.Dannys_members AS mm
	ON s.customer_id = mm.customer_id
ORDER BY s.customer_id, s.order_date

-- Rank All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N), ranking(null/123)

WITH summary_cte AS 
( SELECT s.customer_id, s.order_date, m.product_name, m.price,
    CASE WHEN mm.join_date > s.order_date THEN 'N'
	    WHEN mm.join_date <= s.order_date THEN 'Y'
	    ELSE 'N'END AS member
FROM dbo.Dannys_sales AS s
LEFT JOIN dbo.Dannys_menu AS m
	ON s.product_id = m.product_id
LEFT JOIN dbo.Dannys_members AS mm
	ON s.customer_id = mm.customer_id
)

SELECT 
  *,
	CASE WHEN member = 'N' then NULL
    ELSE
			RANK () OVER(PARTITION BY customer_id, member ORDER BY order_date) 
		END AS ranking
FROM summary_cte;

