# Task 0.5 — NPI / NPPES feasibility

**Status: answered — feasible, and stronger than SPEC.md §2.3 assumes.** Every number below was
measured directly against the August 2026 NPPES bulk file and the NUCC 26.1 code set on
2026-08-24, not recalled. The full pipeline (download → taxonomy filter → geocode → county
FIPS) was executed end to end during this audit; §6 reports its output.

The one premise in the task framing that does **not** hold: there is no taxonomy reference file
inside the NPPES bundle. Taxonomy display names come from NUCC separately (§2).

---

## 1. The bulk file is retrievable

Source page: <https://download.cms.gov/nppes/NPI_Files.html> (`last-modified: Mon, 24 Aug 2026
07:05:49 GMT`).

| Property | Verified value |
|---|---|
| Current monthly URL | `https://download.cms.gov/nppes/NPPES_Data_Dissemination_August_2026_V2.zip` |
| ZIP size | **1,151,460,412 bytes** (1.07 GiB); page states "1,098.12 MB" |
| `last-modified` | Mon, 10 Aug 2026 09:05:09 GMT |
| Main CSV uncompressed | **11,632,650,533 bytes (10.83 GiB)** |
| Whole bundle uncompressed | ~11.9 GiB |
| Format | ZIP of comma-separated, fully quoted CSV (**not** pipe-delimited) |
| Update cadence | **Monthly** full replacement + weekly incremental deltas |
| Server | Akamai, `accept-ranges: bytes` |

Bundle contents (read from the ZIP central directory):

| Member | Uncompressed |
|---|---:|
| `npidata_pfile_20050523-20260809.csv` | 10.83 GiB |
| `pl_pfile_…csv` (Practice Location Reference) | 118,829,947 |
| `endpoint_pfile_…csv` | 125,310,263 |
| `othername_pfile_…csv` | 49,949,439 |
| `NPPES_Data_Dissemination_CodeValues.pdf` | 2,833,301 |
| `NPPES_Data_Dissemination_Readme_v.2.pdf` | 517,521 |

Plus a `_fileheader.csv` per data file holding the column-name row (the data CSVs themselves
carry a header too). The main file has **330 columns**.

**Cadence, quoted from the bundled readme (`NPPES_Data_Dissemination_Readme_v.2.pdf`, dated May
12, 2026, §1.2–1.3):** "Each month, two file versions will be available for download. These
files will contain all of the FOIA-disclosable **active** provider data in NPPES. These files
will replace the file provided the previous month." Weekly files "contain only the new
FOIA-disclosable NPPES provider data since the last weekly or monthly files were generated."

Two operational notes:

- **Use V2 only.** The source page states: "Effective 03/03/2026 NPPES will no longer support
  Version 1 of the Monthly and Weekly Downloadable File. Version 2 includes all updated field
  lengths with extended character limits for First Name and Legal Business Name fields."
- **The monthly file is active-providers-only**, so deactivated NPIs are largely pre-filtered by
  CMS. Deactivations are published separately
  (`NPPES_Deactivated_NPI_Report_081026_V2.zip`, 2,574 KB).

### Pinning (satisfies CLAUDE.md)

The dated URL is **stable and archival**, even though only the current month is linked from the
page. Verified `HTTP 200` for `…_July_2026_V2.zip`, `…_June_2026_V2.zip`, `…_May_2026_V2.zip`,
`…_January_2026_V2.zip`, `…_August_2025_V2.zip`, `…_January_2025_V2.zip`. So a specific month can
be pinned by URL + sha256 in the build manifest and re-fetched later — no mutable "latest"
alias is involved, and no scraping of the index page is needed at build time.

---

## 2. Taxonomy codes — exact, from NUCC 26.1

NPPES stores taxonomy **codes only**; it carries no classification or display-name column. Names
must be joined from the NUCC Health Care Provider Taxonomy code set.

- Authoritative source: <https://www.nucc.org/index.php/code-sets-mainmenu-41/provider-taxonomy-mainmenu-40/csv-mainmenu-57>
- Current version: **26.1, effective 7/1/2026** — `https://www.nucc.org/images/stories/CSV/nucc_taxonomy_261.csv`
  (529,245 bytes, 883 codes; columns `Code,Grouping,Classification,Specialization,Definition,Notes,Display Name,Section`)
