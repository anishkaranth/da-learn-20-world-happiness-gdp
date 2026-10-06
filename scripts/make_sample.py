#!/usr/bin/env python3
"""Build the git-sized raw sample in data/raw/ from data/raw_full/ (deterministic, no randomness).

Rule: every 14th WHR panel country in alphabetical order (1st, 15th, 29th, ...) with all its survey years; the WHR 2024
ranking rows of those countries; and the World Bank GDP / population rows 2005-2023 of their ISO3 codes plus 'WLD'.
Rows are copied verbatim (panel already UTF-8 in raw_full)."""
import csv, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
FULL, OUT = ROOT / "data/raw_full", ROOT / "data/raw"
OUT.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(ROOT / "scripts"))


def load(name):
    with open(FULL / name, newline="", encoding="utf-8") as f:
        return list(csv.reader(f))


def save(name, rows):
    with open(OUT / name, "w", newline="", encoding="utf-8") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)


panel = load("World-happiness-report-updated_2024.csv")
countries = sorted({r[0] for r in panel[1:]})
keep = set(countries[::14])
save("World-happiness-report-updated_2024.csv", [panel[0]] + [r for r in panel[1:] if r[0] in keep])
rank = load("World-happiness-report-2024.csv")
norm = lambda n: "Turkiye" if n in ("Türkiye", "Turkiye") else n
save("World-happiness-report-2024.csv", [rank[0]] + [r for r in rank[1:] if norm(r[0]) in {norm(k) for k in keep}])
# ISO3 lookup mirrors the crosswalk in sql/02_cleaning.sql (names that differ are mapped here too)
OVR = {"Congo (Brazzaville)": "Congo, Rep.", "Congo (Kinshasa)": "Congo, Dem. Rep.", "Egypt": "Egypt, Arab Rep.", "Gambia": "Gambia, The",
       "Hong Kong S.A.R. of China": "Hong Kong SAR, China", "Iran": "Iran, Islamic Rep.", "Ivory Coast": "Cote d'Ivoire",
       "Kyrgyzstan": "Kyrgyz Republic", "Laos": "Lao PDR", "Russia": "Russian Federation", "Slovakia": "Slovak Republic",
       "Somalia": "Somalia, Fed. Rep.", "South Korea": "Korea, Rep.", "State of Palestine": "West Bank and Gaza",
       "Syria": "Syrian Arab Republic", "Venezuela": "Venezuela, RB", "Vietnam": "Viet Nam", "Yemen": "Yemen, Rep.", "Türkiye": "Turkiye"}
pop = load("population.csv")
codes = {r[1] for r in pop[1:] if r[0] in {OVR.get(k, k) for k in keep}} | {"WLD"}
for name in ("gdp.csv", "population.csv"):
    rows = load(name)
    save(name, [rows[0]] + [r for r in rows[1:] if r[1] in codes and 2005 <= int(r[2]) <= 2023])
print("countries:", sorted(keep), "ISO3:", sorted(codes))
