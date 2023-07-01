--- Cleaninf the data

--Total Records = 541909
-- Records without customer ID = 135080
-- Records with customer ID = 406829
WITH online_retail AS (
SELECT [InvoiceNo]
      ,[StockCode]
      ,[Description]
      ,[Quantity]
      ,[InvoiceDate]
      ,[UnitPrice]
      ,[CustomerID]
      ,[Country]
  FROM [Online_Retail].[dbo].[online_retail]
  WHERE  CustomerID != 0
),

--Records with quantity and unit price = 397882
vw_online_retail AS (
SELECT * FROM online_retail
WHERE Quantity > 0
AND UnitPrice > 0
),
--Checking for duplicates

dup_check AS (
SELECT *,
	   ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY InvoiceDate) dup_flag
FROM vw_online_retail
)
-- Number of records duplicated = 5.215
-- Number of records after cleaning the data = 392.667
SELECT * 
INTO #online_retail_main
FROM dup_check
WHERE dup_flag = 1


--- Clean Dataset for Cohort Analysis
SELECT * FROM #online_retail_main

--Unique Identifier (CustomerID)
--Initial Start Date (First Invoice Date)
--Revenue Data

SELECT 
	CustomerID,
	MIN(InvoiceDate) first_purchase_date,
	DATEFROMPARTS(YEAR(MIN(InvoiceDate)),MONTH(MIN(InvoiceDate)),1) Cohort_Date
INTO #cohort
FROM #online_retail_main
GROUP BY CustomerID

SELECT * FROM #cohort

-- Creating the cohort index (integer representation of the number of months that has passed since customers first engagement)
SELECT 
	ftb.*,
	(year_diff * 12 + month_diff +1) cohort_index
INTO #cohort_retention
FROM (
	SELECT 
		fc.*,
		(invoice_year - cohort_year) year_diff,
		(invoice_month - cohort_month) month_diff
	FROM (
		SELECT 
			m.*,
			c.Cohort_Date,
			YEAR(m.InvoiceDate) invoice_year,
			MONTH(m.InvoiceDate) invoice_month,
			YEAR(c.Cohort_Date) cohort_year,
			MONTH(c.Cohort_Date) cohort_month
		FROM #online_retail_main m 
		LEFT JOIN #cohort c 
			ON m.CustomerID = c.CustomerID
		) fc
	) ftb

--Pivoting data to see the Cohort Tabel
SELECT * 
INTO #cohort_pivot
FROM(
	SELECT DISTINCT
		CustomerID,
		Cohort_Date,
		cohort_index
	FROM #cohort_retention
) tbl
PIVOT(
	COUNT(CustomerId)
	FOR Cohort_Index IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])
	) AS pivot_table

SELECT 
	Cohort_Date, 
	1.0 * [1]/[1] * 100 AS [1],
	1.0 * [2]/[1] * 100 AS [2],
	1.0 * [3]/[1] * 100 AS [3],
	1.0 * [4]/[1] * 100 AS [4],
	1.0 * [5]/[1] * 100 AS [5],
	1.0 * [6]/[1] * 100 AS [6],
	1.0 * [7]/[1] * 100 AS [7],
	1.0 * [8]/[1] * 100 AS [8],
	1.0 * [9]/[1] * 100 AS [9],
	1.0 * [10]/[1] * 100 AS [10],
	1.0 * [11]/[1] * 100 AS [11],
	1.0 * [12]/[1] * 100 AS [12],
	1.0 * [13]/[1] * 100 AS [13]
FROM #cohort_pivot
ORDER BY Cohort_Date ASC
