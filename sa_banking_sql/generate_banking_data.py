"""
generate_banking_data.py
────────────────────────
Generates realistic South African banking transaction data.
Run this first to create the CSV files, then use the SQL scripts.

Usage:
    python generate_banking_data.py
"""

import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import os

random.seed(42)
np.random.seed(42)

OUTPUT_DIR = "data"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── Config ─────────────────────────────────────────────────────────────────
START_DATE = datetime(2023, 1, 1)
END_DATE   = datetime(2024, 12, 31)

SA_CITIES = [
    "Johannesburg", "Cape Town", "Durban", "Pretoria",
    "Port Elizabeth", "Bloemfontein", "East London", "Nelspruit"
]

PROVINCES = {
    "Johannesburg": "Gauteng",
    "Pretoria":     "Gauteng",
    "Cape Town":    "Western Cape",
    "Durban":       "KwaZulu-Natal",
    "Port Elizabeth": "Eastern Cape",
    "East London":  "Eastern Cape",
    "Bloemfontein": "Free State",
    "Nelspruit":    "Mpumalanga",
}

TRANSACTION_TYPES = [
    "Purchase", "ATM Withdrawal", "EFT Transfer",
    "Debit Order", "Online Purchase", "Refund"
]

MERCHANT_CATEGORIES = [
    "Groceries", "Fuel", "Restaurants", "Clothing",
    "Electronics", "Medical", "Entertainment",
    "Utilities", "Education", "Transport"
]

MERCHANTS = {
    "Groceries":    ["Checkers", "Pick n Pay", "Shoprite", "Woolworths Food", "SPAR"],
    "Fuel":         ["Engen", "BP", "Shell", "Caltex", "Total"],
    "Restaurants":  ["Nando's", "Steers", "KFC", "Wimpy", "Ocean Basket"],
    "Clothing":     ["Edgars", "Truworths", "Mr Price", "Woolworths", "H&M"],
    "Electronics":  ["Game", "Incredible Connection", "iStore", "Takealot", "eXchange"],
    "Medical":      ["Dis-Chem", "Clicks", "Netcare", "Life Healthcare", "Mediclinic"],
    "Entertainment":["Ster-Kinekor", "Nu Metro", "Computicket", "Showmax", "DStv"],
    "Utilities":    ["Eskom", "City Power", "Vodacom", "MTN", "Telkom"],
    "Education":    ["UNISA", "Varsity College", "Boston City Campus", "CTU", "Udemy"],
    "Transport":    ["Uber", "Bolt", "Gautrain", "MyCiTi", "Computicket Bus"],
}

ACCOUNT_TYPES  = ["Cheque", "Savings", "Credit Card", "Business"]
INCOME_BANDS   = ["Low (R0-R10k)", "Middle (R10k-R30k)", "High (R30k+)"]


# ── 1. Customers ────────────────────────────────────────────────────────────
def generate_customers(n=500):
    first_names = [
        "Thabo", "Sipho", "Nomsa", "Zanele", "Lerato", "Kagiso", "Ayanda",
        "Nkosi", "Palesa", "Tebogo", "Lungelo", "Siyanda", "Bontle", "Mpho",
        "Refilwe", "Lwazi", "Ntombi", "Sifiso", "Khanyi", "Bongani",
        "Johan", "Pieter", "Anri", "Marlene", "Francois", "Ruan", "Hannes",
        "Christiaan", "Liezel", "Estelle", "Wayne", "Brendan", "Taryn",
        "Priya", "Kavitha", "Rajan", "Ashwin", "Nisha", "Suren", "Devi"
    ]
    last_names = [
        "Dlamini", "Nkosi", "Mthembu", "Zulu", "Khumalo", "Ndlovu", "Mkhize",
        "Sithole", "Nxumalo", "Cele", "van der Merwe", "Botha", "du Plessis",
        "Pretorius", "Venter", "Nel", "Steyn", "Fourie", "Olivier", "Jacobs",
        "Pillay", "Naidoo", "Reddy", "Govender", "Moodley", "Chetty", "Singh"
    ]

    records = []
    for i in range(1, n + 1):
        city         = random.choice(SA_CITIES)
        income_band  = random.choices(
            INCOME_BANDS, weights=[0.35, 0.45, 0.20]
        )[0]

        if "Low"    in income_band: monthly_income = round(random.uniform(3000, 10000), 2)
        elif "Middle" in income_band: monthly_income = round(random.uniform(10000, 30000), 2)
        else:                        monthly_income = round(random.uniform(30000, 120000), 2)

        records.append({
            "customer_id":    f"CUST{i:05d}",
            "first_name":     random.choice(first_names),
            "last_name":      random.choice(last_names),
            "city":           city,
            "province":       PROVINCES[city],
            "account_type":   random.choice(ACCOUNT_TYPES),
            "income_band":    income_band,
            "monthly_income": monthly_income,
            "join_date":      (START_DATE - timedelta(days=random.randint(30, 1825))).strftime("%Y-%m-%d"),
            "is_active":      random.choices([1, 0], weights=[0.92, 0.08])[0],
        })

    df = pd.DataFrame(records)
    df.to_csv(f"{OUTPUT_DIR}/customers.csv", index=False)
    print(f"  customers.csv       — {len(df):,} rows")
    return df


