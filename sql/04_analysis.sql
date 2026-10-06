-- 04_analysis.sql  Business KPI queries (Spark SQL dialect). Each result is materialised as an a_* table.

-- Q0 Country-level 2021-2023 averages ("latest" window used by several questions)
CREATE OR REPLACE TABLE a_country_latest AS
SELECT d.country_key, d.country, d.region, d.iso3, COUNT(*) AS obs,
       ROUND(AVG(f.life_ladder), 3) AS life_ladder, ROUND(AVG(f.social_support), 3) AS social_support,
       ROUND(AVG(f.healthy_life_exp), 2) AS healthy_life_exp, ROUND(AVG(f.freedom), 3) AS freedom,
       ROUND(AVG(f.generosity), 3) AS generosity, ROUND(AVG(f.corruption), 3) AS corruption,
       ROUND(AVG(f.gdp_pc_usd), 0) AS gdp_pc_usd, ROUND(AVG(f.population), 0) AS population
FROM fact_country_year f JOIN dim_country d ON f.country_key = d.country_key
WHERE f.year BETWEEN 2021 AND 2023
GROUP BY d.country_key, d.country, d.region, d.iso3;

-- Q1 Headline KPIs
CREATE OR REPLACE TABLE a_kpi_headline AS
WITH q AS (
  SELECT life_ladder, NTILE(5) OVER (ORDER BY gdp_pc_usd) AS qn FROM a_country_latest WHERE gdp_pc_usd IS NOT NULL
), fit AS (
  SELECT regr_slope(life_ladder, ln(gdp_pc_usd)) AS slope, regr_r2(life_ladder, ln(gdp_pc_usd)) AS r2
  FROM a_country_latest WHERE gdp_pc_usd > 0
)
SELECT
  (SELECT COUNT(DISTINCT country_key) FROM fact_country_year)                                   AS countries,
  (SELECT COUNT(*) FROM fact_country_year)                                                      AS country_years,
  (SELECT MIN(year) FROM fact_country_year)                                                     AS first_year,
  (SELECT MAX(year) FROM fact_country_year)                                                     AS last_year,
  (SELECT ROUND(100.0 * SUM(CASE WHEN gdp_pc_usd IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) FROM fact_country_year) AS wb_match_pct,
  (SELECT COUNT(*) FROM a_country_latest)                                                       AS countries_latest,
  (SELECT ROUND(AVG(life_ladder), 3) FROM a_country_latest)                                     AS avg_ladder_latest,
  (SELECT ROUND(SUM(life_ladder * population) / SUM(population), 3) FROM a_country_latest WHERE population > 0) AS pop_weighted_ladder_latest,
  (SELECT MAX(life_ladder) FROM a_country_latest)                                               AS max_ladder_latest,
  (SELECT MIN(life_ladder) FROM a_country_latest)                                               AS min_ladder_latest,
  (SELECT ROUND(corr(life_ladder, ln_gdp_pc_usd), 4) FROM fact_country_year)                    AS corr_ladder_log_gdp_pc,
  (SELECT ROUND(corr(life_ladder, gdp_pc_usd), 4) FROM fact_country_year)                       AS corr_ladder_gdp_pc_linear,
  (SELECT ROUND(r2, 4) FROM fit)                                                                AS r2_ladder_on_log_gdp_latest,
  (SELECT ROUND(slope * ln(2), 3) FROM fit)                                                     AS ladder_gain_per_gdp_doubling,
  (SELECT ROUND(AVG(CASE WHEN qn = 5 THEN life_ladder END) - AVG(CASE WHEN qn = 1 THEN life_ladder END), 3) FROM q) AS ladder_gap_top_bottom_quintile;

-- Q2 Global trend by survey year (simple and population-weighted averages)
CREATE OR REPLACE TABLE a_ladder_by_year AS
SELECT year, COUNT(*) AS countries,
       ROUND(AVG(life_ladder), 3) AS avg_ladder,
       ROUND(percentile_approx(life_ladder, 0.5), 3) AS median_ladder,
       ROUND(SUM(CASE WHEN population > 0 THEN life_ladder * population END) / SUM(CASE WHEN population > 0 THEN population END), 3) AS pop_weighted_ladder,
       ROUND(AVG(negative_affect), 3) AS avg_negative_affect,
       ROUND(AVG(positive_affect), 3) AS avg_positive_affect
FROM fact_country_year GROUP BY year;

-- Q3 Regions (2021-23 country averages)
CREATE OR REPLACE TABLE a_region_summary AS
SELECT region, COUNT(*) AS countries,
       ROUND(AVG(life_ladder), 3) AS avg_ladder, ROUND(MIN(life_ladder), 3) AS min_ladder, ROUND(MAX(life_ladder), 3) AS max_ladder,
       ROUND(SUM(CASE WHEN population > 0 THEN life_ladder * population END) / SUM(CASE WHEN population > 0 THEN population END), 3) AS pop_weighted_ladder,
       ROUND(AVG(gdp_pc_usd), 0) AS avg_gdp_pc_usd, ROUND(SUM(population) / 1e6, 1) AS population_m,
       ROUND(AVG(social_support), 3) AS avg_social_support, ROUND(AVG(healthy_life_exp), 1) AS avg_healthy_life_exp
FROM a_country_latest GROUP BY region;

-- Q4 Does money buy happiness? Ladder by GDP-per-capita quintile (2021-23)
CREATE OR REPLACE TABLE a_gdp_quintile AS
WITH q AS (SELECT *, NTILE(5) OVER (ORDER BY gdp_pc_usd) AS qn FROM a_country_latest WHERE gdp_pc_usd IS NOT NULL)
SELECT concat('Q', CAST(qn AS STRING), CASE qn WHEN 1 THEN ' poorest' WHEN 5 THEN ' richest' ELSE '' END) AS gdp_quintile,
       COUNT(*) AS countries, ROUND(MIN(gdp_pc_usd), 0) AS min_gdp_pc_usd, ROUND(MAX(gdp_pc_usd), 0) AS max_gdp_pc_usd,
       ROUND(AVG(life_ladder), 3) AS avg_ladder, ROUND(AVG(social_support), 3) AS avg_social_support,
       ROUND(AVG(healthy_life_exp), 1) AS avg_healthy_life_exp, ROUND(AVG(freedom), 3) AS avg_freedom,
       ROUND(AVG(corruption), 3) AS avg_corruption
FROM q GROUP BY qn;

-- Q5 Which factors move with happiness? Pooled country-year correlations
CREATE OR REPLACE TABLE a_driver_correlations AS
SELECT 'Log GDP per capita (World Bank, US$)' AS factor, ROUND(corr(life_ladder, ln_gdp_pc_usd), 4) AS corr_with_ladder, COUNT(ln_gdp_pc_usd) AS n_obs FROM fact_country_year
UNION ALL SELECT 'Log GDP per capita (WHR, PPP)', ROUND(corr(life_ladder, whr_log_gdp_pc), 4), COUNT(whr_log_gdp_pc) FROM fact_country_year
UNION ALL SELECT 'Social support', ROUND(corr(life_ladder, social_support), 4), COUNT(social_support) FROM fact_country_year
UNION ALL SELECT 'Healthy life expectancy', ROUND(corr(life_ladder, healthy_life_exp), 4), COUNT(healthy_life_exp) FROM fact_country_year
UNION ALL SELECT 'Freedom to make life choices', ROUND(corr(life_ladder, freedom), 4), COUNT(freedom) FROM fact_country_year
UNION ALL SELECT 'Generosity', ROUND(corr(life_ladder, generosity), 4), COUNT(generosity) FROM fact_country_year
UNION ALL SELECT 'Perceived corruption', ROUND(corr(life_ladder, corruption), 4), COUNT(corruption) FROM fact_country_year
UNION ALL SELECT 'Positive affect', ROUND(corr(life_ladder, positive_affect), 4), COUNT(positive_affect) FROM fact_country_year
UNION ALL SELECT 'Negative affect', ROUND(corr(life_ladder, negative_affect), 4), COUNT(negative_affect) FROM fact_country_year;

-- Q6 Happiest and least happy countries in 2023
CREATE OR REPLACE TABLE a_top_bottom_2023 AS
WITH r AS (
  SELECT d.country, d.region, f.life_ladder, ROUND(f.gdp_pc_usd, 0) AS gdp_pc_usd,
         ROW_NUMBER() OVER (ORDER BY f.life_ladder DESC, d.country) AS top_rnk,
         ROW_NUMBER() OVER (ORDER BY f.life_ladder ASC, d.country) AS bottom_rnk
  FROM fact_country_year f JOIN dim_country d ON f.country_key = d.country_key WHERE f.year = 2023
)
SELECT 'top 10' AS grp, top_rnk AS rnk, country, region, life_ladder, gdp_pc_usd FROM r WHERE top_rnk <= 10
UNION ALL
SELECT 'bottom 10', bottom_rnk, country, region, life_ladder, gdp_pc_usd FROM r WHERE bottom_rnk <= 10;

-- Q7 Who is happier (or less happy) than income predicts? ladder ~ ln(GDP pc), 2021-23
CREATE OR REPLACE TABLE a_income_residual AS
WITH base AS (SELECT * FROM a_country_latest WHERE gdp_pc_usd > 0),
fit AS (SELECT regr_slope(life_ladder, ln(gdp_pc_usd)) AS b, regr_intercept(life_ladder, ln(gdp_pc_usd)) AS a FROM base)
SELECT country, region, gdp_pc_usd, life_ladder,
       ROUND(fit.a + fit.b * ln(gdp_pc_usd), 3) AS predicted_ladder,
       ROUND(life_ladder - (fit.a + fit.b * ln(gdp_pc_usd)), 3) AS residual,
       CAST(ROW_NUMBER() OVER (ORDER BY life_ladder - (fit.a + fit.b * ln(gdp_pc_usd)) DESC, country) AS INT) AS residual_rank
FROM base CROSS JOIN fit;

-- Q8 Change in happiness: 2006-10 average vs 2019-23 average (countries with >= 2 surveys in each window).
--    GDP growth uses the WHR log GDP per capita (PPP, constant prices) and needs >= 2 GDP values in each window.
CREATE OR REPLACE TABLE a_happiness_change AS
WITH w AS (
  SELECT f.country_key,
         AVG(CASE WHEN f.year BETWEEN 2006 AND 2010 THEN f.life_ladder END) AS early_ladder,
         AVG(CASE WHEN f.year BETWEEN 2019 AND 2023 THEN f.life_ladder END) AS late_ladder,
         SUM(CASE WHEN f.year BETWEEN 2006 AND 2010 THEN 1 ELSE 0 END) AS early_n,
         SUM(CASE WHEN f.year BETWEEN 2019 AND 2023 THEN 1 ELSE 0 END) AS late_n,
         AVG(CASE WHEN f.year BETWEEN 2006 AND 2010 THEN f.whr_log_gdp_pc END) AS early_log_gdp,
         AVG(CASE WHEN f.year BETWEEN 2019 AND 2023 THEN f.whr_log_gdp_pc END) AS late_log_gdp,
         COUNT(CASE WHEN f.year BETWEEN 2006 AND 2010 THEN f.whr_log_gdp_pc END) AS early_gdp_n,
         COUNT(CASE WHEN f.year BETWEEN 2019 AND 2023 THEN f.whr_log_gdp_pc END) AS late_gdp_n
  FROM fact_country_year f GROUP BY f.country_key
)
SELECT d.country, d.region, ROUND(early_ladder, 3) AS early_ladder, ROUND(late_ladder, 3) AS late_ladder,
       ROUND(late_ladder - early_ladder, 3) AS ladder_change,
       CASE WHEN early_gdp_n >= 2 AND late_gdp_n >= 2 THEN ROUND(100.0 * (exp(late_log_gdp - early_log_gdp) - 1), 1) END AS gdp_pc_ppp_growth_pct,
       CAST(ROW_NUMBER() OVER (ORDER BY late_ladder - early_ladder DESC, d.country) AS INT) AS change_rank
FROM w JOIN dim_country d ON w.country_key = d.country_key
WHERE early_n >= 2 AND late_n >= 2;

-- Q9 Easterlin check: did faster-growing economies get happier? (quartiles of real PPP GDP-per-capita growth)
CREATE OR REPLACE TABLE a_growth_vs_change AS
WITH q AS (SELECT *, NTILE(4) OVER (ORDER BY gdp_pc_ppp_growth_pct) AS qn FROM a_happiness_change WHERE gdp_pc_ppp_growth_pct IS NOT NULL)
SELECT concat('G', CAST(qn AS STRING), CASE qn WHEN 1 THEN ' slowest' WHEN 4 THEN ' fastest' ELSE '' END) AS growth_quartile,
       COUNT(*) AS countries, ROUND(AVG(gdp_pc_ppp_growth_pct), 1) AS avg_gdp_pc_growth_pct,
       ROUND(AVG(ladder_change), 3) AS avg_ladder_change,
       ROUND(100.0 * SUM(CASE WHEN ladder_change > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_countries_happier
FROM q GROUP BY qn;

-- Q10 Pandemic shift: same countries, 2017-19 vs 2020-22
CREATE OR REPLACE TABLE a_covid_shift AS
WITH p AS (
  SELECT country_key,
         AVG(CASE WHEN year BETWEEN 2017 AND 2019 THEN life_ladder END) AS l0, AVG(CASE WHEN year BETWEEN 2020 AND 2022 THEN life_ladder END) AS l1,
         AVG(CASE WHEN year BETWEEN 2017 AND 2019 THEN negative_affect END) AS n0, AVG(CASE WHEN year BETWEEN 2020 AND 2022 THEN negative_affect END) AS n1,
         AVG(CASE WHEN year BETWEEN 2017 AND 2019 THEN positive_affect END) AS p0, AVG(CASE WHEN year BETWEEN 2020 AND 2022 THEN positive_affect END) AS p1,
         AVG(CASE WHEN year BETWEEN 2017 AND 2019 THEN generosity END) AS g0, AVG(CASE WHEN year BETWEEN 2020 AND 2022 THEN generosity END) AS g1,
         AVG(CASE WHEN year BETWEEN 2017 AND 2019 THEN social_support END) AS s0, AVG(CASE WHEN year BETWEEN 2020 AND 2022 THEN social_support END) AS s1
  FROM fact_country_year GROUP BY country_key
), b AS (SELECT * FROM p WHERE l0 IS NOT NULL AND l1 IS NOT NULL)
SELECT 'Life ladder' AS metric, COUNT(*) AS countries, ROUND(AVG(l0), 3) AS avg_2017_19, ROUND(AVG(l1), 3) AS avg_2020_22, ROUND(AVG(l1) - AVG(l0), 3) AS change FROM b
UNION ALL SELECT 'Negative affect', COUNT(n1), ROUND(AVG(CASE WHEN n1 IS NOT NULL THEN n0 END), 3), ROUND(AVG(CASE WHEN n0 IS NOT NULL THEN n1 END), 3),
       ROUND(AVG(CASE WHEN n0 IS NOT NULL THEN n1 END) - AVG(CASE WHEN n1 IS NOT NULL THEN n0 END), 3) FROM b
UNION ALL SELECT 'Positive affect', COUNT(p1), ROUND(AVG(CASE WHEN p1 IS NOT NULL THEN p0 END), 3), ROUND(AVG(CASE WHEN p0 IS NOT NULL THEN p1 END), 3),
       ROUND(AVG(CASE WHEN p0 IS NOT NULL THEN p1 END) - AVG(CASE WHEN p1 IS NOT NULL THEN p0 END), 3) FROM b
UNION ALL SELECT 'Generosity', COUNT(g1), ROUND(AVG(CASE WHEN g1 IS NOT NULL THEN g0 END), 3), ROUND(AVG(CASE WHEN g0 IS NOT NULL THEN g1 END), 3),
       ROUND(AVG(CASE WHEN g0 IS NOT NULL THEN g1 END) - AVG(CASE WHEN g1 IS NOT NULL THEN g0 END), 3) FROM b
UNION ALL SELECT 'Social support', COUNT(s1), ROUND(AVG(CASE WHEN s1 IS NOT NULL THEN s0 END), 3), ROUND(AVG(CASE WHEN s0 IS NOT NULL THEN s1 END), 3),
       ROUND(AVG(CASE WHEN s0 IS NOT NULL THEN s1 END) - AVG(CASE WHEN s1 IS NOT NULL THEN s0 END), 3) FROM b;
