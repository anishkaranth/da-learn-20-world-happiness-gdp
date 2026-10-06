#!/usr/bin/env python3
"""Render SVG charts (pure vector shapes, no raster) from the KPI tables exported by run_pipeline.py."""
import csv, math, pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import svgcharts as S

BLUE, ORANGE, GREEN, SAND, NAVY = S.PALETTE[0], S.PALETTE[1], S.PALETTE[2], S.PALETTE[3], S.PALETTE[4]
SHORT = {"Log GDP per capita (World Bank, US$)": "Log GDP pc (World Bank, US$)", "Log GDP per capita (WHR, PPP)": "Log GDP pc (WHR, PPP)"}
LABEL = ["Finland", "Denmark", "Costa Rica", "Nicaragua", "Mozambique", "Lebanon", "Botswana", "Afghanistan",
         "Hong Kong S.A.R. of China", "India", "China", "United States", "Luxembourg", "Sierra Leone"]


def rd(t, name):
    with open(pathlib.Path(t) / f"{name}.csv", newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def f(x):
    return float(x) if x not in ("", None) else 0.0


def panels(t):
    k = rd(t, "a_kpi_headline")[0]
    yr = sorted(rd(t, "a_ladder_by_year"), key=lambda r: int(r["year"]))
    yr = [r for r in yr if int(r["countries"]) >= 80]           # 2005 has only 27 (mostly rich) countries
    reg = sorted(rd(t, "a_region_summary"), key=lambda r: -f(r["avg_ladder"]))
    regions = sorted(r["region"] for r in reg)
    q = sorted(rd(t, "a_gdp_quintile"), key=lambda r: r["gdp_quintile"])
    drv = sorted(rd(t, "a_driver_correlations"), key=lambda r: -f(r["corr_with_ladder"]))
    tb = rd(t, "a_top_bottom_2023")
    top = sorted([r for r in tb if r["grp"] == "top 10"], key=lambda r: int(r["rnk"]))
    bot = sorted([r for r in tb if r["grp"] == "bottom 10"], key=lambda r: -int(r["rnk"]))
    res = sorted(rd(t, "a_income_residual"), key=lambda r: int(r["residual_rank"]))
    chg = sorted(rd(t, "a_happiness_change"), key=lambda r: int(r["change_rank"]))
    gvc = sorted(rd(t, "a_growth_vs_change"), key=lambda r: r["growth_quartile"])
    cov = {r["metric"]: r for r in rd(t, "a_covid_shift")}
    dq = sorted([r for r in rd(t, "dq_issues") if f(r["affected_rows"]) > 0], key=lambda r: -f(r["affected_rows"]))
    # fit line ladder = a + b ln(gdp) recovered from two predicted points of a_income_residual
    p1, p2 = min(res, key=lambda r: f(r["gdp_pc_usd"])), max(res, key=lambda r: f(r["gdp_pc_usd"]))
    b = (f(p2["predicted_ladder"]) - f(p1["predicted_ladder"])) / (math.log(f(p2["gdp_pc_usd"])) - math.log(f(p1["gdp_pc_usd"])))
    a = f(p1["predicted_ladder"]) - b * math.log(f(p1["gdp_pc_usd"]))
    pts = [(f(r["gdp_pc_usd"]), f(r["life_ladder"]), regions.index(r["region"])) for r in res]
    labs = {i: r["country"].replace("Hong Kong S.A.R. of China", "Hong Kong") for i, r in enumerate(res) if r["country"] in LABEL}
    two = lambda a_, b_: a_ + b_
    ps = [
        ("ladder_vs_gdp_scatter", S.scatter("Life ladder vs GDP per capita, 2021-23 country averages (log scale)", pts,
                                            f"{len(pts)} countries; dashed = OLS fit, r² = {f(k['r2_ladder_on_log_gdp_latest']):.2f}, "
                                            f"+{f(k['ladder_gain_per_gdp_doubling']):.2f} ladder points per doubling of GDP per capita",
                                            w=760, h=460, logx=True, fit=(a, b), labels=labs, groups=regions,
                                            xticks=[500, 1000, 2000, 5000, 10000, 20000, 50000, 100000], ymin=1, ymax=9,
                                            xlabel="GDP per capita, current US$ (World Bank), log scale", ylabel="life ladder (0-10)")),
        ("ladder_by_year", S.line("Average life ladder by survey year (0-10)", [r["year"] for r in yr],
                                  [("simple average", [f(r["avg_ladder"]) for r in yr]), ("median", [f(r["median_ladder"]) for r in yr]),
                                   ("population-weighted", [f(r["pop_weighted_ladder"]) for r in yr])], "{:.2f}",
                                  "years with 80+ surveyed countries (2006-2023); the country mix changes every year", w=760, every=2)),
        ("gdp_quintile", S.vbar("Life ladder by GDP-per-capita quintile, 2021-23 (28 countries each)", [r["gdp_quintile"] for r in q],
                                [f(r["avg_ladder"]) for r in q], "{:.2f}",
                                f"richest fifth {f(q[-1]['avg_ladder']):.2f} vs poorest {f(q[0]['avg_ladder']):.2f}: a gap of "
                                f"{f(k['ladder_gap_top_bottom_quintile']):.2f} points", w=760, vmax=8, ylabel="avg life ladder",
                                notes=[f"${f(r['min_gdp_pc_usd']):,.0f}-{f(r['max_gdp_pc_usd']):,.0f}" for r in q],
                                color=[S.PALETTE[i] for i in (1, 3, 2, 8, 0)])),
        ("region_ladder", S.hbar("Life ladder by region, 2021-23 (average of countries)", [r["region"] for r in reg],
                                 [f(r["avg_ladder"]) for r in reg], "{:.2f}", "label: countries and average GDP per capita (current US$)",
                                 notes=[f"({r['countries']} countries, ${f(r['avg_gdp_pc_usd']):,.0f})" for r in reg], w=760, vmax=10.5,
                                 color=[S.PALETTE[regions.index(r["region"])] for r in reg])),
        ("drivers", S.dbar("Correlation of each factor with the life ladder (country-years 2005-2023)", [SHORT.get(r["factor"], r["factor"]) for r in drv],
                           [f(r["corr_with_ladder"]) for r in drv], "{:+.2f}", "Pearson r over pooled country-years; NULLs excluded pairwise",
                           w=760, pos_color=BLUE, neg_color=ORANGE)),
        ("top_bottom_2023", S.hbar("Happiest and least happy countries, survey year 2023", [r["country"] for r in top] + [r["country"] for r in bot],
                                   [f(r["life_ladder"]) for r in top + bot], "{:.2f}", "label: GDP per capita 2023 (current US$; blank = no World Bank value)",
                                   notes=[f"(${f(r['gdp_pc_usd']):,.0f})" if r["gdp_pc_usd"] else "(n/a)" for r in top + bot],
                                   color=[BLUE] * len(top) + [ORANGE] * len(bot), w=760, vmax=10)),
        ("income_residual", S.dbar("Happier or less happy than income predicts (2021-23)", [r["country"].replace("Hong Kong S.A.R. of China", "Hong Kong")
                                   for r in res[:10] + res[-10:]], [f(r["residual"]) for r in res[:10] + res[-10:]], "{:+.2f}",
                                   "residual = actual ladder - fit on ln(GDP per capita); top and bottom 10 of the fitted countries", w=760)),
        ("happiness_change", S.dbar("Biggest ladder gains and losses, 2006-10 avg to 2019-23 avg", [r["country"] for r in chg[:10] + chg[-10:]],
                                    [f(r["ladder_change"]) for r in chg[:10] + chg[-10:]], "{:+.2f}",
                                    f"{len(chg)} countries with 2+ surveys in both windows", w=760, pos_color=GREEN, neg_color=ORANGE)),
        ("growth_vs_change", S.dbar("Ladder change by real GDP-per-capita growth quartile, 2006-10 to 2019-23",
                                    [f"{r['growth_quartile']} (growth {f(r['avg_gdp_pc_growth_pct']):+.0f}%, {f(r['pct_countries_happier']):.0f}% happier)" for r in gvc],
                                    [f(r["avg_ladder_change"]) for r in gvc], "{:+.3f}",
                                    f"{sum(int(r['countries']) for r in gvc)} countries; growth = change in WHR log GDP per capita (PPP, constant prices)",
                                    w=760, pos_color=GREEN, neg_color=ORANGE)),
        ("covid_shift", S.dbar("Pandemic shift: same 143 countries, 2020-22 avg minus 2017-19 avg", list(cov),
                               [f(cov[m]["change"]) for m in cov], "{:+.3f}",
                               "ladder 0-10; other factors 0-1 shares (generosity is a residual index)", w=760, pos_color=GREEN, neg_color=ORANGE)),
        ("data_quality", S.hbar("Data-quality findings (rows / countries affected)", [r["check_name"][:58] for r in dq],
                                [f(r["affected_rows"]) for r in dq], "{:,.0f}",
                                f"{int(f(k['country_years'])):,} country-years, {int(f(k['countries']))} countries; {f(k['wb_match_pct']):.2f}% matched "
                                "to World Bank GDP per capita", color=SAND, w=760, vmax=max(f(r["affected_rows"]) for r in dq) * 1.2)),
    ]
    return ps, k


def make_all(tables, out):
    out = pathlib.Path(out); out.mkdir(parents=True, exist_ok=True)
    ps, k = panels(tables)
    for name, p in ps:
        S.save(p, out / f"{name}.svg")
    cards = [("Countries / country-years", f"{int(f(k['countries']))} / {int(f(k['country_years'])):,}"),
             ("Avg life ladder 2021-23", f"{f(k['avg_ladder_latest']):.2f}"),
             ("Pop-weighted ladder 2021-23", f"{f(k['pop_weighted_ladder_latest']):.2f}"),
             ("Corr ladder vs log GDP pc", f"{f(k['corr_ladder_log_gdp_pc']):.2f}"),
             ("Gain per GDP doubling", f"+{f(k['ladder_gain_per_gdp_doubling']):.2f}"),
             ("Richest vs poorest fifth", f"+{f(k['ladder_gap_top_bottom_quintile']):.2f}"),
             ("Matched to World Bank", f"{f(k['wb_match_pct']):.1f}%")]
    order = ["ladder_vs_gdp_scatter", "gdp_quintile", "region_ladder", "drivers", "income_residual", "growth_vs_change"]
    tag = " - SAMPLE" if "sample" in out.parts else ""
    S.dashboard(out / "dashboard.svg", f"World happiness vs GDP per capita ({k['first_year']}-{k['last_year']}, World Happiness Report + World Bank){tag}",
                f"Rendered from {'results/sample/tables (committed raw sample' if tag else 'results/tables (SQL on DuckDB, full data'}: "
                f"{int(f(k['country_years'])):,} country-years, {int(f(k['countries']))} countries). "
                "Life ladder = Gallup Cantril ladder 0-10; GDP per capita = World Bank GDP (current US$) / population; 'latest' = 2021-23 average.",
                cards, [dict(ps)[n] for n in order], cols=2)
    print("charts ->", out, sorted(p.name for p in out.glob("*.svg")))


if __name__ == "__main__":
    root = pathlib.Path(__file__).resolve().parents[1]
    make_all(root / "results/tables", root / "results/images")
