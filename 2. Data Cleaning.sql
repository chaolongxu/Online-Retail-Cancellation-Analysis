USE CommercialSalesProject;

--CLEANED TABLE
WITH PreCleaning AS
(
    SELECT
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
    CAST(InvoiceDate AS date) AS TransactionDate, -- IDENTIFY DATE WITHOUT TIME
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
 
FROM PreCleaning)

SELECT *
FROM Cleaned
