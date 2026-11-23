-- ============================================================================
-- INSTITUTIONAL BROKERAGE & WEALTH MANAGEMENT DATABASE SCHEMA (PostgreSQL)
-- Modeled after the Industry Standard TPC-E Specification
-- Total Tables: 33
-- Modules: Dimension/Reference, Market & Securities, Broker & Trading, Customer & Portfolio
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Clean drop for idempotency
DROP TABLE IF EXISTS holding_summary CASCADE;
DROP TABLE IF EXISTS holding_history CASCADE;
DROP TABLE IF EXISTS holding CASCADE;
DROP TABLE IF EXISTS cash_transaction CASCADE;
DROP TABLE IF EXISTS settlement CASCADE;
DROP TABLE IF EXISTS trade_history CASCADE;
DROP TABLE IF EXISTS trade CASCADE;
DROP TABLE IF EXISTS trade_request CASCADE;
DROP TABLE IF EXISTS watch_item CASCADE;
DROP TABLE IF EXISTS watch_list CASCADE;
DROP TABLE IF EXISTS customer_taxrate CASCADE;
DROP TABLE IF EXISTS account_permission CASCADE;
DROP TABLE IF EXISTS customer_account CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS trade_type CASCADE;
DROP TABLE IF EXISTS commission_rate CASCADE;
DROP TABLE IF EXISTS charge CASCADE;
DROP TABLE IF EXISTS broker CASCADE;
DROP TABLE IF EXISTS news_xref CASCADE;
DROP TABLE IF EXISTS news_item CASCADE;
DROP TABLE IF EXISTS last_trade CASCADE;
DROP TABLE IF EXISTS financial CASCADE;
DROP TABLE IF EXISTS daily_market CASCADE;
DROP TABLE IF EXISTS security CASCADE;
DROP TABLE IF EXISTS exchange CASCADE;
DROP TABLE IF EXISTS company_competitor CASCADE;
DROP TABLE IF EXISTS company CASCADE;
DROP TABLE IF EXISTS industry CASCADE;
DROP TABLE IF EXISTS sector CASCADE;
DROP TABLE IF EXISTS address CASCADE;
DROP TABLE IF EXISTS zip_code CASCADE;
DROP TABLE IF EXISTS taxrate CASCADE;
DROP TABLE IF EXISTS status_type CASCADE;

-- ============================================================================
-- 1. DIMENSION & REFERENCE TABLES
-- ============================================================================

CREATE TABLE status_type (
    st_id VARCHAR(4) PRIMARY KEY, -- 'ACTV', 'CANC', 'CMPL', 'SBMT'
    st_name VARCHAR(25) NOT NULL
);

CREATE TABLE taxrate (
    tx_id VARCHAR(4) PRIMARY KEY,
    tx_name VARCHAR(50) NOT NULL,
    tx_rate NUMERIC(6, 4) NOT NULL CHECK (tx_rate >= 0)
);

CREATE TABLE zip_code (
    zc_code VARCHAR(12) PRIMARY KEY,
    zc_town VARCHAR(80) NOT NULL,
    zc_div VARCHAR(80) NOT NULL -- State / Province
);

CREATE TABLE address (
    ad_id BIGSERIAL PRIMARY KEY,
    ad_line1 VARCHAR(100) NOT NULL,
    ad_line2 VARCHAR(100),
    ad_zc_code VARCHAR(12) NOT NULL REFERENCES zip_code(zc_code),
    ad_ctry VARCHAR(80) NOT NULL
);

-- ============================================================================
-- 2. MARKET, INDUSTRY & SECURITIES (Reference & Dimensions)
-- ============================================================================

