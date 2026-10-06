#!/usr/bin/env python3
"""Write results/RESULTS.md from results/metrics.json + results/tables/*.csv (every number comes from the full-data run)."""
import csv, json, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
RES = ROOT / "results"
T = RES / "tables"


def rd(name):
    with open(T / f"{name}.csv", newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def f(x):
    return float(x) if x not in ("", None) else 0.0


def num(v):
    if v in ("", None):
        return ""
    try:
        x = float(v)
    except ValueError:
        return str(v)
    return f"{int(x):,}" if x.is_integer() and abs(x) >= 1000 else (str(int(x)) if x.is_integer() else f"{x:,.3f}".rstrip("0").rstrip("."))


def table(rows, cols, heads=None):
    out = ["| " + " | ".join(heads or cols) + " |", "|" + "---|" * len(cols)]
    for r in rows:
        out.append("| " + " | ".join(num(r[c]) for c in cols) + " |")
    return "\n".join(out)


def usd(v):
    return f"${f(v):,.0f}"


m = json.loads((RES / "metrics.json").read_text())
k = m["kpis"]
yr = sorted(rd("a_ladder_by_year"), key=lambda r: int(r["year"]))
yd = {r["year"]: r for r in yr}
reg = sorted(rd("a_region_summary"), key=lambda r: -f(r["avg_ladder"]))
rg = {r["region"]: r for r in reg}
q = sorted(rd("a_gdp_quintile"), key=lambda r: r["gdp_quintile"])
drv = sorted(rd("a_driver_correlations"), key=lambda r: -f(r["corr_with_ladder"]))
dv = {r["factor"]: r for r in drv}
tb = rd("a_top_bottom_2023")
top = sorted([r for r in tb if r["grp"] == "top 10"], key=lambda r: int(r["rnk"]))
bot = sorted([r for r in tb if r["grp"] == "bottom 10"], key=lambda r: int(r["rnk"]))
res = sorted(rd("a_income_residual"), key=lambda r: int(r["residual_rank"]))
rs = {r["country"]: r for r in res}
chg = sorted(rd("a_happiness_change"), key=lambda r: int(r["change_rank"]))
cg = {r["country"]: r for r in chg}
gvc = sorted(rd("a_growth_vs_change"), key=lambda r: r["growth_quartile"])
cov = {r["metric"]: r for r in rd("a_covid_shift")}
lat = {r["country"]: r for r in rd("a_country_latest")}
rc = rd("dq_row_counts")
rcd = {r["entity"]: r for r in rc}
iss = sorted(rd("dq_issues"), key=lambda r: -f(r["affected_rows"]))
asr = sorted(rd("dq_assertions"), key=lambda r: r["check_name"])
npass = sum(1 for r in asr if r["status"] == "PASS")
ten = lambda rows, n=10: rows[:n] + rows[-n:]

md = f"""# Results - da-learn-20 World happiness vs GDP

Run: `python run_pipeline.py --source full` on DuckDB {m['engine']['duckdb']} (local, full data: {int(f(rcd['whr_panel']['raw_rows'])):,} raw World Happiness Report panel rows → {int(f(k['country_years'])):,} clean country-years for {int(f(k['countries']))} countries, survey years {k['first_year']}-{k['last_year']}, joined to {int(f(rcd['wb_gdp']['raw_rows'])):,} World Bank GDP rows and {int(f(rcd['wb_population']['raw_rows'])):,} population rows). Databricks was skipped because the workspace hit its resource quota, so there is no live dashboard; every number below is in `metrics.json` and `tables/`, and every chart is in `images/` (SVG + PNG). **Life ladder = national average answer to the Cantril ladder question (0 = worst possible life, 10 = best). GDP per capita = World Bank GDP (current US$) / World Bank population for the same year.** "Latest" = each country's average over survey years 2021-2023. Quality checks: **{npass}/{len(asr)} assertions pass**.

![Dashboard](images/dashboard.png)

## Headline KPIs
| KPI | Value |
|---|---|
| Countries / country-years / survey years | {int(f(k['countries']))} / {int(f(k['country_years'])):,} / {k['first_year']}-{k['last_year']} |
| Country-years matched to World Bank GDP per capita | {f(k['wb_match_pct']):.2f}% |
| Countries with a 2021-23 survey | {int(f(k['countries_latest']))} |
| Average life ladder 2021-23 (simple / population-weighted) | {f(k['avg_ladder_latest']):.3f} / {f(k['pop_weighted_ladder_latest']):.3f} |
| Highest / lowest 2021-23 country average | {f(k['max_ladder_latest']):.3f} / {f(k['min_ladder_latest']):.3f} |
| Correlation ladder vs ln(GDP per capita), all country-years | {f(k['corr_ladder_log_gdp_pc']):.4f} (linear GDP: {f(k['corr_ladder_gdp_pc_linear']):.4f}) |
| R² of ladder on ln(GDP per capita), 2021-23 | {f(k['r2_ladder_on_log_gdp_latest']):.3f} |
| Ladder gain per doubling of GDP per capita | +{f(k['ladder_gain_per_gdp_doubling']):.3f} |
| Richest minus poorest GDP quintile (2021-23) | +{f(k['ladder_gap_top_bottom_quintile']):.3f} |

## Insights
1. **Money and happiness move together, on a log scale.** Across all {int(f(k['country_years'])):,} country-years the life ladder correlates **{f(k['corr_ladder_log_gdp_pc']):.2f}** with log GDP per capita but only {f(k['corr_ladder_gdp_pc_linear']):.2f} with GDP per capita in dollars. In 2021-23, log income alone explains **{f(k['r2_ladder_on_log_gdp_latest']) * 100:.0f}%** of the cross-country variation and each doubling of GDP per capita goes with **+{f(k['ladder_gain_per_gdp_doubling']):.2f}** ladder points. The richest fifth of countries ({usd(q[-1]['min_gdp_pc_usd'])}+) average **{f(q[-1]['avg_ladder']):.2f}**, the poorest fifth (under {usd(q[0]['max_gdp_pc_usd'])}) **{f(q[0]['avg_ladder']):.2f}**, a {f(k['ladder_gap_top_bottom_quintile']):.2f}-point gap; the step from Q2 to Q3 (+{f(q[2]['avg_ladder']) - f(q[1]['avg_ladder']):.2f}) is larger than from Q4 to Q5 (+{f(q[4]['avg_ladder']) - f(q[3]['avg_ladder']):.2f}).
2. **Social support and health matter almost as much as income.** Pooled correlations with the ladder: social support {f(dv['Social support']['corr_with_ladder']):.2f}, healthy life expectancy {f(dv['Healthy life expectancy']['corr_with_ladder']):.2f}, freedom to make life choices {f(dv['Freedom to make life choices']['corr_with_ladder']):.2f}, perceived corruption {f(dv['Perceived corruption']['corr_with_ladder']):.2f}, generosity only {f(dv['Generosity']['corr_with_ladder']):.2f}. The richest quintile stands out less on social support ({f(q[-1]['avg_social_support']):.3f} vs {f(q[3]['avg_social_support']):.3f} in Q4) than on low perceived corruption ({f(q[-1]['avg_corruption']):.3f} vs {f(q[3]['avg_corruption']):.3f}).
3. **Some countries are far happier, or unhappier, than their income predicts.** Against the 2021-23 fit, {res[0]['country']} ({usd(res[0]['gdp_pc_usd'])} per head, ladder {f(res[0]['life_ladder']):.2f}) beats its prediction by **{f(res[0]['residual']):+.2f}**, followed by {res[1]['country']} ({f(res[1]['residual']):+.2f}) and {res[2]['country']} ({f(res[2]['residual']):+.2f}); {sum(r['region'] in ('Latin America and Caribbean', 'Commonwealth of Independent States') for r in res[:10])} of the top 10 over-performers are in Latin America or the CIS (Central Asia). At the other end, {res[-1]['country']} ({f(res[-1]['residual']):+.2f}), {res[-2]['country']} ({f(res[-2]['residual']):+.2f}) and {res[-3]['country']} ({f(res[-3]['residual']):+.2f}) sit far below the line, and rich Hong Kong is {f(rs['Hong Kong S.A.R. of China']['residual']):+.2f}. In 2023 Costa Rica ranks #{next(r['rnk'] for r in top if r['country'] == 'Costa Rica')} ({f(next(r for r in top if r['country'] == 'Costa Rica')['life_ladder']):.2f}) with a GDP per capita of {usd(next(r for r in top if r['country'] == 'Costa Rica')['gdp_pc_usd'])}, about a third of Finland's ({usd(top[0]['gdp_pc_usd'])}, #1 at {f(top[0]['life_ladder']):.2f}).
4. **Over time, faster-growing economies got happier.** For {sum(int(r['countries']) for r in gvc)} countries surveyed in both 2006-10 and 2019-23, the slowest-growing quartile (real GDP per capita {f(gvc[0]['avg_gdp_pc_growth_pct']):+.1f}%) lost **{f(gvc[0]['avg_ladder_change']):+.3f}** ladder points on average and only {f(gvc[0]['pct_countries_happier']):.0f}% got happier, while the fastest quartile ({f(gvc[3]['avg_gdp_pc_growth_pct']):+.1f}%) gained **{f(gvc[3]['avg_ladder_change']):+.3f}** ({f(gvc[3]['pct_countries_happier']):.0f}% happier). The biggest gains were in {chg[0]['region']} ({chg[0]['country']} {f(chg[0]['ladder_change']):+.2f}, {chg[1]['country']} {f(chg[1]['ladder_change']):+.2f}, {chg[2]['country']} {f(chg[2]['ladder_change']):+.2f}); the biggest falls in {chg[-1]['country']} ({f(chg[-1]['ladder_change']):+.2f}), {chg[-2]['country']} ({f(chg[-2]['ladder_change']):+.2f}) and {chg[-3]['country']} ({f(chg[-3]['ladder_change']):+.2f}). Growth is not enough on its own: India grew {f(cg['India']['gdp_pc_ppp_growth_pct']):+.1f}% and still fell {f(cg['India']['ladder_change']):+.2f}.
5. **Regions: a 3-point spread.** North America and ANZ ({f(rg['North America and ANZ']['avg_ladder']):.2f}) and Western Europe ({f(rg['Western Europe']['avg_ladder']):.2f}) lead; Latin America ({f(rg['Latin America and Caribbean']['avg_ladder']):.2f}) matches Central and Eastern Europe ({f(rg['Central and Eastern Europe']['avg_ladder']):.2f}) at about half the GDP per capita ({usd(rg['Latin America and Caribbean']['avg_gdp_pc_usd'])} vs {usd(rg['Central and Eastern Europe']['avg_gdp_pc_usd'])}). Sub-Saharan Africa ({f(rg['Sub-Saharan Africa']['avg_ladder']):.2f}) and South Asia ({f(rg['South Asia']['avg_ladder']):.2f}, home to {f(rg['South Asia']['population_m']):,.0f}M people in the 6 surveyed countries) are lowest, which is why the population-weighted world average ({f(k['pop_weighted_ladder_latest']):.2f}) is below the simple country average ({f(k['avg_ladder_latest']):.2f}).
6. **The pandemic barely dented life evaluations.** For the same {cov['Life ladder']['countries']} countries, the average ladder moved from {f(cov['Life ladder']['avg_2017_19']):.3f} (2017-19) to {f(cov['Life ladder']['avg_2020_22']):.3f} (2020-22), {f(cov['Life ladder']['change']):+.3f}; negative affect rose {f(cov['Negative affect']['change']):+.3f}, social support slipped {f(cov['Social support']['change']):+.3f}, and generosity rose {f(cov['Generosity']['change']):+.3f}.

## Does money buy happiness? (2021-23 country averages)
{table(q, ['gdp_quintile', 'countries', 'min_gdp_pc_usd', 'max_gdp_pc_usd', 'avg_ladder', 'avg_social_support', 'avg_healthy_life_exp', 'avg_freedom', 'avg_corruption'])}

![Ladder vs GDP](images/ladder_vs_gdp_scatter.png)
![GDP quintiles](images/gdp_quintile.png)

## Drivers (pooled country-years 2005-2023)
{table(drv, ['factor', 'corr_with_ladder', 'n_obs'])}

![Drivers](images/drivers.png)

## Regions (2021-23)
{table(reg, ['region', 'countries', 'avg_ladder', 'min_ladder', 'max_ladder', 'pop_weighted_ladder', 'avg_gdp_pc_usd', 'population_m', 'avg_social_support', 'avg_healthy_life_exp'])}

![Regions](images/region_ladder.png)

## Happiest and least happy countries, 2023
{table(top + bot, ['grp', 'rnk', 'country', 'region', 'life_ladder', 'gdp_pc_usd'])}

GDP per capita is blank where the World Bank has no 2023 value (Afghanistan, Yemen and Lebanon in this table).

![Top and bottom 2023](images/top_bottom_2023.png)

## Happier or less happy than income predicts (2021-23, fit: ladder ~ ln GDP per capita)
{table(ten(res), ['residual_rank', 'country', 'region', 'gdp_pc_usd', 'life_ladder', 'predicted_ladder', 'residual'])}

![Income residual](images/income_residual.png)

## Change over time (2006-10 average vs 2019-23 average)
{table(ten(chg), ['change_rank', 'country', 'region', 'early_ladder', 'late_ladder', 'ladder_change', 'gdp_pc_ppp_growth_pct'])}

By real GDP-per-capita growth quartile:

{table(gvc, ['growth_quartile', 'countries', 'avg_gdp_pc_growth_pct', 'avg_ladder_change', 'pct_countries_happier'])}

![Happiness change](images/happiness_change.png)
![Growth vs change](images/growth_vs_change.png)

## Trend by survey year
{table(yr, ['year', 'countries', 'avg_ladder', 'median_ladder', 'pop_weighted_ladder', 'avg_negative_affect', 'avg_positive_affect'])}

2005 covers only {yd['2005']['countries']} (mostly high-income) countries, so the chart starts in 2006. The set of surveyed countries changes every year, so year-to-year moves mix real change with coverage.

![Ladder by year](images/ladder_by_year.png)

## Pandemic shift (same countries, 2017-19 vs 2020-22)
{table(sorted(cov.values(), key=lambda r: r['metric']), ['metric', 'countries', 'avg_2017_19', 'avg_2020_22', 'change'])}

![Covid shift](images/covid_shift.png)

## Data quality (before → after)
{table(rc, ['entity', 'raw_rows', 'distinct_keys', 'clean_rows', 'grain'])}

Issue counts:

{table(iss, ['check_name', 'affected_rows'])}

Null rates (kept as NULL, excluded from averages and correlations):

{table(rd('dq_null_rates'), ['entity', 'column_name', 'null_pct', 'treatment'])}

Assertions ({npass}/{len(asr)} PASS):

{table(asr, ['check_name', 'failed_rows', 'status'])}

![Data quality](images/data_quality.png)

## How the images were made
Every chart is drawn by `scripts/make_charts.py` from the CSVs in `results/tables/` as a plain-vector SVG (rect, line, polyline, circle and text only, via `scripts/svgcharts.py`), then rasterised to PNG at 2x by `scripts/render_png.py` with headless Chrome. `images/dashboard.svg` tiles seven KPI cards and six panels into one page.
"""
(RES / "RESULTS.md").write_text(md)
print("wrote", (RES / "RESULTS.md").relative_to(ROOT), len(md), "chars")
