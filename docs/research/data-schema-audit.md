# Data schema audit — `hf://datasets/seandavis/state-cancer-profiles/`

Audited 2026-08-24 against the live Hugging Face files (all four downloaded and
profiled with DuckDB 1.4.4). Every number below is measured, not inferred.

**Vintage audited:** `_extracted_at` spans `2026-08-24T01:33:42` → `2026-08-24T02:33:48`,
i.e. a single scrape run. This is a post-PR#39 release: all four files carry a
`suppression_reason` column, so suppressed cells are retained as rows with typed
nulls rather than dropped. Historical GitHub releases do **not** have this
(see `state-cancer-profile-scraper/docs/schema-drift.md`) — anything the app says
about suppression is true of this vintage only.

**Sizes / row counts**

| File | Bytes | Rows |
|---|---:|---:|
| `state_cancer_profiles_incidence.parquet` | 75,844,731 | 11,048,853 |
| `state_cancer_profiles_mortality.parquet` | 38,275,580 | 5,866,632 |
| `state_cancer_profiles_demographics.parquet` | 17,508,453 | 3,281,295 |
| `state_cancer_profiles_risk.parquet` | 644,522 | 78,798 |

**DuckDB-WASM viability: confirmed.** HF serves these with
`accept-ranges: bytes`, `access-control-allow-origin: *` on the CDN leg, and
returns `206` with a correct `Content-Range` for a ranged request from an
arbitrary `Origin`. The 302 → CDN redirect also echoes the request Origin.
Range + CORS both work, so partial reads with predicate/projection pushdown are
possible; the app does not have to download 76 MB to answer a county question.

---

## 1. `state_cancer_profiles_incidence.parquet`

11,048,853 rows. Grain: **`(fips, cancer, sex, race, stage, age, areatype)` is a
unique key** (verified: zero duplicate groups). `areatype` is load-bearing in the
key — drop it and the national rows collide, because national is emitted twice
(once per areatype). This is the single biggest footgun for any `GROUP BY` in the app.

### Columns (30)

| Column | Type | Notes |
|---|---|---|
| `reported_locale` | VARCHAR | Raw scraped label. Carries footnote markers and undecoded HTML entities — `Kentucky(7)`, `Harrison County, Kentucky(7)`, `US (SEER+NPCR) &sect; (1)`. **Do not display this.** |
| `fips` | VARCHAR | Zero-padded 5-char. County `21097`; state `21000`; national `00000`. |
| `2023_rural_urban_continuum_codesrural_urban_note` | VARCHAR | RUCC, but collapsed to a binary: `Rural` (6,745,086) / `Urban` (4,117,602) / NULL (186,165 — exactly the state + national rows). Column name is a mangled header concatenation; quote it. |
| `age_adjusted_rate_per_100_000` | DOUBLE | The headline measure. NULL iff `suppression_reason` is set. |
| `lower_ci_rate`, `upper_ci_rate` | DOUBLE | Properly typed here (contrast mortality). |
| `ci_rank`, `lower_ci_rank`, `upper_ci_rank` | DOUBLE | Within-state rank; sparse. |
| `average_annual_count` | DOUBLE | Case count. NULL exactly when rate is NULL. |
| `recent_trend` | VARCHAR | `stable` 582,141 / `falling` 135,324 / `rising` 91,405 / `*` 5,082,443 / `[P1 note]` 202,230 / NULL 4,955,310. **Undecoded glyphs live in this column** — `*` and `[P1 note]` are not nulls. NULL is structural: trend is never computed for `stage='Late Stage'` rows. |
| `recent_5_year_trend_in_rate` | DOUBLE | AAPC. |
| `lower_ci_trend_in_rate`, `upper_ci_trend_in_rate` | DOUBLE | |
| `year` | VARCHAR | **Single value: `Latest 5-year average`.** See §5. |
| `sex` | VARCHAR | 3 values, exactly balanced at 3,682,951 each. |
| `stage` | VARCHAR | `All Stages` 6,093,543 / `Late Stage (Regional & Distant)` 4,955,310. |
| `race` | VARCHAR | 6 values. |
| `cancer` | VARCHAR | 23 values. |
| `areatype` | VARCHAR | `By County` / `By State`. Part of the key. |
| `age` | VARCHAR | 7 values. |
| `state_fips` | VARCHAR | 2-char, `00` for national. |
| `measurement` | VARCHAR | Constant `incidence`. Dead column. |
| `locale_type` | VARCHAR | `county` / `state` / `national`. |
| `_extracted_at` | VARCHAR | ISO timestamp **as a string**, not a TIMESTAMP. |
| `url` | VARCHAR | Source query URL — useful for a "view on SCP" deep link. |
| `suppression_reason` | VARCHAR | `suppressed_small_count` 9,369,770 / `withheld_state_law` 202,230 / NULL 1,476,853. |
| `percent_of_cases_with_late_stage` | VARCHAR | **Typed VARCHAR, carries raw `*`.** NULL for all `All Stages` rows; for `Late Stage` rows it is `*` 4,485,901 times and a numeric string 469,409 times. |
| `locale` | VARCHAR | Cleaned name — county name for county rows, state name for state rows. Use this. |
| `state` | VARCHAR | Cleaned state name, **county rows only**; NULL on state-tier and national rows. |

