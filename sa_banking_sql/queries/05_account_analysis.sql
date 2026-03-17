-- ============================================================
-- 05_account_analysis.sql
-- Account performance, balance distribution, and
-- cross-sell opportunity identification
-- ============================================================

USE sa_banking;
GO

-- ── Analysis 1: Account Balance Distribution ────────────────
-- Segments accounts into balance tiers using CASE
-- and calculates % share of total bank deposits

WITH balance_tiers AS (
    SELECT
        account_id,
        account_type,
        balance,
        CASE
            WHEN balance >= 50000 THEN 'R50k+'
            WHEN balance >= 20000 THEN 'R20k-R50k'
            WHEN balance >= 5000  THEN 'R5k-R20k'
            WHEN balance >= 1000  THEN 'R1k-R5k'
            ELSE 'Under R1k'
        END                             AS balance_tier
    FROM accounts
    WHERE status = 'Active'
)
SELECT
    balance_tier,
    account_type,
    COUNT(*)                            AS account_count,
    ROUND(SUM(balance), 2)              AS total_deposits,
    ROUND(AVG(balance), 2)              AS avg_balance,
    -- % of total deposits this tier holds
    ROUND(SUM(balance) * 100.0 /
          SUM(SUM(balance)) OVER (), 2) AS pct_of_deposits
FROM balance_tiers
GROUP BY balance_tier, account_type
ORDER BY
    CASE balance_tier
        WHEN 'R50k+'      THEN 1
        WHEN 'R20k-R50k'  THEN 2
        WHEN 'R5k-R20k'   THEN 3
        WHEN 'R1k-R5k'    THEN 4
        ELSE 5
    END,
    account_type;
GO


-- ── Analysis 2: Most Valuable Merchant Categories ───────────
-- Ranks merchant categories by total transaction value
-- and shows month-over-month trend for each

WITH category_monthly AS (
    SELECT
        merchant_category,
        YEAR(transaction_date)              AS txn_year,
        MONTH(transaction_date)             AS txn_month,
        ROUND(SUM(amount), 2)               AS monthly_spend
    FROM transactions
    GROUP BY
        merchant_category,
        YEAR(transaction_date),
        MONTH(transaction_date)
),
with_growth AS (
    SELECT
        merchant_category,
        txn_year,
        txn_month,
        monthly_spend,
        LAG(monthly_spend) OVER (
            PARTITION BY merchant_category
            ORDER BY txn_year, txn_month
        )                                   AS prev_month_spend
    FROM category_monthly
)
SELECT
    merchant_category,
    txn_year,
    txn_month,
    monthly_spend,
    prev_month_spend,
    ROUND(
        (monthly_spend - prev_month_spend)
        / NULLIF(prev_month_spend, 0) * 100
    , 2)                                    AS mom_growth_pct,
    -- Running rank of category within each month
    RANK() OVER (
        PARTITION BY txn_year, txn_month
        ORDER BY monthly_spend DESC
    )                                       AS monthly_rank
FROM with_growth
ORDER BY txn_year, txn_month, monthly_rank;
GO


-- ── Analysis 3: Customer Cross-Sell Opportunities ───────────
-- Finds active customers with only 1 account
-- who are high spenders — prime targets for additional products

WITH customer_accounts AS (
    SELECT
        customer_id,
        COUNT(account_id)                   AS num_accounts,
        SUM(balance)                        AS total_balance
    FROM accounts
    WHERE status = 'Active'
    GROUP BY customer_id
),
customer_spend AS (
    SELECT
        customer_id,
        COUNT(transaction_id)               AS total_txns,
        ROUND(SUM(amount), 2)               AS total_spend,
        ROUND(AVG(amount), 2)               AS avg_spend
    FROM transactions
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.first_name + ' ' + c.last_name       AS customer_name,
    c.income_band,
    c.province,
    ca.num_accounts,
    ca.total_balance,
    cs.total_spend,
    cs.avg_spend,
    CASE
        WHEN c.income_band = 'High (R30k+)'
         AND ca.num_accounts = 1            THEN 'Priority Cross-Sell'
        WHEN c.income_band = 'Middle (R10k-R30k)'
         AND ca.num_accounts = 1            THEN 'Standard Cross-Sell'
        ELSE 'Not Targeted'
    END                                     AS cross_sell_segment
FROM customers c
JOIN customer_accounts ca ON c.customer_id = ca.customer_id
JOIN customer_spend    cs ON c.customer_id = cs.customer_id
WHERE ca.num_accounts = 1
  AND c.is_active = 1
ORDER BY
    CASE cross_sell_segment
        WHEN 'Priority Cross-Sell' THEN 1
        WHEN 'Standard Cross-Sell' THEN 2
        ELSE 3
    END,
    cs.total_spend DESC;
GO


-- ── Analysis 4: Channel Usage by Province ───────────────────
-- Shows which channels each province uses most
-- Useful for digital adoption strategy

SELECT
    c.province,
    t.channel,
    COUNT(t.transaction_id)                 AS transaction_count,
    ROUND(SUM(t.amount), 2)                 AS total_spend,
    -- % of transactions in that province on this channel
    ROUND(COUNT(t.transaction_id) * 100.0 /
          SUM(COUNT(t.transaction_id)) OVER
              (PARTITION BY c.province), 2) AS pct_of_province_txns,
    -- Rank channels within each province
    RANK() OVER (
        PARTITION BY c.province
        ORDER BY COUNT(t.transaction_id) DESC
    )                                       AS channel_rank
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.province, t.channel
ORDER BY c.province, channel_rank;
GO
