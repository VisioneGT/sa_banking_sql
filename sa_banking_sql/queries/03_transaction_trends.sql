-- ============================================================
-- 03_transaction_trends.sql
-- Analyses spending trends over time using window functions,
-- rolling averages, and month-over-month comparisons
-- ============================================================

USE sa_banking;
GO

-- ── Analysis 1: Monthly Revenue Trend ───────────────────────
-- Shows total spend per month with month-over-month growth
-- Uses LAG() window function to compare to previous month

WITH monthly_totals AS (
    SELECT
        YEAR(transaction_date)                  AS txn_year,
        MONTH(transaction_date)                 AS txn_month,
        DATENAME(MONTH, transaction_date)       AS month_name,
        COUNT(transaction_id)                    AS total_transactions,
        ROUND(SUM(amount), 2)                    AS total_spend,
        ROUND(AVG(amount), 2)                    AS avg_transaction
    FROM transactions
    GROUP BY
        YEAR(transaction_date),
        MONTH(transaction_date),
        DATENAME(MONTH, transaction_date)
)
SELECT
    txn_year,
    month_name,
    total_transactions,
    total_spend,
    avg_transaction,
    -- Previous month spend using LAG
    LAG(total_spend) OVER (ORDER BY txn_year, txn_month)    AS prev_month_spend,
    -- Month over month growth %
    ROUND(
        (total_spend - LAG(total_spend) OVER
            (ORDER BY txn_year, txn_month))
        / NULLIF(LAG(total_spend) OVER
            (ORDER BY txn_year, txn_month), 0) * 100
    , 2)                                                     AS mom_growth_pct
FROM monthly_totals
ORDER BY txn_year, txn_month;
GO


-- ── Analysis 2: 3-Month Rolling Average Spend ───────────────
-- Smooths out monthly volatility using a rolling average
-- Uses AVG() as window function with ROWS BETWEEN

WITH monthly AS (
    SELECT
        YEAR(transaction_date)              AS txn_year,
        MONTH(transaction_date)             AS txn_month,
        DATENAME(MONTH, transaction_date)   AS month_name,
        ROUND(SUM(amount), 2)               AS total_spend
    FROM transactions
    GROUP BY
        YEAR(transaction_date),
        MONTH(transaction_date),
        DATENAME(MONTH, transaction_date)
)
SELECT
    txn_year,
    month_name,
    total_spend,
    ROUND(AVG(total_spend) OVER (
        ORDER BY txn_year, txn_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                   AS rolling_3mo_avg
FROM monthly
ORDER BY txn_year, txn_month;
GO


-- ── Analysis 3: Spending by Day of Week ─────────────────────
-- Identifies which days of the week have highest spend
-- useful for staffing and marketing decisions

SELECT
    DATENAME(WEEKDAY, transaction_date)     AS day_of_week,
    DATEPART(WEEKDAY, transaction_date)     AS day_number,
    COUNT(transaction_id)                    AS total_transactions,
    ROUND(SUM(amount), 2)                    AS total_spend,
    ROUND(AVG(amount), 2)                    AS avg_spend,
    -- % of weekly total
    ROUND(SUM(amount) * 100.0 /
          SUM(SUM(amount)) OVER (), 2)       AS pct_of_weekly_spend
FROM transactions
GROUP BY
    DATENAME(WEEKDAY, transaction_date),
    DATEPART(WEEKDAY, transaction_date)
ORDER BY day_number;
GO


-- ── Analysis 4: Category Spend Trend (2023 vs 2024) ─────────
-- Compares merchant category spend between years
-- Uses PIVOT-style CASE aggregation

SELECT
    merchant_category,
    ROUND(SUM(CASE WHEN YEAR(transaction_date) = 2023
                   THEN amount ELSE 0 END), 2)  AS spend_2023,
    ROUND(SUM(CASE WHEN YEAR(transaction_date) = 2024
                   THEN amount ELSE 0 END), 2)  AS spend_2024,
    -- Year over year growth
    ROUND(
        (SUM(CASE WHEN YEAR(transaction_date) = 2024 THEN amount ELSE 0 END) -
         SUM(CASE WHEN YEAR(transaction_date) = 2023 THEN amount ELSE 0 END))
        / NULLIF(SUM(CASE WHEN YEAR(transaction_date) = 2023
                          THEN amount ELSE 0 END), 0) * 100
    , 2)                                         AS yoy_growth_pct
FROM transactions
GROUP BY merchant_category
ORDER BY spend_2024 DESC;
GO


-- ── Analysis 5: Running Total of Spend Per Customer ─────────
-- Shows cumulative spend per customer over time
-- Uses SUM() as running total window function

SELECT TOP 500
    customer_id,
    transaction_date,
    amount,
    merchant_category,
    ROUND(SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                       AS running_total_spend
FROM transactions
WHERE customer_id = 'CUST00001'
ORDER BY transaction_date;
GO
