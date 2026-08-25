# Peer tools landscape: US cancer incidence / mortality / risk explorers

Research date: 2026-08-24. Purpose: inform page and view design for Cancer Compass
(client-side Vite + TypeScript + DuckDB-WASM explorer over the scraped State Cancer
Profiles extract).

## Method and caveats

Primary sources are each tool's own site. Notes on how each was read, because it affects
how much weight to put on individual claims:

- **State Cancer Profiles** — pages read directly (`WebFetch`, and `curl` with a browser
  user-agent where WebFetch was refused). Filter inventories below are transcribed from
  the actual `<select>` options in the served HTML, so they are exact.
- **SEER\*Explorer** — landing//about pages read directly. The application itself is a
  SPA; its feature list is taken from SEER's own description of it.
- **CDC USCS Data Visualizations** — `www.cdc.gov` returns HTTP 403 to non-browser
  clients, so descriptive text comes from the
  [RestoredCDC mirror](https://restoredcdc.org/www.cdc.gov/united-states-cancer-statistics/dataviz/index.html)
  of the CDC "About the tool" page (an independent archive, snapshot dated 2025-01-06 —
  treat its *data vintages* as stale, not its feature descriptions). The **module
  inventory** was derived by reading the live application bundle at
  `https://gis.cdc.gov/Cancer/USCS/static/index-DTINlcDX.js` and enumerating its
  `/DataVizApi/GetJSON/*` endpoints — this is strong evidence of what data views exist,
  but it is not a rendered UI walkthrough, so layout/interaction claims for USCS are
  weaker than those for SCP.
- **IHME GBD** — `vizhub.healthdata.org` is a login-walled SPA. Capability claims come
  from IHME's own tool-description pages on `healthdata.org` and `ghdx.healthdata.org`.

---

## 1. NCI State Cancer Profiles (upstream source of Cancer Compass data)

<https://statecancerprofiles.cancer.gov/>

Self-described as an "interactive map engine" whose purpose is "to provide a geographic
profile of cancer burden in the United States and reveal geographic patterns … across
different population subgroups", aimed at "health planners, policy makers, and cancer
information providers" ([site home](https://statecancerprofiles.cancer.gov/),
[brochure PDF](https://statecancerprofiles.cancer.gov/about/State_Cancer_Profiles_Brochure.pdf)).

### Data topics and geography

Four topics ([/data-topics/](https://statecancerprofiles.cancer.gov/data-topics/index.php)):
Demographics, Screening & Risk Factors, Incidence, Mortality. The brochure lists geography
as **County / Health Service Area / State**, incidence and mortality as "counts and rates",
"late-stage rates and percentages", "historical trends", "CI\*Rank", "for over 20 types of
cancer", "by race, ethnicity, sex, and age".

Current vintages advertised on the home page: 2024 ACS (demographics), 2022 SEER incidence,
2022 USCS incidence, 2023 mortality.

### Views

| View | URL | What it does |
|---|---|---|
| Interactive Maps | `/map/index.php` | Choropleth of one measure for one geography |
| Incidence Rates table | `/incidencerates/index.php` | Sortable rate table incl. CI\*Rank, trend |
| Death Rates table | `/deathrates/index.php` | Same for mortality |
| Bar graphs | `/incidencerates/graph.php?…&graph=1` (by CI\*Rank) and `&graph=2` (by rate, with CIs) | Two fixed bar-chart variants reached from the table |
| Historical Trends | `/historicaltrend/index.php` | Long-run rate time series (line graph) |
| 5-Year Rate Changes | `/recenttrend/index.php` | Recent-trend graph |
| Screening & Risk Factors table | `/risk/index.php` | BRFSS prevalence table |
| Demographics table | `/demographics/index.php` | ACS indicator table |
| Quick Profiles | `/quick-profiles/index.php` | Canned per-state summary for a major cancer site |
| CI\*Rank | offsite: <https://surveillance.cancer.gov/cirank/> | Rank-with-confidence-interval methodology, hosted on a *different* site |

### Exact filter inventory (from served HTML)

**Incidence/mortality table** (`/incidencerates/index.php`): Area (US + 50 states + DC + PR),
Area Type (By State / By County / By HSA), Cancer Site (~22 sites), Race/Ethnicity, Sex,
Age (All / <50 / 50+ / <65 / 65+), Stage (All Stages / Late Stage), Rural/Urban,
Year (**"Latest 5-year average" or "latest single year" only**). Plus a limited
"Add Comparison" that adds a second series by Age, Cancer Incidence, Race, Rural/Urban, or Sex.

**Interactive Maps** (`/map/index.php`): Area, Area Type, **Data Group** (Cancer Rates /
Demographic Data / Screening & Risk Factors), Topic, Cancer, Data Type (Incidence All Stages /
Incidence Late Stage / Mortality), Race/Ethnicity (15 options), Sex, **Age — the dropdown
contains only "All Ages"**, Rural/Urban, Year(s) (Latest 5-year average / Latest single year,
the latter *US-by-state only*). The page carries the warning "Please note that not all
combinations of parameters will produce results."

**Historical Trends** (`/historicaltrend/index.php`): Area is **states and US only — no
county option**. Cancer (22 sites, incl. Childhood <15 and <20), Data (Incidence /
Mortality), Race/Ethnicity, Sex, Age, Rural/Urban.

**5-Year Rate Changes** (`/recenttrend/index.php`): Area (states/US), Data, Race, Sex, Age,
Rural/Urban — **no cancer-site selector**.

**Screening & Risk Factors** (`/risk/index.php`): Topic (Alcohol, Colorectal Screening,
Diet & Exercise, Men's Health, Smoking, Vaccines, Women's Health) → Variable, Race, Sex,
**Data Type (Direct Estimates / Bias-Adjusted Modeled Estimates)**, Area. The page states
county-level modeled estimates exist for only **12 named measures** (mammography, Pap,
colonoscopy, FOBT, current/former smoking, etc.); everything else is state-only. **No age
filter and no year selector** — age is baked into each variable's label
("Mammogram in Past 2 Years, Ages 40+").

**Demographics** (`/demographics/index.php`): Area, Area Type, Topic (Crowding, Education,
Food Access, Income, Insurance, Mobility, Non-English Language, Population, Poverty, Social
Vulnerability Index, Workforce) → Variable, Race, Sex, Age. Comparison limited to
Age/Race/Sex. Caveat printed on the page: "Demographic variables are available for a limited
selection of race/age/sex combinations."

### Usability gaps

1. **Server-rendered, form-submit, full-page-reload architecture.** Every view is a separate
   `.php` page; changing any filter reposts the form. A single US-by-county incidence query
   (`/incidencerates/index.php?stateFIPS=00&areatype=county&cancer=001&…`) returns
   **~10.6 MB of HTML** for one table. Cross-view navigation is by hand-built query-string
   links (`graph.php?…&graph=1`, `map/index.php?…`), so state is carried but the whole page
   re-renders.
2. **One state at a time, one measure at a time.** Area is a single-select. You cannot
   select "Kentucky + West Virginia + Ohio", and there is no multi-select of cancer sites.
   The "Add Comparison" affordance covers only Age/Cancer/Race/Rural-Urban/Sex.
3. **No real time dimension in the map or tables.** The only Year values are "Latest 5-year
   average" and "latest single year". Time series live in a *separate* Historical Trends
   page that is **state-level only** — so county-level trend is reduced to a one-word
   `recent_trend` label ("rising"/"falling"/"stable") plus a 5-year APC in the table. There
   is no year slider, no animated choropleth, no county trend line anywhere.
4. **Topics are siloed.** Incidence, mortality, risk factors, and demographics each have
   their own page with its own filter vocabulary. The map's "Data Group" selector shows one
   group at a time. There is **no bivariate view** — you cannot plot smoking prevalence
   against lung cancer incidence across counties, which is arguably the question the site's
   own data most invites.
5. **Fixed chart repertoire.** Two bar-chart variants, one line chart, one choropleth. No
   small multiples, no faceting, no user choice of encoding, no ranking-with-uncertainty
   visual beyond the CI\*Rank column.
6. **Uncertainty is present but visually marginal.** The data carry rate CIs, CI\*Rank with
   rank CIs, and trend CIs, but only `graph=2` renders CIs, and CI\*Rank interpretation is
   pushed to an offsite methodology page and an FAQ ("Cancer statistics require careful
   interpretation", per Quick Profiles).
7. **Per-query export only; no bulk data and no API.** The results page has an "Export Data"
   link (per-query CSV), which is why the upstream scraper exists at all: "the existing site
   does not have bulk downloads or an API"
   ([state-cancer-profile-scraper README](https://github.com/seandavi/state-cancer-profile-scraper)).
8. **Sparse-combination discovery is trial and error.** The map page warns that "not all
   combinations of parameters will produce results", and the scraper's own catalog finds
   "~70-80% of the cartesian space" is suppressed or invalid. The UI gives no advance
   signal about which combinations exist.
9. **No shareable analysis state beyond a URL you have to hand-assemble**, no saved views,
   no annotation, no side-by-side of two different queries.

---

## 2. SEER\*Explorer

<https://seer.cancer.gov/statistics-network/explorer/>

### What it offers

Six statistic types: SEER Incidence, U.S. Mortality, Survival (relative survival),
Prevalence, Risk of Diagnosis/Dying (lifetime probability), and Preliminary Estimates
(delay-adjusted, through 2022).

View types: recent and long-term trend with annual percent change; recent-5-year rate
comparison bar charts; rates by age group; stage distribution (localized / regional /
distant / unstaged); median age at diagnosis or death; **rural/urban comparison** (trends
and rates); and survival-specific views — 5-year survival, survival by time since diagnosis,
and **conditional survival**.

Filters: cancer site (50+ options, with subtypes), sex, race/ethnicity, age group, stage at
diagnosis, year range.

Output controls: precision to four decimal places, optional standard error, confidence
intervals, and case counts; PNG download of graphs; a data-archive and revision-history
section under About.

### Gaps relative to Cancer Compass's problem

- **National only.** Geographic scope is national US (SEER registry-based). There is no
  state map, no county view — the entire geographic-disparity question that SCP data
  answers is out of scope here.
- **Hard cap on comparison breadth**: more than 10 cancer site selections downgrades the
  output to data tables only.
- **PNG-only chart export**, and the tool is a statistics viewer rather than a data-access
  layer.
- **No risk-factor or demographic dimension at all** — no BRFSS screening/smoking
  prevalence, no ACS socioeconomic context, so no way to relate outcomes to exposures.
- Depth on survival/prevalence/conditional survival that SCP lacks entirely — worth naming
  as *out of scope* for Cancer Compass rather than a gap to fill, since the scraped dataset
  has no survival measure.

---

## 3. CDC US Cancer Statistics (USCS) Data Visualizations

About page: <https://www.cdc.gov/united-states-cancer-statistics/dataviz/index.html>
(read via [RestoredCDC mirror](https://restoredcdc.org/www.cdc.gov/united-states-cancer-statistics/dataviz/index.html));
application: <https://gis.cdc.gov/Cancer/USCS/>

### Scope, per CDC's own description

"Provides incidence and death counts, rates, stage distribution, and trend data; survival
and prevalence estimates; and state-, county-, and congressional district-level data in a
user-driven format." Incidence covers ~98% of the US population for the latest single year;
mortality 100%. Trend data 1999→latest. Survival and prevalence are national and state,
based on NPCR data covering 92% of the population. Also includes "the prevalence of risk
factors related to cancer, use of cancer screening tests, and status of human papillomavirus
(HPV) immunization." CDC states that displays are "available as maps and bar charts with
interpretive text when users scroll over each graphic", with downloadable data tables and
per-page social sharing.

### Module inventory (from the application bundle's data endpoints)

Enumerated from `/DataVizApi/GetJSON/*` in
`https://gis.cdc.gov/Cancer/USCS/static/index-DTINlcDX.js`:

- **At a Glance** — `LandingPageMapData_Inci` / `_Mort`, `AtAGlanceTrendsData`
- **Explore** — `Explore_Inci_By_GeoID_*`, `Explore_Mort_By_GeoID_*`, `Explore_Inci_byAge`,
  `Explore_Mort_byAge`, `Explore_Inci_RuralUrban`, `Explore_Mort_RuralUrban`
- **Cancer-site comparison** — `CompareCancerSiteNationalIncidence` / `Mortality` / `Survival`
- **Survival** — `/Survival`, `/SurvivalByStage`, `/SurvivalbyState`
- **Prevalence** — `Prevalence`, `PrevalencebyState_byCancerSiteID_`
- **Congressional districts** — `CongressionalDistricts_Inci` / `_Mort`
- **Childhood cancers** — `ChildhoodByICCCGroup_`, `ChildhoodByPrimarySiteGroups_`,
  `CancerSitesICCC`, `CancerSitesPSG`; plus `BrainCancersbyTumorType`
- **Risk factors and screening (BRFSS)** — state *and* county series for
  `AlcoholConsumption`, `CancerScreening`, `Nutrition`, `Obesity`, `PhysicalActivity`,
  `TobaccoUse`; plus `HPV_Data`
- **AI/AN module** — `AIANData`, `AIANData_ByCancerSiteID_` (IHS-linked, PRCDA-restricted)
- **Preliminary estimates** — `PreliminaryData`
- **Export** — the bundle embeds both an XLSX writer and PptxGenJS, i.e. table→Excel and
  chart→PowerPoint export

### Notes and gaps

- **This is the strongest peer on breadth**: congressional districts, survival by stage,
  childhood ICCC groupings, AI/AN-specific handling, and county BRFSS all exceed what SCP
  exposes. It is also the tool whose *data* most overlaps Cancer Compass's.
- **Still one-measure-at-a-time and module-siloed.** Cancer outcomes and BRFSS risk factors
  live in different modules over different endpoints; I found **no bivariate / scatter
  endpoint** relating a risk factor to an outcome. (Caveat: `scatter`/`bubble` strings in
  the bundle appear to be charting-library internals, not a shipped view.)
- **Heavy pre-baked JSON per selection.** Endpoints are keyed by geography/cancer-site ID
  (`Explore_Inci_By_GeoID_1_CancerSiteID_`), so the query space is whatever CDC
  pre-generated; arbitrary cross-tabs are not expressible.
- **Data currency caveats are prominent and consequential**: 2020 incidence is displayed but
  excluded from joinpoint models, 2021 joinpoint results are "not included in Data
  Visualizations tool", Indiana incidence is missing for 2020–2021, and race/ethnicity rates
  are documented as underestimated for AI/AN, API, and Hispanic populations. Any tool over
  the same estimates inherits these and should surface them inline rather than in a
  technical-notes PDF.
- **Suppression** ("16 or fewer cases", or state-requested) shapes coverage but is disclosed
  in prose, not in the visual encoding.

---

## 4. IHME Global Burden of Disease (cancer results)

- GBD Results tool: <https://www.healthdata.org/data-tools-practices/interactive-visuals/gbd-results>
  (app at <https://vizhub.healthdata.org/gbd-results/>)
- GBD Compare: <https://www.healthdata.org/data-tools-practices/interactive-visuals/gbd-compare>
- Data catalog: <https://ghdx.healthdata.org/gbd-2021>

### GBD Results

A **query-and-download** tool rather than a visualization: "view and download estimates of
the world's health as CSV files." Query space is 292 causes of death, 375 diseases and
injuries, 88 risk factors, 204 countries and territories including subnational estimates for
**660 locations**, years **1990 to 2023**, by age and sex. Measures include deaths, YLLs,
YLDs, DALYs, prevalence, HALE, population attributable fractions, summary exposure values,
and SDI.

### GBD Compare

The visualization counterpart: "maps, plots, treemaps, arrow diagrams, and a dozen other
charts to compare trends in diseases, injuries, and risk factors; to explore the health
profile within a country by age and sex; to compare countries with one another; or to explore
regional and global trends", multilingual, with CSV download.

### Gaps

- **Account required.** "We require all users to create an account in order to search and
  download GBD data" (GBD Results), and GBD Compare says "Create an account to access the
  tool". This is the single biggest contrast with a static client-side app: zero-friction
  access is a real differentiator.
- **Wrong geographic grain for this problem.** US subnational granularity stops at states;
  there is no county layer, and no HSA layer.
- **Cancer granularity is coarse** — GBD causes are a global cause hierarchy (neoplasms and
  a few dozen site-level causes), not the registry-based site taxonomy that SCP/USCS use;
  no stage, no screening-prevalence-by-county.
- **Modeled estimates, not registry counts.** GBD values are model outputs with uncertainty
  intervals — useful for burden comparison, not comparable to NPCR/SEER observed rates.
- **Non-commercial-only data license** (IHME free-of-charge non-commercial user agreement),
  and the tools are SPA-heavy enough that IHME's own help text advises clearing the cache
  and resetting browser zoom if the visualization "looks distorted" — a fair signal of the
  weight of the client.
- Its genuinely good ideas worth stealing: the **arrow diagram** (rank change between two
  time points), **treemap** for burden composition, and consistent display of uncertainty
  intervals alongside every estimate.

---

## Opportunities for Cancer Compass

Synthesizing across all four, the recurring gaps a client-side DuckDB-WASM tool over the
scraped SCP extract is unusually well positioned to close:

1. **Cross-topic views — the biggest open space.** All four tools silo outcomes from
   exposures. None of them lets you plot county-level smoking prevalence against county-level
   lung cancer incidence, or poverty/SVI against late-stage percentage. The scraped extract
   has incidence, mortality, BRFSS risk, and ACS demographics keyed on the same FIPS, so a
   **bivariate scatter / bivariate choropleth with a FIPS join** is both the most obviously
   missing view and nearly free to build. This should be a first-class page, not a footnote.

2. **County-level trend, which literally does not exist upstream.** SCP's Historical Trends
   is state-only; county time information is compressed to a `recent_trend` word and a 5-year
   APC. Even without a full annual county series, Cancer Compass can do far more with what it
   has: a small-multiples grid of counties' APC with CIs, an APC-vs-level quadrant plot, or a
   trend-classified choropleth — instead of a single word in a table cell.

3. **Instant re-filtering instead of form-submit round trips.** SCP reposts a form and can
   ship ~10.6 MB of HTML for one county table. With the whole extract in DuckDB-WASM,
   filters become sub-second, which makes genuinely interactive idioms viable — linked
   brushing between map and table, cross-filtering, faceting by cancer site, and
   filter-as-you-type — none of which any of the four peers offers.

4. **Multi-area comparison as a primitive.** Every peer is single-area-select (or
   single-country). Multi-select of states/counties, "compare my county to its state, its
   HSA, peer rural counties, and the nation" on one chart, and peer-group definitions
   (rural/urban, SVI quartile) are straightforward SQL here and absent everywhere else.

5. **Uncertainty as a default encoding, not an optional column.** The extract carries rate
   CIs, CI\*Rank with rank CIs, and trend CIs. Peers either hide these (SCP's `graph=1`,
   the CI\*Rank methodology offsite) or make them opt-in (SEER\*Explorer checkboxes). Draw
   error bars by default, render rankings as CI\*Rank intervals rather than false-precision
   ordinals, and visually de-emphasize estimates whose CI spans the comparison value.

6. **Make suppression and sparsity legible.** ~70-80% of the upstream cartesian space is
   suppressed or invalid, and both SCP and USCS handle this with prose warnings after the
   fact. Because Cancer Compass holds the data locally, it can *know* before the user picks:
   disable impossible combinations, show row counts per filter option, and distinguish
   "suppressed", "not available", and "zero" in the visual encoding rather than as a
   footnote symbol.

7. **Zero-friction access and real shareability.** No account (unlike GBD), no server
   round-trip, plus URL-encoded full analysis state so any view is a copy-pasteable link —
   and real data export (CSV/Parquet of the *current filtered selection*) rather than SCP's
   per-query CSV or GBD's license-gated bulk download. PPTX/PNG export, which USCS already
   does, is worth matching for the health-planner audience SCP explicitly targets.

8. **Vintage awareness — a differentiator nobody has.** SCP overwrites its estimates in
   place and publishes no archive. The scraper repo preserves distinct upstream *vintages*,
   so Cancer Compass can show which vintage a number came from and, uniquely, how a published
   estimate has changed between vintages. No peer tool exposes anything comparable.

### Deliberately out of scope

Survival, prevalence, conditional survival, lifetime risk (SEER\*Explorer, USCS), and
congressional-district geography (USCS) are not in the scraped extract. Better to link out
to those tools than to imply coverage.
