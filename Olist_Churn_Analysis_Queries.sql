# 📉 E-Commerce Churn Intelligence: Advanced SQL Case Study
**Analytical Engine:** Microsoft SQL Server (SSMS)

---

## 📁 Phase 1: Environment Setup & Data Ingestion
The first stage of this project involves setting up a relational database environment and importing 9 raw CSV datasets.

### 1.1 Initializing the Database
I created a dedicated database `Olist_Ecommerce` to handle the relational schema.

```sql
CREATE DATABASE Olist_Ecommerce;
GO
USE Olist_Ecommerce;
GO
```

### 1.2 Importing Customer Feedback (Reviews Table)
The `Reviews` dataset was the first to be ingested. It contains customer ratings and qualitative feedback.
- **Data Engineering Choice:** To handle diverse comment lengths, I used `nvarchar(MAX)` for comment bodies to ensure no data loss during ingestion.
- **Verification:** I ran a data quality audit to confirm the average rating and total comment count.

```sql
-- Quality Check Query
SELECT 
    AVG(CAST(review_score AS FLOAT)) as Avg_Rating,
    COUNT(review_comment_message) as Total_Comments_Found
FROM Reviews;
```
---





/*
--------------------------------------------------------------------------------
PRO-LEVEL PROJECT: E-COMMERCE CHURN INTELLIGENCE (SSMS)
PHASE 1.3: TRANSACTIONAL AUDIT & INTEGRITY CHECK
--------------------------------------------------------------------------------
OBJECTIVE: 
The 'Orders' table is the central hub of our relational model. 
This audit ensures that all 99,441 records are correctly ingested and that 
the timestamps are ready for time-series analysis.

KEY METRICS:
1. Data Volume: Total transactions captured.
2. Temporal Coverage: First and Last purchase dates.
3. Status Distribution: Break-down of 'Delivered' vs 'Canceled' orders.
--------------------------------------------------------------------------------
*/

-- 1. Verifying Row Count and Date Range
SELECT 
    COUNT(order_id) AS Total_Order_Volume, 
    MIN(order_purchase_timestamp) AS Earliest_Purchase, 
    MAX(order_purchase_timestamp) AS Latest_Purchase
FROM Orders;

-- 2. Auditing Order Status Distribution (%)
-- This helps identify 'Friction Points' where orders were canceled or unavailable.
SELECT 
    order_status, 
    COUNT(*) AS Volume,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(10,2)) AS Market_Share_Percentage
FROM Orders
GROUP BY order_status
ORDER BY Volume DESC;

-- 3. Data Quality Check: Null Values in Critical Timestamps
-- This identifies orders that were supposed to be delivered but have no delivery date.
SELECT 
    COUNT(*) AS Delivered_Orders_Missing_Timestamp
FROM Orders
WHERE order_status = 'delivered' 
AND order_delivered_customer_date IS NULL;

/* 
OBSERVATION FOR PORTFOLIO:
The data successfully spans from Sept 2016 to Oct 2018. 
With over 99k records, the volume is statistically significant for 
predicting churn based on delivery performance.
*/





/*
--------------------------------------------------------------------------------
PHASE 1.5: PRODUCT CATALOG AUDIT & INVENTORY CHECK
--------------------------------------------------------------------------------
OBJECTIVE: 
The 'Products' table allows us to analyze which categories are prone to churn.
This audit identifies the diversity of our catalog and handles missing category tags.

KEY METRICS:
1. Product Volume: Total unique SKUs (Stock Keeping Units).
2. Category Diversity: Number of unique product categories.
3. Data Gaps: Checking for products with missing weight or category info.
--------------------------------------------------------------------------------
*/

-- 1. Auditing Product Catalog Size
-- This tells us how many different items we are selling.
SELECT 
    COUNT(product_id) AS Total_Unique_Products,
    COUNT(DISTINCT product_category_name) AS Total_Unique_Categories
FROM Products;

-- 2. Identifying 'Data Gaps'
-- Missing weights or categories can affect shipping calculations and marketing.
SELECT 
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS Missing_Category_Count,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS Missing_Weight_Count
FROM Products;

-- 3. Top 10 Raw Product Categories by Listing Count
-- This shows our strongest departments (even if names are in Portuguese for now).
SELECT TOP 10
    product_category_name, 
    COUNT(product_id) AS Product_Count
FROM Products
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY Product_Count DESC;

/* 
OBSERVATION FOR PORTFOLIO:
The catalog is diverse with over 30,000+ unique products. 
However, there are data gaps in category names that will be handled 
during the Data Cleaning phase before mapping to English translations.
*/


/*
--------------------------------------------------------------------------------
PHASE 1.7: SUPPLY-SIDE AUDIT - THE SELLERS ENTITY
--------------------------------------------------------------------------------
OBJECTIVE: 
Understanding the seller distribution is key. Shipping delays from distant 
sellers are a primary driver for customer churn. This audit maps our supply hubs.

KEY METRICS:
1. Seller Volume: Total registered vendors.
2. Market Coverage: Number of cities with active sellers.
3. Logistics Hubs: Identifying top states for seller concentration.
--------------------------------------------------------------------------------
*/

