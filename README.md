# Institutional Brokerage & Finance (TPC-E) Benchmark Database for PostgreSQL

A realistic, production-grade **33-table financial trading, investment banking, and brokerage database** modeled directly after the industry-standard **TPC-E specification**. Designed to benchmark, stress-test, and evaluate AI Data Analyst, Text-to-SQL, and LLM Agent tools on PostgreSQL.

---

## 🎯 Why This Exists
Capital markets, wealth management, and investment banking databases are among the most difficult schemas for AI agents:
1. They require strict financial data types (`NUMERIC`, avoiding floating-point imprecision).
2. They feature multi-table entity hops across customers, brokers, securities, exchanges, and trades.
3. They involve temporal queries (daily market prices, corporate quarterly filings, trade settlement dates).

This repository provides an enterprise TPC-E normalized schema pre-populated with **~160,000 realistic records** (5,000–15,000 records per core transactional table) with strict referential integrity.

---

## 🗂️ Database Schema Overview (33 Tables)

```
                  ┌─────────────────┐
                  │    CUSTOMER     │
                  └────────┬────────┘
                           │
       ┌───────────────────┼───────────────────┐
       ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│CUSTOMER_ACCT │    │  WATCH_LIST  │    │  TAX_RATES   │
└──────┬───────┘    └──────┬───────┘    └──────────────┘
       │                   │
       ▼                   ▼
┌──────────────┐    ┌──────────────┐
│   HOLDINGS   │    │  WATCH_ITEM  │
└──────┬───────┘    └──────────────┘
       │
       ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    TRADE     │◄───┤    BROKER    │    │   SECURITY   │
└──────┬───────┘    └──────────────┘    └──────┬───────┘
       │                                       │
       ├──────────────┬──────────────┐         │
       ▼              ▼              ▼         ▼
┌──────────────┐┌──────────────┐┌──────────┐┌──────────┐
│ TRADE_HISTORY││  SETTLEMENT  ││ CASH_TXN ││FINANCIALS│
└──────────────┘└──────────────┘└──────────┘└──────────┘
```

### Table Breakdown by Functional Set

| Set | Table | Purpose | Row Count |
| :--- | :--- | :--- | :--- |
| **Dimension & Reference** | `status_type` | Status lookup codes (ACTV, CMPL, CANC, SBMT) | 4 |
| | `taxrate` | Regional tax rates | 20 |
| | `zip_code` | Postal code geographic mappings | 1,000 |
| | `address` | Normalized address registry | **5,000** |
| **Market & Securities** | `sector` | Broad sectors (Technology, Financials, etc.) | 12 |
| | `industry` | Granular industries linked to sectors | 50 |
| | `company` | Listed public and private corporations | 500 |
| | `company_competitor` | Competitor relationships between companies | 1,500 |
| | `exchange` | Stock exchanges (NYSE, NASDAQ, LSE, NSE, etc.)| 10 |
| | `security` | Tradable financial securities (P/E, 52W H/L) | 1,000 |
| | `daily_market` | Historical daily OHLCV trading bars | **10,000** |
| | `financial` | Corporate quarterly financials (Revenue, EPS) | 4,000 |
| | `last_trade` | Real-time last traded price snapshots | 1,000 |
| | `news_item` | Financial market headlines and news feeds | 2,000 |
| | `news_xref` | Association between news stories and companies | 4,000 |
| **Broker Infrastructure** | `broker` | Financial brokers, trade volumes & commissions | 200 |
| | `trade_type` | Order types (Market Buy/Sell, Limit Buy/Sell) | 4 |
| | `charge` | Transaction fees across customer tiers | 12 |
| | `commission_rate` | Tiered commission rate structures | 60 |
| **Customer & Portfolio** | `customer` | Investors, tier levels, risk profiles | **5,000** |
| | `customer_account` | Brokerage trading accounts and cash balances | **7,500** |
| | `account_permission`| Authorized trading agent permissions | **7,500** |
| | `customer_taxrate` | Tax brackets applied to customer portfolios | **5,000** |
| | `watch_list` | Investor watchlists | **5,000** |
| | `watch_item` | Securities tracked in investor watchlists | **10,000** |
| **Trading & Orders** | `trade_request` | Limit and market order booking requests | **10,000** |
| | `trade` | Executed trades (Price, Quantity, Fees, Taxes) | **10,000** |
| | `trade_history` | Audit trail of trade state transitions | **15,000** |
| | `settlement` | Trade settlement records (T+1/T+2 cash) | **10,000** |
| | `cash_transaction` | Inflow/outflow of cash corresponding to trades | **10,000** |
| **Holdings & Positions** | `holding` | Portfolio security positions acquired by trade | **10,000** |
| | `holding_history` | Historical changes in position quantities | **10,000** |
| | `holding_summary` | Aggregate net holdings per customer account | **10,000** |

---

## 🚀 Quickstart Guide

### 1. Create Database in PostgreSQL
```bash
psql -U postgres -c "CREATE DATABASE finance_benchmark;"
```

### 2. Initialize Schema
```bash
psql -U postgres -d finance_benchmark -f schema.sql
```

### 3. Bulk Load Seed Data
The `data/` folder contains pre-generated CSV files for all 33 tables:
```bash
psql -U postgres -d finance_benchmark -f load_data.sql
```

### 4. (Optional) Re-generate or Scale Data
To re-generate or scale to higher row counts (e.g., $2\times$ volume):
```bash
python generate_data.py 2.0
```

---

## 🧪 Benchmark Evaluation Queries for AI Agents

Test your Text-to-SQL or AI agent with these realistic capital markets analytical queries:

1. **5-Table Join Across Trading & Sector Taxonomies:**
   > *"Find the top 3 brokers by total commission earned from trades executed in the Technology sector over the past quarter."*
   > *Tests:* `broker` $\rightarrow$ `trade` $\rightarrow$ `security` $\rightarrow$ `company` $\rightarrow$ `industry` $\rightarrow$ `sector`

2. **Portfolio Valuation & Liquidity Check:**
   > *"List all customer accounts where the current portfolio market value exceeds \$500,000 and calculate their net available cash balance."*
   > *Tests:* `customer_account` $\rightarrow$ `holding` $\rightarrow$ `last_trade` with aggregations

3. **Insider / News Sentiment Trading Event Correlation:**
   > *"Identify customers who traded a security within 24 hours of a related news item being published for that company."*
   > *Tests:* Date-range join across `trade` + `security` + `company` + `news_xref` + `news_item`
