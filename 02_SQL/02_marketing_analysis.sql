-- =============================================================
-- PROJECT 3 - MARKETING ANALYTICS
-- 02_marketing_analysis.sql
-- MySQL 8.x
-- =============================================================

USE marketing_analytics;

-- =============================================================
-- 1. DATA QUALITY
-- =============================================================
SELECT COUNT(*) AS total_customers FROM marketing_campaign;
SELECT COUNT(DISTINCT ID) AS unique_customers FROM marketing_campaign;

SELECT COUNT(*) AS missing_income
FROM marketing_campaign
WHERE Income IS NULL;

SELECT *
FROM marketing_campaign
WHERE Income IS NULL;

SELECT Education, COUNT(*) AS customers
FROM marketing_campaign
GROUP BY Education
ORDER BY customers DESC;

SELECT Marital_Status, COUNT(*) AS customers
FROM marketing_campaign
GROUP BY Marital_Status
ORDER BY customers DESC;

SELECT Country, COUNT(*) AS customers
FROM marketing_campaign
GROUP BY Country
ORDER BY customers DESC;

-- =============================================================
-- 2. CLEANED / ANALYTICAL VIEW
-- Income missing values are replaced with the overall non-null average.
-- Age uses 2015 because the campaign dataset covers the 2012-2014 period.
-- Total_Purchases intentionally excludes NumDealsPurchases because
-- discount purchases are a subset of purchases by channel and adding them
-- would double-count transactions.
-- =============================================================

CREATE OR REPLACE VIEW vw_marketing_customer AS
SELECT
    ID,
    Year_Birth,
    2015 - Year_Birth AS Age,
    Education,
    Marital_Status,
    COALESCE(Income, (SELECT AVG(Income) FROM marketing_campaign)) AS Income,
    Kidhome,
    Teenhome,
    Kidhome + Teenhome AS Total_Children,
    Kidhome + Teenhome + 1 AS Household_Size,
    Dt_Customer,
    Recency,
    MntWines,
    MntFruits,
    MntMeatProducts,
    MntFishProducts,
    MntSweetProducts,
    MntGoldProds,
    MntWines + MntFruits + MntMeatProducts + MntFishProducts + MntSweetProducts + MntGoldProds AS Total_Spending,
    NumDealsPurchases,
    NumWebPurchases,
    NumCatalogPurchases,
    NumStorePurchases,
    NumWebPurchases + NumCatalogPurchases + NumStorePurchases AS Total_Purchases,
    NumWebVisitsMonth,
    AcceptedCmp1,
    AcceptedCmp2,
    AcceptedCmp3,
    AcceptedCmp4,
    AcceptedCmp5,
    Response,
    AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5 AS Past_Campaign_Accepted,
    AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5 + Response AS Total_Campaign_Accepted,
    Complain,
    Country
FROM marketing_campaign;

-- =============================================================
-- 3. OVERALL KPIs
-- =============================================================
SELECT
    COUNT(*) AS total_customers,
    ROUND(SUM(Total_Spending), 2) AS total_spending,
    ROUND(AVG(Total_Spending), 2) AS avg_customer_spending,
    SUM(Total_Purchases) AS total_purchases,
    ROUND(AVG(Total_Purchases), 2) AS avg_purchases_per_customer,
    ROUND(AVG(Income), 2) AS avg_income,
    ROUND(AVG(Age), 1) AS avg_age,
    ROUND(AVG(Recency), 1) AS avg_recency,
    SUM(Response) AS campaign_responses,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct,
    SUM(Complain) AS complaints
FROM vw_marketing_customer;

-- =============================================================
-- 4. PRODUCT PERFORMANCE
-- =============================================================
SELECT 'Wines' AS product, SUM(MntWines) AS total_spending FROM vw_marketing_customer
UNION ALL
SELECT 'Fruits', SUM(MntFruits) FROM vw_marketing_customer
UNION ALL
SELECT 'Meat', SUM(MntMeatProducts) FROM vw_marketing_customer
UNION ALL
SELECT 'Fish', SUM(MntFishProducts) FROM vw_marketing_customer
UNION ALL
SELECT 'Sweets', SUM(MntSweetProducts) FROM vw_marketing_customer
UNION ALL
SELECT 'Gold', SUM(MntGoldProds) FROM vw_marketing_customer
ORDER BY total_spending DESC;

-- =============================================================
-- 5. CHANNEL PERFORMANCE
-- =============================================================
SELECT 'Web' AS channel, SUM(NumWebPurchases) AS purchases FROM vw_marketing_customer
UNION ALL
SELECT 'Catalog', SUM(NumCatalogPurchases) FROM vw_marketing_customer
UNION ALL
SELECT 'Store', SUM(NumStorePurchases) FROM vw_marketing_customer
UNION ALL
SELECT 'Deals', SUM(NumDealsPurchases) FROM vw_marketing_customer
ORDER BY purchases DESC;