-- 1. Verifying Seller Volume and Reach
SELECT 
    COUNT(seller_id) AS Total_Sellers,
    COUNT(DISTINCT seller_city) AS Seller_Cities_Covered
FROM Sellers;

-- 2. Top 5 Logistics Hubs (By Seller Count)
-- This reveals where the majority of our inventory is stored.
SELECT TOP 5
    seller_state, 
    COUNT(seller_id) AS Seller_Count
FROM Sellers
GROUP BY seller_state
ORDER BY Seller_Count DESC;

/* 
OBSERVATION FOR PORTFOLIO:
With 3,095 sellers across 611 cities, the marketplace has a wide reach. 
São Paulo (SP) is the dominant hub, which we will later correlate with 
delivery speeds in Phase 2.
*/


/*
--------------------------------------------------------------------------------
PHASE 1.6: DATA LOCALIZATION & TRANSLATION MAPPING
--------------------------------------------------------------------------------
OBJECTIVE: 
Translating Portuguese category names to English to make the analysis 
accessible for global business reporting.
--------------------------------------------------------------------------------
*/

-- 1. Checking the lookup table
SELECT * FROM Category_Translation;

-- 2. "Pro" Join: Seeing our top categories in English
SELECT TOP 10
    t.product_category_name_english AS Category_EN,
    COUNT(p.product_id) AS Product_Count
FROM Products p
JOIN Category_Translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY Product_Count DESC;


/*
--------------------------------------------------------------------------------
PHASE 1.9: GEOSPATIAL AUDIT - DATA INTEGRITY CHECK
--------------------------------------------------------------------------------
*/

-- 1. Check total rows (Should be around 1,000,163)
SELECT COUNT(*) AS Total_Geopoints FROM Geolocation;

-- 2. See if the Zip Codes are correct
SELECT TOP 10 * FROM Geolocation ORDER BY geolocation_zip_code_prefix;


/*
--------------------------------------------------------------------------------
PHASE 1.11: PAYMENT BEHAVIOR & METHOD AUDIT
--------------------------------------------------------------------------------
OBJECTIVE: 
Analyzing payment methods is crucial for churn analysis. Friction in payment 
processing or lack of installment options can lead to cart abandonment.
--------------------------------------------------------------------------------
*/

-- 1. Auditing Payment Methods and Volume
SELECT 
    payment_type, 
    COUNT(*) AS Total_Transactions,
    SUM(payment_value) AS Total_Revenue,
    AVG(CAST(payment_installments AS FLOAT)) AS Avg_Installments
FROM Payments
GROUP BY payment_type
ORDER BY Total_Transactions DESC;

-- 2. Data Quality: Checking for zero-value payments
SELECT COUNT(*) AS Zero_Value_Payments
FROM Payments
WHERE payment_value = 0;

/* 
OBSERVATION:
Credit cards usually dominate. A high number of installments often 
indicates high-ticket purchases. We will later correlate payment 
types with customer loyalty.
*/



/*
--------------------------------------------------------------------------------
PHASE 1.8: FINANCIAL CORE AUDIT - REVENUE & LOGISTICS
--------------------------------------------------------------------------------
OBJECTIVE: 
Auditing the financial backbone of the marketplace. We are looking for 
high shipping costs (freight) which are often a major driver of customer churn.
--------------------------------------------------------------------------------
*/

-- 1. Verifying Total Sales and Logistics Burden
SELECT 
    COUNT(order_id) AS Total_Items_Sold,
    SUM(price) AS Gross_Merchandise_Value,
    SUM(freight_value) AS Total_Freight_Cost,
    AVG(price) AS Average_Item_Price
FROM Order_Items;

-- 2. Logistics Friction Check
-- Finding orders where shipping cost was more than 50% of the product price
SELECT 
    COUNT(*) AS High_Shipping_Friction_Orders
FROM Order_Items
WHERE freight_value > (price * 0.5);

/* 
OBSERVATION:
The Gross Merchandise Value (GMV) gives us the total scale of the business. 
The 'High Shipping Friction' count will be a key variable in our 
Churn Prediction model in Phase 2.
*/



/*
--------------------------------------------------------------------------------
PHASE 1.4: CUSTOMER DEMOGRAPHICS & RETENTION AUDIT
--------------------------------------------------------------------------------
OBJECTIVE: 
The 'Customers' table is the final piece of our relational puzzle. 
By comparing 'Total Records' with 'Unique Customers', we can measure the 
base retention rate of the platform.
--------------------------------------------------------------------------------
*/

