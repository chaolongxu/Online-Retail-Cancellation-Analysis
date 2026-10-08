USE CommercialSalesProject;

--This Online Retail II data set contains all the transactions occurring for a UK-based and registered, 
--non-store online retail between 01/12/2009 and 09/12/2011.The company mainly sells unique all-occasion gift-ware.
--Many customers of the company are wholesalers.




--CLEANED TABLE

WITH PreCleaning AS
(
    SELECT DISTINCT -- 5269 DUPLICATE LINES REMOVED 
        UPPER(LTRIM(RTRIM(CAST(Invoice AS varchar(20))))) AS InvoiceNo,
        UPPER(LTRIM(RTRIM(CAST(StockCode AS varchar(30))))) AS StockCode,
        NULLIF(LTRIM(RTRIM(Description)), '') AS ProductDescription,
        TRY_CONVERT(int, Quantity) AS Quantity,
        TRY_CONVERT(datetime2(0), InvoiceDate) AS InvoiceDate,
        TRY_CONVERT(decimal(18, 2), Price) AS UnitPrice,
        TRY_CONVERT(int, [Customer_ID]) AS CustomerID,
        UPPER(LTRIM(RTRIM(Country))) AS Country
    FROM dbo.online_retail_II

), -- Prepares the raw retail data for analysis by standardising text, trimming spaces, converting data types, and marking invalid or blank values as NULL.

Cleaned AS (
SELECT
    InvoiceNo,
    StockCode,
    ProductDescription,
    Quantity,
    InvoiceDate,
    CAST(InvoiceDate AS date) AS TransactionDate, -- EXTRACT DATE WITHOUT TIME
    UnitPrice,
    COALESCE(CAST(CustomerID AS varchar(20)), 'Unknown') AS CustomerID, -- CONVERT NULL CUSTOMERS TO 'UNKNOWN'
    CASE
            WHEN Country = 'EIRE' THEN 'IRELAND'
            WHEN Country = 'RSA'  THEN 'REPUBLIC OF SOUTH AFRICA'
            ELSE UPPER(TRIM(Country)) -- REPLACE ABBREVIATIONS FOR FULL COUNTRY NAME
        END AS Country,

        CASE 
    WHEN StockCode ='D' THEN 'Discount'
    WHEN StockCode= 'S' THEN 'Sample'
    WHEN StockCode= 'M' THEN 'Labour cost'
    WHEN StockCode= 'C2' THEN 'Carriage'
    WHEN StockCode= 'CRUK' THEN 'Operating expenses'
    WHEN StockCode= 'DOT' THEN 'Dotcom postage'
    WHEN StockCode= 'POST' THEN 'Postage '
    WHEN InvoiceNo LIKE 'C%' THEN 'Cancellation'
    WHEN InvoiceNo LIKE 'A%' THEN 'Bad debt'
    ELSE 'Sale' 
END AS TransactionSubType, -- IDENTIFY TRANSACTION SUB TYPE

    CAST(Quantity * UnitPrice AS decimal(18, 2)) AS LineAmount,-- LINE AMOUNT VALUE REGARDLESS OF TRANSACTION TYPE

    CAST(
        CASE
            WHEN Quantity > 0
             AND InvoiceNo NOT LIKE 'C%'
            THEN Quantity * UnitPrice
            ELSE 0
        END AS decimal(18, 2)
    ) AS GrossSales, -- GROSS SALES

    CAST(
        CASE
            WHEN Quantity < 0 OR InvoiceNo LIKE 'C%'
            THEN ABS(Quantity * UnitPrice)
            ELSE 0
        END AS decimal(18, 2)
    ) AS CancellationAmount, -- CANCELLATION AMOUNT AS POSITIVE VALUE

    CAST(Quantity * UnitPrice AS decimal(18, 2)) AS NetSales -- NET SALES
 
FROM PreCleaning
)

SELECT *
INTO #Cleaned
FROM Cleaned; -- TEMPORARY TABLE 




--SALES ANALYSIS

-- Net sales and customer # kpi
SELECT
    ROUND(
        SUM(
            CASE
                WHEN TransactionSubType IN ('Sale', 'Cancellation')
                THEN Quantity * UnitPrice
                ELSE 0
            END
        ),
        2
    ) AS NetSales,

    COUNT(
        DISTINCT CASE
            WHEN TransactionSubType IN ('Sale', 'Cancellation')
            THEN CustomerID
        END
    ) AS TotalCustomers,

        COUNT(
        DISTINCT CASE
            WHEN TransactionSubType IN ('Sale', 'Cancellation')
            THEN StockCode
        END
    ) AS TotalProducts

FROM #Cleaned;

-- Revenue by Month &  % change from previous preriod. TRANSACTIONS WITH NULL DATES ARE EXCLUDED. 
WITH MonthlyRevenue AS (
    SELECT
        DATEFROMPARTS(YEAR(TransactionDate), MONTH(TransactionDate), 1) AS MonthStart,
        SUM(NetSales) AS NetRevenue
    FROM #Cleaned
    WHERE TransactionDate IS NOT NULL
      AND TransactionSubType IN ('Sale', 'Cancellation')
    GROUP BY DATEFROMPARTS(YEAR(TransactionDate), MONTH(TransactionDate), 1)
),
PreviousRevenue AS (
    SELECT
        MonthStart,
        NetRevenue,
        LAG(NetRevenue) OVER (ORDER BY MonthStart) AS PreviousMonthRevenue
    FROM MonthlyRevenue
)
SELECT
    MonthStart,
    NetRevenue,
    PreviousMonthRevenue,
CAST(
    100.0 * (NetRevenue - PreviousMonthRevenue)
    / NULLIF(PreviousMonthRevenue, 0)
    AS decimal(18, 2)
) AS RevenueChangePct
FROM PreviousRevenue
ORDER BY MonthStart;

-- Revenue by Country.TRANSACTIONS WITH NULL COUNTRY ARE EXCLUDED
SELECT
    Country,
    SUM(NetSales) AS NetRevenue
FROM #Cleaned
WHERE Country IS NOT NULL
  AND TransactionSubType IN ('Sale', 'Cancellation')
GROUP BY Country
ORDER BY NetRevenue DESC;

--TOP 10 Products by revenue.TRANSACTIONS WITH NULL PRODUCTDESCRIPTION ARE EXCLUDED
SELECT TOP 10
    ProductDescription,
    SUM(NetSales) AS NetRevenue
FROM #Cleaned
WHERE ProductDescription IS NOT NULL
  AND TransactionSubType IN ('Sale', 'Cancellation')
GROUP BY ProductDescription
ORDER BY NetRevenue DESC ;

-- TOP 5 CUSTOMERS BY NET REVENUE
SELECT TOP (5)
    CustomerID,
    CAST(SUM(NetSales) AS decimal(18, 2)) AS NetRevenue
FROM  #Cleaned
WHERE CustomerID <> 'Unknown'
  AND TransactionSubType IN ('Sale', 'Cancellation')
GROUP BY CustomerID
ORDER BY NetRevenue DESC;





