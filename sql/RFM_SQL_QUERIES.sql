USE PORTFOLIO;

SELECT count(*) FROM SALES;

#RFM - RECENCY - MAX(DATE) ; FREQUENCY - COUNT(INVOICE ID) ; MONETARY - SUM(QUANTITY*UNITPRICE)
WITH rfm AS (
SELECT
  CUSTOMERID,
  SUM(QUANTITY*UNITPRICE) AS MonetaryValue,
  COUNT(DISTINCT INVOICENO) AS Frequency,
   MAX(DATE(STR_TO_DATE(InvoiceDate, '%c/%e/%Y'))) AS Last_order_date,
  DATEDIFF((SELECT MAX(DATE(STR_TO_DATE(InvoiceDate, '%c/%e/%Y'))) FROM SALES),MAX(DATE(STR_TO_DATE(InvoiceDate, '%c/%e/%Y')))) AS Recency
 FROM 
  SALES
 GROUP BY
  CUSTOMERID
),
RFM_CALC AS(
SELECT *, 
NTILE(3) OVER (ORDER BY RECENCY) AS CS_RECENCY,
NTILE(3) OVER (ORDER BY FREQUENCY DESC) AS CS_FREQUENCY,
NTILE(3) OVER (ORDER BY MONETARYVALUE DESC) AS CS_MONETARY
FROM RFM
)
SELECT *, CASE

    -- Champions: Customers who purchased recently, buy frequently, and spend the most.
    WHEN CS_RECENCY = 1
     AND CS_FREQUENCY = 1
     AND CS_MONETARY = 1
    THEN 'Champions'

    -- Loyal Customers: Customers who purchase frequently and continue to generate high value.
    WHEN CS_RECENCY <= 2
     AND CS_FREQUENCY = 1
     AND CS_MONETARY <= 2
    THEN 'Loyal Customers'

    -- New Customers: Customers who have purchased recently but have made only a few purchases so far.
    WHEN CS_RECENCY = 1
     AND CS_FREQUENCY = 3
    THEN 'New Customers'

    -- At Risk: Previously active and valuable customers who have not purchased recently.
    WHEN CS_RECENCY = 3
     AND CS_FREQUENCY = 1
     AND CS_MONETARY <= 2
    THEN 'At Risk'

    -- Lost Customers: Customers who have not purchased recently, buy infrequently, and spend the least.
    WHEN CS_RECENCY = 3
     AND CS_FREQUENCY = 3
     AND CS_MONETARY = 3
    THEN 'Lost Customers'

    -- Need Attention: Customers with moderate purchasing behaviour who need engagement to prevent churn.
    ELSE 'Need Attention'

END AS Customer_Segment
FROM RFM_CALC;