SELECT
    ROUND(AVG(NumWebPurchases), 2) AS avg_web_purchases,
    ROUND(AVG(NumCatalogPurchases), 2) AS avg_catalog_purchases,
    ROUND(AVG(NumStorePurchases), 2) AS avg_store_purchases,
    ROUND(AVG(NumDealsPurchases), 2) AS avg_deal_purchases
FROM vw_marketing_customer;

-- =============================================================
-- 6. CAMPAIGN PERFORMANCE
-- =============================================================
SELECT 'Campaign 1' AS campaign, SUM(AcceptedCmp1) AS accepted_customers,
       ROUND(AVG(AcceptedCmp1) * 100, 2) AS response_rate_pct
FROM vw_marketing_customer
UNION ALL
SELECT 'Campaign 2', SUM(AcceptedCmp2), ROUND(AVG(AcceptedCmp2) * 100, 2) FROM vw_marketing_customer
UNION ALL
SELECT 'Campaign 3', SUM(AcceptedCmp3), ROUND(AVG(AcceptedCmp3) * 100, 2) FROM vw_marketing_customer
UNION ALL
SELECT 'Campaign 4', SUM(AcceptedCmp4), ROUND(AVG(AcceptedCmp4) * 100, 2) FROM vw_marketing_customer
UNION ALL
SELECT 'Campaign 5', SUM(AcceptedCmp5), ROUND(AVG(AcceptedCmp5) * 100, 2) FROM vw_marketing_customer
UNION ALL
SELECT 'Final Campaign', SUM(Response), ROUND(AVG(Response) * 100, 2) FROM vw_marketing_customer
ORDER BY response_rate_pct DESC;

-- =============================================================
-- 7. CUSTOMER SEGMENTATION BY SPENDING QUARTILES
-- =============================================================
WITH ranked AS (
    SELECT *, NTILE(4) OVER (ORDER BY Total_Spending) AS spending_quartile
    FROM vw_marketing_customer
)
SELECT
    CASE spending_quartile
        WHEN 1 THEN 'Low Value'
        WHEN 2 THEN 'Medium-Low Value'
        WHEN 3 THEN 'Medium-High Value'
        WHEN 4 THEN 'High Value'
    END AS customer_segment,
    COUNT(*) AS customers,
    ROUND(AVG(Total_Spending), 2) AS avg_spending,
    ROUND(AVG(Income), 2) AS avg_income,
    ROUND(AVG(Total_Purchases), 2) AS avg_purchases,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct,
    ROUND(AVG(Recency), 1) AS avg_recency
FROM ranked
GROUP BY spending_quartile
ORDER BY spending_quartile;

-- =============================================================
-- 8. AGE GROUP ANALYSIS
-- =============================================================
SELECT
    CASE
        WHEN Age < 30 THEN 'Under 30'
        WHEN Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN Age BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+'
    END AS age_group,
    COUNT(*) AS customers,
    ROUND(AVG(Total_Spending), 2) AS avg_spending,
    ROUND(AVG(Total_Purchases), 2) AS avg_purchases,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct
FROM vw_marketing_customer
GROUP BY age_group
ORDER BY MIN(Age);

-- =============================================================
-- 9. INCOME GROUP ANALYSIS
-- =============================================================
SELECT
    CASE
        WHEN Income < 30000 THEN 'Under 30K'
        WHEN Income < 50000 THEN '30K-50K'
        WHEN Income < 70000 THEN '50K-70K'
        WHEN Income < 100000 THEN '70K-100K'
        ELSE '100K+'
    END AS income_group,
    COUNT(*) AS customers,
    ROUND(AVG(Total_Spending), 2) AS avg_spending,
    ROUND(AVG(Total_Purchases), 2) AS avg_purchases,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct
FROM vw_marketing_customer
GROUP BY income_group
ORDER BY MIN(Income);

-- =============================================================
-- 10. EDUCATION ANALYSIS
-- =============================================================
SELECT
    Education,
    COUNT(*) AS customers,
    ROUND(AVG(Income), 2) AS avg_income,
    ROUND(AVG(Total_Spending), 2) AS avg_spending,
    ROUND(AVG(Total_Purchases), 2) AS avg_purchases,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct
FROM vw_marketing_customer
GROUP BY Education
ORDER BY avg_spending DESC;

-- =============================================================
-- 11. MARITAL STATUS ANALYSIS
-- =============================================================
SELECT
    Marital_Status,
    COUNT(*) AS customers,
    ROUND(AVG(Total_Spending), 2) AS avg_spending,
    ROUND(AVG(Total_Purchases), 2) AS avg_purchases,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct
FROM vw_marketing_customer
GROUP BY Marital_Status
ORDER BY avg_spending DESC;