- Cadence: **twice yearly**, 1 January (`X.0`) and 1 July (`X.1`). There was no 26.0 — the page
  shows Version 25.1 covering both 7/1/25 and 1/1/26.
- Note: NUCC states commercial use requires a license. This project is non-commercial academic;
  flagging it because it is a redistribution constraint on the joined lookup table.

**The four categories SPEC.md §2.3 asks for.** `Grouping` is "Allopathic & Osteopathic
Physicians" and `Section` is "Individual" for every row below. `any` = code appears in any of the
15 taxonomy slots; `primary` = that slot's Primary Taxonomy Switch is `Y`. Counts are NPI
records in the August 2026 file (both entity types).

| Code | Classification | Specialization | Display Name (exact) | any | primary |
|---|---|---|---|---:|---:|
| `207RX0202X` | Internal Medicine | Medical Oncology | Medical Oncology Physician | 8,851 | 6,277 |
| `207RH0003X` | Internal Medicine | Hematology & Oncology | Hematology & Oncology Physician | 20,903 | 17,073 |
| `2085R0001X` | Radiology | Radiation Oncology | Radiation Oncology Physician | 9,781 | 8,397 |
| `2086X0206X` | Surgery | Surgical Oncology | Surgical Oncology Physician | 3,418 | 2,341 |
| `207VX0201X` | Obstetrics & Gynecology | Gynecologic Oncology | Gynecologic Oncology Physician | 2,806 | 2,223 |

**Three adjacent codes that need an explicit include/exclude decision** — they are not in the
four requested categories but will change the density numbers, so the choice must be recorded in
the manifest rather than made implicitly:

| Code | Specialization | Display Name | any | primary | Recommendation |
|---|---|---|---|---:|---:|
| `2085R0203X` | Therapeutic Radiology | Therapeutic Radiology Physician | 1,050 | 299 | **Include** with radiation oncology |
| `2080P0207X` | Pediatric Hematology-Oncology | Pediatric Hematology & Oncology Physician | 4,445 | 3,779 | **Include**, but count separately |
| `207RH0000X` | Hematology | Hematology Physician | 3,718 | 1,561 | **Exclude** (not an oncology code) |

`2085R0203X` matters and is easy to miss. Its NUCC definition is a redirect: *"Therapeutic
Radiology certificate name was changed to Radiation Oncology. Use Radiation Oncology."* It is
still a live code carrying 1,050 NPIs (299 as primary) — legacy registrations that never
re-coded. Dropping it silently undercounts radiation oncology by ~10%.

Deliberately **excluded** as non-physician or facility codes, though they match a naive
`grep -i oncolog`: `163WX0200X` (Oncology RN), `163WP0218X` (Pediatric Oncology RN),
`364SX0200X` / `364SX0204X` (Oncology CNS), `1835X0200X` (Oncology Pharmacist), `133VN1301X`
(Oncology Nutrition RD), `261QX0200X` (Oncology Clinic/Center), `261QX0203X` (Radiation Oncology
Clinic/Center). The last two are `Section = Non-Individual` — counting them as oncologists would
double-count institutions against their own staff.

**Entity type filter is mandatory.** Of 48,112 records carrying at least one target code,
**38,811 are Entity Type 1 (Individual) and 9,301 are Entity Type 2 (Organization)**. Per the
bundled `CodeValues.pdf` Exhibit 1-1, `1 = Individual`, `2 = Organization`. A density measure
must filter `Entity Type Code = 1` or it inflates by ~24%.

---

## 3. Practice address is adequate for county assignment

NPPES carries **two** addresses, both with ZIP: `Provider Business Mailing Address …` (cols
21–28) and `Provider Business Practice Location Address …` (cols 29–36). **Use the practice
location, never the mailing address** — the mailing address is where the provider receives post
and is the one that legitimately holds PO boxes.

There is **no county field and no latitude/longitude** anywhere in the file, so county FIPS must
be derived. Postal code is `VARCHAR(20)` and holds ZIP+4 without a hyphen.

### Measured quality of the practice-address field

Denominator: 37,778 Entity Type 1 records with a core oncology code and a US/blank country code.

