# Dashboard spec (2 pages)

Expected values are from the full data (`results/metrics.json`, `results/tables/`); `powerbi/data/` holds the full star, so they should match.

## Page 1 - Does money buy happiness?
| Visual | Fields | Expected (full data) |
|---|---|---|
| Cards | Countries, Country Years, Avg Life Ladder 2021-23, Corr Ladder vs Log GDP, World Bank Match % | 165 · 2,363 · 5.53 · 0.81 · 98.43% |
| Scatter | X = Avg GDP per Capita (log axis), Y = Avg Life Ladder, details dim_country[country], legend region, slicer dim_year[year] 2021-2023 | 140 countries with GDP; r² ≈ 0.68; +0.46 ladder per GDP doubling |
| Clustered column | fact_country_year[gdp_pc_band] × Avg Life Ladder (all country-years) | < $1.5k 4.30 · $1.5k-5k 5.03 · $5k-15k 5.64 · $15k-40k 6.24 · $40k+ 7.08 (No WB data 37 rows) |
| Bar chart | dim_country[region] × Avg Life Ladder 2021-23 | North America and ANZ 6.93 … South Asia 3.90 |
| Bar chart (diverging) | factors vs ladder: one Corr measure per factor (copy Corr Ladder vs Log GDP, swap the column) | Social support 0.72, Healthy life exp 0.71, Freedom 0.54, Corruption -0.43 |
| Table | dim_country[country], dim_country[region], Avg Life Ladder, Avg GDP per Capita, filter year = 2023, top 10 by ladder | Finland 7.699 ($53,759), Iceland 7.562, Denmark 7.504, Costa Rica 7.384 ($16,942) |

## Page 2 - Trends and change
| Visual | Fields | Expected (full data) |
|---|---|---|
| Line chart | dim_year[year] × Avg Life Ladder, Median Life Ladder, Pop-weighted Life Ladder | 2023: avg 5.621, median 5.863, pop-weighted 5.444 (138 countries) |
| Column chart | dim_year[period] × Avg Life Ladder | 2005-10 5.458 · 2011-14 5.412 · 2015-19 5.466 · 2020-23 5.615 |
| Bar chart | dim_country[country] × Ladder Change 2006-10 to 2019-23, top/bottom 10 | Serbia +1.77, Bulgaria +1.54 … Lebanon -1.92, Afghanistan -2.41 |
| Line chart | dim_year[year] × Avg Negative Affect | 0.255 (2006) → 0.293 (2023) |
| Slicers | dim_country[region], dim_year[year], dim_year[is_covid_years] | |

Note: Power BI's Ladder Change uses the simple average of all surveys in each window; the SQL table `a_happiness_change` additionally requires 2+ surveys per window (126 countries), so countries with a single survey may differ.
