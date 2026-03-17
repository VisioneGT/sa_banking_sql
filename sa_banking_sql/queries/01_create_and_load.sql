-- ============================================================
-- 01_create_and_load.sql
-- SA Banking Analysis — Database Setup
-- Run this first in SSMS
-- ============================================================

-- Create database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'sa_banking')
    CREATE DATABASE sa_banking;
GO

USE sa_banking;
GO

-- ── Drop tables if they exist (for re-runs) ──────────────────
IF OBJECT_ID('transactions', 'U') IS NOT NULL DROP TABLE transactions;
IF OBJECT_ID('accounts',     'U') IS NOT NULL DROP TABLE accounts;
IF OBJECT_ID('customers',    'U') IS NOT NULL DROP TABLE customers;
GO

-- ── Create customers table ───────────────────────────────────
CREATE TABLE customers (
    customer_id     NVARCHAR(10)   PRIMARY KEY,
    first_name      NVARCHAR(50)   NOT NULL,
    last_name       NVARCHAR(50)   NOT NULL,
    city            NVARCHAR(50),
    province        NVARCHAR(50),
    account_type    NVARCHAR(20),
    income_band     NVARCHAR(30),
    monthly_income  DECIMAL(12,2),
    join_date       DATE,
    is_active       BIT            DEFAULT 1
);
GO

-- ── Create accounts table ────────────────────────────────────
CREATE TABLE accounts (
    account_id      NVARCHAR(10)   PRIMARY KEY,
    customer_id     NVARCHAR(10)   NOT NULL REFERENCES customers(customer_id),
    account_type    NVARCHAR(20),
    balance         DECIMAL(12,2),
    credit_limit    DECIMAL(12,2),
    opened_date     DATE,
    status          NVARCHAR(20)
);
GO

-- ── Create transactions table ────────────────────────────────
CREATE TABLE transactions (
    transaction_id      NVARCHAR(12)   PRIMARY KEY,
    account_id          NVARCHAR(10)   NOT NULL REFERENCES accounts(account_id),
    customer_id         NVARCHAR(10)   NOT NULL REFERENCES customers(customer_id),
    transaction_date    DATE           NOT NULL,
    transaction_type    NVARCHAR(30),
    merchant_category   NVARCHAR(50),
    merchant_name       NVARCHAR(100),
    amount              DECIMAL(12,2),
    is_flagged          BIT            DEFAULT 0,
    channel             NVARCHAR(20)
);
GO

-- ── Load data from CSV files ─────────────────────────────────
-- UPDATE THESE PATHS to where you saved the CSV files

BULK INSERT customers
FROM 'C:\YOUR_PATH\sa_banking_sql\data\customers.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
GO

BULK INSERT accounts
FROM 'C:\YOUR_PATH\sa_banking_sql\data\accounts.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
GO

BULK INSERT transactions
FROM 'C:\YOUR_PATH\sa_banking_sql\data\transactions.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    TABLOCK
);
GO

-- ── Verify row counts ────────────────────────────────────────
SELECT 'customers'    AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'accounts',                   COUNT(*)              FROM accounts
UNION ALL
SELECT 'transactions',               COUNT(*)              FROM transactions;
GO
