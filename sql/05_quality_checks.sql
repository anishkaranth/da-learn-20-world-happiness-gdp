-- 05_quality_checks.sql  Data-quality evidence: before/after counts, issue counts, assertions (Spark SQL dialect)

CREATE OR REPLACE TABLE dq_row_counts AS
SELECT 'whr_panel' AS entity, (SELECT COUNT(*) FROM stg_whr_panel) AS raw_rows,
       (SELECT COUNT(*) FROM (SELECT DISTINCT trim(country_name), trim(year) FROM stg_whr_panel) d) AS distinct_keys,
       (SELECT COUNT(*) FROM cln_happiness) AS clean_rows, 'country x survey year' AS grain
UNION ALL SELECT 'whr_2024_ranking', (SELECT COUNT(*) FROM stg_whr_2024),
       (SELECT COUNT(DISTINCT trim(country_name)) FROM stg_whr_2024), (SELECT COUNT(ladder_2024) FROM cln_country), 'country (2024 ranking, matched to panel)'
UNION ALL SELECT 'wb_gdp', (SELECT COUNT(*) FROM stg_wb_gdp),
       (SELECT COUNT(*) FROM (SELECT DISTINCT country_code, year FROM stg_wb_gdp) d),
       (SELECT COUNT(gdp_usd) FROM cln_wb_country_year), 'country/aggregate x year'
UNION ALL SELECT 'wb_population', (SELECT COUNT(*) FROM stg_wb_population),
       (SELECT COUNT(*) FROM (SELECT DISTINCT country_code, year FROM stg_wb_population) d),
       (SELECT COUNT(population) FROM cln_wb_country_year), 'country/aggregate x year'
UNION ALL SELECT 'fact_country_year', NULL, NULL, (SELECT COUNT(*) FROM fact_country_year), 'country x survey year'
UNION ALL SELECT 'dim_country', NULL, NULL, (SELECT COUNT(*) FROM dim_country), 'WHR country'
UNION ALL SELECT 'dim_year', NULL, NULL, (SELECT COUNT(*) FROM dim_year), 'survey year';