| Check | N | % |
|---|---:|---:|
| Blank practice address line 1 | 0 | 0.00% |
| **PO box in practice address line 1** | **12** | **0.03%** |
| Blank practice ZIP | 0 | 0.00% |
| ZIP+4 present (9 digits) | 34,058 | 90.15% |
| 5-digit ZIP only | 3,720 | 9.85% |
| Malformed ZIP | 0 | 0.00% |
| Valid 2-letter state | 37,562 | 99.43% |

The completeness is essentially perfect and the **PO-box concern is empirically negligible in
the practice-location field** (12 records out of 37,778) — because CMS requires a physical
location there and routes PO boxes to the mailing address. That is the single most reassuring
result in this audit, and it is specific to the practice field: do not generalize it to the
mailing address.

### Staleness is the real weakness

`Last Update Date` for the same 37,778 records:

| Year | N | % |
|---|---:|---:|
| 2026 | 4,116 | 10.90% |
| 2025 | 4,512 | 11.94% |
| 2024 | 3,532 | 9.35% |
| 2023 | 3,021 | 8.00% |
| 2022 | 2,870 | 7.60% |
| 2021 | 2,865 | 7.58% |
| **before 2021** | **16,862** | **44.6%** |

**44.6% of oncology records have not been touched in NPPES in over five years.** This is the
binding accuracy limit on the measure, and it is not fixable from NPPES alone. `Last Update Date`
also covers any field edit, so it is an *upper* bound on address freshness — a record updated in
2026 may have had only a phone number changed. Treat it as a lower bound on staleness, not a
measure of address correctness.

### Multi-location practices are partly solvable

The main file holds only the **first primary** practice location per NPI. The bundle's
`pl_pfile` (Practice Location Reference File) holds *all non-primary* locations — the readme §2.3
states it "contains all of the non-primary Practice Locations associated with Type 1 and Type 2
NPIs." Measured across all NPIs:

- 1,241,921 secondary practice-location rows
- **800,662 distinct NPIs have at least one secondary practice location**
- distribution: 587,059 have 1; 132,227 have 2; 39,784 have 3; 5,820 have 10+; max is **363**
- 62,261 NPIs (7.8% of those with secondaries) have secondary locations **in more than one state**

So the "group practice lists only one address" problem is real but is *mitigable*, not inherent —
`pl_pfile` is only 118 MB and joins on NPI. This is a genuine improvement available over the
common published approach of using the primary address alone.

### ZIP-crosswalk vs street geocoding

ZIPs genuinely span county lines. Computed directly from the Census 2020 ZCTA-to-county
relationship file (`https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt`):

- 33,791 ZCTAs total
- **10,186 (30.1%) intersect more than one county**; 9,441 (27.9%) have ≥2 counties each holding
  ≥1% of the ZCTA's land; one ZCTA touches 6 counties

Restricted to the 4,121 distinct ZIPs where oncologists actually practise: 826 (20.6%) span
multiple counties, covering **11.6% of oncologists**. Also, 3.62% of oncologists sit in ZIPs with
**no ZCTA at all** — USPS "unique" ZIPs assigned to single large institutions, which is exactly
what a major cancer center has. A pure ZIP crosswalk therefore fails hardest on the biggest
providers.

**Recommendation: geocode the street address, fall back to ZIP.** Verified working, free, no API
key, no registration:

- `https://geocoding.geo.census.gov/geocoder/geographies/addressbatch`, `benchmark=Public_AR_Current`,
  `vintage=Current_Current` — returns state FIPS and county FIPS as separate columns
- documented limit: "There is currently an upper limit of 10,000 records per batch file"
  (<https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html>)

Fallback for non-matches: HUD USPS ZIP crosswalk (quarterly, ZIP-to-County with `res_ratio` /
`bus_ratio` / `tot_ratio` allocation weights; a ZIP appearing twice means it intersects two
counties) — <https://www.huduser.gov/portal/datasets/usps_crosswalk.html>. For oncologists,
`bus_ratio` is the appropriate weight, not `res_ratio`. HUD's site rejected automated fetches
during this audit (HTTP 202), so the crosswalk itself was not downloaded; the Census ZCTA
relationship file used above is an adequate, freely scriptable substitute for the fallback.

