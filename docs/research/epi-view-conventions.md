# Epidemiological Presentation Conventions for Cancer Surveillance Data

Research notes for Cancer Compass visualization design. Sources are the publishing agencies' own
methodology documentation (NCI State Cancer Profiles, NCI SEER / Surveillance Research Program,
CDC U.S. Cancer Statistics, American Cancer Society), fetched 2026-08-24.

A public-health-literate audience (registry staff, state cancer-control planners, epidemiologists,
health journalists) arrives with expectations set by three tools: **State Cancer Profiles** (SCP),
**SEER\*Explorer**, and the **CDC USCS Data Visualizations tool**. Matching their conventions is
what makes Cancer Compass legible; violating them is what makes it look wrong even when the
arithmetic is right.

---

## 1. Rates are age-adjusted, and the standard population is part of the metric

**Convention.** Every headline incidence and mortality figure is an *age-adjusted rate per 100,000
person-years*, adjusted to the **2000 U.S. standard population**. SCP states it directly: "Rates are
age-adjusted by 5-year age groups to the 2000 U.S. standard million population"
([SCP incidence rates interpretation](https://statecancerprofiles.cancer.gov/incidencerates/index.php?stateFIPS=34&areatype=county&cancer=001&year=0&race=00&sex=0&age=006&type=incd&graph=1&sortVariableName=recentaapc&sortOrder=desc&output=2)).

**Why age-adjustment.** An age-adjusted rate is "a weighted average of the age-specific (crude)
rates, where the weights are the proportions of persons in the corresponding age groups of a standard
population"; using a common standard means "the potential confounding effect of age is reduced when
comparing age-adjusted rates"
([SEER\*Stat tutorial: Calculating Age-adjusted Rates](https://seer.cancer.gov/seerstat/tutorials/aarates/definition.html)).
Cancer is overwhelmingly a disease of older age, so a crude-rate map of the US is close to a map of
median age — Florida looks like a cancer hotspot and Utah looks protected, for reasons that have
nothing to do with cancer control.

**The hard constraint.** NCI's own justification for the 2000 standard is that
"rates produced with different standard populations cannot be compared"
([SEER: Use of the 2000 U.S. Standard Population](https://seer.cancer.gov/stdpopulations/2000stdpop-use.html)).
The 2000 standard was adopted precisely because NCHS (1940), NCI (1970), and CDC (1980/1990) were
publishing mutually incomparable numbers. SEER age-adjusts on 19–20 age groups (0, 1–4, 5–9, …,
80–84, 85+ or 85–89, 90+); ACS's *Cancer Facts & Figures 2026* uses 19 groups on the same 2000
standard ([ACS Cancer Facts & Figures 2026](https://www.cancer.org/research/cancer-facts-statistics/all-cancer-facts-figures/2026-cancer-facts-figures.html)).

**Guardrails.**
- Label the rate fully wherever a number appears: *"age-adjusted to the 2000 U.S. standard
  population, per 100,000"*. Not just "rate".
- Never place a crude rate and an age-adjusted rate on the same axis, in the same choropleth scale,
  or in the same ratio. If crude counts are shown (they are legitimate for burden framing — "how many
  people"), separate them visually and label them *counts*, not rates.
- If Cancer Compass ever ingests a second source using a different standard population (e.g. WHO
  World Standard for international comparison), that is a different metric and must not share a
  scale or a comparison with the 2000-standard values.
- Never age-adjust across a metric boundary: BRFSS screening prevalence is a survey percentage, not
  a rate per 100,000 (see §5).

---

## 2. Trends: five-year AAPC, with significance from the confidence interval

**Convention.** The standard trend statistic is the **Average Annual Percent Change (AAPC)** from
**joinpoint regression**, reported for a "recent 5-year trend" alongside a longer historical series.
The AAPC "is based on the APCs calculated by Joinpoint" — a piecewise linear model is fit to
log-transformed rates, the best-fitting number of segments is selected, and the AAPC is a weighted
average of the segment slopes with weights proportional to segment length
([NCI Joinpoint help](https://surveillance.cancer.gov/help/joinpoint/statistical-notes/statistics-related-to-the-k-joinpoint-model/aapc-comparison);
[Joinpoint sample analysis](https://surveillance.cancer.gov/joinpoint/age.html)).

**How rising/falling/stable is decided.** This is a hard, published rule, not a judgment call. From
SCP's interpretation pages:

| Displayed label | Rule |
| --- | --- |
| **Rising** | 95% CI of the AAPC/APC is entirely **above 0** |
| **Stable** | 95% CI of the AAPC/APC **includes 0** |
| **Falling** | 95% CI of the AAPC/APC is entirely **below 0** |

([SCP incidence rates interpretation](https://statecancerprofiles.cancer.gov/incidencerates/index.php?stateFIPS=34&areatype=county&cancer=001&year=0&race=00&sex=0&age=006&type=incd&graph=1&sortVariableName=recentaapc&sortOrder=desc&output=2);
same wording on the [death rates](https://statecancerprofiles.cancer.gov/deathrates/index.php?age=136&areatype=state&cancer=020&output=2&race=07&sex=0&sortOrder=desc&sortVariableName=name&stateFIPS=00&type=death&year=0)
and [historical trend](https://statecancerprofiles.cancer.gov/historicaltrend/index.php?statefips=00&cancer=001&race=00&sex=2&age=009&year=0&ruralurban=0&datatype=2&output=2) pages.)

"Stable" therefore means *not statistically distinguishable from flat* — it does **not** mean the
point estimate was near zero. A county with AAPC = −4.1% (95% CI −9.0 to +1.2) is **stable**, and
must be rendered as stable.

SCP also warns that the fitted window can differ by area: "Due to data availability issues, the time
period used in the calculation of the joinpoint regression model may differ for selected counties."

**Guardrails.**
- Derive the rising/falling/stable label from the CI, never from the sign of the AAPC point estimate.
  If Cancer Compass has the AAPC but not its CI for some cell, it must show the AAPC unlabeled — not
  guess a direction.
- Use a three-state encoding (up / flat / down) with a distinct neutral treatment for "stable".
  Do not use a continuous diverging color ramp on AAPC alone: that renders a non-significant −4.1%
  as visually indistinguishable from a significant −4.1%.
- Color/arrow direction must be semantically consistent: for incidence and mortality, *falling is
  good*; for screening prevalence, *rising is good*. Do not reuse one ramp across both without
  flipping polarity.
- Show the AAPC's own CI on hover/detail. It is the only way a reader can tell a precise trend from
  a noisy one.
- Do not extend a trend line past the last observed year, and do not let a trend arrow imply a
  forecast.
- If the joinpoint window differs between two areas being compared, say so; don't silently compare a
  2013–2022 AAPC against a 2016–2022 one.

---

## 3. Stage at diagnosis is a standard, expected view

**Convention.** Two presentations coexist and serve different purposes.

- **Full stage distribution** — SEER\*Explorer presents four SEER Summary Stage categories as a
  distribution of incident cases: **Localized** ("confined to the primary site"), **Regional**
  ("spread to regional lymph nodes"), **Distant** ("cancer has metastasized"), and **Unknown /
  Unstaged** ("not enough information to indicate a stage")
  ([SEER\*Explorer help](https://seer.cancer.gov/statistics-network/explorer/help.html)).
- **Late-stage rate** — SCP publishes a stage-stratified *rate* where "Late Stage" is explicitly
  defined as "cases determined to be regional or distant"
  ([SCP incidence rates, late-stage breast](https://statecancerprofiles.cancer.gov/incidencerates/index.php?stateFIPS=06&areatype=county&cancer=047&stage=211&race=00&type=incd&output=2)).
  Late-stage incidence is the conventional proxy for screening *effectiveness* at a population level,
  which is why SCP offers it for the screen-detectable cancers (breast, cervix, colorectal).

Quick Profiles list stage as one of the standard incidence stratifiers, alongside site,
race/ethnicity, sex, age, year, and rural/urban
([SCP Quick Profiles](https://statecancerprofiles.cancer.gov/quick-profiles/index.php?statename=newyork)).

**Guardrails.**
- **Always show the Unknown/Unstaged share.** Dropping it renormalizes the other three categories and
  manufactures a stage shift. Unstaged fractions vary by registry, site, and year — a "rising
  localized share" is frequently a falling unstaged share.
- Order categories by clinical severity (Localized → Regional → Distant → Unknown), not by size.
- Never compute a "% late stage" that silently excludes unstaged cases without labeling the
  denominator.
- A stage distribution (percentages of cases) and a late-stage rate (per 100,000) answer different
  questions and must be labeled distinctly. A place can have a falling late-stage *rate* and a rising
  late-stage *share* at the same time.
- Stage-stratified county cells are the sparsest data in the whole dataset and hit suppression first
  (§7). Expect most county × site × stage × race cells to be unavailable.

---

## 4. Screening and risk-factor prevalence shown next to outcomes

**Convention.** SCP's canonical profile puts **Screening & Risk Factors** as a peer section beside
Demographics, Incidence, and Mortality
([SCP Quick Profiles](https://statecancerprofiles.cancer.gov/quick-profiles/index.php?statename=newyork)) —
i.e. juxtaposing behavior with outcome is expected, not exotic. CDC's geographic-comparison guidance
makes the causal reasoning explicit: "some differences in cancer rates among geographic regions may be
explained by differences in known risk factors, such as rates of lung cancer and other
tobacco-associated cancers being higher in regions with a higher prevalence of smoking"
([CDC USCS: Guidance for Comparing Cancer Data by Geographic Region](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/guidance.html)).

Source and units differ sharply from the registry data: screening and risk-factor prevalence come
from **BRFSS** (a telephone survey) as **weighted percentages with 95% CIs**, while incidence and
mortality come from **NPCR/SEER registries and NCHS vital statistics** as age-adjusted rates.
Healthy People 2030 screening targets are the conventional reference line for the screening
percentages.

**Guardrails.**
- Never put a survey percentage and an age-adjusted rate on a shared axis or a shared color scale.
- Label the BRFSS survey year(s) separately from the registry period. They rarely align, and the
  latency direction matters: today's screening affects tomorrow's stage distribution, not today's.
- **Do not present a cross-sectional area-level correlation as an effect.** A scatter of
  county smoking prevalence vs. lung cancer incidence is a legitimate exploratory view; a fitted line
  with an R² and no caveat is an ecological-fallacy machine. If a scatter is offered, state that
  associations are between *places*, not people, and that the two variables are measured on different
  populations at different times.
- Screening prevalence has its own, stricter suppression rule (§7) — respect it independently.
- Where a Healthy People 2030 target exists, show it as a reference line rather than baking it into
  a good/bad color scale.

---

## 5. Disparity views: expected, and the place where presentation ethics bite hardest

**Convention.** Race/ethnicity, sex, age, rurality, and area socioeconomic status are all standard
stratifiers. SCP carries a Demographics section sourced from the Census Bureau, the American
Community Survey, and the Small Area Health Insurance Estimates, covering education, income,
poverty, insurance, urban/rural, and workforce
([SCP demographics interpretation](https://statecancerprofiles.cancer.gov/demographics/index.php?stateFIPS=33&areatype=county&topic=pov&demo=00008&race=00&sex=0&age=001&type=manyareacensus&sortVariableName=name&sortOrder=desc&output=2)),
and tags rural/urban using 2023 USDA codes.

**Data-quality caveats that must travel with the view.** CDC is explicit that racial and ethnic
categories are not measured with equal quality: race data in cancer registries is "excellent for
White, Black, Asian, and Pacific Islander people, and substantial for Hispanic people, while data for
American Indian and Alaska Native people has been shown to be considerably underreported"; published
rates "may be underestimated for Asian and Pacific Islander, American Indian and Alaska Native, and
Hispanic people … due to racial and Hispanic origin misclassification," and the same underestimation
affects death rates
([CDC USCS: Interpreting Race and Ethnicity in Cancer Data](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/interpreting-race-ethnicity.html)).
CDC's mitigation in its own tool is structural: "analysis has been restricted to non-Hispanic
populations to overcome racial misclassification and to represent populations more accurately."
ACS follows the same convention — rates for White and Black people are reported exclusive of Hispanic
ethnicity ([ACS Cancer Facts & Figures 2026](https://www.cancer.org/research/cancer-facts-statistics/all-cancer-facts-figures/2026-cancer-facts-figures.html)).

**Attribution.** NCI frames disparities primarily through structural and social determinants —
healthcare access, environmental conditions, educational and economic disadvantage, and "systemic
social, racial, and institutional inequalities" — with genetic and tumor-biology differences
acknowledged but secondary and interacting with social exposure
([NCI: Cancer Disparities](https://www.cancer.gov/about-cancer/understanding/disparities)).

**Guardrails.**
- Do not mix "White (all)" with "White, non-Hispanic" in the same comparison. Pick the
  Hispanic-exclusive convention where the source supports it and label it on every axis.
- Attach the underreporting caveat to AI/AN, API, and Hispanic series wherever they are rendered —
  in the view, not buried in a methods page. A bar that is known to be biased low needs to say so
  where it is read.
- Do not rank race/ethnicity groups by rate without also showing the CIs; group-specific counts are
  small and CIs are wide, so apparent orderings are frequently noise.
- Race/ethnicity is a stratifier for exposure and access, not an explanatory variable. Avoid
  copy that implies a group has an intrinsic rate. Where a disparity is shown, the neutral framing is
  the observed difference plus the available context (screening prevalence, poverty, insurance,
  rurality) — not a mechanism.
- Area-level SES (county poverty rate) describes places, not the individuals diagnosed. Don't
  narrate a county-poverty/incidence relationship as a statement about poor people.
- Avoid deficit-only framing and avoid designs where a group's row exists only to be the worst bar
  on the chart.

---

## 6. Rankings: allowed, but only with rank uncertainty attached

**Convention.** NCI publishes ranks and simultaneously publishes a whole methodology for how badly
they mislead. From SCP's ranking guidance
([Interpreting Rankings Data](https://statecancerprofiles.cancer.gov/interpretrankings.html)):

- "Even if registries were able to collect 100% of diagnosed cancer cases, there would still be some
  uncertainty in computed cancer rates" from chance alone.
- "The importance of a cancer as a public health problem in a state is more a function of the absolute
  rate of cancer rather than the state's relative ranking."
- Higher ranks may reflect population composition, screening intensity (more screening → more
  diagnosed cases), or risk-factor prevalence — and readers should not jump to environmental
  carcinogen exposure.

NCI's prescribed remedy is **CI\*Rank**, which "presents ranked, age-adjusted cancer incidence and
mortality rates by state, county, and special region in the US" *and* "confidence intervals for those
ranks," because "providing ranks and their level of uncertainty … together demonstrates not only the
variability of that area's rate but also the variability of closely ranked areas' rates"
([SCP: Confidence Intervals](https://statecancerprofiles.cancer.gov/confidenceintervals.html);
[CI\*Rank](https://surveillance.cancer.gov/cirank/)). Methodology: Zhang et al., *Confidence intervals
for ranks of age-adjusted rates across states or counties*, Stat Med 2014;33(11):1853–66.

The bluntest published statement, repeated in SCP's rate tables: "ranks for relatively rare diseases
or less populated areas may be essentially meaningless because of their large variability, but ranks
for more common diseases in densely populated regions can be very useful"
([SCP incidence rates interpretation](https://statecancerprofiles.cancer.gov/incidencerates/index.php?stateFIPS=11&areatype=county&cancer=001&year=0&race=05&sex=0&age=001&type=incd&sortVariableName=count&sortOrder=desc&output=2)).
SCP surfaces the CI\*Rank column under its own footnote symbol (⋔).

**Guardrails.**
- A ranked table must carry rank uncertainty (CI\*Rank interval where available) or an explicit
  "ranks are unstable for rare cancers and small populations" notice adjacent to the ranking, not on
  a separate page.
- Never render "#1" / "worst in state" as a standalone claim. Rank 1 and rank 12 are routinely
  statistically indistinguishable.
- Suppressed and unstable rates must never be silently ordered into a ranking. Sorting places
  suppressed cells somewhere; that position is meaningless and readers will read it.
- Prefer sorting on the *rate with its CI shown* over sorting on rank alone; prefer showing the
  absolute rate next to any rank.
- Do not let sort order alone imply significance. If Cancer Compass sorts by AAPC, "stable" rows will
  appear at the extremes; keep the stability encoding visible after sorting.

---

## 7. Suppression and rate stability — the binding constraint on county-level views

This is the rule that most constrains what Cancer Compass can render.

### Registry rates, trends, and counts: **< 16**

From [SCP: Suppression](https://statecancerprofiles.cancer.gov/suppressed.html) and the
per-table footnotes:

> "Data has been suppressed to ensure confidentiality and stability of rate estimates. Counts are
> suppressed if fewer than 16 records were reported."

> "A count of less than approximately 16 in a numerator results in a standard error of the rate that
> is approximately 25% or more as large as the rate itself."

CDC states the equivalence and the dual rationale explicitly: a count below ~16 means "the width of
the 95% confidence interval around the rate [is] at least as large as the rate itself"; the threshold
"was selected to reduce misuse and misinterpretation of unstable rates and trends," and separately
protects patient confidentiality
([CDC USCS: Suppression of Rates and Counts](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/suppression.html);
[USCS public-use technical documentation](https://www.cdc.gov/united-states-cancer-statistics/public-use/pdf/uscs-public-use-database-technical-documentation-us-2001-2017-508.pdf)).

Note the scope: the suppression applies to **counts, rates, *and* trends** for the affected cell.

### BRFSS screening / risk factors: **< 50 respondents**

"Data are suppressed when fewer than 50 people were surveyed for a variable, race, sex, and state
combination" ([SCP: Suppression](https://statecancerprofiles.cancer.gov/suppressed.html)).

### Demographics

Census/ACS percentages and medians are suppressed per Census Bureau small-sample standards, to
prevent display of unreliable estimates in tables, graphs, and maps (ibid.).

### The zone above the threshold is the real hazard

SCP's own warning: "Larger confidence intervals indicate less stability of the data. This is often
due to low counts that are not quite low enough to be suppressed." And: with small populations, "a
small change in the numerator (e.g., only one or two additional cases) has a dramatic effect on the
calculated rate"
([SCP rate/trend comparison interpretation](https://statecancerprofiles.cancer.gov/ratetrendbycancer/index.php?cancer=017&sex=0&stateFIPS=09&comparison=00&type=rtcancer&sortVariableName=priorityindex&sortOrder=asc&output=2)).
A county with 17 cases passes suppression and still has a ±50% interval.

**Guardrails.**
- Suppressed cells must be rendered as a **distinct visual state** — not zero, not white, not
  interpolated, not omitted from a legend. A suppressed county on a choropleth needs its own hatch or
  gray with a legend entry ("suppressed: fewer than 16 cases").
- Never impute, smooth over, or carry forward a suppressed value. Never include suppressed cells in a
  computed aggregate, mean, or ratio.
- Never re-derive a suppressed value. If total and all-but-one subgroup are shown, do not display the
  arithmetic residual — that is a confidentiality breach, not a clever fallback.
- Apply the < 50 BRFSS rule and the < 16 registry rule independently; they are different data with
  different thresholds.
- Flag *unstable-but-unsuppressed* rates too. A defensible rule, taken straight from NCI's own
  rationale: mark a rate whose 95% CI width approaches or exceeds the rate itself (equivalently,
  relative standard error ≳ 25%). This is the single highest-value guardrail Cancer Compass can add
  beyond simply honoring the source's suppression.
- Expect suppression to dominate in narrow strata: county × rare site × single race/ethnicity ×
  stage × sex. Design the empty state to be informative ("suppressed for stability at this level of
  detail — try a broader geography or all races combined") rather than a blank chart.

---

## 8. Confidence intervals

**Convention.** 95% is the default; SCP defines the CI as "a range of values that has a specified
probability of containing the rate or trend," noting 95% (p = .05) and 99% (p = .01) as the common
choices ([SCP FAQ](https://statecancerprofiles.cancer.gov/faq.html)). SEER\*Explorer defaults to
p = 0.05 ([SEER\*Explorer help](https://seer.cancer.gov/statistics-network/explorer/help.html)).
CIs are conventionally shown on rate tables, on AAPC/trend statistics, on BRFSS prevalence, and on
ranks (CI\*Rank).

**Guardrails.**
- Every rate, prevalence, and AAPC needs its CI available at the point of reading — in the table, the
  tooltip, or as an error bar. Choropleths cannot carry a CI, so a map must be paired with a
  detail/table view that does, and the map itself must not be the only representation of a value.
- Interval width *is* the reliability signal. Where a CI cannot be shown, substitute an explicit
  stability flag (§7).
- Do not use non-overlapping CIs as a formal test of difference between two areas, and do not build
  UI copy ("significantly higher than") on overlap logic. SCP's comparison feature instead uses a
  documented rate-ratio rule: county vs. US ratio above 1.10 = higher, below 0.90 = lower, in between
  = similar, and combines rate comparison with trend direction into a "priority index" where "an
  index of 1 is the highest priority — that trend is rising and the rate is already higher"
  ([SCP rate/trend comparison interpretation](https://statecancerprofiles.cancer.gov/ratetrendbycancer/index.php?cancer=017&sex=0&stateFIPS=09&comparison=00&type=rtcancer&sortVariableName=priorityindex&sortOrder=asc&output=2)).
  This is a good pattern to borrow: a documented, disclosed threshold rule beats an ad-hoc
  eyeball comparison.
- Single-year rates warrant extra caution, "especially when the rates are based on a relatively small
  number of cases" — which is why the standard county view is a pooled 5-year rate, not annual.

---

## 9. Cross-area comparison caveats that belong in the UI

CDC's geographic-comparison guidance names two factors that must temper any map or ranking
([CDC USCS: Guidance for Comparing Cancer Data by Geographic Region](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/guidance.html);
CDC USCS technical notes, "use caution when interpreting and comparing cancer rates by geographic
region"):

1. **Population composition.** Site-specific rates differ by race/ethnicity — breast incidence is
   typically higher in non-Hispanic White women, prostate incidence higher in non-Hispanic Black men —
   so the racial makeup of an area should be considered, ideally by stratifying rather than only
   age-adjusting.
2. **Risk-factor prevalence.** Tobacco-associated cancer rates track smoking prevalence.

SCP adds a third that is specific to *incidence* and routinely misread: **more screening produces
more diagnosed cases**, so a high incidence rank can reflect good detection rather than more disease
([Interpreting Rankings Data](https://statecancerprofiles.cancer.gov/interpretrankings.html)).
This is the strongest argument for showing mortality next to incidence and for offering the
late-stage view (§3): mortality is far less sensitive to screening intensity.

Other definitional footnotes worth carrying: SCP scopes incidence to "invasive cancer only (except
for bladder cancer which is invasive and in situ)", uses ICD-O-3/WHO 2008 site recodes for incidence
and a combination of ICD-8/9/10 for mortality, and distinguishes NPCR/SEER vs. SEER-only sources by
footnote ([SCP FAQ](https://statecancerprofiles.cancer.gov/faq.html);
[SCP Quick Profiles](https://statecancerprofiles.cancer.gov/quick-profiles/index.php?statename=newyork)).
ACS additionally delay-adjusts incidence for reporting lag; delay-adjusted and non-delay-adjusted
rates are not interchangeable
([ACS Cancer Facts & Figures 2026](https://www.cancer.org/research/cancer-facts-statistics/all-cancer-facts-figures/2026-cancer-facts-figures.html)).

---

## 10. View types this audience expects

Ordered roughly by how load-bearing they are.

1. **Area profile** — one geography, all four sections (demographics, screening/risk factors,
   incidence, mortality), each with a US comparison. This is SCP's Quick Profile and the canonical
   entry point.
2. **Choropleth map** — one site × sex × race × period, age-adjusted rate by state or county, with a
   visible suppressed category. Paired with a table that carries CIs.
3. **Ranked table with rate + CI + trend** — the workhorse view. Sortable, with rank uncertainty and
   suppression flags intact.
4. **Trend line with joinpoint fit** — observed points plus fitted segments, APC per segment and the
   recent 5-year AAPC with CI, labeled rising/stable/falling by the CI rule.
5. **Rate/trend cross-classification** — "rate already high AND rising" as a priority signal
   (SCP's priority index). Genuinely useful for cancer-control planning and cheap to compute.
6. **Stage distribution** — 4-category bar including Unstaged, plus a late-stage rate view for
   screen-detectable sites.
7. **Disparity comparison** — same site and geography, stratified by race/ethnicity (Hispanic-exclusive),
   sex, age group, or rurality, always with CIs and data-quality caveats.
8. **Screening/risk factor vs. outcome** — side-by-side small multiples by default; scatter only with
   an explicit ecological-inference warning and no unqualified trend line.
9. **Site comparison within an area** — burden ordering across cancer sites, where counts (not only
   rates) legitimately matter.

---

## 11. Checklist: minimum guardrails Cancer Compass must implement

- [ ] Every rate labeled "age-adjusted, 2000 U.S. standard population, per 100,000".
- [ ] Crude rates and age-adjusted rates never share an axis, scale, or ratio.
- [ ] Rates from different standard populations never compared.
- [ ] Registry rates/counts/trends suppressed at **< 16** cases; rendered as a distinct, legended
      state; never zero, never blank, never interpolated.
- [ ] BRFSS estimates suppressed at **< 50** respondents, applied independently.
- [ ] Suppressed values never imputed, never included in aggregates, never re-derived as a residual.
- [ ] Unstable-but-unsuppressed rates flagged (CI width ≥ rate, i.e. RSE ≳ 25%).
- [ ] Rising/stable/falling derived from the AAPC 95% CI vs. zero — never from the point estimate's
      sign; "stable" gets a distinct neutral encoding.
- [ ] AAPC shown with its CI; no continuous ramp on AAPC without a significance encoding.
- [ ] Trend polarity semantically correct per metric (falling incidence good, rising screening good).
- [ ] No extrapolation beyond the last observed year.
- [ ] Rankings carry rank uncertainty or an adjacent instability warning; suppressed cells excluded
      from ranking, not sorted into it; no standalone "#1 / worst" claims.
- [ ] Stage views always include Unstaged; late-stage defined as regional + distant and labeled as
      such; distribution (%) vs. rate (per 100,000) clearly distinguished.
- [ ] Race/ethnicity uses one consistent convention (Hispanic-exclusive where supported); AI/AN, API,
      and Hispanic series carry the underreporting caveat in-view.
- [ ] Survey percentages never share an axis or scale with registry rates; survey year vs. registry
      period labeled separately.
- [ ] Any risk-factor/outcome correlation view carries an ecological-fallacy caveat and no
      unqualified fitted line.
- [ ] Incidence never presented without mortality nearby (screening-intensity confound).
- [ ] Data period, data source (NPCR/SEER vs. SEER-only, NCHS, BRFSS, ACS), and site definition
      visible on every view.
- [ ] Non-overlapping CIs never used as, or described as, a significance test between areas; any
      "higher/similar/lower" call uses a disclosed threshold rule.

---

## Source index

**NCI State Cancer Profiles**
- [FAQ](https://statecancerprofiles.cancer.gov/faq.html) — CI definition, ICD site recodes, general suppression statement
- [Suppression](https://statecancerprofiles.cancer.gov/suppressed.html) — < 16 registry, < 50 BRFSS, Census small-sample
- [Interpreting Rankings Data](https://statecancerprofiles.cancer.gov/interpretrankings.html) — ranking cautions, screening confound, absolute-vs-relative
- [Confidence Intervals](https://statecancerprofiles.cancer.gov/confidenceintervals.html) — rank uncertainty rationale, CI\*Rank pointer
- [Incidence rates interpretation](https://statecancerprofiles.cancer.gov/incidencerates/index.php?stateFIPS=34&areatype=county&cancer=001&year=0&race=00&sex=0&age=006&type=incd&graph=1&sortVariableName=recentaapc&sortOrder=desc&output=2) — 2000 std pop, AAPC CI rule, stability note
- [Late-stage incidence footnotes](https://statecancerprofiles.cancer.gov/incidencerates/index.php?stateFIPS=06&areatype=county&cancer=047&stage=211&race=00&type=incd&output=2) — late stage = regional + distant, footnote symbols
- [Rate/trend comparison interpretation](https://statecancerprofiles.cancer.gov/ratetrendbycancer/index.php?cancer=017&sex=0&stateFIPS=09&comparison=00&type=rtcancer&sortVariableName=priorityindex&sortOrder=asc&output=2) — priority index, 0.90/1.10 rate-ratio rule
- [Historical trend interpretation](https://statecancerprofiles.cancer.gov/historicaltrend/index.php?statefips=00&cancer=001&race=00&sex=2&age=009&year=0&ruralurban=0&datatype=2&output=2)
- [Demographics interpretation](https://statecancerprofiles.cancer.gov/demographics/index.php?stateFIPS=33&areatype=county&topic=pov&demo=00008&race=00&sex=0&age=001&type=manyareacensus&sortVariableName=name&sortOrder=desc&output=2) — Census/ACS/SAHIE sources
- [Quick Profiles (NY)](https://statecancerprofiles.cancer.gov/quick-profiles/index.php?statename=newyork) — canonical profile composition

**NCI SEER / Surveillance Research Program**
- [Calculating Age-adjusted Rates](https://seer.cancer.gov/seerstat/tutorials/aarates/definition.html)
- [Use of the 2000 U.S. Standard Population](https://seer.cancer.gov/stdpopulations/2000stdpop-use.html)
- [Standard Populations for Age-Adjustment](https://seer.cancer.gov/stdpopulations/)
- [SEER\*Explorer help](https://seer.cancer.gov/statistics-network/explorer/help.html) — summary stage categories, p-value default
- [Joinpoint: AAPC comparison](https://surveillance.cancer.gov/help/joinpoint/statistical-notes/statistics-related-to-the-k-joinpoint-model/aapc-comparison)
- [Joinpoint: sample age-adjusted rate + regression](https://surveillance.cancer.gov/joinpoint/age.html)
- [CI\*Rank](https://surveillance.cancer.gov/cirank/) — ranks with confidence intervals
- [NCI: Cancer Disparities](https://www.cancer.gov/about-cancer/understanding/disparities)

**CDC U.S. Cancer Statistics** (these pages block automated fetching; content confirmed via indexed
search snippets — re-verify in a browser before quoting verbatim)
- [Suppression of Rates and Counts](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/suppression.html)
- [Interpreting Race and Ethnicity in Cancer Data](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/interpreting-race-ethnicity.html)
- [Guidance for Comparing Cancer Data by Geographic Region](https://www.cdc.gov/united-states-cancer-statistics/technical-notes/guidance.html)
- [Cautionary Notes](https://www.cdc.gov/united-states-cancer-statistics/public-use/cautionary-notes.html)
- [Public Use Database Technical Documentation (PDF)](https://www.cdc.gov/united-states-cancer-statistics/public-use/pdf/uscs-public-use-database-technical-documentation-us-2001-2017-508.pdf)

**American Cancer Society**
- [Cancer Facts & Figures 2026](https://www.cancer.org/research/cancer-facts-statistics/all-cancer-facts-figures/2026-cancer-facts-figures.html) ([PDF](https://www.cancer.org/content/dam/cancer-org/research/cancer-facts-and-statistics/annual-cancer-facts-and-figures/2026/2026-cancer-facts-and-figures.pdf)) — 19 age groups, 2000 std pop, delay adjustment, Hispanic-exclusive race categories
- [Cancer Prevention & Early Detection Facts & Figures 2025-2026 (PDF)](https://www.cancer.org/content/dam/cancer-org/research/cancer-facts-and-statistics/cancer-prevention-and-early-detection-facts-and-figures/2025-cped-files/cped-cff-2025-2026.pdf)
