"""Project-specific settings used by run_pipeline.py (raw files, exports, JSON.shot content)."""
NAME = "da-learn-20-world-happiness-gdp"
DATASET = ("World Happiness Report 2024 data (Helliwell, Layard, Sachs, De Neve, Aknin & Wang; Gallup World Poll): yearly country panel "
           "2005-2023 (2,363 country-years, 165 countries) + WHR 2024 ranking (143 countries); Kaggle "
           "jainaru/world-happiness-report-2024-yearly-updated (CC0 on Kaggle). Joined to World Bank WDI GDP (NY.GDP.MKTP.CD, current US$) "
           "and population (SP.POP.TOTL) via the datasets/gdp and datasets/population GitHub packages (GDP CC BY 4.0, population ODC-PDDL; World Bank WDI source data CC BY 4.0). Total 1,299,097 B in 4 CSVs")
RAW_FILES = ["World-happiness-report-updated_2024.csv", "World-happiness-report-2024.csv", "gdp.csv", "population.csv"]
STAR = ["fact_country_year", "dim_country", "dim_year"]
METRIC_TABLES = ["a_kpi_headline", "a_country_latest", "a_ladder_by_year", "a_region_summary", "a_gdp_quintile", "a_driver_correlations",
                 "a_top_bottom_2023", "a_income_residual", "a_happiness_change", "a_growth_vs_change", "a_covid_shift"]


def export_full(con, export, root):
    """Full run: the whole star is small (2,363 fact rows), so it goes in full to data/clean/star/ and powerbi/data/."""
    for t in STAR:
        export(con, t, root / "data/clean/star" / f"{t}.csv")
        export(con, t, root / "powerbi/data" / f"{t}.csv")
    export(con, "cln_country", root / "data/clean/country_crosswalk.csv")


def build_shot(q, kpi):
    """Headline snapshot written to results/JSON.shot."""
    return {
        "config": {"sql_dialect": "Spark SQL style (+ DuckDB shims in sql/00), run on DuckDB; Databricks skipped (workspace quota)",
                   "grain": "fact_country_year = one WHR country x survey year (Gallup World Poll national average)",
                   "happiness": "life_ladder = Cantril ladder 0-10 (national average answer)",
                   "gdp": "gdp_pc_usd = World Bank GDP current US$ / World Bank population, same calendar year; WHR log GDP pc (PPP) kept alongside",
                   "latest_window": "country averages over survey years 2021-2023 (a_country_latest)",
                   "join": "WHR country name -> World Bank name (18 explicit overrides, Turkiye recoded) -> ISO3; Taiwan and Somaliland have no WB series",
                   "change_windows": "2006-10 vs 2019-23 averages, countries with >= 2 surveys in each window",
                   "sample_rule": "data/raw: every 14th panel country alphabetically with all years, their 2024 ranking rows, and their WB "
                                  "GDP/population rows 2005-2023 plus WLD (scripts/make_sample.py)"},
        "headline": kpi,
        "top5_2023": q("SELECT country, life_ladder, gdp_pc_usd FROM a_top_bottom_2023 WHERE grp = 'top 10' ORDER BY rnk LIMIT 5"),
        "bottom5_2023": q("SELECT country, life_ladder, gdp_pc_usd FROM a_top_bottom_2023 WHERE grp = 'bottom 10' ORDER BY rnk LIMIT 5"),
        "gdp_quintiles": q("SELECT gdp_quintile, countries, avg_ladder, avg_social_support FROM a_gdp_quintile ORDER BY gdp_quintile"),
        "drivers": q("SELECT factor, corr_with_ladder FROM a_driver_correlations ORDER BY corr_with_ladder DESC"),
        "growth_vs_change": q("SELECT growth_quartile, countries, avg_gdp_pc_growth_pct, avg_ladder_change FROM a_growth_vs_change ORDER BY growth_quartile"),
        "covid_shift": q("SELECT metric, countries, avg_2017_19, avg_2020_22, change FROM a_covid_shift ORDER BY metric"),
    }