### Cardinalities

- `locale_type`: `county` 10,862,688 rows / 3,143 FIPS; `state` 179,073 / 52 FIPS;
  `national` 7,092 / 1 FIPS (`00000`, duplicated across both areatypes at 3,546 each).
- `cancer` (23): All Cancer Sites, Bladder, Brain & ONS, Breast (Female),
  Breast (Female in situ), Cervix, Childhood (Ages <15, All Sites),
  Childhood (Ages <20, All Sites), Colon & Rectum, Esophagus,
  Kidney & Renal Pelvis, Leukemia, Liver & Bile Duct, Lung & Bronchus,
  Melanoma of the Skin, Non-Hodgkin Lymphoma, Oral Cavity & Pharynx, Ovary,
  Pancreas, Prostate, Stomach, Thyroid, Uterus (Corpus & Uterus, NOS).
- **The cancer × stage × age cross-product is ragged.** Most sites have 2 stages ×
  5 ages. `All Cancer Sites`, `Leukemia`, `Breast (Female in situ)` have
  `All Stages` only (1 stage × 5 ages). The two `Childhood` sites have 1 stage ×
  1 age, and their single age value is `Age < 15` / `Age < 20` respectively —
  **not** `All Ages`. A UI that offers age and stage as free-floating filters will
  produce empty results constantly.
- `sex` (3): Both Sexes, Female, Male.
- `race` (6): All Races (includes Hispanic), White (Non-Hispanic),
  Black (Non-Hispanic), Hispanic (any race),
  Asian / Pacific Islander (Non-Hispanic), Amer. Indian / AK Native (Non-Hispanic).
  AI/AN is short 185 counties relative to the others (1,748,196 rows vs ~1,859,895).
- `age` (7): All Ages, `<50`, `50+`, `<65`, `65+`, `Age < 15`, `Age < 20`.
- `year` (1): `Latest 5-year average`.

### Quirks

- **Suppression is the norm, not the exception.** Only **13.4%** of rows
  (1,476,853) have a non-null rate. By tier: county 12.4% available, state 66.2%,
  national 99.9%.
- **But the headline stratum is nearly complete.** County × `All Cancer Sites` ×
  `Both Sexes` × `All Races` × `All Ages` × `All Stages` is **96.4% populated**
  (3,143 rows). The 86.6% overall suppression is driven by the fine strata —
  race × age × stage × site at county level. Availability by race for that
  otherwise-complete stratum: All Races 96.4%, White 95.7%, Black 48.8%,
  Hispanic 42.5%, API 22.0%, AI/AN 18.7%. **Any race-stratified county view needs
  an explicit "no reliable estimate" state, not an empty chart.**
- **Kansas is fully withheld at county level.** All 202,230 `withheld_state_law`
  rows are Kansas; its 105 counties have zero available rates in the headline
  stratum. This is state law, permanent, and should be labelled distinctly from
  small-count suppression.
