-- 03_model.sql  Star schema (Spark SQL dialect)

CREATE OR REPLACE TABLE dim_country AS
SELECT CAST(ROW_NUMBER() OVER (ORDER BY country) AS INT) AS country_key,
       country, iso3, wb_name, region, ladder_2024,
       CAST(RANK() OVER (ORDER BY ladder_2024 DESC) AS INT) AS rank_2024_among_panel,
       first_year, last_year, survey_years,
       CASE WHEN iso3 IS NULL THEN 0 ELSE 1 END AS has_wb_match
FROM cln_country;

CREATE OR REPLACE TABLE dim_year AS
SELECT year,
       CASE WHEN year <= 2010 THEN '1: 2005-10' WHEN year <= 2014 THEN '2: 2011-14' WHEN year <= 2019 THEN '3: 2015-19'
            ELSE '4: 2020-23' END AS period,
       CASE WHEN year BETWEEN 2020 AND 2022 THEN 1 ELSE 0 END AS is_covid_years
FROM (SELECT DISTINCT year FROM cln_happiness) y;

CREATE OR REPLACE TABLE fact_country_year AS
SELECT
  d.country_key, h.year,
  h.life_ladder, h.whr_log_gdp_pc, h.social_support, h.healthy_life_exp, h.freedom, h.generosity, h.corruption,
  h.positive_affect, h.negative_affect,
  w.gdp_usd, w.population, w.gdp_pc_usd,
  CASE WHEN w.gdp_pc_usd > 0 THEN ln(w.gdp_pc_usd) END AS ln_gdp_pc_usd,
  CASE WHEN w.gdp_pc_usd IS NULL THEN 'No WB data'
       WHEN w.gdp_pc_usd < 1500 THEN '1: < $1.5k' WHEN w.gdp_pc_usd < 5000 THEN '2: $1.5k-5k'
       WHEN w.gdp_pc_usd < 15000 THEN '3: $5k-15k' WHEN w.gdp_pc_usd < 40000 THEN '4: $15k-40k' ELSE '5: $40k+' END AS gdp_pc_band,
  h.dq_missing_factors, h.dq_ladder_out_of_range, h.dq_ratio_out_of_range,
  CASE WHEN w.gdp_pc_usd IS NULL THEN 1 ELSE 0 END AS dq_no_gdp_pc
FROM cln_happiness h
JOIN dim_country d ON h.country = d.country
LEFT JOIN cln_wb_country_year w ON d.iso3 = w.iso3 AND h.year = w.year;
