-- =============================================================
-- PROJECT 3 - MARKETING ANALYTICS
-- 01_create_database_and_load_marketing.sql
-- MySQL 8.x
-- =============================================================

CREATE DATABASE IF NOT EXISTS marketing_analytics;
USE marketing_analytics;

DROP TABLE IF EXISTS marketing_campaign;

CREATE TABLE marketing_campaign (
    ID INT NOT NULL,
    Year_Birth SMALLINT NOT NULL,
    Education VARCHAR(50) NOT NULL,
    Marital_Status VARCHAR(50) NOT NULL,
    Income DECIMAL(12,2) NULL,
    Kidhome TINYINT NOT NULL,
    Teenhome TINYINT NOT NULL,
    Dt_Customer DATE NOT NULL,
    Recency SMALLINT NOT NULL,
    MntWines DECIMAL(12,2) NOT NULL,
    MntFruits DECIMAL(12,2) NOT NULL,
    MntMeatProducts DECIMAL(12,2) NOT NULL,
    MntFishProducts DECIMAL(12,2) NOT NULL,
    MntSweetProducts DECIMAL(12,2) NOT NULL,
    MntGoldProds DECIMAL(12,2) NOT NULL,
    NumDealsPurchases SMALLINT NOT NULL,
    NumWebPurchases SMALLINT NOT NULL,
    NumCatalogPurchases SMALLINT NOT NULL,
    NumStorePurchases SMALLINT NOT NULL,
    NumWebVisitsMonth SMALLINT NOT NULL,
    AcceptedCmp3 TINYINT NOT NULL,
    AcceptedCmp4 TINYINT NOT NULL,
    AcceptedCmp5 TINYINT NOT NULL,
    AcceptedCmp1 TINYINT NOT NULL,
    AcceptedCmp2 TINYINT NOT NULL,
    Response TINYINT NOT NULL,
    Complain TINYINT NOT NULL,
    Country VARCHAR(100) NOT NULL,
    PRIMARY KEY (ID)
);

-- IMPORTANT:
-- Replace the path below with the FULL path to marketing_data.csv on your PC.
-- Example Windows path:
-- C:/Users/YourName/Downloads/marketing_data.csv
-- Use forward slashes in the MySQL path.

-- Replace the placeholder below with the absolute path to 01_Data/marketing_data.csv on your computer.
LOAD DATA LOCAL INFILE 'C:/YOUR/PATH/marketing_data.csv'
INTO TABLE marketing_campaign
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@ID, @Year_Birth, @Education, @Marital_Status, @Income,
 @Kidhome, @Teenhome, @Dt_Customer, @Recency,
 @MntWines, @MntFruits, @MntMeatProducts, @MntFishProducts,
 @MntSweetProducts, @MntGoldProds, @NumDealsPurchases,
 @NumWebPurchases, @NumCatalogPurchases, @NumStorePurchases,
 @NumWebVisitsMonth, @AcceptedCmp3, @AcceptedCmp4, @AcceptedCmp5,
 @AcceptedCmp1, @AcceptedCmp2, @Response, @Complain, @Country)
SET
    ID = @ID,
    Year_Birth = @Year_Birth,
    Education = TRIM(@Education),
    Marital_Status = TRIM(@Marital_Status),
    Income = NULLIF(TRIM(@Income), ''),
    Kidhome = @Kidhome,
    Teenhome = @Teenhome,
    Dt_Customer = STR_TO_DATE(@Dt_Customer, '%Y-%m-%d'),
    Recency = @Recency,
    MntWines = @MntWines,
    MntFruits = @MntFruits,
    MntMeatProducts = @MntMeatProducts,
    MntFishProducts = @MntFishProducts,
    MntSweetProducts = @MntSweetProducts,
    MntGoldProds = @MntGoldProds,
    NumDealsPurchases = @NumDealsPurchases,
    NumWebPurchases = @NumWebPurchases,
    NumCatalogPurchases = @NumCatalogPurchases,
    NumStorePurchases = @NumStorePurchases,
    NumWebVisitsMonth = @NumWebVisitsMonth,
    AcceptedCmp3 = @AcceptedCmp3,
    AcceptedCmp4 = @AcceptedCmp4,
    AcceptedCmp5 = @AcceptedCmp5,
    AcceptedCmp1 = @AcceptedCmp1,
    AcceptedCmp2 = @AcceptedCmp2,
    Response = @Response,
    Complain = @Complain,
    Country = TRIM(@Country);

-- Useful index for common filtering/grouping.
CREATE INDEX idx_marketing_country ON marketing_campaign (Country);
CREATE INDEX idx_marketing_education ON marketing_campaign (Education);
CREATE INDEX idx_marketing_recency ON marketing_campaign (Recency);
CREATE INDEX idx_marketing_response ON marketing_campaign (Response);

-- =============================================================
-- Verification
-- =============================================================
SELECT COUNT(*) AS total_customers FROM marketing_campaign;
SELECT COUNT(DISTINCT ID) AS unique_customers FROM marketing_campaign;
SELECT COUNT(*) AS duplicate_ids
FROM (
    SELECT ID
    FROM marketing_campaign
    GROUP BY ID
    HAVING COUNT(*) > 1
) d;

SELECT COUNT(*) AS missing_income FROM marketing_campaign WHERE Income IS NULL;
SELECT MIN(Year_Birth) AS min_birth_year, MAX(Year_Birth) AS max_birth_year FROM marketing_campaign;
SELECT MIN(Income) AS min_income, MAX(Income) AS max_income FROM marketing_campaign;
SELECT MIN(Dt_Customer) AS first_customer_date, MAX(Dt_Customer) AS last_customer_date FROM marketing_campaign;

-- NOTE ABOUT RELATIONSHIPS:
-- This source is a customer-level dataset: one row = one customer.
-- There is no second natural entity/table with a valid foreign key in the source.
-- Therefore, DO NOT invent foreign-key relationships.
-- ID is the primary key of the customer-level table.
-- Campaigns, channels, products and demographics are attributes of each customer.
