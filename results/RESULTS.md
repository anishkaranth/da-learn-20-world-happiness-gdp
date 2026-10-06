# Results - da-learn-20 World happiness vs GDP

Run: `python run_pipeline.py --source full` on DuckDB 1.5.6 (local, full data: 2,363 raw World Happiness Report panel rows → 2,363 clean country-years for 165 countries, survey years 2005-2023, joined to 13,979 World Bank GDP rows and 17,394 population rows). Databricks was skipped because the workspace hit its resource quota, so there is no live dashboard; every number below is in `metrics.json` and `tables/`, and every chart is in `images/` (SVG + PNG). **Life ladder = national average answer to the Cantril ladder question (0 = worst possible life, 10 = best). GDP per capita = World Bank GDP (current US$) / World Bank population for the same year.** "Latest" = each country's average over survey years 2021-2023. Quality checks: **24/24 assertions pass**.

![Dashboard](images/dashboard.png)

## Headline KPIs
| KPI | Value |
|---|---|
| Countries / country-years / survey years | 165 / 2,363 / 2005-2023 |
| Country-years matched to World Bank GDP per capita | 98.43% |
| Countries with a 2021-23 survey | 143 |
| Average life ladder 2021-23 (simple / population-weighted) | 5.528 / 5.266 |
| Highest / lowest 2021-23 country average | 7.741 / 1.721 |
| Correlation ladder vs ln(GDP per capita), all country-years | 0.8109 (linear GDP: 0.7044) |
| R² of ladder on ln(GDP per capita), 2021-23 | 0.679 |
| Ladder gain per doubling of GDP per capita | +0.459 |
| Richest minus poorest GDP quintile (2021-23) | +2.610 |

## Insights
1. **Money and happiness move together, on a log scale.** Across all 2,363 country-years the life ladder correlates **0.81** with log GDP per capita but only 0.70 with GDP per capita in dollars. In 2021-23, log income alone explains **68%** of the cross-country variation and each doubling of GDP per capita goes with **+0.46** ladder points. The richest fifth of countries ($31,509+) average **6.84**, the poorest fifth (under $1,687) **4.24**, a 2.61-point gap; the step from Q2 to Q3 (+0.92) is larger than from Q4 to Q5 (+0.63).
2. **Social support and health matter almost as much as income.** Pooled correlations with the ladder: social support 0.72, healthy life expectancy 0.71, freedom to make life choices 0.54, perceived corruption -0.43, generosity only 0.18. The richest quintile stands out less on social support (0.897 vs 0.887 in Q4) than on low perceived corruption (0.459 vs 0.788).
3. **Some countries are far happier, or unhappier, than their income predicts.** Against the 2021-23 fit, Nicaragua ($2,356 per head, ladder 6.28) beats its prediction by **+1.49**, followed by Uzbekistan (+1.42) and Mozambique (+1.36); 7 of the top 10 over-performers are in Latin America or the CIS (Central Asia). At the other end, Lebanon (-2.41), Botswana (-2.23) and Afghanistan (-1.82) sit far below the line, and rich Hong Kong is -1.49. In 2023 Costa Rica ranks #4 (7.38) with a GDP per capita of $16,942, about a third of Finland's ($53,759, #1 at 7.70).
4. **Over time, faster-growing economies got happier.** For 122 countries surveyed in both 2006-10 and 2019-23, the slowest-growing quartile (real GDP per capita +0.4%) lost **-0.248** ladder points on average and only 29% got happier, while the fastest quartile (+66.2%) gained **+0.495** (73% happier). The biggest gains were in Central and Eastern Europe (Serbia +1.77, Bulgaria +1.54, Latvia +1.38); the biggest falls in Afghanistan (-2.41), Lebanon (-1.92) and Venezuela (-1.57). Growth is not enough on its own: India grew +79.9% and still fell -1.08.
5. **Regions: a 3-point spread.** North America and ANZ (6.93) and Western Europe (6.84) lead; Latin America (6.14) matches Central and Eastern Europe (6.17) at about half the GDP per capita ($9,091 vs $17,418). Sub-Saharan Africa (4.33) and South Asia (3.90, home to 1,931M people in the 6 surveyed countries) are lowest, which is why the population-weighted world average (5.27) is below the simple country average (5.53).
6. **The pandemic barely dented life evaluations.** For the same 143 countries, the average ladder moved from 5.546 (2017-19) to 5.501 (2020-22), -0.046; negative affect rose +0.013, social support slipped -0.018, and generosity rose +0.044.