CREATE TABLE sector (
    sc_id VARCHAR(3) PRIMARY KEY,
    sc_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE industry (
    in_id VARCHAR(3) PRIMARY KEY,
    in_name VARCHAR(60) UNIQUE NOT NULL,
    in_sc_id VARCHAR(3) NOT NULL REFERENCES sector(sc_id)
);

CREATE TABLE company (
    co_id BIGSERIAL PRIMARY KEY,
    co_st_id VARCHAR(4) NOT NULL REFERENCES status_type(st_id),
    co_name VARCHAR(100) NOT NULL,
    co_in_id VARCHAR(3) NOT NULL REFERENCES industry(in_id),
    co_sp_rate VARCHAR(4), -- S&P Credit Rating (AAA, AA+, etc.)
    co_open_date DATE NOT NULL,
    co_ad_id BIGINT NOT NULL REFERENCES address(ad_id)
);

CREATE TABLE company_competitor (
    cp_co_id BIGINT NOT NULL REFERENCES company(co_id),
    cp_comp_co_id BIGINT NOT NULL REFERENCES company(co_id),
    cp_in_id VARCHAR(3) NOT NULL REFERENCES industry(in_id),
    PRIMARY KEY (cp_co_id, cp_comp_co_id)
);

CREATE TABLE exchange (
    ex_id VARCHAR(6) PRIMARY KEY, -- 'NYSE', 'NASDAQ', 'LSE', 'NSE'
    ex_name VARCHAR(100) NOT NULL,
    ex_ad_id BIGINT NOT NULL REFERENCES address(ad_id),
    ex_open INT NOT NULL,  -- e.g. 0930 (HHMM)
    ex_close INT NOT NULL  -- e.g. 1600 (HHMM)
);

CREATE TABLE security (
    s_symb VARCHAR(15) PRIMARY KEY,
    s_issue VARCHAR(10) NOT NULL,
    s_st_id VARCHAR(4) NOT NULL REFERENCES status_type(st_id),
    s_name VARCHAR(100) NOT NULL,
    s_ex_id VARCHAR(6) NOT NULL REFERENCES exchange(ex_id),
    s_co_id BIGINT NOT NULL REFERENCES company(co_id),
    s_num_out BIGINT NOT NULL, -- Outstanding shares
    s_start_date DATE NOT NULL,
    s_end_date DATE,
    s_pe NUMERIC(10, 2),       -- Price to Earnings ratio
    s_52wk_high NUMERIC(12, 4),
    s_52wk_low NUMERIC(12, 4),
    s_dividend NUMERIC(10, 4) DEFAULT 0.0000
);

CREATE TABLE daily_market (
    dm_date DATE NOT NULL,
    dm_s_symb VARCHAR(15) NOT NULL REFERENCES security(s_symb),
    dm_close NUMERIC(12, 4) NOT NULL,
    dm_high NUMERIC(12, 4) NOT NULL,
    dm_low NUMERIC(12, 4) NOT NULL,
    dm_vol BIGINT NOT NULL,
    PRIMARY KEY (dm_date, dm_s_symb)
);

CREATE TABLE financial (
    fi_co_id BIGINT NOT NULL REFERENCES company(co_id),
    fi_year INT NOT NULL,
    fi_qtr INT NOT NULL CHECK (fi_qtr BETWEEN 1 AND 4),
    fi_qtr_start_date DATE NOT NULL,
    fi_revenue NUMERIC(16, 2) NOT NULL,
    fi_net_earn NUMERIC(16, 2) NOT NULL,
    fi_basic_eps NUMERIC(10, 4) NOT NULL,
    fi_dilut_eps NUMERIC(10, 4) NOT NULL,
    fi_margin NUMERIC(8, 4) NOT NULL,
    PRIMARY KEY (fi_co_id, fi_year, fi_qtr)
);

CREATE TABLE last_trade (
    lt_s_symb VARCHAR(15) PRIMARY KEY REFERENCES security(s_symb),
    lt_dts TIMESTAMPTZ NOT NULL,
    lt_price NUMERIC(12, 4) NOT NULL,
    lt_open_price NUMERIC(12, 4) NOT NULL,
    lt_vol BIGINT NOT NULL
);

CREATE TABLE news_item (
    ni_id BIGSERIAL PRIMARY KEY,
    ni_headline VARCHAR(255) NOT NULL,
    ni_summary TEXT NOT NULL,
    ni_dts TIMESTAMPTZ NOT NULL,
    ni_source VARCHAR(80) NOT NULL,
    ni_author VARCHAR(80)
);

CREATE TABLE news_xref (
    nx_ni_id BIGINT NOT NULL REFERENCES news_item(ni_id) ON DELETE CASCADE,
    nx_co_id BIGINT NOT NULL REFERENCES company(co_id) ON DELETE CASCADE,
    PRIMARY KEY (nx_ni_id, nx_co_id)
);

-- ============================================================================
-- 3. BROKER & TRADING INFRASTRUCTURE
-- ============================================================================

CREATE TABLE broker (
    b_id BIGSERIAL PRIMARY KEY,
    b_st_id VARCHAR(4) NOT NULL REFERENCES status_type(st_id),
    b_name VARCHAR(100) NOT NULL,
    b_num_trades INT DEFAULT 0,
    b_comm_total NUMERIC(14, 2) DEFAULT 0.00
);

CREATE TABLE charge (
    ch_c_tier INT NOT NULL,
    ch_tt_id VARCHAR(3) NOT NULL,
    ch_chrg NUMERIC(10, 2) NOT NULL CHECK (ch_chrg >= 0),
    PRIMARY KEY (ch_c_tier, ch_tt_id)
);

CREATE TABLE commission_rate (
    cr_c_tier INT NOT NULL,
    cr_tt_id VARCHAR(3) NOT NULL,
    cr_ex_id VARCHAR(6) NOT NULL REFERENCES exchange(ex_id),
    cr_from_qty INT NOT NULL,
    cr_to_qty INT NOT NULL,
    cr_rate NUMERIC(8, 4) NOT NULL,
    PRIMARY KEY (cr_c_tier, cr_tt_id, cr_ex_id, cr_from_qty)
);

CREATE TABLE trade_type (
    tt_id VARCHAR(3) PRIMARY KEY, -- 'TMB', 'TMS', 'TLB', 'TLS' (Market Buy/Sell, Limit Buy/Sell)
    tt_name VARCHAR(25) NOT NULL,
    tt_is_sell BOOLEAN NOT NULL,
    tt_is_mrkt BOOLEAN NOT NULL
);

-- ============================================================================
-- 4. CUSTOMER & ACCOUNTS
-- ============================================================================

CREATE TABLE customer (
    c_id BIGSERIAL PRIMARY KEY,
    c_st_id VARCHAR(4) NOT NULL REFERENCES status_type(st_id),
    c_l_name VARCHAR(50) NOT NULL,
    c_f_name VARCHAR(50) NOT NULL,
    c_m_name VARCHAR(50),
    c_gndr CHAR(1),
    c_tier INT NOT NULL CHECK (c_tier IN (1, 2, 3)),
    c_dob DATE NOT NULL,
    c_ad_id BIGINT NOT NULL REFERENCES address(ad_id),
    c_ctry_1 VARCHAR(3),
    c_area_1 VARCHAR(5),
    c_local_1 VARCHAR(15),
    c_email_1 VARCHAR(100) NOT NULL,
    c_email_2 VARCHAR(100)
);

CREATE TABLE customer_account (
    ca_id BIGSERIAL PRIMARY KEY,
    ca_b_id BIGINT NOT NULL REFERENCES broker(b_id),
    ca_c_id BIGINT NOT NULL REFERENCES customer(c_id),
    ca_name VARCHAR(80),
    ca_tax_st INT NOT NULL CHECK (ca_tax_st IN (0, 1, 2)),
    ca_bal NUMERIC(14, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE account_permission (
    ap_ca_id BIGINT NOT NULL REFERENCES customer_account(ca_id) ON DELETE CASCADE,
    ap_acl VARCHAR(4) NOT NULL, -- Access Control: '0001', '0011'
    ap_tax_id VARCHAR(20) NOT NULL,
    ap_l_name VARCHAR(50) NOT NULL,
    ap_f_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (ap_ca_id, ap_tax_id)
);

CREATE TABLE customer_taxrate (
    cx_tx_id VARCHAR(4) NOT NULL REFERENCES taxrate(tx_id),
    cx_c_id BIGINT NOT NULL REFERENCES customer(c_id),
    PRIMARY KEY (cx_tx_id, cx_c_id)
);

CREATE TABLE watch_list (
    wl_id BIGSERIAL PRIMARY KEY,
    wl_c_id BIGINT NOT NULL REFERENCES customer(c_id) ON DELETE CASCADE
);

CREATE TABLE watch_item (
    wi_wl_id BIGINT NOT NULL REFERENCES watch_list(wl_id) ON DELETE CASCADE,
    wi_s_symb VARCHAR(15) NOT NULL REFERENCES security(s_symb),
    PRIMARY KEY (wi_wl_id, wi_s_symb)
);

-- ============================================================================
-- 5. TRADING TRANSACTIONS & SETTLEMENTS (Core Fact Tables)
-- ============================================================================

CREATE TABLE trade_request (
    tr_t_id BIGSERIAL PRIMARY KEY,
    tr_tt_id VARCHAR(3) NOT NULL REFERENCES trade_type(tt_id),
    tr_s_symb VARCHAR(15) NOT NULL REFERENCES security(s_symb),
    tr_qty INT NOT NULL CHECK (tr_qty > 0),
    tr_bid_price NUMERIC(12, 4) NOT NULL,
    tr_ca_id BIGINT NOT NULL REFERENCES customer_account(ca_id),
    tr_b_id BIGINT NOT NULL REFERENCES broker(b_id),
    tr_dts TIMESTAMPTZ NOT NULL
);

CREATE TABLE trade (
    t_id BIGSERIAL PRIMARY KEY,
    t_dts TIMESTAMPTZ NOT NULL,
    t_st_id VARCHAR(4) NOT NULL REFERENCES status_type(st_id),
    t_tt_id VARCHAR(3) NOT NULL REFERENCES trade_type(tt_id),
    t_is_cash BOOLEAN NOT NULL,
    t_s_symb VARCHAR(15) NOT NULL REFERENCES security(s_symb),
    t_qty INT NOT NULL CHECK (t_qty > 0),
    t_bid_price NUMERIC(12, 4) NOT NULL,
    t_ca_id BIGINT NOT NULL REFERENCES customer_account(ca_id),
    t_trade_price NUMERIC(12, 4),
    t_chrg NUMERIC(10, 2) DEFAULT 0.00,
    t_comm NUMERIC(10, 2) DEFAULT 0.00,
    t_tax NUMERIC(10, 2) DEFAULT 0.00,
    t_lifo BOOLEAN DEFAULT FALSE
);

CREATE TABLE trade_history (
    th_t_id BIGINT NOT NULL REFERENCES trade(t_id) ON DELETE CASCADE,
    th_dts TIMESTAMPTZ NOT NULL,
    th_st_id VARCHAR(4) NOT NULL REFERENCES status_type(st_id),
    PRIMARY KEY (th_t_id, th_st_id)
);

CREATE TABLE settlement (
    se_t_id BIGINT PRIMARY KEY REFERENCES trade(t_id) ON DELETE CASCADE,
    se_cash_type VARCHAR(40) NOT NULL,
    se_cash_due_date DATE NOT NULL,
    se_amt NUMERIC(14, 2) NOT NULL
);

CREATE TABLE cash_transaction (
    ct_t_id BIGINT PRIMARY KEY REFERENCES trade(t_id) ON DELETE CASCADE,
    ct_dts TIMESTAMPTZ NOT NULL,
    ct_amt NUMERIC(14, 2) NOT NULL,
    ct_name VARCHAR(100)
);

-- ============================================================================
-- 6. HOLDINGS & PORTFOLIO SNAPSHOTS
-- ============================================================================

CREATE TABLE holding (
    h_t_id BIGINT PRIMARY KEY REFERENCES trade(t_id),
    h_ca_id BIGINT NOT NULL REFERENCES customer_account(ca_id),
    h_s_symb VARCHAR(15) NOT NULL REFERENCES security(s_symb),
    h_dts TIMESTAMPTZ NOT NULL,
    h_price NUMERIC(12, 4) NOT NULL,
    h_qty INT NOT NULL
);

CREATE TABLE holding_history (
    hh_h_t_id BIGINT NOT NULL REFERENCES trade(t_id),
    hh_t_id BIGINT NOT NULL REFERENCES trade(t_id),
    hh_before_qty INT NOT NULL,
    hh_after_qty INT NOT NULL,
    PRIMARY KEY (hh_h_t_id, hh_t_id)
);

CREATE TABLE holding_summary (
    hs_ca_id BIGINT NOT NULL REFERENCES customer_account(ca_id),
    hs_s_symb VARCHAR(15) NOT NULL REFERENCES security(s_symb),
    hs_qty INT NOT NULL,
    PRIMARY KEY (hs_ca_id, hs_s_symb)
);

-- ============================================================================
-- INDEXES FOR COMPLEX ANALYTICAL & JOIN PERFORMANCE
-- ============================================================================

CREATE INDEX idx_sec_co_id ON security(s_co_id);
CREATE INDEX idx_sec_ex_id ON security(s_ex_id);
CREATE INDEX idx_dm_symb_date ON daily_market(dm_s_symb, dm_date);
CREATE INDEX idx_trade_ca_id ON trade(t_ca_id);
CREATE INDEX idx_trade_s_symb ON trade(t_s_symb);
CREATE INDEX idx_trade_dts ON trade(t_dts);
CREATE INDEX idx_holding_ca_id ON holding(h_ca_id);
CREATE INDEX idx_holding_symb ON holding(h_s_symb);
CREATE INDEX idx_cust_acct_cust ON customer_account(ca_c_id);
CREATE INDEX idx_cust_acct_broker ON customer_account(ca_b_id);
CREATE INDEX idx_company_industry ON company(co_in_id);
