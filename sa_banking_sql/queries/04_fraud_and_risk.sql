-- ============================================================
-- 04_fraud_and_risk.sql
-- Identifies suspicious transaction patterns using subqueries,
-- window functions and multi-condition CASE logic
-- This is the most impressive script for interviews
-- ============================================================

USE sa_banking;
GO

-- ── Analysis 1: Flagged Transaction Summary ─────────────────
-- Overview of flagged vs normal transactions by category

SELECT
    merchant_category,
    COUNT(transaction_id)                       AS total_transactions,
    SUM(CAST(is_flagged AS INT))                AS flagged_count,
    ROUND(SUM(CAST(is_flagged AS INT)) * 100.0 /
          COUNT(transaction_id), 2)             AS flag_rate_pct,
    ROUND(AVG(CASE WHEN is_flagged = 1
                   THEN amount END), 2)         AS avg_flagged_amount,
    ROUND(AVG(CASE WHEN is_flagged = 0
                   THEN amount END), 2)         AS avg_normal_amount
FROM transactions
GROUP BY merchant_category
ORDER BY flag_rate_pct DESC;
GO


-- ── Analysis 2: High Risk Customers ─────────────────────────
-- Finds customers with unusually high transaction amounts
-- relative to their income band average
-- Uses subquery to calculate band averages

WITH band_averages AS (
    SELECT
        c.income_band,
        ROUND(AVG(t.amount), 2)             AS band_avg_spend
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
    GROUP BY c.income_band
),
customer_spend AS (
    SELECT
        c.customer_id,
        c.first_name + ' ' + c.last_name   AS customer_name,
        c.income_band,
        c.monthly_income,
        COUNT(t.transaction_id)              AS total_txns,
        ROUND(AVG(t.amount), 2)              AS avg_spend,
        SUM(CAST(t.is_flagged AS INT))       AS flagged_count
    FROM customers c
    JOIN transactions t ON c.customer_id = t.customer_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        c.income_band,
        c.monthly_income
)
SELECT
    cs.customer_id,
    cs.customer_name,
    cs.income_band,
    cs.monthly_income,
    cs.avg_spend,
    ba.band_avg_spend,
    cs.flagged_count,
    -- How many times above the band average they spend
    ROUND(cs.avg_spend / NULLIF(ba.band_avg_spend, 0), 2)   AS spend_ratio,
    CASE
        WHEN cs.flagged_count >= 10
         AND cs.avg_spend > ba.band_avg_spend * 2            THEN 'High Risk'
        WHEN cs.flagged_count >= 5
          OR cs.avg_spend > ba.band_avg_spend * 1.5          THEN 'Medium Risk'
        ELSE 'Low Risk'
    END                                                      AS risk_rating
FROM customer_spend cs
JOIN band_averages ba ON cs.income_band = ba.income_band
ORDER BY cs.flagged_count DESC, spend_ratio DESC;
GO


-- ── Analysis 3: Unusual Spending Spikes ─────────────────────
-- Detects days where a customer spent more than 3x
-- their own personal daily average — potential fraud signal
-- Uses window functions to calculate personal averages

WITH daily_spend AS (
    SELECT
        customer_id,
        transaction_date,
        ROUND(SUM(amount), 2)               AS daily_total
    FROM transactions
    GROUP BY customer_id, transaction_date
),
with_personal_avg AS (
    SELECT
        customer_id,
        transaction_date,
        daily_total,
        ROUND(AVG(daily_total) OVER (
            PARTITION BY customer_id
        ), 2)                               AS personal_daily_avg
    FROM daily_spend
)
SELECT
    w.customer_id,
    c.first_name + ' ' + c.last_name       AS customer_name,
    c.province,
    w.transaction_date,
    w.daily_total,
    w.personal_daily_avg,
    ROUND(w.daily_total /
          NULLIF(w.personal_daily_avg, 0), 2) AS spike_ratio,
    CASE
        WHEN w.daily_total > w.personal_daily_avg * 5 THEN 'Extreme Spike'
        WHEN w.daily_total > w.personal_daily_avg * 3 THEN 'High Spike'
        WHEN w.daily_total > w.personal_daily_avg * 2 THEN 'Moderate Spike'
        ELSE 'Normal'
    END                                     AS spike_category
FROM with_personal_avg w
JOIN customers c ON w.customer_id = c.customer_id
WHERE w.daily_total > w.personal_daily_avg * 2
ORDER BY spike_ratio DESC;
GO


-- ── Analysis 4: Channel Risk Analysis ───────────────────────
-- Compares flagged transaction rates across channels
-- Online and Mobile channels typically have higher fraud rates

SELECT
    channel,
    COUNT(transaction_id)                   AS total_transactions,
    SUM(CAST(is_flagged AS INT))            AS flagged_count,
    ROUND(SUM(CAST(is_flagged AS INT)) * 100.0 /
          COUNT(transaction_id), 2)         AS flag_rate_pct,
    ROUND(AVG(amount), 2)                   AS avg_amount,
    ROUND(MAX(amount), 2)                   AS max_amount,
    -- Rank channels by risk
    RANK() OVER (ORDER BY
        SUM(CAST(is_flagged AS INT)) * 100.0 /
        COUNT(transaction_id) DESC)         AS risk_rank
FROM transactions
GROUP BY channel
ORDER BY flag_rate_pct DESC;
GO


-- ── Analysis 5: Dormant Account Activity ────────────────────
-- Finds transactions on accounts marked as Dormant
-- Dormant accounts with transactions is a red flag

SELECT
    t.transaction_id,
    t.account_id,
    a.status                                AS account_status,
    c.first_name + ' ' + c.last_name       AS customer_name,
    c.province,
    t.transaction_date,
    t.amount,
    t.merchant_category,
    t.channel,
    'ALERT: Transaction on dormant account' AS alert_message
FROM transactions t
JOIN accounts a  ON t.account_id  = a.account_id
JOIN customers c ON t.customer_id = c.customer_id
WHERE a.status = 'Dormant'
ORDER BY t.amount DESC;
GO