## Does money buy happiness? (2021-23 country averages)
| gdp_quintile | countries | min_gdp_pc_usd | max_gdp_pc_usd | avg_ladder | avg_social_support | avg_healthy_life_exp | avg_freedom | avg_corruption |
|---|---|---|---|---|---|---|---|---|
| Q1 poorest | 28 | 357 | 1,687 | 4.235 | 0.638 | 57.5 | 0.706 | 0.764 |
| Q2 | 28 | 1,708 | 4,398 | 4.733 | 0.718 | 62.1 | 0.76 | 0.777 |
| Q3 | 28 | 4,561 | 10,280 | 5.649 | 0.818 | 65.1 | 0.793 | 0.803 |
| Q4 | 28 | 10,933 | 30,944 | 6.21 | 0.887 | 68.6 | 0.8 | 0.788 |
| Q5 richest | 28 | 31,509 | 126,842 | 6.845 | 0.897 | 71.2 | 0.857 | 0.459 |

![Ladder vs GDP](images/ladder_vs_gdp_scatter.png)
![GDP quintiles](images/gdp_quintile.png)

## Drivers (pooled country-years 2005-2023)
| factor | corr_with_ladder | n_obs |
|---|---|---|
| Log GDP per capita (World Bank, US$) | 0.811 | 2,326 |
| Log GDP per capita (WHR, PPP) | 0.784 | 2,335 |
| Social support | 0.723 | 2,350 |
| Healthy life expectancy | 0.715 | 2,300 |
| Freedom to make life choices | 0.538 | 2,327 |
| Positive affect | 0.515 | 2,339 |
| Generosity | 0.177 | 2,282 |
| Negative affect | -0.352 | 2,347 |
| Perceived corruption | -0.43 | 2,238 |

![Drivers](images/drivers.png)

## Regions (2021-23)
| region | countries | avg_ladder | min_ladder | max_ladder | pop_weighted_ladder | avg_gdp_pc_usd | population_m | avg_social_support | avg_healthy_life_exp |
|---|---|---|---|---|---|---|---|---|---|
| North America and ANZ | 4 | 6.927 | 6.724 | 7.057 | 6.766 | 60,701 | 404.6 | 0.92 | 69.7 |
| Western Europe | 20 | 6.842 | 5.933 | 7.741 | 6.671 | 57,708 | 429.6 | 0.903 | 71.7 |
| Central and Eastern Europe | 17 | 6.171 | 5.304 | 6.821 | 6.322 | 17,418 | 116.7 | 0.892 | 68.2 |
| Latin America and Caribbean | 19 | 6.143 | 5.607 | 6.956 | 6.219 | 9,091 | 622.6 | 0.843 | 66.8 |
| East Asia | 6 | 5.94 | 5.317 | 6.503 | 6.006 | 27,301 | 1,599.2 | 0.856 | 69.5 |
| Southeast Asia | 9 | 5.551 | 4.342 | 6.525 | 5.659 | 13,338 | 683.2 | 0.794 | 64.9 |
| Commonwealth of Independent States | 10 | 5.539 | 4.873 | 6.195 | 5.667 | 6,147 | 276.8 | 0.842 | 65.4 |
| Middle East and North Africa | 17 | 5.201 | 2.706 | 7.341 | 4.846 | 15,741 | 552 | 0.779 | 66.1 |
| Sub-Saharan Africa | 35 | 4.33 | 3.186 | 5.816 | 4.363 | 2,234 | 1,078.9 | 0.657 | 56.9 |
| South Asia | 6 | 3.895 | 1.721 | 5.162 | 4.082 | 1,968 | 1,931.4 | 0.588 | 61.3 |

