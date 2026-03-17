# 🏦 SA Banking Transaction Analysis

A pure SQL analysis project using **SQL Server** to analyse South African banking transaction patterns, customer segmentation, fraud detection, and account performance across 500 customers and 80,000+ transactions.

---

## 📊 What This Project Analyses

| Script | Focus | Key Techniques |
|---|---|---|
| `02_customer_segmentation.sql` | Customer value and spend tiers | CTEs, RANK(), PERCENTILE_CONT, GROUP BY |
| `03_transaction_trends.sql` | Monthly trends and growth | LAG(), rolling averages, CASE pivots |
| `04_fraud_and_risk.sql` | Suspicious transaction detection | Subqueries, spike detection, risk scoring |
| `05_account_analysis.sql` | Account performance and cross-sell | Window functions, balance tiers, opportunity scoring |

---

## 🗄️ Database Schema

```
customers (500 rows)
    customer_id PK
    first_name, last_name
    city, province
    income_band
    monthly_income
    join_date, is_active

accounts (650 rows)
    account_id PK
    customer_id FK → customers
    account_type
    balance, credit_limit
    status (Active/Dormant/Closed)

transactions (80,000+ rows)
    transaction_id PK
    account_id FK → accounts
    customer_id FK → customers
    transaction_date
    transaction_type
    merchant_category
    merchant_name
    amount
    is_flagged
    channel
```

---

## ⚙️ Setup Instructions

### Step 1: Generate the data
```bash
python generate_banking_data.py
```
This creates 3 CSV files in `data/`:
- `customers.csv` — 500 SA customers
- `accounts.csv` — ~650 bank accounts
- `transactions.csv` — 80,000+ transactions

### Step 2: Open SSMS and run the setup script
1. Open **SQL Server Management Studio**
2. Connect to your local SQL Server instance
3. Open `queries/01_create_and_load.sql`
4. **Update the file paths** on the BULK INSERT lines to match where you saved the CSVs
5. Run the script — it creates the database, tables, and loads all data

### Step 3: Run the analysis scripts
Run each script in order in SSMS:
- `02_customer_segmentation.sql`
- `03_transaction_trends.sql`
- `04_fraud_and_risk.sql`
- `05_account_analysis.sql`

---

## 🔍 Key Findings

**Customer Segmentation:**
- High income customers (R30k+) account for ~20% of customers but ~45% of total spend
- Gauteng and Western Cape dominate transaction volume

**Transaction Trends:**
- Month-end (25th–31st) sees 20% higher transaction volume — driven by salary payments and debit orders
- Groceries and Utilities are the most consistent categories year over year

**Fraud & Risk:**
- Online and Mobile App channels have the highest flag rates
- A small number of customers show extreme spending spikes (5x+ their personal average)
- Dormant accounts with recent transactions are flagged for investigation

**Account Analysis:**
- Over 60% of deposits are held by accounts with R20k+ balances
- ~30% of high-income customers have only 1 account — strong cross-sell opportunity

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Python + pandas | Data generation |
| SQL Server | Database |
| SSMS | Query execution and results |
| Git / GitHub | Version control |

---

## 📄 CV Bullet Points

```
SA Banking Transaction Analysis | SQL Server, Python, SSMS | 2026

• Designed and queried a 3-table relational database with 80,000+
  banking transactions using SQL Server, covering customers,
  accounts, and transactions.

• Built customer segmentation queries using CTEs, RANK() window
  functions, and PERCENTILE_CONT to classify customers into value
  tiers and identify cross-sell opportunities.

• Developed fraud detection logic using subqueries and window
  functions to flag customers with spending spikes 3x above their
  personal daily average and identify suspicious dormant account
  activity.

• Performed month-over-month trend analysis using LAG() and rolling
  3-month averages to identify seasonal spending patterns across
  10 merchant categories.
```

---

## 📬 Contact

**Fayaaz Vally** — fayaazvally786@gmail.com — [GitHub](https://github.com/VisioneGT)
