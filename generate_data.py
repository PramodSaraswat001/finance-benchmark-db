"""
Institutional Brokerage & Finance (TPC-E) Benchmark Data Generator for PostgreSQL (33 Tables)
Generates CSV files with strict referential integrity into the data/ folder.
Zero external dependencies required (uses standard Python library).
"""

import os
import sys
import csv
import random
from datetime import datetime, timedelta, date

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
os.makedirs(DATA_DIR, exist_ok=True)

random.seed(42)

FIRST_NAMES = [
    "Aarav", "Aditi", "Alexander", "Amit", "Ananya", "Benjamin", "Charlotte",
    "Daniel", "David", "Deepak", "Elena", "Emily", "Ethan", "Fatima", "Grace",
    "Hannah", "Ishaan", "James", "John", "Kavita", "Liam", "Lucas", "Manish",
    "Michael", "Neha", "Noah", "Oliver", "Pooja", "Priya", "Rahul", "Rohan",
    "Sam", "Sarah", "Sneha", "Sophia", "Suresh", "Tanvi", "Vikram", "William", "Zoe"
]

LAST_NAMES = [
    "Agarwal", "Anderson", "Brown", "Chakraborty", "Clark", "Davis", "Deshmukh",
    "Garcia", "Gupta", "Harris", "Iyer", "Johnson", "Joshi", "Kapoor", "Khan",
    "Kumar", "Martin", "Mehta", "Miller", "Nair", "Patel", "Pillai", "Rao",
    "Reddy", "Robinson", "Rodriguez", "Sharma", "Singh", "Smith", "Taylor",
    "Thomas", "Varma", "Walker", "White", "Williams", "Wilson"
]

def random_date(start_days_ago=730, end_days_ago=0):
    start = datetime.now() - timedelta(days=start_days_ago)
    delta_days = start_days_ago - end_days_ago
    random_days = random.randint(0, max(0, delta_days))
    random_seconds = random.randint(0, 86400)
    return (start + timedelta(days=random_days, seconds=random_seconds)).strftime("%Y-%m-%d %H:%M:%S+00")

def random_date_only(start_days_ago=730, end_days_ago=0):
    start = date.today() - timedelta(days=start_days_ago)
    delta_days = start_days_ago - end_days_ago
    random_days = random.randint(0, max(0, delta_days))
    return (start + timedelta(days=random_days)).isoformat()

def write_csv(filepath, headers, rows):
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
    print(f"  [+] Wrote {len(rows):,} rows -> {os.path.basename(filepath)}")

