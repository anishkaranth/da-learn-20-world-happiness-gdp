-- 02_cleaning.sql  (Spark SQL dialect; runs on DuckDB via 00_duckdb_compat.sql shims)

-- ---------------------------------------------------------------- WHR panel: country x survey year
CREATE OR REPLACE TABLE cln_happiness AS
WITH typed AS (
  SELECT
    CASE WHEN trim(country_name) IN ('Türkiye', 'Turkiye') THEN 'Turkiye' ELSE trim(country_name) END AS country,
    TRY_CAST(trim(year) AS INT)                          AS year,
    TRY_CAST(trim(life_ladder) AS DOUBLE)                AS life_ladder,
    TRY_CAST(trim(log_gdp_pc) AS DOUBLE)                 AS whr_log_gdp_pc,
    TRY_CAST(trim(social_support) AS DOUBLE)             AS social_support,
    TRY_CAST(trim(healthy_life_exp) AS DOUBLE)           AS healthy_life_exp,
    TRY_CAST(trim(freedom) AS DOUBLE)                    AS freedom,
    TRY_CAST(trim(generosity) AS DOUBLE)                 AS generosity,
    TRY_CAST(trim(corruption) AS DOUBLE)                 AS corruption,
    TRY_CAST(trim(positive_affect) AS DOUBLE)            AS positive_affect,
    TRY_CAST(trim(negative_affect) AS DOUBLE)            AS negative_affect,
    CASE WHEN trim(country_name) = 'Türkiye' THEN 1 ELSE 0 END AS dq_name_recoded
  FROM stg_whr_panel
), dedup AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY country, year ORDER BY life_ladder DESC) AS rn
  FROM typed
  WHERE country IS NOT NULL AND country <> '' AND year IS NOT NULL AND life_ladder IS NOT NULL
)
SELECT country, year, life_ladder, whr_log_gdp_pc, social_support, healthy_life_exp, freedom, generosity, corruption,
       positive_affect, negative_affect, dq_name_recoded,
       CASE WHEN life_ladder < 0 OR life_ladder > 10 THEN 1 ELSE 0 END AS dq_ladder_out_of_range,
       CASE WHEN social_support NOT BETWEEN 0 AND 1 OR freedom NOT BETWEEN 0 AND 1 OR corruption NOT BETWEEN 0 AND 1
              OR positive_affect NOT BETWEEN 0 AND 1 OR negative_affect NOT BETWEEN 0 AND 1 THEN 1 ELSE 0 END AS dq_ratio_out_of_range,
       (CASE WHEN whr_log_gdp_pc IS NULL THEN 1 ELSE 0 END + CASE WHEN social_support IS NULL THEN 1 ELSE 0 END
        + CASE WHEN healthy_life_exp IS NULL THEN 1 ELSE 0 END + CASE WHEN freedom IS NULL THEN 1 ELSE 0 END
        + CASE WHEN generosity IS NULL THEN 1 ELSE 0 END + CASE WHEN corruption IS NULL THEN 1 ELSE 0 END
        + CASE WHEN positive_affect IS NULL THEN 1 ELSE 0 END + CASE WHEN negative_affect IS NULL THEN 1 ELSE 0 END) AS dq_missing_factors
FROM dedup
WHERE rn = 1;

