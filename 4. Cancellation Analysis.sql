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


--CANCELLATION ANALYSIS

-- Overall cancellation value as a percentage of gross sales. 7% OF SALES ARE CANCELLED 
SELECT
    SUM(GROSSSALES) AS GROSSSALES,
    SUM(CANCELLATIONAMOUNT) AS CANCELLATION_VALUE,
     SUM(CANCELLATIONAMOUNT)/ SUM(GROSSSALES)*100 AS PERCENTAGE_CANCELLED
FROM #Cleaned
WHERE TransactionSubType IN ('Sale', 'Cancellation')


-- Average Customer Cancellation-to-Sales Value Ratio. 3.36%
WITH CustomerCounts AS (
    SELECT
        CustomerID,
        SUM(CASE WHEN TransactionSubType = 'Sale' THEN GrossSales ELSE 0 END) AS GrossSales,
        SUM(CASE WHEN TransactionSubType = 'Cancellation' THEN CancellationAmount ELSE 0 END) AS CancellationAmount
    FROM #Cleaned
    WHERE CustomerID <> 'Unknown'
    GROUP BY CustomerID
)
SELECT
    CAST(
        AVG(100.0 * CancellationAmount / NULLIF(GrossSales, 0))
        AS decimal(10, 2)
    ) AS AverageCustomerCancellationRatePct
FROM CustomerCounts;

-- Top 10 Customers by Total Cancellation Value
SELECT TOP (10)
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS  CancellationInvoices,
    CAST(SUM(CancellationAmount) AS decimal(18, 2)) AS TotalCancellationValue
FROM #Cleaned
WHERE CustomerID <> 'Unknown'
  AND TransactionSubType IN ('Sale', 'Cancellation')
  AND CancellationAmount > 0
GROUP BY CustomerID
ORDER BY TotalCancellationValue DESC;


--High-Value Customers with Elevated Cancellation Ratios.
WITH CustomerTotals AS
(
    SELECT
        CustomerID,
        SUM(CASE
                WHEN TransactionSubType = 'Sale'
                THEN 1 ELSE 0
            END) AS SalesLines,

        SUM(CASE
                WHEN TransactionSubType = 'Cancellation'
                THEN 1 ELSE 0
            END) AS CancellationLines,

        SUM(CASE
                WHEN TransactionSubType = 'Sale'
                THEN NetSales ELSE 0
            END) AS SalesValue,

        SUM(CASE
                WHEN TransactionSubType = 'Cancellation'
                THEN ABS(NetSales) ELSE 0
            END) AS CancellationValue
    FROM #cleaned
    WHERE CustomerID <> 'Unknown'
    GROUP BY CustomerID
),
CustomerMetrics AS
(
    SELECT
        *,
        100.0 * CancellationValue
            / NULLIF(SalesValue, 0) AS CancellationValueRatePct
    FROM CustomerTotals
)
SELECT
    CustomerID,
    SalesValue,
    CancellationValue,
    SalesLines,
    CancellationLines,
    CAST(CancellationValueRatePct AS decimal(10, 2))
        AS CancellationValueRatePct
FROM CustomerMetrics
WHERE SalesLines > 50
  AND SalesValue > 10000
  AND CancellationValueRatePct > 3.36 -- AVERAGE CUSOTMER CANCELLATION FROM PREVIOUS QUERY
ORDER BY CustomerMetrics.CancellationValueRatePct DESC;

-- Identify potential sale–cancellation matches and unmatched lines
-- for customer 15482 using product code, quantity and unit price.
WITH Sales AS
(
    SELECT *
    FROM #Cleaned
    WHERE TransactionSubType = 'Sale'
      AND CustomerID = '15482'
),
Cancellations AS
(
    SELECT *
    FROM #Cleaned
    WHERE TransactionSubType = 'Cancellation'
      AND CustomerID = '15482'
)
SELECT
    COALESCE(s.CustomerID, c.CustomerID) AS CustomerID,
    COALESCE(s.StockCode, c.StockCode) AS StockCode,
    COALESCE(s.ProductDescription, c.ProductDescription)
        AS ProductDescription,

    s.InvoiceNo AS SalesInvoice,
    s.Quantity AS SalesQuantity,
    s.UnitPrice AS SalesUnitPrice,

    c.InvoiceNo AS CancellationInvoice,
    c.Quantity AS CancellationQuantity,
    c.UnitPrice AS CancellationUnitPrice,

    CASE
        WHEN s.TransactionSubType IS NULL
            THEN 'Cancellation without match'
        WHEN c.TransactionSubType IS NULL
            THEN 'Sale without match'
        ELSE 'Potential match'
    END AS MatchStatus
FROM Sales AS s
FULL OUTER JOIN Cancellations AS c
    ON s.CustomerID = c.CustomerID
   AND s.StockCode = c.StockCode
   AND s.Quantity = -c.Quantity
   AND s.UnitPrice = c.UnitPrice
ORDER BY
    COALESCE(s.StockCode, c.StockCode),
    s.InvoiceNo,
    c.InvoiceNo;