![Regions](images/region_ladder.png)

## Happiest and least happy countries, 2023
| grp | rnk | country | region | life_ladder | gdp_pc_usd |
|---|---|---|---|---|---|
| top 10 | 1 | Finland | Western Europe | 7.699 | 53,759 |
| top 10 | 2 | Iceland | Western Europe | 7.562 | 80,433 |
| top 10 | 3 | Denmark | Western Europe | 7.504 | 67,967 |
| top 10 | 4 | Costa Rica | Latin America and Caribbean | 7.384 | 16,942 |
| top 10 | 5 | Netherlands | Western Europe | 7.255 | 62,545 |
| top 10 | 6 | Norway | Western Europe | 7.249 | 87,962 |
| top 10 | 7 | Sweden | Western Europe | 7.161 | 56,305 |
| top 10 | 8 | Kuwait | Middle East and North Africa | 7.13 | 33,332 |
| top 10 | 9 | Australia | North America and ANZ | 7.025 | 64,660 |
| top 10 | 10 | Luxembourg | Western Europe | 7.016 | 128,678 |
| bottom 10 | 1 | Afghanistan | South Asia | 1.446 |  |
| bottom 10 | 2 | Malawi | Sub-Saharan Africa | 3.272 | 667 |
| bottom 10 | 3 | Botswana | Sub-Saharan Africa | 3.332 | 7,820 |
| bottom 10 | 4 | Congo (Kinshasa) | Sub-Saharan Africa | 3.383 | 628 |
| bottom 10 | 5 | Sierra Leone | Sub-Saharan Africa | 3.467 | 450 |
| bottom 10 | 6 | Yemen | Middle East and North Africa | 3.532 |  |
| bottom 10 | 7 | Zimbabwe | Sub-Saharan Africa | 3.572 | 1,624 |
| bottom 10 | 8 | Comoros | Sub-Saharan Africa | 3.588 | 1,590 |
| bottom 10 | 9 | Lebanon | Middle East and North Africa | 3.588 |  |
| bottom 10 | 10 | Sri Lanka | South Asia | 3.602 | 3,828 |

GDP per capita is blank where the World Bank has no 2023 value (Afghanistan, Yemen and Lebanon in this table).

![Top and bottom 2023](images/top_bottom_2023.png)

## Happier or less happy than income predicts (2021-23, fit: ladder ~ ln GDP per capita)
| residual_rank | country | region | gdp_pc_usd | life_ladder | predicted_ladder | residual |
|---|---|---|---|---|---|---|
| 1 | Nicaragua | Latin America and Caribbean | 2,356 | 6.283 | 4.795 | 1.488 |
| 2 | Uzbekistan | Commonwealth of Independent States | 2,301 | 6.195 | 4.779 | 1.416 |
| 3 | Mozambique | Sub-Saharan Africa | 562 | 5.207 | 3.846 | 1.361 |
| 4 | Kosovo | Central and Eastern Europe | 5,588 | 6.562 | 5.366 | 1.196 |
| 5 | El Salvador | Latin America and Caribbean | 5,042 | 6.468 | 5.298 | 1.17 |
| 6 | Kyrgyzstan | Commonwealth of Independent States | 1,687 | 5.714 | 4.573 | 1.141 |
| 7 | Tajikistan | Commonwealth of Independent States | 1,037 | 5.281 | 4.251 | 1.03 |
| 8 | Honduras | Latin America and Caribbean | 2,990 | 5.969 | 4.952 | 1.017 |
| 9 | Philippines | Southeast Asia | 3,612 | 6.048 | 5.078 | 0.97 |
| 10 | Costa Rica | Latin America and Caribbean | 14,469 | 6.956 | 5.996 | 0.96 |
| 131 | Jordan | Middle East and North Africa | 4,316 | 4.186 | 5.195 | -1.009 |
| 132 | Lesotho | Sub-Saharan Africa | 1,001 | 3.186 | 4.228 | -1.042 |
| 133 | Egypt | Middle East and North Africa | 3,839 | 3.977 | 5.118 | -1.141 |
| 134 | Sri Lanka | South Asia | 3,723 | 3.897 | 5.098 | -1.201 |
| 135 | Zimbabwe | Sub-Saharan Africa | 1,708 | 3.341 | 4.582 | -1.241 |
| 136 | Hong Kong S.A.R. of China | East Asia | 49,299 | 5.317 | 6.808 | -1.491 |
| 137 | Eswatini | Sub-Saharan Africa | 3,930 | 3.502 | 5.133 | -1.631 |
| 138 | Afghanistan | South Asia | 357 | 1.721 | 3.545 | -1.824 |
| 139 | Botswana | Sub-Saharan Africa | 8,075 | 3.383 | 5.61 | -2.227 |
| 140 | Lebanon | Middle East and North Africa | 3,850 | 2.706 | 5.12 | -2.414 |