- Smallest-N states are effectively single-county-ish for map purposes: Delaware 3,
  Hawaii 5 (4 available), Rhode Island 5, Connecticut 8.
- Suppression decoding is **partial**: `age_adjusted_rate_per_100_000`,
  `average_annual_count`, and the rate CIs are properly nulled, but
  `recent_trend` and `percent_of_cases_with_late_stage` still carry literal `*`
  and `[P1 note]` strings. Filter or `TRY_CAST` these.

---

## 2. `state_cancer_profiles_mortality.parquet`

5,866,632 rows. Grain: **`(fips, cancer, sex, race, age, areatype)`** — unique,
verified. Note the absence of `stage` from the key.

### Columns (28) — differences from incidence

Same shape as incidence **minus** `stage` and `percent_of_cases_with_late_stage`,
plus these type divergences:

| Column | incidence | mortality | Consequence |
|---|---|---|---|
| `lower_ci_rate` | DOUBLE | **VARCHAR** | 5,349,611 rows hold the literal `*`. |
| `upper_ci_rate` | DOUBLE | **VARCHAR** | same |
| `recent_5_year_trend_in_rate` | DOUBLE | **VARCHAR** | 5,464,650 rows hold `*`. |

`age_adjusted_rate_per_100_000`, `ci_rank`/`lower_ci_rank`/`upper_ci_rank`,
`average_annual_count`, `lower_ci_trend_in_rate`, `upper_ci_trend_in_rate` are
DOUBLE in both. **This is the sharpest cross-file trap:** a view that unions
incidence and mortality, or that computes an incidence-to-mortality ratio, must
`TRY_CAST` the mortality CI and trend columns. They will not cast implicitly and
the raw `*` will not compare as null.

### Cardinalities

- `locale_type`: `county` 5,769,018 / 3,143 FIPS; `state` 93,942 / 52;
  `national` 1,836 × 2 areatypes / 1.
- `cancer` (22): the incidence list minus `Breast (Female in situ)`.
  All non-childhood sites are exactly 287,580 rows; the two childhood sites
  57,516 each. **`Leukemia` is a full-size site here (287,580) but a reduced one
  in incidence (284,745)** — because incidence splits by stage and mortality
  does not.
- `sex`, `race`, `age`, `year`: identical vocabularies to incidence.
  `race` counts are ~977,670 each; AI/AN is *not* short here.
- No `stage` dimension at all. The README's example mortality rows show a `stage`
  column; the current file has none. **Schema has drifted** — do not build a
  mortality-by-stage view.

### Quirks

- `suppression_reason`: `suppressed_small_count` 5,349,611 / NULL 517,021.
  **Only 8.8% of mortality rows carry a value** — noticeably worse than incidence.
- No `withheld_state_law` rows. Kansas withholds incidence, not mortality.
- Cross-topic caveat carried from the source docs: incidence and mortality cover
  **different five-year windows**. Both label their `year` as
  `Latest 5-year average`, which makes them look aligned when they are not. Any
  side-by-side or ratio view must say so.

---

## 3. `state_cancer_profiles_risk.parquet`

78,798 rows — three orders of magnitude smaller than incidence, and by far the
messiest of the four. Grain: `(fips, risk, sex, race, locale_type)` — unique.

### Columns (20)

