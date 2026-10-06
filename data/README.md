# data/

- `raw/` holds a **deterministic sample** of the four real source files (27,233 B), built by `scripts/make_sample.py` from the full files. Rule: every 14th WHR panel country in alphabetical order (12 countries: Afghanistan, Benin, Chile, Ecuador, Guatemala, Italy, Liberia, Mongolia, Oman, Serbia, Suriname, Ukraine) with all survey years (163 rows), their 10 rows of the WHR 2024 ranking, and the World Bank GDP (246 rows) and population (247 rows) of their ISO3 codes plus `WLD` for 2005-2023. Rows are copied verbatim with the original headers. `python run_pipeline.py --source sample` runs the whole pipeline on it (24/24 assertions pass).
- `raw_full/` (git-ignored) holds the four full files, written by `python scripts/download_full_data.py` (SHA-256 checked against the original bytes; the panel file is Latin-1 in the source and is re-encoded to UTF-8 on download).
- `clean/star/` holds the **full** cleaned star schema (`fact_country_year` 2,363 rows, `dim_country` 165, `dim_year` 19), and `clean/country_crosswalk.csv` the cleaned country master (`cln_country`: WHR name → World Bank name → ISO3, region, 2024 ladder, flags). Both are written by the full run and are small enough to commit.

| File (raw_full) | Rows | Grain | Columns |
|---|---|---|---|
| World-happiness-report-updated_2024.csv | 2,363 | country × survey year, 2005-2023, 165 countries | Country name, year, Life Ladder, Log GDP per capita, Social support, Healthy life expectancy at birth, Freedom to make life choices, Generosity, Perceptions of corruption, Positive affect, Negative affect |
| World-happiness-report-2024.csv | 143 | country (WHR 2024 ranking, 2021-23 average) | Country name, Regional indicator, Ladder score, upperwhisker, lowerwhisker, Log GDP per capita, Social support, Healthy life expectancy, Freedom to make life choices, Generosity, Perceptions of corruption, Dystopia + residual (the factor columns are "explained by" contributions) |
| gdp.csv | 13,979 | country/aggregate × year, 1960-2023, 262 codes | Country Name, Country Code, Year, Value (GDP, current US$, NY.GDP.MKTP.CD) |
| population.csv | 17,394 | country/aggregate × year, 1960-2025, 264 codes | Country Name, Country Code, Year, Value (total population, SP.POP.TOTL) |

Sources: World Happiness Report 2024 data via Kaggle `jainaru/world-happiness-report-2024-yearly-updated` (CC0); World Bank WDI via the `datasets/gdp` (CC BY 4.0) and `datasets/population` (ODC-PDDL) data packages. See the README's "Complete dataset" section.
