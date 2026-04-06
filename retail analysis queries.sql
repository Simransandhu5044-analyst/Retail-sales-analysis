


SELECT
  Description AS ProductName,
  ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
  SUM(Quantity) AS TotalQuantitySold
FROM "Online Retail"
WHERE Quantity > 0 AND UnitPrice > 0 AND Description IS NOT NULL
GROUP BY Description
ORDER BY TotalRevenue DESC
LIMIT 10;


SELECT
  ROUND(SUM(TopRevenue), 2) AS Top10ProductRevenue,
  (SELECT ROUND(SUM(Quantity * UnitPrice), 2)
   FROM "Online Retail"
   WHERE Quantity > 0 AND UnitPrice > 0) AS TotalRevenue,
  ROUND(100.0 * SUM(TopRevenue) /
   (SELECT SUM(Quantity * UnitPrice)
    FROM "Online Retail"
    WHERE Quantity > 0 AND UnitPrice > 0), 2) AS PercentageOfTotal
FROM (
  SELECT SUM(Quantity * UnitPrice) AS TopRevenue
  FROM "Online Retail"
  WHERE Quantity > 0 AND UnitPrice > 0 AND Description IS NOT NULL
  GROUP BY Description
  ORDER BY TopRevenue DESC
  LIMIT 10
);


SELECT
  Country,
  ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
  COUNT(DISTINCT InvoiceNo) AS NumberOfOrders
FROM "Online Retail"
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
GROUP BY Country
ORDER BY TotalRevenue DESC
LIMIT 10;


SELECT
  CustomerID,
  ROUND(SUM(Quantity * UnitPrice), 2) AS TotalSpent,
  COUNT(DISTINCT InvoiceNo) AS NumberOfOrders,
  ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo), 2) AS AvgOrderValue
FROM "Online Retail"
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY TotalSpent DESC
LIMIT 15;


WITH MonthlyRevenue AS (
  SELECT
    SUBSTR(InvoiceDate, 7, 4) AS Year,
    SUBSTR(InvoiceDate, 4, 2) AS Month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS Revenue
  FROM "Online Retail"
  WHERE Quantity > 0 AND UnitPrice > 0
  GROUP BY Year, Month
)
SELECT
  Year,
  Month,
  Revenue,
  LAG(Revenue) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue,
  ROUND(Revenue - LAG(Revenue) OVER (ORDER BY Year, Month), 2) AS MonthlyChange
FROM MonthlyRevenue
ORDER BY Year, Month;


SELECT
  Description AS ProductName,
  ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
  COUNT(DISTINCT InvoiceNo) AS NumberOfSales,
  SUM(Quantity) AS TotalQuantitySold
FROM "Online Retail"
WHERE Quantity > 0 AND UnitPrice > 0 AND Description IS NOT NULL
GROUP BY Description
ORDER BY TotalRevenue ASC
LIMIT 15;


SELECT
  CASE
    WHEN PurchaseCount = 1 THEN 'One-time Buyer'
    WHEN PurchaseCount BETWEEN 2 AND 5 THEN 'Occasional Buyer'
    ELSE 'Loyal Customer'
  END AS CustomerType,
  COUNT(CustomerID) AS NumberOfCustomers,
  ROUND(AVG(TotalSpent), 2) AS AvgSpendingPerCustomer
FROM (
  SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS PurchaseCount,
    SUM(Quantity * UnitPrice) AS TotalSpent
  FROM "Online Retail"
  WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
  GROUP BY CustomerID
)
GROUP BY CustomerType;


SELECT
  CustomerID,
  ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
  RANK() OVER (ORDER BY SUM(Quantity * UnitPrice) DESC) AS RevenueRank
FROM "Online Retail"
WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
GROUP BY CustomerID
LIMIT 15;

WITH CustomerSummary AS (
  SELECT
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders,
    ROUND(SUM(Quantity * UnitPrice), 2) AS CustomerRevenue
  FROM "Online Retail"
  WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
  GROUP BY CustomerID, Country
),
CountrySummary AS (
  SELECT
    Country,
    ROUND(SUM(Quantity * UnitPrice), 2) AS CountryRevenue,
    COUNT(DISTINCT CustomerID) AS TotalCustomers
  FROM "Online Retail"
  WHERE Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
  GROUP BY Country
)
SELECT
  cs.CustomerID,
  cs.Country,
  cs.TotalOrders,
  cs.CustomerRevenue,
  ct.CountryRevenue,
  ct.TotalCustomers,
  ROUND(100.0 * cs.CustomerRevenue / ct.CountryRevenue, 2) AS CustomerShareOfCountryRevenue
