#!/usr/bin/env python3
"""Download the full World Happiness Report + World Bank GDP/population files into data/raw_full/ and verify SHA-256.

World Happiness Report 2024 (Kaggle: https://www.kaggle.com/datasets/jainaru/world-happiness-report-2024-yearly-updated, CC0)
  World-happiness-report-updated_2024.csv  country x year panel 2005-2023 (2,363 rows, 165 countries; Gallup World Poll)
  World-happiness-report-2024.csv          WHR 2024 ranking (143 countries, with 'Regional indicator')
  Mirror: GitHub copy of the unmodified Kaggle files, pinned to a commit (identical copy also in Hamed-Ahmadinia/DASP-2025).
  The panel file is Latin-1 encoded (e.g. 'Türkiye'); it is verified on the original bytes, then re-encoded to UTF-8
  so DuckDB and Databricks read_files() can both load it with default options.
World Bank WDI (via the datasets/* Frictionless Data packages, pinned commits; CC BY 4.0, source: World Bank)
  gdp.csv         NY.GDP.MKTP.CD  GDP (current US$), country/aggregate x year 1960-2023
  population.csv  SP.POP.TOTL     population, country/aggregate x year 1960-2025
"""
import hashlib, pathlib, urllib.request

FILES = {
    "World-happiness-report-updated_2024.csv": (
        "https://raw.githubusercontent.com/semypak/data/3c7201660c4985d2ec5b232563126049d95449b0/World-happiness-report-updated_2024.csv",
        "2125094682ab2777e00135a705a26b0ce75972867447b455ea453063e70ebe2b", "latin-1"),
    "World-happiness-report-2024.csv": (
        "https://raw.githubusercontent.com/semypak/data/3c7201660c4985d2ec5b232563126049d95449b0/World-happiness-report-2024.csv",
        "0539aaa1984b903f6750ace8e265e54e30ea52f9f92fade118010fc2fc379de0", None),
    "gdp.csv": (
        "https://raw.githubusercontent.com/datasets/gdp/36d761dc5617982d3e50b213e02b9a1b47c4e958/data/gdp.csv",
        "8d84ef6bcaccf740c01c5ed7566aae8f7b149d0e2c20001e441efd3cb5b2fa86", None),
    "population.csv": (
        "https://raw.githubusercontent.com/datasets/population/d4b1a4a9a17e2123baf0ef119de05bceced1ab1b/data/population.csv",
        "2c697c3e668c8cb06ee467cd0d475b37b52844fdc48cb7725b79b58f18bf0b02", None),
}
out = pathlib.Path(__file__).resolve().parents[1] / "data" / "raw_full"
out.mkdir(parents=True, exist_ok=True)
bad = 0
for name, (url, sha, enc) in FILES.items():
    p = out / name
    orig = out / (name + ".sha256")
    if not p.exists():
        print("downloading", url)
        data = urllib.request.urlopen(url, timeout=120).read()
        got = hashlib.sha256(data).hexdigest()
        if enc:
            data = data.decode(enc).encode("utf-8")
        p.write_bytes(data)
        orig.write_text(got)
    got = orig.read_text().strip() if orig.exists() else hashlib.sha256(p.read_bytes()).hexdigest()
    print(f"{name:42s} {p.stat().st_size:>11,} bytes  {'OK' if got == sha else 'CHECKSUM MISMATCH ' + got}"
          + ("  (re-encoded latin-1 -> utf-8)" if enc else ""))
    bad += got != sha
raise SystemExit(1 if bad else 0)
