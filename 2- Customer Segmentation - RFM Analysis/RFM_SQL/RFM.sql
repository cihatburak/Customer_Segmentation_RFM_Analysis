/*Creating RFM Table*/

CREATE TABLE [dbo].[RFM_SEGMENT](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[customer_id] [varchar](50) NULL,
	[Last_Invoice_Date] [datetime] NULL,
	[Recency] [int] NULL,
	[Frequency] [int] NULL,
	[Monetary] [int] NULL,
	[Recency_Score] [int] NULL,
	[Frequency_Score] [int] NULL,
	[Monetary_Score] [float] NULL,
	[Segment] [varchar](50) NULL 
) 

SELECT * FROM RFM_SEGMENT

/*Inserting customer_id*/

INSERT INTO RFM_SEGMENT (customer_id)
SELECT DISTINCT customer_id FROM [dbo].[olist_customers_dataset]

SELECT order_purchase_timestamp FROM [dbo].[olist_orders_dataset] 

/*Calculating & Inserting RFM Metrics*/

UPDATE RFM_SEGMENT SET Last_Invoice_Date=(SELECT MAX(order_purchase_timestamp) 
FROM [dbo].[olist_orders_dataset]  where customer_id=RFM_SEGMENT.customer_id)

SELECT max(Last_Invoice_Date) FROM RFM_SEGMENT

UPDATE RFM_SEGMENT SET Recency=DATEDIFF(DAY,Last_Invoice_Date,'20181111')

UPDATE RFM_SEGMENT SET Frequency=(select COUNT(order_id) from [dbo].[olist_orders_dataset] WHERE customer_id=RFM_SEGMENT.customer_id GROUP BY customer_id)

UPDATE RFM_SEGMENT SET Monetary=(SELECT SUM(payment_value2) FROM [dbo].[olist_orders_dataset] AS ORDERS JOIN [dbo].[olist_order_payments_dataset] AS PAYMENTS ON ORDERS.order_id = PAYMENTS.order_id WHERE customer_id=RFM_SEGMENT.customer_id GROUP BY customer_id) 

SELECT payment_value from (SELECT payment_value FROM [dbo].[olist_orders_dataset] AS ORDERS JOIN [dbo].[olist_order_payments_dataset] AS PAYMENTS ON ORDERS.order_id = PAYMENTS.order_id) T 

INSERT INTO [dbo].[olist_order_payments_dataset] (payment_value1)
SELECT DISTINCT payment_value FROM [dbo].[olist_order_payments_dataset]

/*RFM Scores**/

UPDATE RFM_SEGMENT SET Recency_Score= 
(
 select RANK from
 (
SELECT  *,
       NTILE(5) OVER(
       ORDER BY Recency desc) Rank
FROM RFM_SEGMENT
) t where  customer_id=RFM_SEGMENT. customer_id)

UPDATE RFM_SEGMENT SET Frequency_Score= 
(
 select RANK from
 (
SELECT  *,
       NTILE(5) OVER(
       ORDER BY Frequency) Rank
FROM RFM_SEGMENT
) t where  customer_id=RFM_SEGMENT. customer_id)

UPDATE RFM_SEGMENT SET Monetary_Score= 
(
 select RANK from
 (
SELECT  *,
       NTILE(5) OVER(
       ORDER BY Monetary) Rank
FROM RFM_SEGMENT
) t where  customer_id=RFM_SEGMENT. customer_id)


/*Segmentation**/

UPDATE RFM_SEGMENT SET Segment =(
CASE
WHEN Recency_Score LIKE  '[1-2]%' AND Frequency_Score LIKE '[1-2]%' THEN 'Hibernating'
WHEN Recency_Score LIKE  '[1-2]%' AND Frequency_Score LIKE '[3-4]%' THEN 'At_Risk'
WHEN Recency_Score LIKE  '[1-2]%' AND Frequency_Score LIKE '[5]%' THEN 'Cant_Loose'
WHEN Recency_Score LIKE  '[3]%' AND Frequency_Score LIKE '[1-2]%' THEN 'About_to_Sleep'
WHEN Recency_Score LIKE  '[3]%' AND Frequency_Score LIKE '[3]%' THEN 'Need_Attention'
WHEN Recency_Score LIKE  '[3-4]%' AND Frequency_Score LIKE '[4-5]%' THEN 'Loyal_Customers'
WHEN Recency_Score LIKE  '[4]%' AND Frequency_Score LIKE '[1]%' THEN 'Promising'
WHEN Recency_Score LIKE  '[5]%' AND Frequency_Score LIKE '[1]%' THEN 'New_Customers'
WHEN Recency_Score LIKE  '[4-5]%' AND Frequency_Score LIKE '[2-3]%' THEN 'Potential_Loyalists'
WHEN Recency_Score LIKE  '[5]%' AND Frequency_Score LIKE '[4-5]%' THEN 'Champions'
ELSE NULL
END) 

/*Segment Final**/

SELECT Segment , COUNT(*) as Count__ FROM RFM_SEGMENT GROUP BY Segment ORDER BY Count__ DESC