| Column | Type | Notes |
|---|---|---|
| `reported_locale` | VARCHAR | Only locale label available — **no `locale`/`state` clean columns here.** |
| `fips` | VARCHAR | 5-char, same convention as incidence. |
| `percent` | DOUBLE | The measure — **populated on only 10,331 of 78,798 rows (13%).** See quirks. |
| `lower_ci_percent`, `upper_ci_percent` | DOUBLE | |
| `respondents` | DOUBLE | BRFSS respondent count; non-null 8,996. |
| `topic`, `topic_label` | VARCHAR | 7 topics. |
| `risk`, `risk_label` | VARCHAR | 37 measures, coded `v01`…`v521`. |
| `race` | VARCHAR | 8 values — **a different vocabulary from incidence/mortality.** |
| `sex` | VARCHAR | Both Sexes 36,596 / Male 23,749 / Female 18,453 (unbalanced by design — sex-specific measures). |
| `datatype` | VARCHAR | Constant `Direct Estimates`. Dead column, and **misleading** — the model-based measures are also labelled this. |
| `statefips_query` | VARCHAR | The query parameter used (`00` or `99`), not a geography. Explains the `other` duplication below. |
| `state_fips` | VARCHAR | 2-char. |
| `locale_type` | VARCHAR | `county` / `state` / `national` / **`other`**. |
| `_extracted_at`, `url` | VARCHAR | |
| `suppression_reason` | VARCHAR | `suppressed_small_count` 4,141 / NULL 74,657. |
| `model_based_percent3` | VARCHAR | **Second measure column.** Holds the value for six measures; note the trailing space in the raw strings (`"23.7 "`). |

### Cardinalities

Topics and measure counts:

| topic | topic_label | measures | rows |
|---|---|---:|---:|
| `smoke` | Smoking | 17 | 42,116 |
| `colorec` | Colorectal Screening | 5 | 20,838 |
| `dietex` | Diet & Exercise | 7 | 7,248 |
| `men` | Men's Health | 1 | 6,286 |
| `alcohol` | Alcohol | 1 | 990 |
| `women` | Women's Health | 3 | 990 |
| `vaccine` | Vaccines | 2 | 330 |

`locale_type`: `other` 32,300 / `county` 32,010 / `state` 14,198 / `national` 290.

`race` (8): All Races (includes Hispanic) 66,930; Black (Non-Hispanic) 2,310;
Hispanic (any race) 2,310; White (Non-Hispanic) 2,310;
Amer. Indian / AK Native (Non-Hispanic) 2,310;
**`Asian / Pacifice Islander (Non-Hispanic)`** 1,980 *(sic — typo in the source)*;
Asian (Non-Hispanic/Latino) 330;
Native Hawaiian/other Pacific Islander (Non-Hispanic/Latino) 318.

### Quirks — read all of these before building a risk view

1. **The value lives in one of two columns depending on the measure.**
   62,860 rows have `percent IS NULL` **and no `suppression_reason`** — because the
   value is in `model_based_percent3` instead. Breakdown:
   - `percent` set, `model_based_percent3` null: 10,331
   - `model_based_percent3` set, `percent` null: 62,860
   - both null, suppressed: 4,141
   - both null, no reason given: 1,466 (unexplained)

   The six model-based measures, all with complete 3,143-county coverage and
   **zero** `percent` values: `v300` Former Smoking, `v301` Former Smoking Quit 1
   Year+, `v302` Colonoscopy Past 10 Years, `v303` Guidance Sufficient CRC,
   `v304` Ever Had FOBT, `v350` PSA Screening. A naive
   `SELECT percent … WHERE risk='v302'` returns all nulls and looks like a
   coverage gap. It is not. **`coalesce(percent, try_cast(trim(model_based_percent3) AS DOUBLE))`
   is the correct read**, ideally with a flag recording which column supplied it —
   direct BRFSS estimates and small-area model-based estimates are not the same
   thing and should not be charted identically.

2. **`locale_type='other'` is a near-duplicate of `locale_type='county'`.**
   32,010 of the 32,300 `other` rows share an exact `(fips, risk, sex, race)` key
   with a `county` row. The split is an artifact of the scraper's query strategy:
   `county` rows come from `statefips=99` URLs, `other` rows from `statefips=00`.
   The only `other`-exclusive FIPS is `02900` (**Alaska**, 290 rows), which is a
   state, not a county. **Any county-level risk query must filter to exactly one
   of these or it double-counts.** Recommend `locale_type='county'` plus an
   explicit special case for Alaska.

3. **The state tier is missing Alaska, DC, and Puerto Rico.** `locale_type='state'`
   has 49 distinct states (Alabama…Wyoming, no AK, no DC, no PR). Alaska is in
   `other` as `02900`; DC and PR are absent entirely from risk. Incidence and
   mortality have 52 state-tier FIPS. **The risk state map will have holes that
   the cancer maps do not.**

