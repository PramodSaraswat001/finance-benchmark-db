-- ============================================================================
-- BULK LOAD SCRIPT FOR FINANCE / TPC-E BENCHMARK (PostgreSQL)
-- Executes \copy in exact referential dependency order
-- Run: psql -U <username> -d <database_name> -f load_data.sql
-- ============================================================================

\echo '--- Loading Set 1: Dimension & Reference ---'
\copy status_type FROM 'data/status_type.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy taxrate FROM 'data/taxrate.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy zip_code FROM 'data/zip_code.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy address FROM 'data/address.csv' WITH (FORMAT csv, HEADER true, NULL '');

\echo '--- Loading Set 2: Market, Industry & Securities ---'
\copy sector FROM 'data/sector.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy industry FROM 'data/industry.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy company FROM 'data/company.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy company_competitor FROM 'data/company_competitor.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy exchange FROM 'data/exchange.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy security FROM 'data/security.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy daily_market FROM 'data/daily_market.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy financial FROM 'data/financial.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy last_trade FROM 'data/last_trade.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy news_item FROM 'data/news_item.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy news_xref FROM 'data/news_xref.csv' WITH (FORMAT csv, HEADER true, NULL '');

\echo '--- Loading Set 3: Broker & Trading Rules ---'
\copy broker FROM 'data/broker.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy trade_type FROM 'data/trade_type.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy charge FROM 'data/charge.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy commission_rate FROM 'data/commission_rate.csv' WITH (FORMAT csv, HEADER true, NULL '');

\echo '--- Loading Set 4: Customer & Accounts ---'
\copy customer FROM 'data/customer.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy customer_account FROM 'data/customer_account.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy account_permission FROM 'data/account_permission.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy customer_taxrate FROM 'data/customer_taxrate.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy watch_list FROM 'data/watch_list.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy watch_item FROM 'data/watch_item.csv' WITH (FORMAT csv, HEADER true, NULL '');

\echo '--- Loading Set 5: Trading Transactions & Settlements ---'
\copy trade_request FROM 'data/trade_request.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy trade FROM 'data/trade.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy trade_history FROM 'data/trade_history.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy settlement FROM 'data/settlement.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy cash_transaction FROM 'data/cash_transaction.csv' WITH (FORMAT csv, HEADER true, NULL '');

\echo '--- Loading Set 6: Holdings & Portfolio Snapshots ---'
\copy holding FROM 'data/holding.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy holding_history FROM 'data/holding_history.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy holding_summary FROM 'data/holding_summary.csv' WITH (FORMAT csv, HEADER true, NULL '');

\echo '=== Finance / TPC-E Data Load Complete! ==='