---

## 4. Download and processing time — not a constraint

Measured on this machine, 2026-08-24:

| Step | Measured |
|---|---|
| Download 1.07 GiB ZIP | **1.9 s** (616 MB/s sustained; a 100 MB ranged probe hit 338 MB/s) |
| Full scan of the 10.83 GiB CSV, Python `csv` | ~4–5 min per pass |
| Geocode 13,361 distinct addresses (2 batches) | 233 s + 47 s = **4.7 min** |

The "several GB, slow download" worry does not survive measurement — **download is seconds; the
single-threaded CSV parse is the slow part**, and DuckDB's `read_csv` will cut that substantially
over the Python loop used here.

Useful trick, used throughout this audit: the ZIP is served with `accept-ranges: bytes`, so the
column headers and both bundled PDFs can be pulled with ranged requests plus a raw-deflate
decompress **without downloading the 1.07 GiB archive**. Worth keeping for a cheap
schema-drift check in CI.

---

## 5. Sanity checks that the filter is right

Top practice ZIPs by oncologist count are exactly the places they should be — this is the
strongest available evidence that the taxonomy filter selects real oncologists:
`77030` (863, MD Anderson / Texas Medical Center), `10065` (431, Memorial Sloan Kettering),
`19104` (387, Penn), `02215` (366, Dana-Farber), `55905` (350, Mayo Rochester).

Top counties after geocoding: `36061` New York (1,233), `06037` Los Angeles (1,230), `25025`
Suffolk MA (1,005), `48201` Harris TX (996), `17031` Cook IL (882), `42101` Philadelphia (671),
`53033` King WA (629), `04013` Maricopa (470), `48113` Dallas (417), `39035` Cuyahoga (375).

All 51 states/DC are represented. **Kansas is present**, which matters: Kansas withholds
county-level *incidence* (see `04-suppression-overlap.md`) but its oncologist density is fully
computable. Kansas county pages can therefore carry a real access measure even where MIR is
permanently unavailable.

---

## 6. Pipeline output — the headline finding

Full run: 9,726,865 NPI records → taxonomy + Entity Type 1 filter → 37,778 US oncologists →
13,361 distinct practice addresses → Census batch geocode → county FIPS.

| Assignment path | Oncologists | % |
|---|---:|---:|
| Street-address geocode (county FIPS exact) | 33,066 | 87.5% |
| ZIP fallback (largest-land-share county) | 4,129 | 10.9% |
| Unresolved (no street match, no ZCTA) | 583 | 1.5% |

Address-level geocoder outcome: 86.6% Match (of which 769/872 "Exact" in a 1,000-address
validation sample), 12.7% No_Match, 0.7% Tie. Ties need a documented tie-break rule; they are
small enough to resolve by taking the modal county.

**County coverage — this is the number SPEC.md §2.3 is really asking for:**

| Measure | Geocode only | Geocode + ZIP fallback |
|---|---:|---:|
| Counties with ≥1 oncologist | 1,123 | **1,174** |
| **Counties with ZERO oncologists** | 2,021 (64.3%) | **1,970 (62.7%)** |
| Counties with exactly 1 | 214 | 217 |
| Counties with ≤2 | 321 | 336 |
| Median oncologists per covered county | 6 | — |

**Roughly 62–64% of US counties have no oncologist of any of these specialties with a practice
address in the county.** SPEC.md §2.3 says "counties with no oncologist at all are the finding,
not missing data" — that instinct is correct and the finding is much larger than a footnote. It
is the majority of the map.

---

## 7. Consequence for M5

**Feasible. Build it.** No blockers; this is the least risky of the three access measures in
SPEC.md §2.3.

1. **Pin `NPPES_Data_Dissemination_August_2026_V2.zip` by dated URL + sha256** in the build
   manifest, alongside `nucc_taxonomy_261.csv`. Both are archival at a stable URL. Record the
   NUCC version string ("26.1, 7/1/2026") separately from the file hash, since NUCC reuses
   version labels across release dates.