-- ---------------------------------------------------------------- country master: region + World Bank crosswalk
-- Region = WHR 2024 'Regional indicator'; 22 panel countries absent from the 2024 ranking get the WHR grouping explicitly.
-- World Bank name = WHR name unless overridden below (18 overrides; Turkiye is recoded above; Taiwan + Somaliland have no WB series).
CREATE OR REPLACE TABLE cln_country AS
WITH c AS (
  SELECT country, MIN(year) AS first_year, MAX(year) AS last_year, COUNT(*) AS survey_years
  FROM cln_happiness GROUP BY country
), r AS (
  SELECT CASE WHEN trim(country_name) IN ('Türkiye', 'Turkiye') THEN 'Turkiye' ELSE trim(country_name) END AS country,
         trim(regional_indicator) AS region,
         TRY_CAST(trim(ladder_score) AS DOUBLE) AS ladder_2024
  FROM stg_whr_2024
), x AS (
  SELECT c.*, r.region AS region_2024, r.ladder_2024,
    CASE c.country
      WHEN 'Congo (Brazzaville)' THEN 'Congo, Rep.'
      WHEN 'Congo (Kinshasa)' THEN 'Congo, Dem. Rep.'
      WHEN 'Egypt' THEN 'Egypt, Arab Rep.'
      WHEN 'Gambia' THEN 'Gambia, The'
      WHEN 'Hong Kong S.A.R. of China' THEN 'Hong Kong SAR, China'
      WHEN 'Iran' THEN 'Iran, Islamic Rep.'
      WHEN 'Ivory Coast' THEN 'Cote d''Ivoire'
      WHEN 'Kyrgyzstan' THEN 'Kyrgyz Republic'
      WHEN 'Laos' THEN 'Lao PDR'
      WHEN 'Russia' THEN 'Russian Federation'
      WHEN 'Slovakia' THEN 'Slovak Republic'
      WHEN 'Somalia' THEN 'Somalia, Fed. Rep.'
      WHEN 'South Korea' THEN 'Korea, Rep.'
      WHEN 'State of Palestine' THEN 'West Bank and Gaza'
      WHEN 'Syria' THEN 'Syrian Arab Republic'
      WHEN 'Venezuela' THEN 'Venezuela, RB'
      WHEN 'Vietnam' THEN 'Viet Nam'
      WHEN 'Yemen' THEN 'Yemen, Rep.'
      ELSE c.country END AS wb_name,
    CASE WHEN c.country IN ('Congo (Brazzaville)', 'Congo (Kinshasa)', 'Egypt', 'Gambia', 'Hong Kong S.A.R. of China', 'Iran', 'Ivory Coast',
                            'Kyrgyzstan', 'Laos', 'Russia', 'Slovakia', 'Somalia', 'South Korea', 'State of Palestine', 'Syria',
                            'Venezuela', 'Vietnam', 'Yemen') THEN 1 ELSE 0 END AS dq_name_override
  FROM c LEFT JOIN r ON c.country = r.country
), wb AS (
  SELECT DISTINCT trim(country_name) AS wb_name, trim(country_code) AS iso3 FROM stg_wb_population
)
SELECT x.country, w.iso3, x.wb_name,
  COALESCE(x.region_2024,
    CASE WHEN x.country IN ('Angola', 'Burundi', 'Central African Republic', 'Djibouti', 'Rwanda', 'Somalia', 'Somaliland region',
                            'South Sudan', 'Sudan') THEN 'Sub-Saharan Africa'
         WHEN x.country IN ('Belize', 'Cuba', 'Guyana', 'Haiti', 'Suriname', 'Trinidad and Tobago') THEN 'Latin America and Caribbean'
         WHEN x.country IN ('Belarus', 'Turkmenistan') THEN 'Commonwealth of Independent States'
         WHEN x.country IN ('Bhutan', 'Maldives') THEN 'South Asia'
         WHEN x.country IN ('Oman', 'Qatar', 'Syria') THEN 'Middle East and North Africa'
    END) AS region,
  x.ladder_2024, x.first_year, x.last_year, x.survey_years,
  CASE WHEN x.region_2024 IS NULL THEN 1 ELSE 0 END AS dq_region_fallback,
  x.dq_name_override,
  CASE WHEN w.iso3 IS NULL THEN 1 ELSE 0 END AS dq_no_wb_match
FROM x LEFT JOIN wb w ON x.wb_name = w.wb_name;

-- ---------------------------------------------------------------- World Bank GDP + population (country x year)
CREATE OR REPLACE TABLE cln_wb_country_year AS
WITH g AS (
  SELECT trim(country_code) AS iso3, TRY_CAST(trim(year) AS INT) AS year, TRY_CAST(trim(value) AS DOUBLE) AS gdp_usd
  FROM stg_wb_gdp
), p AS (
  SELECT trim(country_code) AS iso3, TRY_CAST(trim(year) AS INT) AS year, TRY_CAST(trim(value) AS DOUBLE) AS population
  FROM stg_wb_population
), j AS (
  SELECT COALESCE(g.iso3, p.iso3) AS iso3, COALESCE(g.year, p.year) AS year, g.gdp_usd, p.population
  FROM g FULL OUTER JOIN p ON g.iso3 = p.iso3 AND g.year = p.year
)
SELECT iso3, year, gdp_usd, population,
       CASE WHEN gdp_usd > 0 AND population > 0 THEN gdp_usd / population END AS gdp_pc_usd,
       CASE WHEN gdp_usd IS NULL THEN 1 ELSE 0 END AS dq_missing_gdp,
       CASE WHEN population IS NULL THEN 1 ELSE 0 END AS dq_missing_population
FROM j
WHERE iso3 IS NOT NULL AND year IS NOT NULL;
