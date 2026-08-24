# Task 0.6 — Travel time: build vs borrow

**Status: answered. Split verdict — ingest the travel-time matrix, build the NCI/CoC nearest-facility
times ourselves.** A clean, CC0, ZCTA-level oncology travel-time + 2SFCA dataset exists, was
downloaded and verified end to end during this audit, and should be ingested. But it does **not**
contain what SPEC.md §2.3 actually asks for — travel time to the nearest NCI-designated center and
to the nearest CoC-accredited program — because it routes to *individual oncologist practice sites*,
with no facility-accreditation dimension anywhere in the release. SPEC.md's "ingest the published
dataset if viable" is therefore half-satisfiable as written.

---

## 1. The dataset that exists

**Liu L, Onega T, Moen EL, Tosteson ANA, Smith RE, Wang Q, Cowan L, Wang F. "Telehealth
Infrastructure for Cancer Care in the United States." *Scientific Data* 2026;13:881.**
doi:[10.1038/s41597-026-07063-z](https://doi.org/10.1038/s41597-026-07063-z) (published 2026-03-16;
open access at [PMC13260728](https://pmc.ncbi.nlm.nih.gov/articles/PMC13260728/)).

Data deposit: **Harvard Dataverse, [doi:10.7910/DVN/OIFW0D](https://doi.org/10.7910/DVN/OIFW0D)**.
Queried via the Dataverse API during this audit: **version 4.0, RELEASED, published 2026-02-18**,
10 files, **`restricted=null` on every file**, md5 recorded per file by the repository. Not
"available on request" — genuinely open.

**License: CC0 1.0 Universal** (`rightsIdentifier: CC0-1.0`, confirmed from the Dataverse dataset
metadata API, not from the article text). Note the article *body* carries CC BY-NC-ND 4.0, which
does **not** govern the deposit; the deposit's own license record is CC0. No attribution obligation,
though we cite it anyway.

### Verified by download, not by reading the paper

| Check | Result |
|---|---|
| `Accessibility_45_60_90_120_Min.csv.gz` (2.4 MB) downloads unauthenticated | yes, HTTP 200 |
| Rows | 33,642 ZCTAs + header, all 5-digit GEOIDs |
| `200km_9m_OD_list.csv.gz` (253.6 MB) downloads unauthenticated | yes, HTTP 200 |
| OD rows | **9,565,623** (ZCTA × oncologist site, Haversine ≤ 200 km pre-filter) |
| Distinct ZCTAs with ≥1 oncologist site in range | **33,395** of 33,642 — **247 ZCTAs have no OD row at all** |
| `Duration` units | minutes (confirmed: median nearest-site drive 29.5 min, p90 98.8 min, max 583.7 min) |
| Nearest-oncologist drive > 60 min | 7,573 ZCTAs |
| Nearest-oncologist drive > 120 min | 1,728 ZCTAs |

Download URLs are the Dataverse per-file access API, e.g.
`https://dataverse.harvard.edu/api/access/datafile/12109924` (OD list) and
`.../12110271` (accessibility scores). Both pinnable by file id + md5, satisfying CLAUDE.md's
"pinned and hashed" requirement for the derived artifact.

### Files relevant to us

- **`200km_9m_OD_list.csv.gz`** — `OID, ZCTA, HaversineMile, Duration, DistanceMile`. This is the
  reusable asset: a national ZCTA→oncologist-site drive-time matrix.
- **`Oncologist_FTE.csv.gz`** — 9,967 unique practice sites with `lon, lat, Sum(FTE)`.
- **`Accessibility_45_60_90_120_Min.csv.gz`** — `45/60/90/120Min_2SFCA` plus telehealth (2SVCA)
  variants. Units are **FTE oncologists per 1,000 cancer cases**, not per capita.
- The remaining files are broadband/5G/ACS telehealth inputs — irrelevant to §2.3.

### A zero-encoding gotcha, confirmed arithmetically

2SFCA is exactly 0 for 11,148 ZCTAs at 45 min, 7,820 at 60 min, and 1,975 at 120 min. No blanks or
`NA` anywhere. The 120-min figure decomposes exactly: **1,728 ZCTAs with a nearest site beyond
120 min + 247 ZCTAs with no OD row at all = 1,975.** So `0` is doing double duty — "no oncologist
within the threshold" *and* "not routable / outside the 200 km pre-filter." Per CLAUDE.md these are
two different states and neither may render as a bare zero. The 247 must be reconstructed by
anti-joining the OD list against the ZCTA list; the release does not flag them.

---

## 2. Why this does not close SPEC.md §2.3

The supply universe is NPPES individual providers filtered to three taxonomy codes —
**207RH0003X (Hematology & Oncology), 207RX0202X (Medical Oncology), 2085R0001X (Radiation
Oncology)** — collapsed to practice sites. Quoting the Methods: routing is "between ZCTA centroids
and oncologist practice sites." **NCI designation and CoC accreditation appear nowhere in the paper
or the deposit.** Nor are surgical or gynecologic oncology included (contrast Task 0.5, which asks
for four taxonomy families).

So this dataset supplies a *better version of SPEC.md §2.3's first bullet* (oncologist access, as a
travel-time-aware 2SFCA rather than a within-county density) and supplies **none of the second
bullet**.

### Two further reasons not to ingest the 2SFCA scores uncritically

1. **The demand denominator is imputed suppressed incidence.** The 2SFCA's demand is the authors'
   own ZCTA cancer-incidence layer (`NCI_cancer_count.csv.gz`), from Liu, Wang & Onega, *Sci Data*
   2025;12:909, doi:[10.1038/s41597-025-05254-8](https://doi.org/10.1038/s41597-025-05254-8),
   Dataverse [doi:10.7910/DVN/W3S2LW](https://doi.org/10.7910/DVN/W3S2LW), CC BY 4.0. That layer
   **imputes suppressed county-level State Cancer Profiles incidence by Monte Carlo and then
   disaggregates to ZCTA**. This is very close to the operation SPEC.md §2.2 explicitly forbids
   ("Do not attempt an incidence version by back-computing counts from rates and populations — the
   suppression pattern makes that unreliable and it would be indefensible under review"). Shipping
   a headline access number whose denominator is built that way, in a paper whose methods section
   rejects the technique, is a `statistical-reviewer` finding waiting to happen.
2. **Window mismatch with our pinned archive.** That incidence layer interpolates SCP **diagnosis
   years 2016–2020**. Our pinned V3 incidence window is 2018–2022 (Task 0.1). Task 0.1 is the whole
   methodological contribution of this repo; importing a second, older incidence window through a
   side door undercuts it.

**Recommendation: ingest `200km_9m_OD_list.csv.gz` (the raw travel-time matrix — assumption-free,
just OSRM minutes) and `Oncologist_FTE.csv.gz`. Recompute any 2SFCA ourselves against a denominator
we control. Do not ingest `Accessibility_*.csv.gz` as a published headline number.**

---

## 3. Currency and vintage — the weak point

| Input | Vintage | Source of claim |
|---|---|---|
| ZCTA geography | 2020 Census, TIGER/Line cartographic boundaries | Methods, stated |
| Oncologist locations | **NPPES "full replacement" file — no date given** | Methods; deposit filename `US-Telehealth-2025.tab` and the 2025 companion paper imply a 2024–2025 extract |
| Road network | **OSRM on OpenStreetMap — no snapshot date, no statement on free-flow vs congested speeds** | Methods |
| ZCTA centroid definition | **not stated** (population-weighted vs geometric) | Methods; only the *broadband* variables are documented as population-weighted |
| Demand (cancer cases) | SCP incidence, diagnosis years 2016–2020 | Liu et al. 2025 |
| Broadband / ACS (not used by us) | FCC BDC accessed 2024; ACS S2801, 2020 | Methods |

The 2020 ZCTA vintage and a ~2024–25 provider extract are **current enough to be defensible in a
2026 paper**. The reproducibility gaps are the problem: with no NPPES snapshot date and no OSM
snapshot date, we cannot honour CLAUDE.md's "record what was fetched and when" for the *upstream*
of this dataset. We can only pin the derived artifact (Dataverse DOI + version 4.0 + per-file md5),
and the manifest entry must say so explicitly rather than implying we know the provider vintage.

Currency is **not** grounds to recompute the oncologist matrix. A ~1-year-stale NPPES extract moves
a drive-time-to-nearest-oncologist number very little, and recomputing costs an OSRM build to
reproduce a number someone already published under CC0.

---

## 4. Geographic unit and the crosswalk to county

Unit is **2020 ZCTA**. ZCTA→county is not 1:1 (the deposit's own
`ZCTA-FixedBroadBand.csv.gz` notes "ZCTA in multiple counties", n=33,782 ZCTA×county pairs versus
33,642 ZCTAs).

Options checked:

- **Census 2020 ZCTA-to-County Relationship File** —
  `https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt`
  (HTTP 200, 6.8 MB, verified). Gives every ZCTA×county pair with `AREALAND_PART`/`AREAWATER_PART`.
  **Area-weighted only — no population.** Area weighting an access measure is wrong: it
  over-weights empty land, which is exactly the rural geography we care about.
  ([explanation PDF](https://www2.census.gov/geo/pdfs/maps-data/data/rel2020/zcta520/explanation_tab20_zcta520_county20_natl.pdf))
- **HUD USPS ZIP–county crosswalk** ([huduser.gov](https://www.huduser.gov/portal/datasets/usps_crosswalk.html))
  — population/address-count weighted and quarterly, but keyed on **USPS ZIP, not ZCTA**, so it
  needs the UDS Mapper ZIP→ZCTA step first and inherits both files' error.
- **Missouri Geocorr** — generates population-weighted ZCTA→county allocation factors directly.
  ([statsamerica.org geography tools](https://www.statsamerica.org/geography-tools.aspx))

**Preferred: don't crosswalk at all for the nearest-facility measure.** Census publishes 2020
population-weighted centroids at county and block-group level, both verified HTTP 200 this audit:

- `https://www2.census.gov/geo/docs/reference/cenpop2020/county/CenPop2020_Mean_CO.txt` (3,221 counties)
- `https://www2.census.gov/geo/docs/reference/cenpop2020/blkgrp/CenPop2020_Mean_BG.txt` (242,335 block groups)

Block groups nest cleanly inside counties, so routing block-group centroids and population-weighting
to county gives an exact, crosswalk-free county number. Use Geocorr-style population weighting only
where we genuinely need the *published* ZCTA scores rolled up for comparison with Liu et al.

---

## 5. The build side: NCI and CoC nearest-facility times

### NCI-designated centers — solved, trivial

`https://gis.cancer.gov/ncicatchment/NCI_CancerCenter_Address_2025.zip` (HTTP 200, 29 KB,
downloaded and parsed this audit). Point shapefile, **76 records**, fields
`id, name, Street, City, state, Zip_Code, Latitude, Longitude, County, type, url`, where `type`
distinguishes Comprehensive / Clinical / Basic Laboratory. File dated 2025-12-17. Companion
`NCI_Catchment_Areas_2026.zip` and county/catchment mortality workbooks (updated May 2026) are at
the same portal. No explicit license statement; US federal GIS output, and the portal requests
citation of DelNero et al., *Cancer Epidemiol Biomarkers Prev* 2022.
([gis.cancer.gov/ncicatchment](https://gis.cancer.gov/ncicatchment/))

Two caveats: (a) **main-campus addresses only** — no satellite facilities, and Onega et al.
(*Cancer* 2017, doi:[10.1002/cncr.30727](https://doi.org/10.1002/cncr.30727)) showed that including
satellites materially improves measured access for rural and minority populations, so a
parent-campus-only travel time systematically *overstates* distance; (b) **Basic Laboratory centers
provide no clinical care** and should be excluded from a care-access measure, leaving 66–68 sites.
Both belong in the methods text.

### CoC-accredited programs — this is the actual blocker

No public bulk file and no public API. The ACS directory is a Google-Maps-driven server-rendered
locator at `https://www.facs.org/find-a-hospital/?companyType=CoC` (HTTP 200); probed this audit for
a JSON endpoint and found none (no `/umbraco/api/*`, no embedded JSON payload). ACS describes
"nearly 1,400" accredited programs
([facs.org CoC](https://www.facs.org/quality-programs/cancer-programs/commission-on-cancer/)), and
the NCDB describes "more than 1,500"
([facs.org NCDB](https://www.facs.org/quality-programs/cancer-programs/national-cancer-database/about/)).
Getting the list means scraping the locator (terms-of-use exposure, and a fragile dependency for a
citable paper) or licensing the AHA Annual Survey, which carries the CoC flag but is paid and
redistribution-restricted.

**Recommendation: descope the CoC bullet from M5 unless a licensed or clearly-permitted list turns
up.** Ship NCI-center travel time, which is fully sourced and defensible, and state in the paper
that CoC-accredited program locations are not available as an openly redistributable dataset. That
is itself a reportable finding about US cancer-care data infrastructure, and it is more honest than
a scraped facility list we cannot pin or hash.

### Effort to build NCI travel time

Facility points: done (above). Origins: `CenPop2020_Mean_BG.txt`, verified. Router: OSRM in Docker
against a Geofabrik `north-america` extract (~14 GB pbf; `osrm-extract` + `osrm-partition` +
`osrm-customize` is an overnight run on a workstation and wants ~64 GB disk). Then 242,335 origins ×
~67 clinical NCI destinations via the OSRM `/table` service in chunks — a few hours, embarrassingly
parallel. Population-weight block groups to county.

**Estimate: 1–2 days wall clock, most of it unattended OSRM preprocessing.** Cheap, and it gives us
a router we can reuse for the §2.3 trials bullet ("count within a 60-minute drive"), which has no
published equivalent at all and must be built regardless.

---

## 6. Consequence for M5

1. **§2.3 bullet 2 changes shape.** "Travel time to nearest NCI-designated center **and** to the
   nearest CoC-accredited program" becomes NCI-only, from the NCI GIS point file, computed by us.
   The CoC half is descoped with a stated reason. SPEC.md §2.3 should be edited rather than left to
   fail silently.
2. **Ingest is still the right call for the oncologist measure**, but for the OD matrix, not the
   headline scores. `200km_9m_OD_list.csv.gz` (CC0, Dataverse v4.0, md5-pinnable) gives
   nearest-oncologist drive time per ZCTA for free and replaces SPEC.md's within-county oncologist
   density with something strictly better — a county with zero oncologists but one 20 minutes across
   the line stops looking like a desert. Keep the raw zero-count density too, since SPEC.md §2.3 is
   right that "counties with no oncologist at all are the finding."
3. **Do not adopt the published 2SFCA scores as a headline.** Their denominator is Monte
   Carlo-imputed suppressed SCP incidence for 2016–2020 — a different window than our pinned V3, and
   the same back-computation §2.2 rules out. If a 2SFCA is shown, recompute it against a denominator
   we control and say so.
4. **OSRM is on the critical path regardless**, because the trials bullet needs a 60-minute drive
   catchment. Budget the OSRM build once in M2 and spend it three times (NCI centers, trial sites,
   any recomputed 2SFCA).
5. **Three distinct "no reliable estimate" states** must exist for access, not one: no oncologist
   within threshold (11,148 ZCTAs at 45 min), not routable / no site within 200 km (247 ZCTAs, which
   the release silently encodes as `0`), and county not covered. CLAUDE.md forbids rendering any of
   them as a bare zero, and the first two mean opposite things for a planner.
6. **Manifest honesty.** Pin Dataverse `doi:10.7910/DVN/OIFW0D` version 4.0 with per-file md5s, and
   record that the upstream NPPES and OpenStreetMap snapshot dates are **not disclosed by the
   depositors** — a limitation of the ingested artifact, not something to paper over.

---

## Sources

- Liu L, et al. Telehealth Infrastructure for Cancer Care in the United States. *Sci Data* 2026;13:881. https://doi.org/10.1038/s41597-026-07063-z — open access: https://pmc.ncbi.nlm.nih.gov/articles/PMC13260728/
- Deposit: Harvard Dataverse https://doi.org/10.7910/DVN/OIFW0D (v4.0, CC0 1.0; metadata and files retrieved via `dataverse.harvard.edu/api`, 2026-08-24)
- Liu L, Wang F, Onega T. Cancer incidence data at the ZCTA level in the United States interpolated by Monte Carlo simulation with multiple constraints. *Sci Data* 2025;12:909. https://doi.org/10.1038/s41597-025-05254-8 — deposit https://doi.org/10.7910/DVN/W3S2LW (CC BY 4.0)
- Liu L, et al. Digital divides in telehealth accessibility for cancer care in the United States. *npj Digit Med* 2025. https://www.nature.com/articles/s41746-025-01931-5 (companion analysis; `US-Telehealth-2025.tab` in the deposit)
- NCI GIS Portal, Catchment Areas: https://gis.cancer.gov/ncicatchment/ — `NCI_CancerCenter_Address_2025.zip`, `NCI_Catchment_Areas_2026.zip`
- Onega T, et al. Population-based geographic access to parent and satellite NCI Cancer Center facilities. *Cancer* 2017. https://doi.org/10.1002/cncr.30727
- Onega T, et al. Geographic access to cancer care in the U.S. *Cancer* 2008. https://doi.org/10.1002/cncr.23229
- ACS Commission on Cancer: https://www.facs.org/quality-programs/cancer-programs/commission-on-cancer/ — locator https://www.facs.org/find-a-hospital/?companyType=CoC (no bulk export, no public API)
- Census 2020 ZCTA-to-County Relationship File: https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt
- Census 2020 population-weighted centroids: https://www2.census.gov/geo/docs/reference/cenpop2020/county/CenPop2020_Mean_CO.txt , https://www2.census.gov/geo/docs/reference/cenpop2020/blkgrp/CenPop2020_Mean_BG.txt
- HUD USPS ZIP crosswalk: https://www.huduser.gov/portal/datasets/usps_crosswalk.html
