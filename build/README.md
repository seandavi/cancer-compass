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

## Not yet built

Per `docs/audit.md`'s open decisions — these need a project-owner call before their build scripts
are written, not just more engineering time:

- Mortality ingest (blocked on the NCHS restricted-use DUA, `docs/audit/03-cdc-wonder.md` §9)
- NPPES oncologist density pipeline (fully validated end-to-end in `docs/audit/05-nppes.md`, not
  yet turned into a repo script)
- Travel-time ingest from Liu et al. 2026 / NCI facility geocoding (`docs/audit/06-travel-time.md`)
- ClinicalTrials.gov site geocoding