2. **Record the taxonomy code list as data, not as a hard-coded literal** — the include/exclude
   decisions in §2 (`2085R0203X` in, `207RH0000X` out, pediatric counted separately) are
   defensible but arguable, and a reviewer will ask. Six codes recommended for the headline
   "oncologist" definition: `207RX0202X`, `207RH0003X`, `2085R0001X`, `2085R0203X`,
   `2086X0206X`, `207VX0201X`.
3. **Filter `Entity Type Code = 1`.** Skipping this inflates counts by ~24%.
4. **Two-stage county assignment**: Census batch geocoder on the street address (87.5%), HUD or
   ZCTA ZIP fallback for the remainder (10.9%). Persist the geocode result keyed on the distinct
   address string — 37,778 providers collapse to 13,361 addresses, so the geocode is cheap and
   cacheable, and re-running monthly costs ~5 minutes.
5. **Carry the assignment method per provider into the output** so the county page can state how
   its number was derived. A county whose count rests entirely on ZIP-fallback assignment is
   weaker evidence than one built from exact street matches.
6. **Zero is a real zero, and must not render as "no reliable estimate."** This is a direct
   collision with the CLAUDE.md rule that suppressed/unmodeled cells never render as zero. The
   two states are genuinely different here and both are needed: *"no oncologist practises in this
   county"* (a measured finding, ~1,970 counties) versus *"we could not determine this"* (the
   1.5% unresolved). Encode them as distinct states in the per-county JSON, not as the same null.
7. **Uncertainty (CLAUDE.md: never optional).** A density per 100k from an exact provider count
   has no sampling error, so the honest uncertainty statement is not a confidence interval — it
   is the **44.6% five-year staleness rate** and the 12.5% non-exact geocode share. State those
   as a documented data-quality caveat adjacent to the number. Do not manufacture a CI to satisfy
   the rule; say plainly what is and is not known.
8. **Consider joining `pl_pfile`** to capture secondary practice locations (800,662 NPIs have
   them nationally). This measurably improves on the primary-address-only approach most published
   work uses. Treat it as a documented enhancement with a clear counting rule — a provider at
   three sites should not count as three oncologists; either fractionally allocate or count
   "counties with any oncology presence" as a separate indicator.
9. **Editorial (SPEC.md §4).** "Zero oncologists in this county" is a supply fact and is safe
   copy. It is *not* a statement about what care residents receive — they may travel a short
   distance across a county line. Since 30.1% of ZCTAs straddle counties, the travel-time measure
   (Task 0.6) is the necessary companion, and the oncologist-density number should not be
   presented alone as an access conclusion.

**Known limitations to state in the paper**, all measured above rather than asserted: 44.6%
of records not updated in 5+ years; primary practice address only unless `pl_pfile` is joined;
12.5% of providers placed by ZIP rather than street match; NPPES reflects *registration*, not
active clinical practice or FTE, so a listed oncologist may be retired, administrative, or
practising elsewhere; and per the bundled MLN reference, "Issuance of an NPI does not ensure or
validate that the Health Care Provider is Licensed or Credentialed."

---

## Sources

All fetched or computed 2026-08-24.

- NPPES file index — <https://download.cms.gov/nppes/NPI_Files.html>
- Monthly bulk file — <https://download.cms.gov/nppes/NPPES_Data_Dissemination_August_2026_V2.zip>
- `NPPES_Data_Dissemination_Readme_v.2.pdf` (May 12, 2026) and
  `NPPES_Data_Dissemination_CodeValues.pdf` (Feb 1, 2025) — bundled inside the ZIP
- NUCC taxonomy CSV index — <https://www.nucc.org/index.php/code-sets-mainmenu-41/provider-taxonomy-mainmenu-40/csv-mainmenu-57>
- NUCC 26.1 code set — <https://www.nucc.org/images/stories/CSV/nucc_taxonomy_261.csv>
- Census Geocoding Services API — <https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html>
- Census 2020 ZCTA-to-county relationship file — <https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt>
- HUD USPS ZIP crosswalk — <https://www.huduser.gov/portal/datasets/usps_crosswalk.html>
- NPI: What You Need to Know (CMS MLN) — <https://www.cms.gov/Outreach-and-Education/Medicare-Learning-Network-MLN/MLNProducts/Downloads/NPI-What-You-Need-To-Know.pdf>
