-- 01_staging.sql
-- Land the four raw CSVs as all-STRING staging tables with snake_case column names (no type inference; casting in 02).
-- {{RAW_DIR}} is substituted by run_pipeline.py.
-- DuckDB : read_csv(path, header = true, all_varchar = true, names = [...])
-- Spark/Databricks equivalent (not run here: Databricks skipped, workspace quota):
--   SELECT * FROM read_files('<path>/<file>.csv', format => 'csv', header => true,
--          multiLine => true, escape => '"', inferColumnTypes => false, schema => '<col> STRING, ...')
CREATE OR REPLACE TABLE stg_whr_panel AS
SELECT * FROM read_csv('{{RAW_DIR}}/World-happiness-report-updated_2024.csv', header = true, all_varchar = true, quote = '"', escape = '"',
  names = ['country_name', 'year', 'life_ladder', 'log_gdp_pc', 'social_support', 'healthy_life_exp', 'freedom', 'generosity',
           'corruption', 'positive_affect', 'negative_affect']);

CREATE OR REPLACE TABLE stg_whr_2024 AS
SELECT * FROM read_csv('{{RAW_DIR}}/World-happiness-report-2024.csv', header = true, all_varchar = true, quote = '"', escape = '"',
  names = ['country_name', 'regional_indicator', 'ladder_score', 'upperwhisker', 'lowerwhisker', 'expl_gdp', 'expl_social',
           'expl_health', 'expl_freedom', 'expl_generosity', 'expl_corruption', 'dystopia_residual']);

CREATE OR REPLACE TABLE stg_wb_gdp AS
SELECT * FROM read_csv('{{RAW_DIR}}/gdp.csv', header = true, all_varchar = true, quote = '"', escape = '"',
  names = ['country_name', 'country_code', 'year', 'value']);

CREATE OR REPLACE TABLE stg_wb_population AS
SELECT * FROM read_csv('{{RAW_DIR}}/population.csv', header = true, all_varchar = true, quote = '"', escape = '"',
  names = ['country_name', 'country_code', 'year', 'value']);