4. **County coverage is extremely thin outside the model-based measures.** Most
   BRFSS measures are state-only: `v19` (Current Smokers) has 882 state rows but
   only 36 county rows. Measures with `n=55`/`165`/`330`/`990` (smoking laws,
   HPV vaccination, mammography, Pap) are state-tier only. The county-level risk
   layer is effectively *six model-based measures*, nothing more.

5. Availability where `percent` does apply ranges 37%–99%; HPV vaccination (`v281`,
   `v282`) and the smoking-law measures are ~96–99% complete because they are
   state-level administrative data, not survey estimates.

---

## 4. `state_cancer_profiles_demographics.parquet`

3,281,295 rows. Grain: `(area_code, demo, sex, race, age, areatype)` — unique.

### Columns (43)

Dimension / key columns:

| Column | Type | Notes |
|---|---|---|
| `reported_locale` | VARCHAR | Only locale label; **no `locale`/`state` clean columns.** |
| **`area_code`** | VARCHAR | **The geography key is named `area_code`, not `fips`.** Same 5-char convention and same value domain. |
| `2023_rural_urban_continuum_codesrural_urban_note` | VARCHAR | RUCC, as in incidence. |
| `rank` | VARCHAR | Free text, e.g. `"1620 of 2776"`. Not a number. Parse or ignore. |
| `topic`, `topic_label` | VARCHAR | 8 topics. |
| `demo`, `demo_label` | VARCHAR | 44 measures, zero-padded codes (`00002`…`03014`). |
| `areatype` | VARCHAR | `By County` / `By State`. |
| `race` | VARCHAR | **10 values, a third distinct vocabulary, with encoding damage.** |
| `sex` | VARCHAR | Both Sexes 1,208,657 / Female 1,036,319 / Male 1,036,319. |
| `age` | VARCHAR | 7 values, **all different from the incidence/mortality age labels.** |
| `state_fips`, `locale_type`, `_extracted_at`, `url` | VARCHAR | |
| `suppression_reason` | VARCHAR | **100% NULL.** Demographics carries no suppression decoding at all. |

Value columns — 26 of them:

| Column | Type |
|---|---|
| `percent` | DOUBLE |
| `value_dollars`, `value_index`, `persistent_poverty` | VARCHAR |
| 22 per-measure raw columns: `households_with_>1_person_per_room`, `people_education:_less_than_9th_grade`, `people_education:_at_least_bachelor's_degree`, `people_with_limited_access`, `people_insured`, `people_uninsured`, `people_age_under_18`, `people_age_40_and_over`, `people_age_50_and_over`, `people_age_65_and_over`, `people_age_18_39`, `people_age_40_64`, `people_foreign_born`, `people_black`, `people_ai/an`, `people_api`, `people_hispanic`, `people_white`, `people_non_hispanic_origin_recode`, `people_male`, `people_female`, `families_below_poverty`, `people_below_poverty`, `people_<150pct_of_poverty` | mixed DOUBLE / VARCHAR |

### The value-column layout — the thing to understand first

This file is long on `(topic, demo)` but **wide and sparse on value**: each row
populates exactly one per-measure raw column, plus (usually) the shared `percent`.
Verified mapping:

- **`percent` is the canonical numeric for 38 of 44 measures.** For each of those,
  the per-measure raw column is 100% populated and `percent` is the parsed subset;
  the gap is the string `"data not available"` sitting in the raw column
  (e.g. `demo='00002'`: 469,959 raw values, 454,216 parsed, 15,743 literal
  `"data not available"`).
- **Six measures have no `percent` at all** and must be read from elsewhere:
  - `00010` Median family income ($), `00011` Median household income ($) → **`value_dollars`** (VARCHAR, e.g. `"56250.000000000"`, or `"data not available"` 6,805×)
  - `03010`–`03014` SVI (Overall, Socioeconomic Status, Household Characteristics, Racial & Ethnic Minority Status, Housing Type & Transportation) → **`value_index`** (VARCHAR, 0–1, 3,143 county rows each)
  - `03001` Persistent Poverty → **`persistent_poverty`** (categorical: `no` 2,801 / `yes` 319 / `"data not available"` 23)
