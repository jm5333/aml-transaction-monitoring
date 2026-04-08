-- ============================================================
-- AML TRANSACTION MONITORING — SQL ANALYSIS QUERIES
-- Author: Jeevan Lal Mourya | Risk Analyst Portfolio Project
-- Dataset: 10,000 synthetic financial transactions (2024)
-- ============================================================

-- ── 1. AML EXECUTIVE KPI SUMMARY ─────────────────────────────
SELECT
    COUNT(*)                                                          AS total_transactions,
    SUM(is_suspicious)                                                AS suspicious_count,
    ROUND(SUM(is_suspicious) * 100.0 / COUNT(*), 2)                  AS suspicious_rate_pct,
    SUM(CASE WHEN alert_level = 'HIGH'   THEN 1 ELSE 0 END)          AS high_alerts,
    SUM(CASE WHEN alert_level = 'MEDIUM' THEN 1 ELSE 0 END)          AS medium_alerts,
    ROUND(AVG(aml_risk_score), 2)                                     AS avg_portfolio_risk_score,
    ROUND(SUM(CASE WHEN is_suspicious = 1 THEN amount ELSE 0 END), 2) AS suspicious_volume_usd
FROM transactions;

-- ── 2. SUSPICIOUS TRANSACTION RATE BY COUNTRY ────────────────
-- Identifies high-risk jurisdictions for AML compliance monitoring
SELECT
    country,
    COUNT(*)                                                AS total_transactions,
    SUM(is_suspicious)                                      AS suspicious_count,
    ROUND(SUM(is_suspicious) * 100.0 / COUNT(*), 1)         AS suspicious_rate_pct,
    ROUND(AVG(aml_risk_score), 1)                           AS avg_risk_score,
    ROUND(SUM(amount), 2)                                   AS total_volume_usd,
    CASE WHEN country IN ('RU','NG','IR')
         THEN 'HIGH RISK JURISDICTION'
         ELSE 'STANDARD' END                                AS jurisdiction_risk
FROM transactions
GROUP BY country
ORDER BY suspicious_rate_pct DESC;

-- ── 3. AML RISK BY TRANSACTION TYPE ──────────────────────────
SELECT
    type                                                    AS transaction_type,
    COUNT(*)                                                AS total_count,
    SUM(is_suspicious)                                      AS suspicious_count,
    ROUND(SUM(is_suspicious) * 100.0 / COUNT(*), 1)         AS suspicious_rate_pct,
    ROUND(AVG(amount), 2)                                   AS avg_transaction_amount,
    ROUND(AVG(aml_risk_score), 1)                           AS avg_risk_score
FROM transactions
GROUP BY type
ORDER BY avg_risk_score DESC;

-- ── 4. STRUCTURING DETECTION (SMURFING) ──────────────────────
-- Identifies transactions just below $10,000 reporting threshold
SELECT
    COUNT(*)                                                AS structuring_alerts,
    ROUND(SUM(amount), 2)                                   AS total_structured_amount,
    ROUND(AVG(aml_risk_score), 1)                           AS avg_risk_score,
    COUNT(DISTINCT country)                                 AS countries_involved
FROM transactions
WHERE structuring_flag = 1;

-- ── 5. OFF-HOURS SUSPICIOUS ACTIVITY ─────────────────────────
SELECT
    CASE WHEN hour BETWEEN 0 AND 5 THEN 'Off-Hours (0-5am)'
         WHEN hour BETWEEN 6 AND 9 THEN 'Early Morning (6-9am)'
         WHEN hour BETWEEN 10 AND 17 THEN 'Business Hours (10-5pm)'
         ELSE 'Evening (6pm-11pm)' END                      AS time_period,
    COUNT(*)                                                AS total_tx,
    SUM(is_suspicious)                                      AS suspicious_count,
    ROUND(SUM(is_suspicious) * 100.0 / COUNT(*), 1)         AS suspicious_rate_pct,
    ROUND(AVG(aml_risk_score), 1)                           AS avg_risk_score
FROM transactions
GROUP BY time_period
ORDER BY suspicious_rate_pct DESC;

-- ── 6. MONTHLY TREND MONITORING ──────────────────────────────
SELECT
    SUBSTR(date, 1, 7)                                      AS month,
    COUNT(*)                                                AS total_transactions,
    SUM(is_suspicious)                                      AS suspicious_count,
    ROUND(SUM(amount) / 1000000, 2)                         AS volume_millions,
    ROUND(AVG(aml_risk_score), 2)                           AS avg_risk_score,
    SUM(CASE WHEN alert_level = 'HIGH' THEN 1 ELSE 0 END)  AS high_alerts
FROM transactions
GROUP BY month
ORDER BY month;

-- ── 7. DATA VALIDATION CHECKS ────────────────────────────────
SELECT 'Null transaction_id'  AS check_name, COUNT(*) AS issues FROM transactions WHERE transaction_id IS NULL
UNION ALL SELECT 'Negative amount',      COUNT(*) FROM transactions WHERE amount < 0
UNION ALL SELECT 'Invalid alert level',  COUNT(*) FROM transactions WHERE alert_level NOT IN ('HIGH','MEDIUM','LOW')
UNION ALL SELECT 'Risk score out of range', COUNT(*) FROM transactions WHERE aml_risk_score < 0 OR aml_risk_score > 100
UNION ALL SELECT 'Missing country code', COUNT(*) FROM transactions WHERE country IS NULL OR country = '';