CREATE OR REPLACE TABLE dq_null_rates AS
SELECT 'whr_panel' AS entity, 'Log GDP per capita' AS column_name,
       ROUND(100.0 * SUM(CASE WHEN whr_log_gdp_pc IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3) AS null_pct, 'kept NULL; WB GDP used instead' AS treatment FROM cln_happiness
UNION ALL SELECT 'whr_panel', 'Social support', ROUND(100.0 * SUM(CASE WHEN social_support IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'kept NULL (excluded from AVG/corr)' FROM cln_happiness
UNION ALL SELECT 'whr_panel', 'Healthy life expectancy', ROUND(100.0 * SUM(CASE WHEN healthy_life_exp IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'kept NULL' FROM cln_happiness
UNION ALL SELECT 'whr_panel', 'Freedom to make life choices', ROUND(100.0 * SUM(CASE WHEN freedom IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'kept NULL' FROM cln_happiness
UNION ALL SELECT 'whr_panel', 'Generosity', ROUND(100.0 * SUM(CASE WHEN generosity IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'kept NULL' FROM cln_happiness
UNION ALL SELECT 'whr_panel', 'Perceptions of corruption', ROUND(100.0 * SUM(CASE WHEN corruption IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'kept NULL' FROM cln_happiness
UNION ALL SELECT 'whr_panel', 'Positive affect', ROUND(100.0 * SUM(CASE WHEN positive_affect IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'kept NULL' FROM cln_happiness
UNION ALL SELECT 'whr_panel', 'Negative affect', ROUND(100.0 * SUM(CASE WHEN negative_affect IS NULL THEN 1 ELSE 0 END) / COUNT(*), 3), 'kept NULL' FROM cln_happiness
UNION ALL SELECT 'fact_country_year', 'gdp_pc_usd (World Bank)', ROUND(100.0 * SUM(dq_no_gdp_pc) / COUNT(*), 3), 'no WB match or no GDP that year' FROM fact_country_year;

CREATE OR REPLACE TABLE dq_issues AS
SELECT 'whr_panel: duplicate country x year rows dropped' AS check_name,
       (SELECT COUNT(*) FROM stg_whr_panel) - (SELECT COUNT(*) FROM cln_happiness) AS affected_rows
UNION ALL SELECT 'whr_panel: rows with >= 1 missing factor (kept)', (SELECT COUNT(*) FROM cln_happiness WHERE dq_missing_factors > 0)
UNION ALL SELECT 'whr_panel: country name recoded (Türkiye -> Turkiye)', (SELECT SUM(dq_name_recoded) FROM cln_happiness)
UNION ALL SELECT 'whr_panel: ladder outside 0..10', (SELECT SUM(dq_ladder_out_of_range) FROM cln_happiness)
UNION ALL SELECT 'whr_panel: ratio factor outside 0..1', (SELECT SUM(dq_ratio_out_of_range) FROM cln_happiness)
UNION ALL SELECT 'country: WHR -> World Bank name overrides applied', (SELECT SUM(dq_name_override) FROM cln_country)
UNION ALL SELECT 'country: no World Bank series (Taiwan, Somaliland)', (SELECT SUM(dq_no_wb_match) FROM cln_country)
UNION ALL SELECT 'country: region not in WHR 2024 ranking (explicit fallback)', (SELECT SUM(dq_region_fallback) FROM cln_country)
UNION ALL SELECT 'country: WHR 2024 ranking rows not in panel', (SELECT COUNT(*) FROM stg_whr_2024 s WHERE CASE WHEN trim(s.country_name) IN ('Türkiye', 'Turkiye') THEN 'Turkiye' ELSE trim(s.country_name) END NOT IN (SELECT country FROM cln_country))
UNION ALL SELECT 'fact: country-years without World Bank GDP per capita', (SELECT SUM(dq_no_gdp_pc) FROM fact_country_year)
UNION ALL SELECT 'wb: WHR-country years 2005-2023 with population but no GDP', (SELECT SUM(w.dq_missing_gdp) FROM cln_wb_country_year w JOIN cln_country c ON w.iso3 = c.iso3 WHERE w.year BETWEEN 2005 AND 2023)
UNION ALL SELECT 'RI: fact rows lost in dim joins', (SELECT COUNT(*) FROM cln_happiness) - (SELECT COUNT(*) FROM fact_country_year);

CREATE OR REPLACE TABLE dq_assertions AS
WITH c AS (
  SELECT 'fact (country_key, year) unique' AS check_name,
         (SELECT COUNT(*) - COUNT(DISTINCT concat(CAST(country_key AS STRING), '-', CAST(year AS STRING))) FROM fact_country_year) AS failed_rows
  UNION ALL SELECT 'fact rows = cleaned panel rows (no fan-out / loss in joins)',
         (SELECT ABS((SELECT COUNT(*) FROM fact_country_year) - (SELECT COUNT(*) FROM cln_happiness)))
  UNION ALL SELECT 'fact.country_key -> dim_country', (SELECT COUNT(*) FROM fact_country_year WHERE country_key NOT IN (SELECT country_key FROM dim_country))
  UNION ALL SELECT 'fact.year -> dim_year', (SELECT COUNT(*) FROM fact_country_year WHERE year NOT IN (SELECT year FROM dim_year))
  UNION ALL SELECT 'dim_country.country unique', (SELECT COUNT(*) - COUNT(DISTINCT country) FROM dim_country)
  UNION ALL SELECT 'dim_country.iso3 unique where present', (SELECT COUNT(iso3) - COUNT(DISTINCT iso3) FROM dim_country)
  UNION ALL SELECT 'every country has a region', (SELECT COUNT(*) FROM dim_country WHERE region IS NULL)
  UNION ALL SELECT 'life ladder within 0..10', (SELECT COUNT(*) FROM fact_country_year WHERE life_ladder < 0 OR life_ladder > 10)
  UNION ALL SELECT 'ratio factors within 0..1', (SELECT SUM(dq_ratio_out_of_range) FROM fact_country_year)
  UNION ALL SELECT 'GDP per capita > 0 where present', (SELECT COUNT(*) FROM fact_country_year WHERE gdp_pc_usd <= 0)
  UNION ALL SELECT 'World Bank match >= 95% of country-years', (SELECT CASE WHEN AVG(1 - dq_no_gdp_pc) >= 0.95 THEN 0 ELSE 1 END FROM fact_country_year)
  UNION ALL SELECT 'WB and WHR log GDP agree (corr >= 0.9)', (SELECT CASE WHEN corr(ln_gdp_pc_usd, whr_log_gdp_pc) >= 0.9 THEN 0 ELSE 1 END FROM fact_country_year)
  UNION ALL SELECT 'GDP quintiles cover all latest countries with GDP', (SELECT ABS((SELECT SUM(countries) FROM a_gdp_quintile) - (SELECT COUNT(*) FROM a_country_latest WHERE gdp_pc_usd IS NOT NULL)))
  UNION ALL SELECT 'clean panel rows = distinct valid (country, year) keys in staging', (SELECT ABS((SELECT COUNT(*) FROM cln_happiness)
         - (SELECT COUNT(*) FROM (SELECT DISTINCT CASE WHEN trim(country_name) IN ('Türkiye', 'Turkiye') THEN 'Turkiye' ELSE trim(country_name) END, TRY_CAST(trim(year) AS INT)
            FROM stg_whr_panel WHERE trim(country_name) <> '' AND TRY_CAST(trim(year) AS INT) IS NOT NULL AND TRY_CAST(trim(life_ladder) AS DOUBLE) IS NOT NULL) k)))
  UNION ALL SELECT 'no NULL country / year / life ladder in fact', (SELECT COUNT(*) FROM fact_country_year WHERE country_key IS NULL OR year IS NULL OR life_ladder IS NULL)
  UNION ALL SELECT 'survey years within 2005..2023', (SELECT COUNT(*) FROM fact_country_year WHERE year NOT BETWEEN 2005 AND 2023)
  UNION ALL SELECT 'every WHR 2024 ranking country found in panel', (SELECT COUNT(*) FROM stg_whr_2024 s WHERE CASE WHEN trim(s.country_name) IN ('Türkiye', 'Turkiye') THEN 'Turkiye' ELSE trim(s.country_name) END NOT IN (SELECT country FROM cln_country))
  UNION ALL SELECT 'only Taiwan + Somaliland lack a World Bank code', (SELECT COUNT(*) FROM dim_country WHERE iso3 IS NULL AND country NOT IN ('Taiwan Province of China', 'Somaliland region'))
  UNION ALL SELECT 'World Bank (iso3, year) unique', (SELECT COUNT(*) - COUNT(DISTINCT concat(iso3, '-', CAST(year AS STRING))) FROM cln_wb_country_year)
  UNION ALL SELECT 'population > 0 where present', (SELECT COUNT(*) FROM fact_country_year WHERE population <= 0)
  UNION ALL SELECT 'gdp_pc_usd = gdp_usd / population', (SELECT COUNT(*) FROM fact_country_year WHERE gdp_pc_usd IS NOT NULL AND ABS(gdp_pc_usd - gdp_usd / population) > 1e-6 * gdp_pc_usd)
  UNION ALL SELECT 'healthy life expectancy within 0..100', (SELECT COUNT(*) FROM fact_country_year WHERE healthy_life_exp < 0 OR healthy_life_exp > 100)
  UNION ALL SELECT 'latest-window countries all have 2021-23 surveys', (SELECT COUNT(*) FROM a_country_latest WHERE obs < 1 OR obs > 3)
  UNION ALL SELECT 'positive ladder-GDP correlation (sanity)', (SELECT CASE WHEN corr_ladder_log_gdp_pc > 0 THEN 0 ELSE 1 END FROM a_kpi_headline)
)
SELECT check_name, failed_rows, CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status FROM c;