FROM CustomerSummary cs
JOIN CountrySummary ct ON cs.Country = ct.Country
WHERE cs.TotalOrders = 1
ORDER BY cs.CustomerRevenue DESC
LIMIT 20;


SELECT
  COUNT(*) AS TotalRows,
  COUNT(CustomerID) AS RowsWithCustomerID,
  COUNT(*) - COUNT(CustomerID) AS MissingCustomerIDs,
  SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS NegativeQuantityRows,
  SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS ZeroPriceRows,
  ROUND(100.0 * COUNT(CustomerID) / COUNT(*), 2) AS DataCompletenessRate
FROM "Online Retail";


SELECT
  Description AS ProductName,
  ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
  SUM(Quantity) AS TotalUnitsSold,
  ROUND(AVG(UnitPrice), 2) AS AvgUnitPrice,
  ROUND(SUM(Quantity * UnitPrice) / SUM(Quantity), 2) AS RevenuePerUnit
FROM "Online Retail"
WHERE Quantity > 0 AND UnitPrice > 0 AND Description IS NOT NULL
GROUP BY Description
HAVING SUM(Quantity) > 100
ORDER BY RevenuePerUnit ASC
LIMIT 15;


WITH ProductMetrics AS (
  SELECT
    Description AS ProductName,
    SUM(Quantity) AS TotalVolume,
    ROUND(SUM(Quantity * UnitPrice), 2) AS TotalRevenue,
    ROUND(SUM(Quantity * UnitPrice) / SUM(Quantity), 2) AS RevenuePerUnit,
    ROUND(100.0 * SUM(Quantity * UnitPrice) /
      SUM(SUM(Quantity * UnitPrice)) OVER (), 2) AS RevenueShare
  FROM "Online Retail"
  WHERE Quantity > 0 AND UnitPrice > 0 AND Description IS NOT NULL
  GROUP BY Description
)
SELECT
  ProductName,
  TotalVolume,
  TotalRevenue,
  RevenuePerUnit,
  RevenueShare,
  CASE
    WHEN RevenueShare > 1.0 AND RevenuePerUnit < 1.50 THEN 'Priority Renegotiation'
    WHEN RevenueShare > 0.5 AND RevenuePerUnit < 1.00 THEN 'Cost Review Needed'
    WHEN TotalVolume > 5000 AND RevenuePerUnit < 0.80 THEN 'Volume Discount Opportunity'
    ELSE 'Monitor'
  END AS CommercialAction
FROM ProductMetrics
ORDER BY TotalRevenue DESC
LIMIT 20;



WITH MonthlyProductRevenue AS (
  SELECT
    SUBSTR(InvoiceDate, 7, 4) AS Year,
    SUBSTR(InvoiceDate, 4, 2) AS Month,
    Description AS ProductName,
    ROUND(AVG(UnitPrice), 2) AS AvgMonthlyPrice
  FROM "Online Retail"
  WHERE Quantity > 0 AND UnitPrice > 0 AND Description IS NOT NULL
  GROUP BY Year, Month, Description
),
PriceMovement AS (
  SELECT
    ProductName,
    Month,
    AvgMonthlyPrice,
    LAG(AvgMonthlyPrice) OVER (PARTITION BY ProductName ORDER BY Year, Month) AS PrevMonthPrice,
    ROUND(AvgMonthlyPrice - LAG(AvgMonthlyPrice)
      OVER (PARTITION BY ProductName ORDER BY Year, Month), 2) AS PriceChange
  FROM MonthlyProductRevenue
)
SELECT
  ProductName,
  Month,
  AvgMonthlyPrice,
  PrevMonthPrice,
  PriceChange,
  CASE
    WHEN PriceChange > 0.60 THEN 'Cost Inflation Risk'
    WHEN PriceChange < -0.60 THEN 'Deflationary Opportunity'
    ELSE 'Stable'
  END AS PriceFlag
FROM PriceMovement
WHERE PriceChange IS NOT NULL AND ABS(PriceChange) > 0.60
ORDER BY ABS(PriceChange) DESC
LIMIT 20;