- `03003` Food insecurity is the one measure with `percent` and **no** per-measure
  raw column (12,788 rows, 9,636 populated).

Practical consequence: the app needs a small `demo → value column + value kind
(percent | dollars | index | categorical)` lookup. The 22 per-measure raw columns
are redundant with `percent` and can be ignored except as the source of the
`"data not available"` sentinel. **`percent IS NULL` in this file means either
"not available" or "wrong column" — it never means "suppressed", because
`suppression_reason` is always NULL here.**

### Cardinalities

`locale_type`: `county` 3,178,449 / 3,143 area codes; `state` 93,345 / 49;
`national` 1,905 × 2 areatypes / 1; **`other` 5,691 / 3**.

- **`locale_type='other'` = Alaska (`02900`), District of Columbia (`11001`),
  Puerto Rico (`72001`)**, 1,905 / 1,905 / 1,881 rows. So the state tier is 49,
  not 52, and the three missing entities are misfiled under `other`. Worse,
  **DC is coded `11001` (a county FIPS) here, while incidence/mortality use
  `11000` for DC-as-state** — the one place the geography keys genuinely diverge.
- Topics: Population (14 measures), Insurance (12), Poverty (4), SVI (5),
  Education (2), Income (2), Food Access (2), Crowding (1).
- Measure row counts are wildly uneven — from 3,143 (SVI, persistent poverty,
  county-only, no demographic stratification) to 469,959 (`00002` Ages under 18,
  `00003` Ages 65+, `00006` Bachelor's degree — fully crossed by race × sex × age).
  A generic "pick a demographic measure" control will therefore offer some
  measures that support race/sex/age breakdowns and some that support none.
- `race` (10) — **note the encoding damage and the unclosed paren, both verbatim
  from the source:**
  `All Races (includes Hispanic)` 1,351,959;
  `Hispanic (any race)` 300,827;
  `   White Non-Hispanic` 300,827 *(literal backslash-u escapes, undecoded NBSP)*;
  `Black` 290,927;
  `Amer. Indian / AK Native` 287,730;
  `Asian / Pacific Islander` 287,730;
  `White (includes Hispanic` 287,730 *(missing closing paren)*;
  `Hispanic (any race)`; `American Indian/Alaska Native Non-Hispanic` 57,855;
  `Asian Non-Hispanic` 57,855; `Black Non-Hispanic` 57,855.
  Two parallel schemes coexist — a bridged one without the `(Non-Hispanic)` suffix
  and a `… Non-Hispanic` one — and **neither matches the incidence/mortality
  vocabulary.**
- `age` (7): `All Ages` 1,045,095, `18 to 64 years`, `21 to 64 years`,
  `40 to 64 years`, `50 to 64 years`, `Under 65 years` (374,358 each),
  `Under 19 years` (364,410). **Zero overlap with the incidence/mortality age
  labels** (`<50`, `50+`, `<65`, `65+`).

### Quirks

- No `suppression_reason` decoding; missingness is the string
  `"data not available"` in the raw columns, and shows up as `percent IS NULL`.
- `rank` is text (`"1620 of 2776"`) and the denominator varies by measure, so it
  is not comparable across measures.
- `value_dollars` and `value_index` are VARCHAR and need `try_cast`.
  `value_dollars` includes ACS top-codes (`250001.000000000` appears 16×) — a
  ceiling value, not a real income.
- Several column names need quoting in SQL: `people_ai/an`,
  `people_education:_at_least_bachelor's_degree` (embedded apostrophe),
  `people_<150pct_of_poverty`, `households_with_>1_person_per_room`.

---

## 5. Cross-cutting: what is *not* in this dataset

Worth stating plainly because it constrains the app's whole information architecture.

- **There is no time dimension.** `year` has exactly one value in both
  incidence and mortality: `Latest 5-year average`. Risk and demographics have no
  year column at all. **No trend lines, no year sliders, no time-series charts
  are possible from a single release.** Change over time is available only as
  the precomputed `recent_trend` label (rising/falling/stable) and
  `recent_5_year_trend_in_rate` (AAPC) with its CI — a per-row scalar, not a series.
  Longitudinal analysis would require loading multiple *vintages*, which is the
  upstream archive's purpose and a separate, larger design question.
- **Incidence and mortality five-year windows differ** and are not labelled
  distinguishably. Per the source spec's Usage Notes: consecutive vintages share
  four of five years (so they must not be naively differenced), and SCP displays
  but excludes 2020 incidence from trend fits.
- No sub-county geography. No absolute population denominators except via the
  demographics percentages.

---

## 6. Shared join keys

**The geography key is clean and complete.** All four files contain **exactly the
same 3,194 geography codes** — verified by set intersection in both directions
(`incidence \ demographics` = 0, `demographics \ incidence` = 0). Same zero-padded
5-char format throughout. `00000` = national, `SS000` = state, everything else =
county.

| File | Geography column | State column | Clean label columns |
|---|---|---|---|
| incidence | `fips` | `state_fips` | `locale`, `state` |
| mortality | `fips` | `state_fips` | `locale`, `state` |
| risk | `fips` | `state_fips` (+ `statefips_query`, not a geography) | none |
| demographics | **`area_code`** | `state_fips` | none |

### Reliable join keys

- **`fips` / `area_code`** — the primary and only trustworthy cross-file key.
  Rename `area_code` on read for sanity.
- **`state_fips`** (2-char, `00` for national) — reliable in all four for rolling
  county rows up to a state.
- **`locale_type`** — present in all four with a *shared but not identical*
  domain: `county`/`state`/`national` everywhere, plus `other` in risk and
  demographics only, meaning two different things (near-duplicate county rows in
  risk; AK/DC/PR in demographics). **Do not treat `locale_type` as a
  cross-file-comparable filter without normalizing it first.**
- `areatype` — `By County`/`By State` in incidence, mortality, demographics;
  **absent from risk.** Needed in the incidence/mortality grain key.

### Keys that look shared but are not

- **`race`** — three incompatible vocabularies. incidence/mortality use
  `Asian / Pacific Islander (Non-Hispanic)`; risk uses
  `Asian / Pacifice Islander (Non-Hispanic)` (typo) *and* a separate
  `Asian (Non-Hispanic/Latino)` / `Native Hawaiian/other Pacific Islander …`
  split; demographics uses `Asian / Pacific Islander` (no suffix) alongside
  `Asian Non-Hispanic`, and has `   White Non-Hispanic` with
  undecoded escapes. **A crosswalk table is required before any race-stratified
  cross-topic view.** Practical minimum viable set that maps cleanly across all
  three: All Races, White, Black, Hispanic — and even those need string
  normalization.
- **`sex`** — the only dimension whose labels agree across all four
  (`Both Sexes` / `Male` / `Female`). Safe to join on directly.
- **`age`** — incidence/mortality (`<50`, `50+`, `<65`, `65+`, `All Ages`) and
  demographics (`18 to 64 years`, `Under 65 years`, …) share only `All Ages`.
  Not joinable beyond that. Risk has no `age` column at all — age bands are baked
  into `risk_label` text (`"Ages 50-75"`).
- **DC** — `11000` in incidence/mortality, `11001` in demographics. The one FIPS
  value that will silently fail to join for DC-as-a-state.

### Recommended shape for the app's base views

1. A **geography dimension** built from incidence (`fips`, `locale`, `state`,
   `locale_type`, RUCC) — it is the only file with cleaned name columns; risk and
   demographics have only the footnote-laden `reported_locale`.
2. Per-topic fact views that (a) normalize `locale_type`/dedupe risk's `other`
   rows, (b) coalesce risk's two value columns and demographics' four, and
   (c) `try_cast` mortality's VARCHAR CI/trend columns.
3. Join cross-topic on `fips` + `sex` only, and treat race and age as
   within-topic filters unless and until a crosswalk exists.
