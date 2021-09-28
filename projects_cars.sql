-- Overview of the database

SELECT 'Customers' AS table_name,
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers

 UNION ALL

SELECT 'Products' AS table_name,
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

 UNION ALL

SELECT 'ProductLines' AS table_name,
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

 UNION ALL

SELECT 'Orders' AS table_name,
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

 UNION ALL

SELECT 'OrderDetails' AS table_name,
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

 UNION ALL

SELECT 'Payments' AS table_name,
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name,
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

 UNION ALL

SELECT 'Offices' AS table_name,
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;


/*

Question #1: Which products should we order more of or less of?

This question refers to inventory reports, including low stock and product performance.
This will optimize the supply and the user experience by preventing the best-selling products from going out-of-stock.

- The low stock represents the quantity of each product sold divided by the quantity of product in stock.
  We can consider the ten lowest rates. These will be the top ten products that are (almost) out-of-stock.
- The product performance represents the sum of sales per product.
- Priority products for restocking are those with high product performance that are on the brink of being out of stock.

 */


-- 1.1 Finding which products are low on stock

SELECT p.productCode, ROUND(SUM(od.quantityOrdered) * 1.0 / p.quantityInStock, 2) AS low_stock
  FROM products p
  JOIN Orderdetails od
    ON p.productCode = od.productCode
 GROUP BY p.productCode
 ORDER BY low_stock
 LIMIT 10;


-- 1.2 Finding the products that sell more

SELECT productCode, SUM(quantityOrdered * priceEach) AS product_performance
  FROM orderdetails
 GROUP BY productCode
 ORDER BY product_performance DESC
 LIMIT 10;


-- 1.3 Combining queries to answer Question #1

 WITH
 low_stock_table AS (SELECT p.productCode,
                            p.productName,
                            p.productLine,
                            ROUND(SUM(od.quantityOrdered) * 1.0 / p.quantityInStock, 2) AS low_stock
                 FROM products p
                 JOIN Orderdetails od
                   ON p.productCode = od.productCode
                GROUP BY p.productCode
                ORDER BY low_stock
                LIMIT 10
 )

 SELECT lst.productCode,
        lst.productName,
        lst.productLine,
        SUM(quantityOrdered * priceEach) AS product_performance
   FROM low_stock_table lst
   JOIN orderdetails od
     ON lst.productCode = od.productCode
  GROUP BY lst.productCode
  ORDER BY product_performance DESC
  LIMIT 10;


/*
Question #2: How Should We Match Marketing and Communication Strategies to Customer Behavior?

We’ll explore customer information by answering the second question:
how should we match marketing and communication strategies to customer behaviors?
This involves categorizing customers:
finding the VIP (very important person) customers and those who are less engaged.

*/


-- 2.1 Profit for each customer

 SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
   FROM products p
   JOIN orderdetails od
     ON p.productCode = od.productCode
   JOIN orders o
     ON o.orderNumber = od.orderNumber
  GROUP BY o.customerNumber;

-- 2.2 (CTE) Top Five VIP Customers

    WITH

  money_in_by_customer_table AS (
  SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
    FROM products p
    JOIN orderdetails od
      ON p.productCode = od.productCode
    JOIN orders o
      ON o.orderNumber = od.orderNumber
   GROUP BY o.customerNumber
  )

  SELECT contactFirstName, contactLastName, city, country, mc.revenue
    FROM customers c
    JOIN money_in_by_customer_table mc
      ON mc.customerNumber = c.customerNumber
   ORDER BY mc.revenue DESC
   LIMIT 5;


-- Alternative way (using subqueries)

-- 2.1.1 Profit for each customer

   SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
     FROM products p
     JOIN orderdetails od
       ON p.productCode = od.productCode
     JOIN orders o
       ON o.orderNumber = od.orderNumber
    GROUP BY o.customerNumber;
    ORDER BY proft_per_customer DESC
    LIMIT 5;

-- 2.2.2 (CTE) Top Five VIP Customers

    WITH
    top_five AS (   SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
         FROM products p
         JOIN orderdetails od
           ON p.productCode = od.productCode
         JOIN orders o
           ON o.orderNumber = od.orderNumber
        GROUP BY o.customerNumber
        ORDER BY revenue DESC
        LIMIT 5
    )

    SELECT customerNumber,
           contactLastName,
           contactFirstName,
           city,
           country,
           (SELECT revenue
              FROM top_five
            WHERE customerNumber = c.customerNumber) AS revenue
      FROM customers c
     WHERE c.customerNumber IN (SELECT customerNumber
                                  FROM top_five)

      GROUP BY customerNumber
      ORDER BY revenue DESC;

-- 2.3 Top five least engaged customers

WITH
less_engaged AS (

SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)

SELECT c.customerNumber,
       contactFirstName,
       contactLastName,
       city,
       country,
       ls.revenue
FROM less_engaged ls
JOIN customers c
ON ls.customerNumber = c.customerNumber
ORDER BY revenue
LIMIT 5;


/* Question #3: How much we can spend on marketing for each customer?

To determine how much money we can spend acquiring new customers,
we can compute the Customer Lifetime Value (LTV),
representing the average amount of money a customer generates.
We can then determine how much we can spend on marketing.

*/

-- 3.1 CLV

WITH
money_in_by_customer_table AS(

SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber

)

SELECT ROUND(AVG(revenue), 2) AS CLV
  FROM money_in_by_customer_table mc;