-- 1. Auditing Total Records vs Unique Customers
-- A higher difference means more repeat customers (Higher Loyalty).
SELECT 
    COUNT(customer_id) AS Total_Transactions, 
    COUNT(DISTINCT customer_unique_id) AS Unique_Human_Users,
    (COUNT(customer_id) - COUNT(DISTINCT customer_unique_id)) AS Repeat_Customers
FROM Customers;

-- 2. Analyzing Top Customer Hubs
SELECT TOP 5
    customer_state, 
    COUNT(customer_id) AS Total_Orders
FROM Customers
GROUP BY customer_state
ORDER BY Total_Orders DESC;




## 🚀 Phase 2: Strategic RFM Analysis (Recency, Frequency, Monetary)
Now that the data is ingested, we move to **RFM Modeling**. This is the industry-standard method to segment customers:
1. **Recency:** Days since the last purchase (High recency = Risk of Churn).
2. **Frequency:** Total orders made (Loyalty indicator).
3. **Monetary:** Total spending (Revenue impact).


/* 
OBSERVATION:
If 'Repeat_Customers' is low, it indicates a 'Leaky Bucket' problem 
where the business is good at getting new users but fails to keep them.
*/



/* 
--------------------------------------------------------------------------------
STEP 2.1: CALCULATING RFM METRICS
--------------------------------------------------------------------------------
We are calculating:
- Recency: Days between the latest date in DB and the customer's last order.
- Frequency: Count of orders per unique customer.
- Monetary: Total value spent by the customer.
--------------------------------------------------------------------------------
*/

WITH Customer_Revenue AS (
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS Last_Purchase_Date,
        COUNT(o.order_id) AS Frequency,
        SUM(p.payment_value) AS Monetary
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN Payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT TOP 10
    customer_unique_id,
    DATEDIFF(DAY, Last_Purchase_Date, (SELECT MAX(order_purchase_timestamp) FROM Orders)) AS Recency_Days,
    Frequency,
    Monetary
FROM Customer_Revenue
ORDER BY Monetary DESC;



/* 
--------------------------------------------------------------------------------
STEP 2.2: SCORING & SEGMENTATION
Assigning scores (1-5) for Recency, Frequency, and Monetary.
Note: For Recency, a LOWER day count gets a HIGHER score (better).
--------------------------------------------------------------------------------
*/

WITH RFM_Base AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF(DAY, MAX(o.order_purchase_timestamp), (SELECT MAX(order_purchase_timestamp) FROM Orders)) AS Recency,
        COUNT(o.order_id) AS Frequency,
        SUM(p.payment_value) AS Monetary
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN Payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score, -- Higher days = Lower Score
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM RFM_Base
)
SELECT TOP 15
    customer_unique_id,
    Recency, Frequency, Monetary,
    (R_Score + F_Score + M_Score) AS Total_RFM_Score,
    CASE 
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
        WHEN R_Score >= 4 AND F_Score >= 2 THEN 'Loyal Customers'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk / Can''t Lose Them'
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Hibernating / Lost'
        ELSE 'About to Sleep'
    END AS Customer_Segment
FROM RFM_Scores
ORDER BY Total_RFM_Score DESC;





/* 
--------------------------------------------------------------------------------
STEP 2.3: FINAL BUSINESS INSIGHTS - SEGMENT DISTRIBUTION
--------------------------------------------------------------------------------
This summary tells the CEO exactly where the business is leaking money.
We are calculating the total count of customers in each segment and their 
contribution to total revenue.
--------------------------------------------------------------------------------
*/

WITH RFM_Base AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF(DAY, MAX(o.order_purchase_timestamp), (SELECT MAX(order_purchase_timestamp) FROM Orders)) AS Recency,
        COUNT(o.order_id) AS Frequency,
        SUM(p.payment_value) AS Monetary
    FROM Customers c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN Payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM RFM_Base
),
Final_Segmentation AS (
    SELECT *,
    CASE 
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
        WHEN R_Score >= 4 AND F_Score >= 2 THEN 'Loyal Customers'
        WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk / Can''t Lose Them'
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Hibernating / Lost'
        ELSE 'About to Sleep'
    END AS Customer_Segment
    FROM RFM_Scores
)
SELECT 
    Customer_Segment,
    COUNT(*) AS Total_Customers,
    ROUND(SUM(Monetary), 2) AS Total_Revenue,
    ROUND(AVG(Recency), 0) AS Avg_Recency_Days
FROM Final_Segmentation
GROUP BY Customer_Segment
ORDER BY Total_Revenue DESC;


## 🏁 Phase 2.3: Strategic Segmentation Results
After applying the RFM model, I categorized the 96k customers into distinct tiers. 
- **Champions:** High-value users who are active and loyal.
- **Hibernating / Lost:** The largest group, representing customers who haven't returned in 400+ days.
- **At Risk:** High-frequency shoppers who are showing signs of churn. 

**Business Action:** Retention campaigns should focus on 'At Risk' users before they move to the 'Hibernating' tier.


