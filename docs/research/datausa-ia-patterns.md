# Data USA information architecture — patterns worth borrowing for Cancer Compass

Research date: 2026-08-24. All observations are from the live site or Datawheel's public
source/docs; every claim below has a source link.

---

## 1. The one-sentence summary of Data USA's IA

Data USA is **one page template per dimension**, rendered ~47,000 times. There is no
hand-authored page. The homepage advertises exactly this: "over 47,000 automated reports"
across six dimensions — Locations (37,016), Industries (309), Jobs (650), Universities
(7,624), Degrees (1,837), Products (254) ([datausa.io](https://datausa.io/)).

That is the single most important structural idea for Cancer Compass: **pick your dimensions,
write one template per dimension, and let the data enumerate the pages.**

---

## 2. Page types observed

### 2.1 Geography profile — `/profile/geo/<slug>`

Observed on [`/profile/geo/california`](https://datausa.io/profile/geo/california) and
[`/profile/geo/durham-county-nc`](https://datausa.io/profile/geo/durham-county-nc).

**Hero:** place name plus a fixed row of 5–6 KPI stats, each with year, value, and
year-over-year delta. Durham County, NC shows: 2024 Population 332,353; Median Age 36.1
(+0.838% 1-yr); Poverty Rate 11.5% (−4.19% 1-yr); Median Household Income $82,316 (+3.54%);
Median Property Value $389,400 (+10.7%); Employed Population 177,032 (+1.85%). A
**"Add Comparison"** control sits in the header.

**Top-level sections** (identical set on state and county pages — the template is shared):
`About`, `Population & Diversity`, `Health`, `Economy`, `Civics`, `Education`,
`Housing & Living`, `Keep Exploring`.

**Subsections per section** (California; counties render a subset where data exists):

| Section | Subsections |
|---|---|
| Population & Diversity | Population by Location; Residents by Gender and Age; Citizenship; Race and Ethnicity; Global Diversity; Foreign-Born Population; Non-English Households; Military/Veterans |
| Health | Coverage; Patient-to-Clinician Ratios; Health Care Diversity; Uninsured People; Health Outcomes; Health Behaviors; Clinical Care |
| Economy | Employment/Workforce Diversity; Workforce and Wage by Location; Occupations; Unemployment Insurance Claims; Industries; Median Earnings by Industry; Employment by Industry Sector; Establishments by Size; Payroll by Industry Sector; Domestic Trade; Interstate Trade |
| Civics | Presidential popular vote over time; popular vote by county; Senator elections |
| Education | Admissions & Enrollments; Completions/Concentrations; Universities; Student Diversity; Awarded Degrees Over Time; Tuition; Working Population/Educational Pyramid; Educational Attainment |
| Housing & Living | Rent vs Own; Household Income; Wage Distribution; Commuter Transportation; Commute Time; Car Ownership; Severe Housing Problems; Poverty & Diversity; Children in Poverty; Social Needs; Crimes & Accidents |

**Anatomy of a single subsection** — this is the reusable unit. Three verbatim examples from
Durham County, NC:

- *Race and Ethnicity*: narrative — "In 2024, there were 1.31 times more White (Non-Hispanic)
  residents (139k people) in Durham County, NC than any other race or ethnicity." Plus a
  ranked top-3 list, a bar chart of 8 groups as % of total, a KPI callout ("15.8% Hispanic
  Population, 52.5k people"), and a selector to filter to a specific group.
- *Health Outcomes*: narrative — "In 2025, the average number of mentally unhealthy days
  reported in past 30 days (age-adjusted) was 4.63 in Durham County, NC." Plus a trend line
  chart and a **tab strip** of sibling measures (Low Birthweight, Poor Physical Health Days,
  Poor Mental Health Days, Poor/Fair Health, Frequent Physical Distress, Frequent Mental
  Distress, Diabetes Prevalence, HIV Prevalence) that swap the chart in place.
- *Median Earnings by Industry*: narrative — "The industries with the best median earnings for
  men in 2024 are Finance & Insurance, & Real Estate & Rental & Leasing ($89,074), Information
  ($87,008)…" Plus paired KPI callouts ($58,308 men / $51,760 women) and an All/Men/Women
  dropdown that rewrites both narrative and chart.

So the unit is: **narrative sentence(s) → KPI callout(s) → one chart → selector/tab controls →
per-chart actions.** Every chart carries the same action row: *View Data*, *Save Image*,
*Share/Embed*.

**Built-in peer context:** charts don't just plot the focus geography. The Durham citizenship
chart plots the county against "neighboring and parent geographies" — i.e. peer + parent
comparison is baked into the chart config, not a separate feature.

**Keep Exploring:** a card grid of sibling/adjacent members. California links to
Los Angeles-Long Beach-Anaheim MSA, San Francisco-Oakland-Hayward MSA,
Riverside-San Bernardino-Ontario MSA, Arizona, San Diego-Carlsbad MSA, and
Sacramento–Roseville–Arden-Arcade MSA — a mix of *child/contained* and *peer* geographies,
all `/profile/geo/<slug>`.

### 2.2 Topic profile — `/profile/soc/<slug>`, `/profile/naics/<slug>`, etc.

Observed on [`/profile/soc/registered-nurses`](https://datausa.io/profile/soc/registered-nurses).

Same shell — hero KPI row, stacked sections, Keep Exploring — but the section vocabulary is
about the *entity*, with geography demoted to one subsection:

- Hero KPIs: 2024 Workforce 3.54M; Average Age 43.1; Estimated Job Growth 4.9% (10-yr);
  Average Salary $82,141; Average Male Salary $95,342; Average Female Salary $80,303.
- Sections: `Employment` (Employment Over Time, Employment by Location, Yearly Wage Ranking,
  Wage Distribution); `Industry` (Occupations by Industries); `Diversity` (Gender and Age,
  Ethnicity, Races); `Education & Skills` (Majors, Education Levels, Skills);
  `Projections` (Job Growth).
- Charts: line (trend, projections), choropleth map (state wage distribution), bar/column,
  treemap (ethnicity), distribution curve (wage, with GINI), radar/bar (skills).
- Keep Exploring links *up* the hierarchy (parent occupation groups) and *sideways* to sibling
  detailed occupations.

**The inversion is the point:** geography profile = "everything about this place, including
topics"; topic profile = "everything about this topic, including places". Same components,
transposed.

### 2.3 Search / browse — `/search`

The homepage's six dimension tiles each link into filtered search
(`/?dimension=Geography`), and the primary CTA is "Search Reports" → `/search`. Results are
grouped by report type / dimension ([datausa.io](https://datausa.io/),
[/search](https://datausa.io/search)). Dimension is the primary facet; a single global search
box is the main entry point rather than a nested menu.

### 2.4 Global nav

Deliberately tiny: **Reports**, **About**, **Data** (API). That's it — no topic mega-menu. All
real navigation happens through (a) the global search box, (b) Keep Exploring cards, and (c)
in-page section anchors. Confirmed on both the homepage and profile pages.

---

## 3. URL / routing conventions

`/profile/<dimension-slug>/<member-slug>`, one dimension slug per cube dimension. Observed on
the California page's outbound links:

| Pattern | Dimension |
|---|---|
| `/profile/geo/<slug>` | Geography (nation, state, MSA, county, place, PUMA) |
| `/profile/naics/<slug>` | Industry (NAICS) |
| `/profile/soc/<slug>` | Occupation (SOC) |
| `/profile/cip/<slug>` | Degree/field of study (CIP), e.g. `computer-science-110701` |
| `/profile/university/<slug>` | University |
| `/profile/sctg/<slug>` | Traded commodity (SCTG) |

Notes: slugs are human-readable and often carry the code as a suffix
(`computer-science-110701`) to disambiguate; the classification system's own acronym is the
route segment, so the URL tells you which cube you're in. Comparison is a header control
(`Add Comparison`) rather than a path segment — `/profile/geo/a/b` returns 404, and the
comparison state is not visible in server-rendered HTML, so treat the exact query-param form
as unverified.

---

## 4. How the pages are assembled (Canon)

From Datawheel's own Canon CMS package
([github.com/Datawheel/canon/tree/master/packages/cms](https://github.com/Datawheel/canon/tree/master/packages/cms)):

- **Dimension** = a categorical axis (Geography, Industry). **Member** = one entity within it
  (Massachusetts, Metalworkers). **Variant** = one dimension wired to multiple cubes so shared
  logic can span data sources.
- **Profile** = a page template bound to one (or more) dimensions.
- **Section** = a vertically stacked block of "prose and vizes".
- **Generator** = calls an API and stores the response as `resp`, returning key/value pairs
  into a variables object. **Materializer** = same shape, runs after generators, no network —
  derives or combines variables.
- **Variables** = a flat lookup table produced by generators/materializers, interpolated with
  `{{variableName}}`.
- **Stat** = label + value + subtitle; stats sharing a label auto-group into columns.
- **Description** = a prose paragraph with variable interpolation.
- **Selector** = a dropdown of fixed or data-driven options, referenced as `[[selectorId]]`.
- **Visualization** = a D3plus chart type named by string, plus HTML types like `Table` and
  `Graphic`.
- **Section layouts** available: Hero, Default (sidebar prose + wide viz), Grouping (nested
  signposting), Info Card, Multicolumn, Single Column, Tabs.

Charts are D3plus, Datawheel's own D3 wrapper whose value proposition is *defaults* — one
config object per chart, consistent output.

**Takeaway for a no-backend app:** the generator/materializer split maps cleanly onto
DuckDB-WASM. A "generator" is one parameterized SQL query returning a small result set; a
"materializer" is a pure TS function deriving ratios, ranks, and deltas from those rows; and
the narrative sentence is a template string over the resulting variables. This is the
mechanism that makes the prose feel written without anyone writing it.

---

## 5. Why it feels cohesive

Concrete, copyable reasons rather than "good design":

1. **One template, many members.** Every county page has the same sections in the same order,
   so the second page a user visits is already familiar.
2. **Prose is generated from the same variables as the chart.** The sentence and the chart
   can't disagree, and every chart arrives pre-interpreted ("1.31 times more…", "the industries
   with the best median earnings are…").
3. **Superlatives, not tables.** Narratives lead with ranks, ratios and top-N rather than
   dumping numbers.
4. **Fixed chart affordance.** Identical *View Data / Save Image / Share* row on every viz.
5. **Selectors mutate the block, not the page.** Dropdowns and tab strips re-render one
   subsection in place — deep exploration with no navigation.
6. **Comparison is ambient.** Charts include parent and neighbouring geographies by default, so
   a value is never presented context-free.
7. **Nav is search + adjacency.** Tiny top nav, one search box, and a Keep Exploring grid on
   every page — the site is a graph you walk, not a tree you climb.
8. **Every stat is dated with a delta.** "2024 Median Age 36.1, +0.838% 1-year increase" —
   recency and direction on every KPI.

---

## 6. Contrast: two health-domain comparables

### County Health Rankings & Roadmaps

URL pattern is `/health-data/<state-slug>/<county-slug>` (e.g.
[`/health-data/north-carolina/durham`](https://www.countyhealthrankings.org/health-data/north-carolina/durham));
data is rendered client-side, so a plain fetch returns the shell.

Two ideas Data USA does *not* have, both worth stealing
([Making Use of Your Snapshot](http://www.countyhealthrankings.org/explore-health-rankings/use-data/making-use-your-snapshot),
[Peer Counties Tool](https://www.countyhealthrankings.org/resources/peer-counties-tool),
[Making the Most of Your Data](https://www.countyhealthrankings.org/health-data/making-the-most-of-your-data)):

- **"Areas of Strength" / "Areas to Explore"** — sits directly above the measure table on each
  county snapshot and auto-surfaces measures where the county is *meaningfully* better or worse
  than state and national values. Every county is guaranteed at least three Areas of Strength.
  This is a computed "what's notable here" block — a screenful of insight before any chart.
- **Explicit peer counties** — peers defined by demographic/social/economic similarity (a
  CHR + CDC CHSI collaboration), plus a *Compare Counties* tool at the bottom of every
  snapshot that compares one county against specific counties, all counties in its state, the
  nation, or counties with similar rural/urban character.
- Every measure shows **county, state, and national values side by side** as a matter of
  course.

### KFF State Health Facts

Two symmetric entry paths, mirroring Data USA's geography/topic inversion but making it
explicit in the IA ([kff.org/statedata](https://www.kff.org/statedata/)):

- **Indicator-first:** 800+ indicators in 13 categories; each indicator page shows all states,
  mappable, rankable, downloadable. `/state-indicator/<indicator>/`,
  browsable via `/state-category/<topic>/`.
- **State-first:** curated state fact sheets (Medicaid, dual-eligible, women's health) at
  `/interactive/<tool>/`, plus a custom report builder at `/state-health-facts/custom/`.

The lesson: KFF's *indicator page* ("this one measure, all 50 states, mapped and ranked") is a
page type Data USA lacks and Cancer Compass clearly needs.

---

## 7. Proposed page-type inventory for Cancer Compass

Given the actual data — incidence/mortality rates by state + county; BRFSS risk-factor and
screening prevalence; ACS demographics; dimensions cancer site, sex, race, age, stage, year,
geography — the dimensions are **geography**, **cancer site**, and **measure/indicator**. That
suggests four page types.

### A. Geography profile — `/geo/<state>` and `/geo/<state>/<county>`

Sections, in Data USA order (place-first, then the interesting stuff):

1. **Hero** — place name + KPI row: all-sites incidence rate (age-adjusted, latest year, with
   trend arrow), all-sites mortality rate, population, median age, % adults with no health
   coverage, screening-up-to-date rate for the flagship screen (e.g. colorectal). Each with
   year and delta. Plus an "Add comparison" control.
2. **At a glance / Notable here** — CHR's Areas of Strength/Explore, computed: cancer sites and
   risk factors where this place sits meaningfully above or below state and national values.
   Guarantee at least three of each.
3. **Cancer Burden** — incidence by site (bar/treemap, ranked, top-N narrative); mortality by
   site; incidence-to-mortality ratio by site; trend over time (line, with tab strip across
   sites); stage-at-diagnosis distribution (stacked bar) — the section where the `site` and
   `stage` dimensions live.
4. **Who Is Affected** — rates by sex, by race/ethnicity, by age group (population-pyramid-style
   for age-specific rates); disparity ratios as narrative superlatives.
5. **Risk Factors & Screening** (BRFSS) — smoking, obesity, physical inactivity, heavy
   drinking, HPV vaccination; screening prevalence by modality. Tab strip across measures, one
   trend line each, county vs state vs national.
6. **Population & Context** (ACS) — age structure, race/ethnicity, income, insurance coverage,
   rurality. Kept short: this is denominator context, not the story.
7. **Keep Exploring** — card grid: parent state, sibling counties in-state, demographically
   similar peer counties, and the top-burden cancer sites for this place (cross-links into page
   type B).

### B. Cancer site profile — `/cancer/<site>` (e.g. `/cancer/colorectal`)

The topic-first transpose. Geography becomes a subsection.

1. **Hero** — national incidence and mortality rate, 5-year trend, sex ratio, median age at
   diagnosis, % diagnosed at late stage.
2. **Geographic Distribution** — state choropleth; ranked state table; county map within a
   selected state; highest/lowest narrative.
3. **Trends** — national and per-state incidence and mortality over time.
4. **Demographics** — rates by sex, race/ethnicity, age.
5. **Stage** — stage distribution, and stage distribution *by* race/sex where the disparity
   story lives.
6. **Associated Risk Factors & Screening** — the BRFSS measures relevant to this site,
   correlated against county incidence (scatter with state/county points).
7. **Keep Exploring** — parent site group, sibling sites, highest-burden geographies.

### C. Indicator/measure page — `/measure/<measure>` (the KFF pattern)

One measure, every geography, mapped and ranked. Choropleth + sortable ranked table + national
distribution histogram + trend small-multiples. This is the cheapest page type to build (one
query shape) and the one users link to.

### D. Comparison view — `/compare?geo=a,b,c`

Explicit, not a mode bolted onto A. Aligned KPI rows, overlaid trend lines, side-by-side site
rankings. CHR's framing is the right one: compare against named places, all counties in the
state, or the nation.

Plus: `/search` (single global search over geographies, cancer sites, and measures, faceted by
dimension) and a `/methods` page for rate definitions, age-adjustment standard, and
suppression rules.

### Reusable view components implied

Twelve components cover every page above:

| Component | Used by |
|---|---|
`KpiRow` (value + year + delta, auto-grouping) | all hero sections
`NotableCallouts` (computed strengths/concerns vs benchmarks) | A, B
`NarrativeBlock` (template string over query variables) | every subsection
`TrendLine` (multi-series: focus + parent + peers) | A3–A5, B3, C
`RankedBar` / `Treemap` (top-N by site or measure) | A3, B2
`Choropleth` (state and county, with legend + suppression hatching) | A3, B2, C
`RankedTable` (sortable, benchmark columns) | C, D
`StackedBar` (stage, race composition) | A4, A6, B5
`DemographicBreakdown` (sex × race × age small multiples) | A4, B4
`Scatter` (risk factor vs outcome, geography points) | B6
`SelectorBar` (dropdowns + tab strip; mutate block in place) | every subsection
`RelatedCards` (parent / sibling / peer / cross-dimension) | A7, B7

And two cross-cutting conventions to adopt wholesale from Data USA: a fixed
**View Data / Download / Save Image / Share** action row on every chart, and **every value
rendered with its year, its benchmark, and its direction of change**.

### One domain-specific divergence

Data USA has no equivalent of rate suppression or confidence intervals. Cancer registry data
does (small-count suppression, unstable-rate flags), and BRFSS estimates carry wide CIs at
county level. Suppression and uncertainty must be first-class in `Choropleth`, `RankedTable`,
and `TrendLine` — a hatched county and a visible CI band — rather than an afterthought, or the
"Notable here" computation will happily rank noise. This is the one place to be *less*
minimalist than the model site.

---

## Sources

- [datausa.io homepage](https://datausa.io/)
- [datausa.io/search](https://datausa.io/search)
- [Profile: California (state geography)](https://datausa.io/profile/geo/california)
- [Profile: Durham County, NC (county geography)](https://datausa.io/profile/geo/durham-county-nc)
- [Profile: Registered Nurses (SOC topic)](https://datausa.io/profile/soc/registered-nurses)
- [Datawheel Canon CMS package](https://github.com/Datawheel/canon/tree/master/packages/cms)
- [@datawheel/canon-cms on npm](https://www.npmjs.com/package/@datawheel/canon-cms)
- [County Health Rankings — Durham, NC](https://www.countyhealthrankings.org/health-data/north-carolina/durham)
- [CHR — Making Use of Your Snapshot](http://www.countyhealthrankings.org/explore-health-rankings/use-data/making-use-your-snapshot)
- [CHR — Making the Most of Your Data](https://www.countyhealthrankings.org/health-data/making-the-most-of-your-data)
- [CHR — Peer Counties Tool](https://www.countyhealthrankings.org/resources/peer-counties-tool)
- [CHR — Peer Counties Methodology](https://www.countyhealthrankings.org/resources/peer-counties-methodology)
- [KFF State Health Facts](https://www.kff.org/statedata/)