-- =============================================================
-- 12. COUNTRY ANALYSIS
-- =============================================================
SELECT
    Country,
    COUNT(*) AS customers,
    ROUND(AVG(Total_Spending), 2) AS avg_spending,
    ROUND(SUM(Total_Spending), 2) AS total_spending,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct
FROM vw_marketing_customer
GROUP BY Country
ORDER BY total_spending DESC;

-- =============================================================
-- 13. OVERTIME-LIKE BEHAVIOR: WEB VISITS VS WEB PURCHASES
-- =============================================================
SELECT
    NumWebVisitsMonth,
    COUNT(*) AS customers,
    ROUND(AVG(NumWebPurchases), 2) AS avg_web_purchases,
    ROUND(AVG(Total_Spending), 2) AS avg_spending
FROM vw_marketing_customer
GROUP BY NumWebVisitsMonth
ORDER BY NumWebVisitsMonth;

-- =============================================================
-- 14. TOP 20 CUSTOMERS
-- =============================================================
SELECT
    ID, Age, Education, Country, Income,
    Total_Spending, Total_Purchases,
    NumWebPurchases, NumCatalogPurchases, NumStorePurchases,
    Response
FROM vw_marketing_customer
ORDER BY Total_Spending DESC
LIMIT 20;

-- =============================================================
-- 15. HIGH-VALUE CUSTOMERS
-- =============================================================
WITH ranked AS (
    SELECT *, NTILE(4) OVER (ORDER BY Total_Spending) AS spending_quartile
    FROM vw_marketing_customer
)
SELECT *
FROM ranked
WHERE spending_quartile = 4
ORDER BY Total_Spending DESC;

-- =============================================================
-- 16. CAMPAIGN RESPONSE BY CUSTOMER SEGMENT
-- =============================================================
WITH ranked AS (
    SELECT *, NTILE(4) OVER (ORDER BY Total_Spending) AS spending_quartile
    FROM vw_marketing_customer
)
SELECT
    CASE spending_quartile
        WHEN 1 THEN 'Low Value'
        WHEN 2 THEN 'Medium-Low Value'
        WHEN 3 THEN 'Medium-High Value'
        WHEN 4 THEN 'High Value'
    END AS customer_segment,
    COUNT(*) AS customers,
    SUM(Response) AS responses,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct
FROM ranked
GROUP BY spending_quartile
ORDER BY spending_quartile;

-- =============================================================
-- 17. COMPLAINT ANALYSIS
-- =============================================================
SELECT
    Complain,
    COUNT(*) AS customers,
    ROUND(AVG(Total_Spending), 2) AS avg_spending,
    ROUND(AVG(Response) * 100, 2) AS response_rate_pct
FROM vw_marketing_customer
GROUP BY Complain;

-- =============================================================
-- 18. BUSINESS QUESTIONS - QUICK ANSWERS
-- =============================================================

-- Best product by total spending
SELECT product, total_spending
FROM (
    SELECT 'Wines' AS product, SUM(MntWines) AS total_spending FROM vw_marketing_customer
    UNION ALL SELECT 'Fruits', SUM(MntFruits) FROM vw_marketing_customer
    UNION ALL SELECT 'Meat', SUM(MntMeatProducts) FROM vw_marketing_customer
    UNION ALL SELECT 'Fish', SUM(MntFishProducts) FROM vw_marketing_customer
    UNION ALL SELECT 'Sweets', SUM(MntSweetProducts) FROM vw_marketing_customer
    UNION ALL SELECT 'Gold', SUM(MntGoldProds) FROM vw_marketing_customer
) p
ORDER BY total_spending DESC
LIMIT 1;

-- Best campaign by response rate
SELECT campaign, response_rate_pct
FROM (
    SELECT 'Campaign 1' AS campaign, AVG(AcceptedCmp1) * 100 AS response_rate_pct FROM vw_marketing_customer
    UNION ALL SELECT 'Campaign 2', AVG(AcceptedCmp2) * 100 FROM vw_marketing_customer
    UNION ALL SELECT 'Campaign 3', AVG(AcceptedCmp3) * 100 FROM vw_marketing_customer
    UNION ALL SELECT 'Campaign 4', AVG(AcceptedCmp4) * 100 FROM vw_marketing_customer
    UNION ALL SELECT 'Campaign 5', AVG(AcceptedCmp5) * 100 FROM vw_marketing_customer
    UNION ALL SELECT 'Final Campaign', AVG(Response) * 100 FROM vw_marketing_customer
) c
ORDER BY response_rate_pct DESC
LIMIT 1;

-- Highest-spending education group
SELECT Education, avg_spending
FROM (
    SELECT Education, AVG(Total_Spending) AS avg_spending
    FROM vw_marketing_customer
    GROUP BY Education
) e
ORDER BY avg_spending DESC
LIMIT 1;