![Income residual](images/income_residual.png)

## Change over time (2006-10 average vs 2019-23 average)
| change_rank | country | region | early_ladder | late_ladder | ladder_change | gdp_pc_ppp_growth_pct |
|---|---|---|---|---|---|---|
| 1 | Serbia | Central and Eastern Europe | 4.53 | 6.303 | 1.773 | 37.6 |
| 2 | Bulgaria | Central and Eastern Europe | 3.878 | 5.419 | 1.541 | 42.3 |
| 3 | Latvia | Central and Eastern Europe | 4.798 | 6.181 | 1.383 | 34.5 |
| 4 | Romania | Central and Eastern Europe | 5.224 | 6.478 | 1.254 | 52.7 |
| 5 | Georgia | Commonwealth of Independent States | 3.888 | 5.114 | 1.226 | 74.4 |
| 6 | Togo | Sub-Saharan Africa | 3.005 | 4.205 | 1.2 | 42.7 |
| 7 | Mongolia | East Asia | 4.563 | 5.733 | 1.17 | 67.1 |
| 8 | Hungary | Central and Eastern Europe | 4.858 | 6.018 | 1.16 | 35.9 |
| 9 | Nicaragua | Latin America and Caribbean | 5.11 | 6.25 | 1.14 | 23.3 |
| 10 | Philippines | Southeast Asia | 4.831 | 5.898 | 1.067 | 51.8 |
| 117 | Yemen | Middle East and North Africa | 4.545 | 3.773 | -0.772 |  |
| 118 | Egypt | Middle East and North Africa | 4.977 | 4.146 | -0.831 | 25.5 |
| 119 | Zambia | Sub-Saharan Africa | 4.703 | 3.728 | -0.975 | 21.8 |
| 120 | India | South Asia | 5.006 | 3.927 | -1.079 | 79.9 |
| 121 | Malawi | Sub-Saharan Africa | 4.623 | 3.533 | -1.09 | 23.6 |
| 122 | Botswana | Sub-Saharan Africa | 4.581 | 3.413 | -1.168 | 16.7 |
| 123 | Jordan | Middle East and North Africa | 5.525 | 4.221 | -1.304 | -19.3 |
| 124 | Venezuela | Latin America and Caribbean | 6.863 | 5.295 | -1.567 |  |
| 125 | Lebanon | Middle East and North Africa | 4.872 | 2.955 | -1.916 | -18 |
| 126 | Afghanistan | South Asia | 4.295 | 1.884 | -2.41 | -0.8 |

By real GDP-per-capita growth quartile:

| growth_quartile | countries | avg_gdp_pc_growth_pct | avg_ladder_change | pct_countries_happier |
|---|---|---|---|---|
| G1 slowest | 31 | 0.4 | -0.248 | 29 |
| G2 | 31 | 17.2 | 0.076 | 54.8 |
| G3 | 30 | 33 | 0.392 | 80 |
| G4 fastest | 30 | 66.2 | 0.495 | 73.3 |

![Happiness change](images/happiness_change.png)
![Growth vs change](images/growth_vs_change.png)

## Trend by survey year
| year | countries | avg_ladder | median_ladder | pop_weighted_ladder | avg_negative_affect | avg_positive_affect |
|---|---|---|---|---|---|---|
| 2,005 | 27 | 6.446 | 6.62 | 6.241 | 0.256 | 0.672 |
| 2,006 | 89 | 5.197 | 5.084 | 5.099 | 0.255 | 0.661 |
| 2,007 | 102 | 5.418 | 5.222 | 5.395 | 0.25 | 0.652 |
| 2,008 | 110 | 5.419 | 5.182 | 5.356 | 0.244 | 0.653 |
| 2,009 | 114 | 5.458 | 5.361 | 5.173 | 0.247 | 0.643 |
| 2,010 | 124 | 5.497 | 5.461 | 5.349 | 0.241 | 0.647 |
| 2,011 | 146 | 5.424 | 5.224 | 5.346 | 0.249 | 0.637 |
| 2,012 | 141 | 5.444 | 5.309 | 5.322 | 0.259 | 0.641 |
| 2,013 | 136 | 5.393 | 5.245 | 5.25 | 0.27 | 0.655 |
| 2,014 | 144 | 5.386 | 5.323 | 5.299 | 0.27 | 0.656 |
| 2,015 | 142 | 5.401 | 5.331 | 5.21 | 0.278 | 0.658 |
| 2,016 | 141 | 5.396 | 5.417 | 5.207 | 0.285 | 0.656 |
| 2,017 | 147 | 5.46 | 5.553 | 5.142 | 0.291 | 0.648 |
| 2,018 | 141 | 5.499 | 5.465 | 5.124 | 0.293 | 0.653 |
| 2,019 | 143 | 5.571 | 5.626 | 5.013 | 0.287 | 0.655 |
| 2,020 | 116 | 5.728 | 5.77 | 5.348 | 0.302 | 0.664 |
| 2,021 | 122 | 5.636 | 5.781 | 5.162 | 0.29 | 0.653 |
| 2,022 | 140 | 5.499 | 5.797 | 5.087 | 0.295 | 0.651 |
| 2,023 | 138 | 5.621 | 5.863 | 5.444 | 0.293 | 0.652 |

2005 covers only 27 (mostly high-income) countries, so the chart starts in 2006. The set of surveyed countries changes every year, so year-to-year moves mix real change with coverage.

![Ladder by year](images/ladder_by_year.png)

## Pandemic shift (same countries, 2017-19 vs 2020-22)
| metric | countries | avg_2017_19 | avg_2020_22 | change |
|---|---|---|---|---|
| Generosity | 139 | -0.024 | 0.021 | 0.044 |
| Life ladder | 143 | 5.546 | 5.501 | -0.046 |
| Negative affect | 143 | 0.289 | 0.302 | 0.013 |
| Positive affect | 143 | 0.654 | 0.654 | 0 |
| Social support | 143 | 0.815 | 0.797 | -0.018 |

![Covid shift](images/covid_shift.png)

## Data quality (before → after)
| entity | raw_rows | distinct_keys | clean_rows | grain |
|---|---|---|---|---|
| dim_country |  |  | 165 | WHR country |
| dim_year |  |  | 19 | survey year |
| fact_country_year |  |  | 2,363 | country x survey year |
| wb_gdp | 13,979 | 13,979 | 13,979 | country/aggregate x year |
| wb_population | 17,394 | 17,394 | 17,394 | country/aggregate x year |
| whr_2024_ranking | 143 | 143 | 143 | country (2024 ranking, matched to panel) |
| whr_panel | 2,363 | 2,363 | 2,363 | country x survey year |

