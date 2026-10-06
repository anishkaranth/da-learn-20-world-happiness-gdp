# Build guide (Power BI Desktop, Windows)

No `.pbix` is committed: this repo is built on Linux and Power BI Desktop runs on Windows only.

1. Use the committed CSVs in `powerbi/data/` (3 files, ~350 KB, UTF-8): the **full** star schema (`fact_country_year` 2,363 rows, `dim_country` 165, `dim_year` 19). They are rewritten by `python run_pipeline.py --source full`.
2. Power BI Desktop > Get data > Text/CSV: load all three. In Power Query set `country`, `iso3`, `wb_name`, `region`, `period`, `gdp_pc_band` to **Text**; `country_key`, `year`, `first_year`, `last_year`, `survey_years`, `rank_2024_among_panel`, `has_wb_match`, `is_covid_years` and `dq_*` to Whole number; every other numeric column (`life_ladder`, factors, `gdp_usd`, `population`, `gdp_pc_usd`, `ln_gdp_pc_usd`, `whr_log_gdp_pc`, `ladder_2024`) to Decimal number. Empty cells load as blank (NULL), which `AVERAGE` skips, matching the SQL.
3. Model view: create the two relationships in `model.md` (single direction, many-to-one).
4. New measures: paste `measures.dax` one measure at a time into `fact_country_year`.
5. Set `dim_country[region]` data category to none, and `dim_country[iso3]` to *Country/Region* if you want a filled map.
6. Build the two pages in `dashboard_spec.md` and compare with the "Expected" column (the data is complete, so values should match exactly, up to rounding).
7. Optional: match colours to `results/images/dashboard.png`.
8. Save as `da-learn-20-world-happiness-gdp.pbix` locally (the binary is not committed).
