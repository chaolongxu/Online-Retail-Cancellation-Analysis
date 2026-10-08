USE CommercialSalesProject;

SELECT *
FROM online_retail_II;

---------------------------------------------EXPLORING THE VARIABLES-------------------
----DATA TYPE----
--FINDINGS: STOCKCODE AS STRING
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'online_retail_II'
ORDER BY ORDINAL_POSITION;

----Invoice----
--FINDINGS: Invoice with A in the front always has Adjust Bad Debt in description. Most likely unrecoverable payment. 

SELECT *
FROM online_retail_II
WHERE LEN(Invoice) <> 6 AND Invoice NOT LIKE 'C%' ;

--FINDINGS No invoice related to bad debt. Recomendation: remove from table
SELECT *
FROM online_retail_II 
WHERE Invoice LIKE '%563185%' OR Invoice LIKE '%563186%' OR Invoice LIKE '%563187%';


--FINDINGS: Invoice with C in the front always has negative quantity. most likely represent a return

SELECT *
FROM online_retail_II 
WHERE INVOICE LIKE 'c%' ;--AND Quantity> 0

--FINDING: SOME RETURNS INVOICE DO NOT HAVE A MATCHING PURCHASE INVOICE 
SELECT
    r.Invoice AS ReturnInvoice,
    r.Customer_ID,
    r.StockCode,
    r.Quantity AS ReturnQuantity,
    r.InvoiceDate AS ReturnDate,
    p.Invoice AS OriginalInvoice,
    p.Quantity AS OriginalQuantity,
    p.InvoiceDate AS OriginalSaleDate
FROM online_retail_II AS r
LEFT JOIN online_retail_II AS p
    ON  p.Customer_ID = r.Customer_ID
    AND p.StockCode   = r.StockCode
    AND p.Quantity    = ABS(r.Quantity)
    AND p.InvoiceDate <= r.InvoiceDate
WHERE r.Invoice LIKE 'C%'
ORDER BY r.InvoiceDate;


----STOCKCODE ----
-- NO NULL VALUES 
SELECT *
FROM online_retail_II
WHERE StockCode IS NULL;

--3958 DISITNCT STOCK CODES 
SELECT COUNT(DISTINCT UPPER(StockCode))
FROM online_retail_II;

-- D= DISCOUNT/ M= MANUAL (POSSIBLY LABOUR COST)/ S= SAMPLE/  B= Bad Debt/ C2= CARRIAGE
--CRUCK= CRUCK COMMISSION/DOT= DOTCOM POSTAGE /POST= POSTAGE 
SELECT StockCode,Description, COUNT(*) AS ROW_COUNT
FROM online_retail_II
WHERE LEN(StockCode)<5
GROUP BY StockCode,Description;

--CLEANING/CATEGORISING 

SELECT 
CASE 
    WHEN StockCode ='D' THEN 'DISCOUNT'
    WHEN StockCode= 'S' THEN 'SAMPLE'
    WHEN StockCode= 'M' THEN 'LABOUR COST'
    WHEN StockCode= 'C2' THEN 'CARRIAGE'
    WHEN StockCode= 'CRUK' THEN 'OPERATING EXPENSES'
    WHEN StockCode= 'DOT' THEN 'DOTCOM POSTAGE'
    WHEN StockCode= 'POST' THEN 'POSTAGE '
    WHEN INVOICE LIKE 'C%' THEN 'RETURN'
    WHEN Invoice LIKE 'A%' THEN 'BAD DEBT'
    ELSE 'ORDER' 
END AS INVOICE_TYPE
FROM online_retail_II;


----- COUNTRY----
-- UNSPECIFIED COUNTRY,  EIRE= IRELAND RSA= REPUBLIC OF SOUTH AFRICA
SELECT DISTINCT Country
FROM online_retail_II ;

--CLEANING

 SELECT 
    CASE 
        WHEN Country = 'EIRE' THEN 'IRELAND' 
        WHEN Country = 'RSA' THEN 'REPUBLIC OF SOUTH AFRICA' 
        ELSE UPPER(Country)
    END AS CLEAN_COUNTRY
FROM online_retail_II;



----CUSTOMER_ID ----
----4372 DISTINCT CUSTOMERS 
SELECT COUNT(DISTINCT Customer_ID)
FROM online_retail_II;


----PRICE ----
--CLEANING
SELECT CAST(PRICE AS float) AS CLEAN_PRICE
FROM online_retail_II;


--DETECTING DUPLICATE VALUES
WITH DUPLICATES AS (
SELECT
    Invoice,
    StockCode,
    Description,
    InvoiceDate,
    Quantity,
    Price,
    Customer_ID,
    Country,
    COUNT_BIG(*) AS DuplicateCount
FROM online_retail_II
GROUP BY
   Invoice,
    StockCode,
    Description,
    InvoiceDate,
    Quantity,
    Price,
    Customer_ID,
    Country
HAVING COUNT_BIG(*) > 1)

SELECT SUM(DUPLICATECOUNT)
FROM DUPLICATES -- 10149 DUPLICATE LINES IDENTIFIED. 