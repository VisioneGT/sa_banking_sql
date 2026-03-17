-- ============================================================
-- 02_customer_segmentation.sql
-- Segments customers by spending behaviour using window
-- functions, CTEs, and CASE statements
-- ============================================================

USE sa_banking;
GO

-- ── Analysis 1: Customer Lifetime Value by Income Band ──────
-- Shows average spend, transaction count and total revenue
-- per income segment using GROUP BY and aggregations

SELECT
    c.income_band,
    COUNT(DISTINCT c.customer_id)           AS total_customers,
    COUNT(t.transaction_id)                  AS total_transactions,
    ROUND(AVG(t.amount), 2)                  AS avg_transaction_amount,
    ROUND(SUM(t.amount), 2)                  AS total_spend,
    ROUND(SUM(t.amount) / COUNT(DISTINCT
          c.customer_id), 2)                 AS spend_per_customer
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.income_band
ORDER BY spend_per_customer DESC;
GO


-- ── Analysis 2: Top Spending Customers with Ranking ─────────
-- Uses window function RANK() to rank customers by total spend
-- Shows top 20 customers with their rank and province

WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name       AS customer_name,
        c.province,
        c.income_band,
        COUNT(t.transaction_id)                  AS total_transactions,
        ROUND(SUM(t.amount), 2)                  AS total_spend,
        ROUND(AVG(t.amount), 2)                  AS avg_spend
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.province,
        c.income_band
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_spend DESC)              AS spend_rank,
        RANK() OVER (PARTITION BY province
                     ORDER BY total_spend DESC)              AS province_rank
    FROM customer_spend
)
SELECT TOP 20
    spend_rank,
    customer_name,
    province,
    income_band,
    total_transactions,
    total_spend,
    avg_spend,
    province_rank
FROM ranked
ORDER BY spend_rank;
GO


-- ── Analysis 3: Customer Spend Segmentation ─────────────────
-- Classifies customers into spend tiers using CASE
-- and subquery to calculate thresholds

WITH customer_totals AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name   AS customer_name,
        c.province,
        c.income_band,
        ROUND(SUM(t.amount), 2)             AS total_spend
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.province,
        c.income_band
),
thresholds AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP
            (ORDER BY total_spend) OVER ()  AS p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP
            (ORDER BY total_spend) OVER ()  AS p75
    FROM customer_totals
)
SELECT DISTINCT
    ct.customer_id,
    ct.customer_name,
    ct.province,
    ct.income_band,
    ct.total_spend,
    CASE
        WHEN ct.total_spend >= t.p75 THEN 'High Value'
        WHEN ct.total_spend >= t.p25 THEN 'Mid Value'
        ELSE 'Low Value'
    END                                     AS spend_segment
FROM customer_totals ct
CROSS JOIN (SELECT DISTINCT p25, p75 FROM thresholds) t
ORDER BY ct.total_spend DESC;
GO


-- ── Analysis 4: Province Performance Summary ────────────────
-- Compares provinces by total spend, avg spend, and
-- transaction volume — useful for regional strategy

SELECT
    c.province,
    COUNT(DISTINCT c.customer_id)           AS unique_customers,
    COUNT(t.transaction_id)                  AS total_transactions,
    ROUND(SUM(t.amount), 2)                  AS total_spend,
    ROUND(AVG(t.amount), 2)                  AS avg_transaction,
    ROUND(SUM(t.amount) /
          COUNT(DISTINCT c.customer_id), 2)  AS revenue_per_customer,
    -- % of total national spend
    ROUND(SUM(t.amount) * 100.0 /
          SUM(SUM(t.amount)) OVER (), 2)     AS pct_of_national_spend
FROM customers c
JOIN transactions t ON c.customer_id = t.customer_id
GROUP BY c.province
ORDER BY total_spend DESC;
GO