Issue counts:

| check_name | affected_rows |
|---|---|
| whr_panel: rows with >= 1 missing factor (kept) | 266 |
| fact: country-years without World Bank GDP per capita | 37 |
| wb: WHR-country years 2005-2023 with population but no GDP | 37 |
| country: region not in WHR 2024 ranking (explicit fallback) | 22 |
| country: WHR -> World Bank name overrides applied | 18 |
| whr_panel: country name recoded (Türkiye -> Turkiye) | 18 |
| country: no World Bank series (Taiwan, Somaliland) | 2 |
| RI: fact rows lost in dim joins | 0 |
| country: WHR 2024 ranking rows not in panel | 0 |
| whr_panel: duplicate country x year rows dropped | 0 |
| whr_panel: ladder outside 0..10 | 0 |
| whr_panel: ratio factor outside 0..1 | 0 |

Null rates (kept as NULL, excluded from averages and correlations):

| entity | column_name | null_pct | treatment |
|---|---|---|---|
| fact_country_year | gdp_pc_usd (World Bank) | 1.566 | no WB match or no GDP that year |
| whr_panel | Freedom to make life choices | 1.523 | kept NULL |
| whr_panel | Generosity | 3.428 | kept NULL |
| whr_panel | Healthy life expectancy | 2.666 | kept NULL |
| whr_panel | Log GDP per capita | 1.185 | kept NULL; WB GDP used instead |
| whr_panel | Negative affect | 0.677 | kept NULL |
| whr_panel | Perceptions of corruption | 5.29 | kept NULL |
| whr_panel | Positive affect | 1.016 | kept NULL |
| whr_panel | Social support | 0.55 | kept NULL (excluded from AVG/corr) |

Assertions (24/24 PASS):

| check_name | failed_rows | status |
|---|---|---|
| GDP per capita > 0 where present | 0 | PASS |
| GDP quintiles cover all latest countries with GDP | 0 | PASS |
| WB and WHR log GDP agree (corr >= 0.9) | 0 | PASS |
| World Bank (iso3, year) unique | 0 | PASS |
| World Bank match >= 95% of country-years | 0 | PASS |
| clean panel rows = distinct valid (country, year) keys in staging | 0 | PASS |
| dim_country.country unique | 0 | PASS |
| dim_country.iso3 unique where present | 0 | PASS |
| every WHR 2024 ranking country found in panel | 0 | PASS |
| every country has a region | 0 | PASS |
| fact (country_key, year) unique | 0 | PASS |
| fact rows = cleaned panel rows (no fan-out / loss in joins) | 0 | PASS |
| fact.country_key -> dim_country | 0 | PASS |
| fact.year -> dim_year | 0 | PASS |
| gdp_pc_usd = gdp_usd / population | 0 | PASS |
| healthy life expectancy within 0..100 | 0 | PASS |
| latest-window countries all have 2021-23 surveys | 0 | PASS |
| life ladder within 0..10 | 0 | PASS |
| no NULL country / year / life ladder in fact | 0 | PASS |
| only Taiwan + Somaliland lack a World Bank code | 0 | PASS |
| population > 0 where present | 0 | PASS |
| positive ladder-GDP correlation (sanity) | 0 | PASS |
| ratio factors within 0..1 | 0 | PASS |
| survey years within 2005..2023 | 0 | PASS |

![Data quality](images/data_quality.png)

## How the images were made
Every chart is drawn by `scripts/make_charts.py` from the CSVs in `results/tables/` as a plain-vector SVG (rect, line, polyline, circle and text only, via `scripts/svgcharts.py`), then rasterised to PNG at 2x by `scripts/render_png.py` with headless Chrome. `images/dashboard.svg` tiles seven KPI cards and six panels into one page.