# ── 2. Accounts ─────────────────────────────────────────────────────────────
def generate_accounts(customers_df):
    records = []
    account_id = 1

    for _, cust in customers_df.iterrows():
        # Everyone has at least 1 account, some have 2
        num_accounts = random.choices([1, 2], weights=[0.70, 0.30])[0]
        for _ in range(num_accounts):
            balance = round(random.uniform(100, 80000), 2)
            records.append({
                "account_id":     f"ACC{account_id:06d}",
                "customer_id":    cust["customer_id"],
                "account_type":   random.choice(ACCOUNT_TYPES),
                "balance":        balance,
                "credit_limit":   round(balance * random.uniform(1.5, 3.0), 2),
                "opened_date":    cust["join_date"],
                "status":         random.choices(
                    ["Active", "Dormant", "Closed"],
                    weights=[0.88, 0.08, 0.04]
                )[0],
            })
            account_id += 1

    df = pd.DataFrame(records)
    df.to_csv(f"{OUTPUT_DIR}/accounts.csv", index=False)
    print(f"  accounts.csv        — {len(df):,} rows")
    return df


# ── 3. Transactions ──────────────────────────────────────────────────────────
def generate_transactions(accounts_df, customers_df):
    active_accounts = accounts_df[accounts_df["status"] == "Active"]["account_id"].tolist()
    cust_income     = customers_df.set_index("customer_id")["monthly_income"].to_dict()
    acc_cust        = accounts_df.set_index("account_id")["customer_id"].to_dict()

    records    = []
    txn_id     = 1
    current    = START_DATE

    while current <= END_DATE:
        # More transactions on weekends and month end
        is_weekend   = current.weekday() >= 5
        is_month_end = current.day >= 25
        base_txns    = random.randint(80, 150)
        if is_weekend:   base_txns = int(base_txns * 1.3)
        if is_month_end: base_txns = int(base_txns * 1.2)

        for _ in range(base_txns):
            account_id = random.choice(active_accounts)
            customer_id = acc_cust[account_id]
            income      = cust_income.get(customer_id, 15000)
            category    = random.choice(MERCHANT_CATEGORIES)
            merchant    = random.choice(MERCHANTS[category])
            txn_type    = random.choice(TRANSACTION_TYPES)

            # Amount based on income band and category
            if category in ["Electronics", "Education"]:
                amount = round(random.uniform(200, min(income * 0.3, 8000)), 2)
            elif category in ["Groceries", "Fuel", "Utilities"]:
                amount = round(random.uniform(50, min(income * 0.1, 2000)), 2)
            else:
                amount = round(random.uniform(30, min(income * 0.15, 3000)), 2)

            # Flag suspicious transactions (large amounts)
            is_flagged = 1 if amount > income * 0.5 else 0

            records.append({
                "transaction_id":   f"TXN{txn_id:08d}",
                "account_id":       account_id,
                "customer_id":      customer_id,
                "transaction_date": current.strftime("%Y-%m-%d"),
                "transaction_type": txn_type,
                "merchant_category": category,
                "merchant_name":    merchant,
                "amount":           amount,
                "is_flagged":       is_flagged,
                "channel":          random.choice(["Branch", "ATM", "Online", "Mobile App"]),
            })
            txn_id += 1

        current += timedelta(days=1)

    df = pd.DataFrame(records)
    df.to_csv(f"{OUTPUT_DIR}/transactions.csv", index=False)
    print(f"  transactions.csv    — {len(df):,} rows")
    return df


# ── Run ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("\nGenerating SA Banking data...\n")
    customers    = generate_customers(500)
    accounts     = generate_accounts(customers)
    transactions = generate_transactions(accounts, customers)
    print(f"\nDone — all files saved to data/")