def generate(scale=1.0):
    print(f"--- Generating Finance / TPC-E Brokerage Data with Scale {scale} ---")

    # 1. status_type
    status_types = [
        ["ACTV", "Active"],
        ["CANC", "Canceled"],
        ["CMPL", "Completed"],
        ["SBMT", "Submitted"]
    ]
    write_csv(os.path.join(DATA_DIR, "status_type.csv"), ["st_id", "st_name"], status_types)

    # 2. taxrate
    taxrates = [[f"TX{i:02d}", f"Tax Tier {i+1}", round(random.uniform(0.05, 0.35), 4)] for i in range(20)]
    write_csv(os.path.join(DATA_DIR, "taxrate.csv"), ["tx_id", "tx_name", "tx_rate"], taxrates)

    # 3. zip_code & 4. address
    zip_codes = []
    zip_code_list = []
    for i in range(1000):
        zc = f"{10000 + i}"
        zip_code_list.append(zc)
        zip_codes.append([zc, f"Metropolis {i % 50}", f"State {i % 20}"])
    write_csv(os.path.join(DATA_DIR, "zip_code.csv"), ["zc_code", "zc_town", "zc_div"], zip_codes)

    addresses = [[i + 1, f"{random.randint(100, 9999)} Financial Way", f"Suite {random.randint(10, 500)}", random.choice(zip_code_list), "USA"] for i in range(5000)]
    write_csv(os.path.join(DATA_DIR, "address.csv"), ["ad_id", "ad_line1", "ad_line2", "ad_zc_code", "ad_ctry"], addresses)

    # 5. sector & 6. industry
    sectors = [
        ["TEC", "Technology"], ["FIN", "Financials"], ["HLT", "Healthcare"],
        ["ENG", "Energy"], ["IND", "Industrials"], ["CNS", "Consumer Discretionary"],
        ["STP", "Consumer Staples"], ["COM", "Communication Services"],
        ["MAT", "Materials"], ["UTL", "Utilities"], ["REA", "Real Estate"], ["GOV", "Government/Municipal"]
    ]
    write_csv(os.path.join(DATA_DIR, "sector.csv"), ["sc_id", "sc_name"], sectors)

    industries = [[f"I{i:02d}", f"Industry Subsector {i+1}", sectors[i % len(sectors)][0]] for i in range(50)]
    write_csv(os.path.join(DATA_DIR, "industry.csv"), ["in_id", "in_name", "in_sc_id"], industries)
    ind_ids = [ind[0] for ind in industries]

    # 7. company & 8. company_competitor
    companies = []
    co_ids = []
    ratings = ["AAA", "AA+", "AA", "A+", "A", "BBB+", "BBB", "BB", "B"]
    for i in range(500):
        co_id = i + 1
        co_ids.append(co_id)
        companies.append([co_id, "ACTV", f"Global Enterprise Asset {co_id}", random.choice(ind_ids), random.choice(ratings), random_date_only(3000, 1000), random.randint(1, 5000)])
    write_csv(os.path.join(DATA_DIR, "company.csv"), ["co_id", "co_st_id", "co_name", "co_in_id", "co_sp_rate", "co_open_date", "co_ad_id"], companies)

    competitors = []
    for co_id in co_ids:
        for _ in range(3):
            comp_id = random.choice(co_ids)
            if comp_id != co_id:
                competitors.append([co_id, comp_id, random.choice(ind_ids)])
    competitors = list({(r[0], r[1]): r for r in competitors}.values())
    write_csv(os.path.join(DATA_DIR, "company_competitor.csv"), ["cp_co_id", "cp_comp_co_id", "cp_in_id"], competitors)

    # 9. exchange
    exchanges = [
        ["NYSE", "New York Stock Exchange", 1, 930, 1600],
        ["NASDAQ", "Nasdaq Global Select Market", 2, 930, 1600],
        ["LSE", "London Stock Exchange", 3, 800, 1630],
        ["NSE", "National Stock Exchange of India", 4, 915, 1530],
        ["JPX", "Tokyo Stock Exchange", 5, 900, 1500],
        ["XETRA", "Frankfurt Stock Exchange", 6, 900, 1730],
        ["HKEX", "Hong Kong Stock Exchange", 7, 930, 1600],
        ["SIX", "SIX Swiss Exchange", 8, 900, 1730],
        ["ASX", "Australian Securities Exchange", 9, 1000, 1600],
        ["TSX", "Toronto Stock Exchange", 10, 930, 1600]
    ]
    write_csv(os.path.join(DATA_DIR, "exchange.csv"), ["ex_id", "ex_name", "ex_ad_id", "ex_open", "ex_close"], exchanges)
    ex_ids = [e[0] for e in exchanges]

    # 10. security
    securities = []
    symbs = []
    for i in range(1000):
        symb = f"SEC{i+1000}"
        symbs.append(symb)
        co_id = random.choice(co_ids)
        pe = round(random.uniform(8.0, 65.0), 2)
        high52 = round(random.uniform(50, 450), 4)
        low52 = round(high52 * random.uniform(0.5, 0.85), 4)
        div = round(random.uniform(0.0, 8.5), 4)
        securities.append([symb, "COMMON", "ACTV", f"Security Instrument {symb}", random.choice(ex_ids), co_id, random.randint(10000000, 500000000), random_date_only(2000, 500), "", pe, high52, low52, div])
    write_csv(os.path.join(DATA_DIR, "security.csv"), ["s_symb", "s_issue", "s_st_id", "s_name", "s_ex_id", "s_co_id", "s_num_out", "s_start_date", "s_end_date", "s_pe", "s_52wk_high", "s_52wk_low", "s_dividend"], securities)

    # 11. daily_market
    daily_market = []
    for i in range(10000):
        s = random.choice(symbs)
        d = random_date_only(365, 0)
        c = round(random.uniform(20.0, 500.0), 4)
        daily_market.append([d, s, c, round(c * 1.03, 4), round(c * 0.97, 4), random.randint(10000, 5000000)])
    daily_market = list({(r[0], r[1]): r for r in daily_market}.values())
    write_csv(os.path.join(DATA_DIR, "daily_market.csv"), ["dm_date", "dm_s_symb", "dm_close", "dm_high", "dm_low", "dm_vol"], daily_market)

    # 12. financial
    financials = []
    for co_id in co_ids:
        for year in [2022, 2023]:
            for qtr in [1, 2, 3, 4]:
                rev = round(random.uniform(10000000, 500000000), 2)
                earn = round(rev * random.uniform(0.08, 0.28), 2)
                eps = round(earn / random.randint(5000000, 20000000), 4)
                financials.append([co_id, year, qtr, f"{year}-{(qtr-1)*3 + 1:02d}-01", rev, earn, eps, eps, round(earn/rev, 4)])
    write_csv(os.path.join(DATA_DIR, "financial.csv"), ["fi_co_id", "fi_year", "fi_qtr", "fi_qtr_start_date", "fi_revenue", "fi_net_earn", "fi_basic_eps", "fi_dilut_eps", "fi_margin"], financials)

    # 13. last_trade
    last_trades = []
    for s in symbs:
        p = round(random.uniform(20.0, 500.0), 4)
        last_trades.append([s, random_date(1, 0), p, round(p * random.uniform(0.98, 1.02), 4), random.randint(50000, 2000000)])
    write_csv(os.path.join(DATA_DIR, "last_trade.csv"), ["lt_s_symb", "lt_dts", "lt_price", "lt_open_price", "lt_vol"], last_trades)

    # 14. news_item & 15. news_xref
    news_items = [[i + 1, f"Market Alert: Strong Q{random.randint(1,4)} Earnings Beat", "Corporate earnings filings exceed Wall Street consensus forecasts.", random_date(180, 0), "Reuters", "Financial Staff"] for i in range(2000)]
    write_csv(os.path.join(DATA_DIR, "news_item.csv"), ["ni_id", "ni_headline", "ni_summary", "ni_dts", "ni_source", "ni_author"], news_items)

    news_xrefs = list({(random.randint(1, 2000), random.choice(co_ids)): [random.randint(1, 2000), random.choice(co_ids)] for _ in range(4000)}.values())
    write_csv(os.path.join(DATA_DIR, "news_xref.csv"), ["nx_ni_id", "nx_co_id"], news_xrefs)

    # 16. broker & 17. trade_type & 18. charge & 19. commission_rate
    brokers = []
    b_ids = []
    for i in range(200):
        b_id = i + 1
        b_ids.append(b_id)
        trades_cnt = random.randint(50, 1500)
        comm = round(trades_cnt * random.uniform(15.0, 35.0), 2)
        brokers.append([b_id, "ACTV", f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}", trades_cnt, comm])
    write_csv(os.path.join(DATA_DIR, "broker.csv"), ["b_id", "b_st_id", "b_name", "b_num_trades", "b_comm_total"], brokers)

    trade_types = [
        ["TMB", "Market Buy", "False", "True"],
        ["TMS", "Market Sell", "True", "True"],
        ["TLB", "Limit Buy", "False", "False"],
        ["TLS", "Limit Sell", "True", "False"]
    ]
    write_csv(os.path.join(DATA_DIR, "trade_type.csv"), ["tt_id", "tt_name", "tt_is_sell", "tt_is_mrkt"], trade_types)
    tt_ids = [t[0] for t in trade_types]

    charges = [[tier, tt, round(random.uniform(5.0, 25.0), 2)] for tier in [1, 2, 3] for tt in tt_ids]
    write_csv(os.path.join(DATA_DIR, "charge.csv"), ["ch_c_tier", "ch_tt_id", "ch_chrg"], charges)

    comm_rates = [[tier, tt, ex, 0, 1000, round(random.uniform(0.001, 0.005), 4)] for tier in [1, 2, 3] for tt in tt_ids for ex in ex_ids[:5]]
    write_csv(os.path.join(DATA_DIR, "commission_rate.csv"), ["cr_c_tier", "cr_tt_id", "cr_ex_id", "cr_from_qty", "cr_to_qty", "cr_rate"], comm_rates)

    # 20. customer & 21. customer_account
    customers = []
    c_ids = []
    for i in range(5000):
        c_id = i + 1
        c_ids.append(c_id)
        fn = random.choice(FIRST_NAMES)
        ln = random.choice(LAST_NAMES)
        tier = random.choices([1, 2, 3], weights=[0.6, 0.3, 0.1])[0]
        customers.append([c_id, "ACTV", ln, fn, "", "M" if i%2==0 else "F", tier, random_date_only(20000, 8000), random.randint(1, 5000), "001", "555", f"{random.randint(1000000, 9999999)}", f"{fn.lower()}.{ln.lower()}{i}@investor.com", ""])
    write_csv(os.path.join(DATA_DIR, "customer.csv"), ["c_id", "c_st_id", "c_l_name", "c_f_name", "c_m_name", "c_gndr", "c_tier", "c_dob", "c_ad_id", "c_ctry_1", "c_area_1", "c_local_1", "c_email_1", "c_email_2"], customers)

    accounts = []
    ca_ids = []
    for i in range(7500):
        ca_id = i + 1
        ca_ids.append(ca_id)
        bal = round(random.uniform(5000, 1500000), 2)
        accounts.append([ca_id, random.choice(b_ids), random.choice(c_ids), f"Brokerage Account {ca_id}", random.randint(0, 2), bal])
    write_csv(os.path.join(DATA_DIR, "customer_account.csv"), ["ca_id", "ca_b_id", "ca_c_id", "ca_name", "ca_tax_st", "ca_bal"], accounts)

    # 22. account_permission & 23. customer_taxrate & 24. watch_list & 25. watch_item
    acct_perms = [[ca_id, "0011", f"TAX{ca_id:06d}", "AuthUser", "Owner"] for ca_id in ca_ids]
    write_csv(os.path.join(DATA_DIR, "account_permission.csv"), ["ap_ca_id", "ap_acl", "ap_tax_id", "ap_l_name", "ap_f_name"], acct_perms)

    cust_taxrates = [[f"TX{random.randint(0, 19):02d}", c_id] for c_id in c_ids]
    write_csv(os.path.join(DATA_DIR, "customer_taxrate.csv"), ["cx_tx_id", "cx_c_id"], cust_taxrates)

    watch_lists = [[i + 1, random.choice(c_ids)] for i in range(5000)]
    write_csv(os.path.join(DATA_DIR, "watch_list.csv"), ["wl_id", "wl_c_id"], watch_lists)

    watch_items = list({(wl_id, random.choice(symbs)): [wl_id, random.choice(symbs)] for wl_id in range(1, 5001) for _ in range(2)}.values())
    write_csv(os.path.join(DATA_DIR, "watch_item.csv"), ["wi_wl_id", "wi_s_symb"], watch_items)

    # 26. trade_request & 27. trade
    trade_requests = [[i + 1, random.choice(tt_ids), random.choice(symbs), random.randint(10, 500) * 10, round(random.uniform(25.0, 450.0), 4), random.choice(ca_ids), random.choice(b_ids), random_date(180, 0)] for i in range(10000)]
    write_csv(os.path.join(DATA_DIR, "trade_request.csv"), ["tr_t_id", "tr_tt_id", "tr_s_symb", "tr_qty", "tr_bid_price", "tr_ca_id", "tr_b_id", "tr_dts"], trade_requests)

    trades = []
    t_ids = []
    for i in range(10000):
        t_id = i + 1
        t_ids.append(t_id)
        qty = random.randint(10, 1000)
        bid = round(random.uniform(20.0, 500.0), 4)
        t_price = round(bid * random.uniform(0.99, 1.01), 4)
        chrg = round(random.uniform(2.0, 15.0), 2)
        comm = round(qty * t_price * 0.001, 2)
        tax = round(comm * 0.18, 2)
        trades.append([t_id, random_date(180, 0), "CMPL", random.choice(tt_ids), "True" if i%2==0 else "False", random.choice(symbs), qty, bid, random.choice(ca_ids), t_price, chrg, comm, tax, "False"])
    write_csv(os.path.join(DATA_DIR, "trade.csv"), ["t_id", "t_dts", "t_st_id", "t_tt_id", "t_is_cash", "t_s_symb", "t_qty", "t_bid_price", "t_ca_id", "t_trade_price", "t_chrg", "t_comm", "t_tax", "t_lifo"], trades)

    # 28. trade_history & 29. settlement & 30. cash_transaction
    trade_history = []
    for t_id in t_ids:
        trade_history.append([t_id, random_date(180, 5), "SBMT"])
        trade_history.append([t_id, random_date(4, 0), "CMPL"])
    write_csv(os.path.join(DATA_DIR, "trade_history.csv"), ["th_t_id", "th_dts", "th_st_id"], trade_history[:15000])

    settlements = [[t_id, "Cash Account Deposit", random_date_only(60, 0), round(random.uniform(500, 50000), 2)] for t_id in t_ids]
    cash_transactions = [[t_id, random_date(60, 0), round(random.uniform(500, 50000), 2), "Securities Trade Settlement"] for t_id in t_ids]
    write_csv(os.path.join(DATA_DIR, "settlement.csv"), ["se_t_id", "se_cash_type", "se_cash_due_date", "se_amt"], settlements)
    write_csv(os.path.join(DATA_DIR, "cash_transaction.csv"), ["ct_t_id", "ct_dts", "ct_amt", "ct_name"], cash_transactions)

    # 31. holding & 32. holding_history & 33. holding_summary
    holdings = [[t_id, random.choice(ca_ids), random.choice(symbs), random_date(90, 0), round(random.uniform(20.0, 500.0), 4), random.randint(10, 500)] for t_id in t_ids]
    write_csv(os.path.join(DATA_DIR, "holding.csv"), ["h_t_id", "h_ca_id", "h_s_symb", "h_dts", "h_price", "h_qty"], holdings)

    holding_hist = []
    for _ in range(10000):
        t1, t2 = random.choice(t_ids), random.choice(t_ids)
        if t1 != t2:
            holding_hist.append([t1, t2, random.randint(50, 200), random.randint(0, 150)])
    holding_hist = list({(r[0], r[1]): r for r in holding_hist}.values())
    write_csv(os.path.join(DATA_DIR, "holding_history.csv"), ["hh_h_t_id", "hh_t_id", "hh_before_qty", "hh_after_qty"], holding_hist)

    holding_summary = list({(random.choice(ca_ids), random.choice(symbs)): [random.choice(ca_ids), random.choice(symbs), random.randint(50, 2000)] for _ in range(10000)}.values())
    write_csv(os.path.join(DATA_DIR, "holding_summary.csv"), ["hs_ca_id", "hs_s_symb", "hs_qty"], holding_summary)

    print("=== Finance / TPC-E Benchmark Data Generation Finished ===")

if __name__ == "__main__":
    s = 1.0
    if len(sys.argv) > 1:
        try:
            s = float(sys.argv[1])
        except ValueError:
            pass
    generate(s)
