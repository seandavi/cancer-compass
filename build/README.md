# Build

Pinned upstream sources are listed in `manifest.json`. Everything under `cache/` and `out/` is a
build artifact — never committed, always reproducible from the manifest plus the scripts here.

## Fetch the pinned sources

```sh
mkdir -p build/cache/zenodo-v3 build/cache/tiger2021
curl -sS -o build/cache/zenodo-v3/state_cancer_profiles_incidence.parquet \
  "https://zenodo.org/records/22085273/files/state_cancer_profiles_incidence.parquet?download=1"
curl -sS -o build/cache/zenodo-v3/state_cancer_profiles_mortality.parquet \
  "https://zenodo.org/records/22085273/files/state_cancer_profiles_mortality.parquet?download=1"
curl -sS -o build/cache/zenodo-v3/state_cancer_profiles_risk.parquet \
  "https://zenodo.org/records/22085273/files/state_cancer_profiles_risk.parquet?download=1"
curl -sS -o build/cache/zenodo-v3/state_cancer_profiles_demographics.parquet \
  "https://zenodo.org/records/22085273/files/state_cancer_profiles_demographics.parquet?download=1"
curl -sS -o build/cache/tl_2021_us_county.zip \
  "https://www2.census.gov/geo/tiger/TIGER2021/COUNTY/tl_2021_us_county.zip"
(cd build/cache/tiger2021 && unzip -oq ../tl_2021_us_county.zip)
```

Verify against `manifest.json`'s recorded sha256 before trusting a fetch — a mismatch means the
upstream file changed and every downstream number in `docs/audit/` needs re-checking, not silent
re-pinning.

## Scripts

- `adjacency.sql` — derives county queen-contiguity for the BYM2/CAR model (M4) from TIGER2021,
  with the FIPS crosswalk that makes the node set match the pinned SCP extract's 3,142 counties
  exactly. Validated in `docs/audit/07-adjacency.md` to reproduce the official 2025 Census County
  Adjacency File bit-for-bit. Run: `duckdb -f build/adjacency.sql` from the repo root. Asserts the
  crosswalked node set equals the SCP county set and fails loudly (non-empty `mismatch` table) if
  a future TIGER or SCP vintage drifts.

- **Oncologist density pipeline (M5's `docs/audit/05-nppes.md`), three steps, run in order:**
  1. Fetch the NPPES monthly bulk file (~1.15 GiB), unzip `npidata_pfile_*.csv` into
     `build/cache/nppes/` (see fetch commands above pattern — same `curl` + `unzip` shape,
     substituting the dated NPPES URL from `download.cms.gov/nppes/NPI_Files.html`).
  2. `duckdb` the taxonomy + entity-type filter into `build/cache/nppes/oncologists.parquet` and
     `distinct_addresses.csv` (inline in this README until it earns its own script — the filter is
     the seven-code list in `docs/audit/05-nppes.md` §2: `207RX0202X`, `207RH0003X`,
     `2085R0001X`, `2085R0203X`, `2086X0206X`, `207VX0201X`, `2080P0207X`, `Entity Type Code = 1`,
     country blank or `US`).
  3. `python3 build/geocode_addresses.py` — batches distinct addresses through the Census batch
     geocoder (10,000/request limit), writes `build/cache/nppes/geocoded.csv`. Records `No_Match`
     and `Tie` rows explicitly rather than dropping them (their API response has 3 columns instead
     of 12 — a real bug caught by checking output row counts against input, not by inspection).
  4. `duckdb -f build/oncologist_density.sql` — resolves county FIPS (geocode match, else
     ZIP-fallback via the Census ZCTA-to-county relationship file, else unplaced), applies the same
     crosswalk as `adjacency.sql`, and writes `build/out/county_oncologist_density.csv`.

  Run end-to-end 2026-08-24: 37,778 oncologists (exact match to the audit's headline number),
  **62.5%** of the 3,142-county universe has zero oncologists across the seven target specialties
  (audit reported 62.6% from an earlier geocoder run — the ~0.1pp difference across independent
  runs of a live external geocoding service is expected, not a discrepancy to chase).

## Not yet built

Per `docs/audit.md`'s open decisions — these need a project-owner call before their build scripts
are written, not just more engineering time:

- Mortality ingest (blocked on the NCHS restricted-use DUA, `docs/audit/03-cdc-wonder.md` §9)
- Travel-time ingest from Liu et al. 2026 / NCI facility geocoding (`docs/audit/06-travel-time.md`)
- ClinicalTrials.gov site geocoding
