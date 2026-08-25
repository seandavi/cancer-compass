# Task 0.3 — CDC WONDER extraction

**Status: answered. CDC WONDER is a NO; the data is obtainable another way.**

The premise in SPEC.md §1/§2.2/§2.4 that annual county-level mortality counts can be pulled
programmatically from CDC WONDER is **false** — WONDER's API refuses all sub-national queries by
explicit NVSS policy, verified empirically against the live service (§3). **But the underlying data is
available as NVSS restricted-use micro-data**, which is a better input than WONDER would have been:
record-level, all counties, 1989–latest, no cell suppression, no rate limit (§9). The cost is a
~4-week NCHS approval with no stated fee, which lands on the critical path for M4–M8.

**One item remains genuinely open and could still invalidate the deliverable:** whether per-county
figures derived from restricted-use micro-data may be *published* on a public site. No output-review
clause appears in the public conditions of use, but the DUA text itself was not read. Resolve this
while the application is open — see §9 and decision 2.

Everything in §§1–8 was tested against the live service on **2026-08-24**. Probe scripts and raw
request/response pairs are in the session scratchpad (`wtest.py`, `req_*.xml`, `resp_*.xml`); the
reproduction recipe is in §7 so this can be re-verified rather than trusted. §9 was verified against
NCHS primary sources rather than the live API.

---

## 1. The correct database IDs (verified, not from memory)

The API endpoint is `POST https://wonder.cdc.gov/controller/datarequest/{DB}` with a form field
`request_xml` holding the request document, per
<https://wonder.cdc.gov/wonder/help/wonder-api.html> ("The request must be a POST which contains
one parameter with the name `request_xml` … sent to
`https://wonder.cdc.gov/controller/datarequest/[database ID]`").

Database IDs read directly out of the `action=` attribute of each database's request form
(`curl https://wonder.cdc.gov/{page}.html | grep datarequest/D`):

| DB | `dataset_label` | Years | Page |
|---|---|---|---|
| **D76** | Underlying Cause of Death, 1999–2020 | 1999–2020 | `ucd-icd10.html` |
| **D158** | Underlying Cause of Death, 2018–2024, Single Race | 2018–2024 | `ucd-icd10-expanded.html` |
| D77 | Multiple Cause of Death, 1999–2020 | 1999–2020 | `mcd-icd10.html` |
| D157 | Multiple Cause of Death, 2018–2024, Single Race | 2018–2024 | `mcd-icd10-expanded.html` |
| D176 | Provisional Mortality Statistics, 2018 through Last Week | 2018– | `mcd-icd10-provisional.html` |
| D140 | Compressed Mortality, 1999–2016 | 1999–2016 | `cmf-icd10.html` |
| D16 | Compressed Mortality, 1979–1998 | 1979–1998 | `cmf-icd9.html` |

Underlying cause of death is the right family for this project (D76/D158, not the multiple-cause
D77/D157). **There is no single database covering 1999–present.** Covering 1999–2024 requires
stitching **D76 (1999–2020) + D158 (2021–2024)**, and the two are not drop-in compatible: D76 uses
*bridged-race* population denominators, D158 uses *single-race*. NCHS stopped producing bridged-race
estimates after 2020, which is why D76 ends there. Any 1999–present panel therefore has a
documented methodological seam at 2020/2021 that has to be disclosed, not smoothed over.

D76's year finder (`F_D76.V1`) offers exactly `1999`–`2020`; the maximum `O_timeout` is 900 s
(15 min); export formats offered in the UI are XLS/TSV/CSV. All read from the live request form.

## 2. Test query: the API works, and it is fast

Request: group by Year, cause of death limited to ICD-10 **C00–C97** (malignant neoplasms),
year 2019, national, measures = deaths + population + crude rate + age-adjusted rate.

```
POST https://wonder.cdc.gov/controller/datarequest/D76
  request_xml=<request-parameters>…</request-parameters>
  accept_datause_restrictions=true
```

**Result: HTTP 200 in 2.1 s, 121,546 bytes of XML.** The data row, verbatim from `<data-table>`:

```xml
<r><c l="2019"/><c v="599,601"/><c v="328,239,523"/><c v="182.7"/>
   <c v="146.2" a="c"><l v="(145.8 - 146.5)"/></c><c v="0.2"/><c v="100.0%"/></r>
```

599,601 cancer deaths, population 328,239,523, crude rate 182.7, age-adjusted rate 146.2
(95% CI 145.8–146.5) per 100,000. So the mechanism, the XML format, and the ICD-10 code selection
all work as documented.

A deliberately larger query (22 years × 10-year age groups × sex × ICD sub-chapter, 528 rows,
209,862 bytes) also returned in **2.4 s**. **Per-query latency is ~2–3 s and essentially independent
of result size.** The bottleneck is not WONDER's compute — it is the rate limit (§5).

Response format is XML only. There is no JSON and no CSV/TSV from the API; the export formats are a
web-UI feature. The results table is `<data-table>` → `<r>` rows → `<c>` cells, positional (no
column names on the cells), with sub-level values such as confidence intervals nested as `<l>`.
Parsing requires knowing the by-variable and measure order from the request. Subtotal rows are
marked `c="1"`/`c="2"` and must be filtered out, and `<c dt=…>` marks total cells.

## 3. County-level data: refused by the API, by policy

This is the finding that matters. **Six independent probes, every one rejected with HTTP 500.**
Same message each time:

> Only national data are available for this dataset when using the WONDER web service. Please check
> that your query does not group results by region, division, state, county or urbanization,
> (B_1 through B_5), nor limit these location variables to any specific values. For more information
> please contact CDC WONDER customer support at cwus@cdc.gov or (888) 496-8347.

| Probe | Request | Result |
|---|---|---|
| B | `B_1=D76.V9`, 3 county FIPS (01001/01003/01005) | HTTP 500, refused |
| C | no location grouping, *limit* only to county 01001 | HTTP 500, refused |
| E | `B_1=Year, B_2=D76.V9`, limited to state 01 | HTTP 500, refused |
| F | `B_1=D76.V9-level1, B_2=D76.V9-level2` (well-formed State→County hierarchy), county FIPS | HTTP 500, refused |
| G | `B_1=D76.V9-level2`, `F_D76.V9=*All*` — **no location filter at all** | HTTP 500, refused |
| H | D158, `B_1=D158.V9-level2`, `F_D158.V9=*All*` | HTTP 500, refused |

Probes F and G matter most: F uses the exact hierarchical codes the web form itself offers
(`D76.V9-level1` = State, `D76.V9-level2` = County, read from the live `B_1` select list), so the
refusal is not an artifact of a malformed request. G asks for *all* counties with no filtering
whatsoever and is still refused — so this is not a confidentiality check on a small selection, it is
a blanket geographic restriction. H confirms it applies to the newer single-race database too, so it
is not a D76 quirk.

This is documented policy, not a bug. From <https://wonder.cdc.gov/wonder/help/wonder-api.html>:

> The vital statistics online databases are open to API queries as of February 23, 2015. However, in
> keeping with the vital statistics policy for public data sharing, **only national data are
> available for query by the API. Queries for mortality and births statistics from the National
> Vital Statistics System cannot limit or group results by any location field, such as Region,
> Division, State or County, or Urbanization** (urbanization categories map to specific geographic
> counties). … These 'sub-national" data fields cannot be grouped by or limited via the API,
> although these fields are available in the web application.

Note the last clause: county data **is** available in the interactive web application (the `B_1`
select list confirms a County option, and a browser session reaches the request form fine). The
restriction is specifically on automated/web-service access. Driving the web UI programmatically to
get around this is the same act the policy exists to prevent, and it is not a defensible provenance
story for a paper — a methods section cannot cite a route CDC states is closed. **If county-level
WONDER data is wanted, the route is to ask CDC (cwus@cdc.gov, 888-496-8347), who the API docs say
"will try to run a custom data request for you," not to script the UI.** That is a decision for the
project owner, not something to implement quietly.

## 4. Suppression threshold and encoding

From the D76 help page (<https://wonder.cdc.gov/wonder/help/ucd.html>), quoted verbatim:

- **Counts:** "Death counts are suppressed for statistics representing zero to nine (0-9) deaths."
- **Confidentiality rule:** "The term 'Suppressed' replaces death counts, births counts, death rates
  and associated confidence intervals and standard errors, as well as corresponding population
  figures, when the figure represents one to nine (1-9) persons for deaths in 1999 and later years."
- **Rates:** "Rates are suppressed for statistics representing zero to nine (0-9) deaths in years
  1999 and later. Corresponding denominator population figures are also suppressed when the
  population represents fewer than 10 persons."
- **Unreliable (D76):** "Rates are marked as 'unreliable' when the death count is less than 20." And:
  "Death rates based on counts of less than twenty (death count < 20) are flagged as 'Unreliable'. A
  death rate based on fewer than 20 deaths has a relative standard error (RSE(R)) of 23 percent or
  more."
- **Unreliable (D158 — a different rule, and it changed six months ago):** "Rates are unreliable when
  the relative width of the upper and lower 95% confidence interval exceeds 160% of the rate," and
  critically **"Rate values are not displayed when rates are flagged as 'unreliable.'"** D76 shows
  the value and flags it; D158 withholds it. The rule is also newly changed: "Prior to sharing the
  2024 final deaths on CDC WONDER in **February 2026**, rates were flagged as unreliable when the
  number of deaths was less than twenty, the equivalent of a Relative Standard Error (RSE) of 23% or
  more." So D158 results pulled before and after Feb 2026 are not comparable on this flag — another
  reason to pin and hash the extraction date, per CLAUDE.md.
- **Interval method differs across the seam too.** For D158 (2018+), "the 95% confidence intervals
  for rates, and the standard errors for age-adjusted death rates … are calculated using the
  Fay-Feuer modification of the Chi Square or Gamma distribution method" (Fay & Feuer, *Statistics in
  Medicine* 1997;16:791-801). D76 uses the older normal-approximation SEs. SPEC.md §2.1 propagates
  uncertainty through the MIR ratio, so which interval method produced the input matters and should
  be stated rather than mixed silently.

**Encoding:** suppressed and unusable cells carry literal English strings, not sentinel numbers or
nulls — `Suppressed`, `Unreliable`, `Not Applicable`, `Missing`, `Not Available`. Any ingest must
treat these as first-class categorical states, which is what SPEC.md §3's "no reliable estimate"
requirement already wants.

**This differs from SCP's rule.** SCP's own pinned-release documentation, quoted verbatim from
`notes_mortality.txt` (`10.5281/zenodo.22085273`): "Data has been suppressed to ensure
confidentiality and stability of rate estimates. Counts are suppressed if fewer than **16**
records were reported in a specific area-sex-race category." (Corroborated secondhand in
`docs/research/epi-view-conventions.md` §7, but the primary source is one HTTP
request away and is quoted here directly.) WONDER suppresses counts at **<10** and flags rates
unreliable at **<20**. Three different thresholds across the two sources, so the suppression
masks do not coincide and cannot be
assumed to. Any MIR or comparison built across both must carry two distinct missingness reasons.

### 4a. Compressed Mortality (D140) has a much friendlier county rule — but ends in 2016

Worth recording because it is the historically standard county-mortality source and someone will
ask. Its suppression regime is far more permissive than the Underlying Cause of Death databases, from
<https://wonder.cdc.gov/wonder/help/cmf.html>:

> For 1989 and later, counts and rates for counties with census year populations of less than
> 100,000, are replaced with "Suppressed" if the number of deaths is five or less (death count <=5)
> **and the death count is based on only one or two years of data.**

and

> Small death counts are not suppressed for counties with small populations if three or [more years
> of data are combined].

So CMF suppresses at **≤5** rather than <10, only for counties under 100,000 population, and **not at
all** once three or more years are aggregated. That is a materially better small-county picture than
D76/D158 offer, and it is the regime a custom data request should ask about.

Two caveats kill it as a standalone answer: **D140 covers only 1999–2016** (D16 covers 1979–1998), so
it cannot reach the present, and the three-year-aggregation exemption is in tension with SPEC.md
§2.4's need for annual points. I did **not** get a clean API probe of D140 — its variable schema
differs from D76 and my substituted request failed schema validation before the location check ran,
and further probing began returning HTTP 403 from CDC's WAF, at which point I stopped rather than
risk the IP being blocked from a resource this project needs legitimately. So D140's API behaviour is
**unresolved**. It is also probably moot: the API help states the restriction covers "mortality and
births statistics from the National Vital Statistics System," which includes CMF, and the year range
disqualifies it regardless.

## 5. Rate limits — two numbers, both real

- **Enforced, observed:** a request sent ~1 s after the previous one returned **HTTP 429**:
  > Request rate exceeded. To protect system resources, API/XML requests must have at least
  > **15 seconds** between consecutive requests. Please implement a 15-second wait period in your
  > code before making the next request.

  This is the hard floor and it is machine-enforced. (It is *not* in the API help page — it was
  discovered only by tripping it, which is worth noting: the docs understate the current limits.)
- **Documented courtesy rate:** the API help asks for something far slower —
  > "If you are running a single robot to 'data mine' the system, please post the queries in a
  > series, one at a time. Please don't run multiple instances simultaneously. **Firing a query every
  > 2 minutes** provides good recovery time of our system."

  So 15 s is what the server permits; 120 s is what CDC asks for. A good-faith bulk extraction
  should budget at the 2-minute rate, not the 15-second floor.

No parallelism is permitted ("don't run multiple instances simultaneously"), so the extraction is
inherently serial and the rate limit multiplies directly into wall-clock time.

## 6. Extraction time estimate

Query granularity, from the live `B_1` select list: WONDER allows up to **five** simultaneous
by-variables, and County (`D76.V9-level2`) can be one of them alongside Year, Sex, and 10-Year Age
Groups. So the natural unit is *one query per state per cancer site*, grouped by
County × Year × Age × Sex — roughly 62 counties × 26 years × 11 age groups × 2 sexes ≈ 35,000 rows
per query, which given the 2–3 s observed latency and the 900 s timeout ceiling is comfortable. Year
does **not** need to be a separate query, which is what keeps this tractable.

For ~20 cancer sites plus all-sites (21), covering 1999–2024:

| Scenario | Queries | At 15 s (enforced floor) | At 120 s (documented courtesy rate) |
|---|---:|---:|---:|
| 1 query per state × site | 51 × 21 = **1,071** | **4.5 h** | **1.5 days** |
| forced to split by year as well | 51 × 26 × 21 = **27,846** | 4.8 days | **39 days** |

**Realistic estimate: 4.5 hours to 1.5 days** for the tractable granularity, and up to ~6 weeks in
the pathological case. Latency is irrelevant; this is 100% rate-limit-bound.

**This estimate is hypothetical.** It describes what the pull *would* cost if county access existed.
Per §3 it does not, so the real cost of the WONDER route is however long a custom-data-request
conversation with CDC takes — unknown, and not schedulable.

## 7. Authentication and registration

**No API key, no registration, no account.** Confirmed by the successful national query in §2, which
used nothing but two form fields. The only requirement is asserting the data-use agreement, and it
can travel in the request itself:

```xml
<parameter><name>accept_datause_restrictions</name><value>true</value></parameter>
```

or as a second POST field `accept_datause_restrictions=true` (what the §2 probe used). Per the docs:
"The parameter must occur at least once and the value must be true." There is no per-session
handshake for the API path — the older behavior of clicking through an agreement applies to the web
UI, not the web service.

Attribution is required when data are republished: "please be sure to include WONDER in the credit
('powered by CDC WONDER' is fine) and also give the official data source citations in the 'Suggested
Citation' data that comes packaged with the result sets," plus the footnotes and caveats, and
"please be sure to observe the suppression constraints, if you re-assemble the data." That last
clause is directly relevant to SPEC.md §2.2 — the exceedance model publishes smoothed estimates for
counties WONDER suppresses, and the manuscript should state explicitly that it publishes model
posteriors, never a reconstructed suppressed count.

Reproduction: `POST` the example request at
<https://wonder.cdc.gov/wonder/help/api-examples/D76_Example1-req.xml> (documented pair with
`D76_Example1-resp.xml`) to `https://wonder.cdc.gov/controller/datarequest/D76` with
`accept_datause_restrictions=true`; change `B_1` to `D76.V9-level2` to reproduce the refusal in §3.
Wait 15 s between requests.

## 8. County-level gaps found in WONDER's documentation

Found while reading the two databases' help pages. **Read this alongside §9** — some of these are
WONDER artifacts that the micro-data route makes disappear, others are upstream facts about the
underlying data that survive any sourcing choice. Each item below says which.

- **D158 publishes no county-level age-specific populations at all.** Stated three times in
  `help/ucd-expanded.html`: "Rates and populations are not available for single-year age groups or
  10-year age groups at the county level for analysis of mortality by Single Race, including analysis
  of Urbanization categories for counties," and consequently "age-adjusted rates are not available at
  the county level for analysis of mortality by Single Race … because the standard populations are
  weighted to the 10-year age groups, and county level population estimates are not available."
  Note precisely what is and is not missing: **the constraint is on rates and populations, not on
  deaths.** County × year × age-group death *counts* remain available; it is the *denominator* that
  D158 does not publish. So for **2021–2024 WONDER can supply the numerator but not the
  denominator.** Denominators must come from elsewhere — SEER's free county population file by
  single year of age, sex and bridged race, 1969–2024
  (<https://seer.cancer.gov/popdata/>) is the standard substitute and is what NCI itself uses for
  SCP's rates, so using it keeps this project's denominators consistent with the archive it builds on.

  *(WONDER artifact — irrelevant on the §9 micro-data route, where age-specific counts come from the
  records themselves. Recorded because it is what rules out the WONDER route even for M3.)*

  **The denominator side is fully solved and needs no negotiation** — verified by download, not
  assumed. `https://seer.cancer.gov/popdata/yr1969_2024.20ages/wy.1969_2024.20ages.txt.gz` returned
  HTTP 200, 493,369 bytes in 0.9 s with no authentication, one gzipped fixed-width file per state,
  116,431 rows for Wyoming. Records carry year + state + **5-digit county FIPS** + race/origin/sex +
  age group + population (first row: `1969WY56001  1910000000275`). 20 age groups, matching the
  20-group age-adjustment NCI moved to and which `docs/audit/01-window-alignment.md` records SCP's
  mortality table using. So whatever happens to the numerator, expected-count denominators for
  indirect standardization (SPEC.md §2.2) are available for the full 1999–2024 span, free, pinnable
  and hashable.
- **This reaches back into M3.** `docs/audit/01-window-alignment.md` prescribes rebuilding the
  mortality rate for exactly **2018–2022** to match the incidence window. 2021 and 2022 fall only in
  D158, which cannot produce county age-adjusted rates. So the window-aligned MIR cannot read a rate
  off WONDER at all — it must be computed by the project from county × year × age-group *counts* and
  independent denominators. The methodological contribution SPEC.md §2.1 claims is still available,
  but it costs strictly more than the spec assumes.
- **Connecticut breaks in 2022 — but only in WONDER, and SEER already fixes it.** WONDER:
  "Population estimates and rates are flagged as 'Not Available' for the eight Connecticut counties in
  years 2022-2024. Deaths are reported for the eight Connecticut counties in years 2022-2024." CT
  reports population by nine *planning regions* from 2022, so WONDER has counts but no denominators.
  **This does not propagate to this project**, because the SEER population file we are already using
  for denominators resolves it upstream: "starting with Vintage 2022, nine planning regions are used
  as county-equivalent geographic units … To align with the geographic unit currently used for
  tracking cancer incidence and deaths, W&P converted 2020-2024 populations for Connecticut from
  planning regions to counties" (<https://seer.cancer.gov/popdata/>). So CT county denominators 2022–24
  *are* available from SEER even though WONDER reports none — a concrete argument for taking
  denominators from SEER rather than from the mortality source. **CT therefore does not need a
  Kansas-style explanation page**, but the planning-region-to-county conversion is a modelled
  reallocation and should be disclosed in methods.
- **Alaska geography changes in 2020.** Valdez-Cordova Census Area (02261) was split; WONDER sums
  Copper River (02066) and Chugach (02063) populations as its denominator for 2020+. A stable
  county panel needs an explicit crosswalk.
- **A known data error inside the study window.** "County of residence is misidentified in 316
  deaths that occurred in the year 2000, for Hartford County, CT (FIPS 09003) and New London County,
  CT (FIPS 09011)" in the Underlying Cause of Death database. State totals and the two-county
  aggregate are correct.
- **Miami-Dade FIPS change**: 12025 → 12086, effective 1997-11-13; WONDER uses 12086.
The Alaska recode, the CT-2000 misassignment and the Miami-Dade FIPS change are **upstream facts about
the death records** and survive any sourcing choice — they need a county-FIPS crosswalk in the build
regardless. The remaining items are WONDER-only.

- **`O_show_suppressed`, `O_show_zeros`, `O_show_totals`** must be set deliberately (WONDER-only).
  Suppressed and
  zero rows are omitted unless requested, which would silently turn a suppressed county into an
  absent row rather than an explicit "no reliable estimate" — precisely the failure mode CLAUDE.md
  forbids. Set all three to `true` on every extraction query.

## 9. Where the county numerator actually comes from: NVSS restricted-use micro-data

WONDER is a dead end, but the data is obtainable — and by a route that is *better* than the query
API, not merely a fallback. Verified against NCHS primary sources.

**The route: NVSS Restricted-Use Vital Statistics Data**
(<https://www.cdc.gov/nchs/nvss/nvss-restricted-data.htm>, page reviewed 2026-05-27). The offered
file is literally *"Deaths (Mortality) — Multiple cause of death, states and all counties —
Detailed"*, and the release-policy table grants **"Death - All Counties | 1989-latest | State Yes |
County All"**. The policy text:

> Researchers may request micro-data files … containing geographic detail for all states and counties
> for those data years with limited (1989-2004) or no (2005 forward) geographic detail in the
> public-use files. NCHS will evaluate the research request. If approved, the applicant will have
> access to the files upon submission of a signed NCHS Data Use Agreement.

**This is record-level micro-data, not a query interface, and that changes the whole extraction
picture.** Every problem in §§3–6 evaporates: no rate limit, no 1,071 queries, no 15-second floor, no
XML parsing, no WONDER cell suppression (suppression is a *presentation* rule applied by WONDER, not
a property of the micro-data), and full freedom to aggregate county × year × age × sex × ICD-10 site
however the model needs. **The §6 extraction-time estimate becomes irrelevant** — the cost is a
one-time ~4-week approval, then local aggregation. Files come to you: *"The data files should be
stored on, and accessed from, the secure computer system of the researcher's affiliated
organization."* Not an enclave.

**Requirements:** Project Review Form plus investigator CVs to `nvssrestricteddata@cdc.gov`; an
institutional Data Use Agreement signed by an authorized official **who is not the PI**, using a PKI
digital certificate; *"please allow up to 4 weeks for processing."* **No fee is stated** for this
route.

**Two listed disqualifiers, neither of which bites here:** *"Requests that plan to assess a single
state"* and *"Requests that involve using NCHS data for commercial or resale purposes."* A national
3,143-county non-commercial atlas is clear on both — but note the second one constrains how the site
may ever be monetized, which is worth knowing before SPEC.md §0's "cancer center credited as sponsor"
turns into anything resembling a commercial arrangement.

**Do NOT go via the NCHS Research Data Center.** It is the wrong door and would be refused:
<https://www.cdc.gov/rdc/nchs-geographic-variables/index.html> states *"The committee never approves
projects to produce county-level or lower-level estimates from NCHS survey data"* and *"The RDC
rarely approves projects involving geographic estimates at levels lower than the national level."*
RDC also charges $3,000 (1–6 data years) / $3,750 (7–8) / $4,500 (9–10). The restricted-use route
above is a different program with different rules; do not conflate them in correspondence.

**The one genuinely open item is publication terms.** The eight Conditions of Use on the
restricted-data page are all file-handling (use only for the stated scope, destroy on completion, no
sharing outside the DUA, no cloud storage, no re-identification) — there is **no output-review or
publication-approval clause**, which is the RDC's mechanism, not this one. But the DUA text itself was
not read, so "no barrier appears in the public conditions" is as far as this audit goes; it is not an
affirmative clearance to publish 3,143 per-county counts. Assume NCHS presentation standards apply:
`presentation-standards-mortality-2024.pdf` suppresses rates based on fewer than 20 deaths with an
asterisk. **Resolve this before M4, not after** — and note the question to put to NCHS is specifically
about publishing *modeled posterior estimates* (SPEC.md §2.2) rather than observed small counts,
which is a materially easier ask and is what the site actually renders.

Corroborating our §3 finding, from the NCHS release policy: *"CDC WONDER includes more geographic
detail than the downloadable public-use files."* The API is the deliberately narrowest channel of
the three.

### 9a. Everything else checked, and why each fails

| Source | County? | Verdict |
|---|---|---|
| **NCHS public-use micro-data, 2005–2024** | **None** | Dead. `Record_Layout_2005.pdf` p1: "A new vital statistics data access policy excluding geographic identifiers goes into effect with the 2005 data year information." County FIPS appears only in the separate **Territories** file. Confirmed identically in the 2019 and 2024 layouts. |
| **NCHS public-use micro-data, 1999–2004** | Partial, unusable | Only counties ≥100,000 population are individually identified; all others collapse into a single per-state `999` bucket — roughly **570 of 3,143 counties**. Exactly inverted from what this project needs, since the small rural counties are the whole point of §2.2. |
| NBER mirrors | None | "No geographic identifiers are included in the files for 2005-on due to a restriction imposed by the States." Adds nothing. |
| data.cdc.gov / healthdata.gov | — | No county-level cancer mortality dataset exists at all. |
| **NCI State Cancer Profiles** | 5-year only | County mortality is 5-year windows only, consistent with `docs/audit/02-counts-vs-rates.md`. Critically, **its Historical Trends tool is state/US only** — the area dropdown has 54 state options and no county. **So §2.4's trajectory analytic cannot be sourced from SCP.** |
| IHME GHDx US county estimates | Annual, but modeled | Genuinely annual county series (1980–2014, 2000–2019), but these are **modeled small-area estimates of rates, not observed counts** — unusable as Poisson observations for §2.2, and non-commercial licence. Usable only as an external validation comparator. |

The authoritative summary is NCHS's own release-policy table
(<https://www.cdc.gov/nchs/nvss/dvs_data_release.htm>, reviewed 2024-10-31): public-use county detail
is **"All"** for 1988 and earlier, **"Population size >= 100,000"** for 1989–2004, and **No / No /
No** (state / county / city) for 2005–latest.

---

## Consequence for M2 (data assembly) and M4 (exceedance model)

**M2's "WONDER extraction" line item cannot be built as specified.** The API is confirmed working,
fast, key-free and well-documented — and confirmed to refuse every sub-national query by explicit
NVSS policy. There is no parameter combination, database, or request form that unlocks county data
through the web service; six probes including an unfiltered all-counties request all return the same
refusal.

**But M2 and M4 are not blocked — the route just changes.** §9 establishes that NVSS restricted-use
micro-data grants "Death - All Counties | 1989-latest", as record-level files delivered to the
researcher's own systems, with a ~4-week approval and no stated fee. That is a *better* input than
WONDER queries would have been: record-level data means the annual county × age × site panel the BYM2
model needs can be aggregated locally, with no cell suppression, no rate limit, and no 1,071-query
extraction. **The §6 time estimate is superseded** — the schedule item is a 4-week approval lead time,
not a multi-day scrape.

**The practical effect on M2 is a dependency reordering, not a descoping.** M2 cannot start its
mortality workstream until the DUA is signed, so the application is now on the critical path for
M4–M8. SEER county populations (§8) and TIGER adjacency are unblocked and can proceed in parallel.

**M3 (the go/no-go) is unblocked but costs more than the spec assumes.** Window-aligned MIR needs a
2018–2022 county mortality rate, and §8 shows WONDER cannot supply one at any price (D158 publishes no
county age-adjusted rates, and 2021–2022 exist only in D158). With restricted-use micro-data the rate
is *computable* — county age-group deaths from the micro-data, denominators from SEER — so the
methodological contribution SPEC.md §2.1 claims survives intact. It just has to be built rather than
fetched, and it inherits the DUA lead time.

**§2.4's trajectory analytic now has exactly one viable source.** SCP's Historical Trends tool is
state/US only (§9a), so the annual county panel must come from the restricted-use micro-data too.
There is no fallback: if the DUA is refused, §2.4 is dropped, not degraded.

**Decisions this forces, in order:**

1. **Start the NVSS restricted-data application now.** Project Review Form plus CVs to
   `nvssrestricteddata@cdc.gov`, institutional DUA signed by an authorized official who is *not* the
   PI, PKI certificate, ~4 weeks. It gates M4–M8 and nothing else can shorten it. Frame the request
   as a national multi-state atlas — "requests that plan to assess a single state" are listed as not
   appropriate.
2. **Get the publication question answered in writing as part of that application**, not after: may
   per-county *modeled posterior estimates* derived from the micro-data be published on a public
   site? Ask about posteriors specifically, since that is what the site renders and it is a much
   easier ask than publishing observed small counts. This is the one item that could still invalidate
   the deliverable, so it should be resolved while the application is open rather than discovered at
   M7.
3. **Do not file with the Research Data Center.** It would be refused on stated policy and costs
   $3,000–$4,500 (§9). Different program, different door.
4. Treat the 2020/2021 bridged-race → single-race seam as a disclosed methods limitation in any
   1999–present panel. With micro-data this becomes a denominator choice rather than a database
   stitch, which is cleaner, but it still has to be stated.
5. Note that "no commercial or resale purposes" is a standing condition on the data — relevant to how
   SPEC.md §0's sponsorship framing is allowed to evolve.

**Do not attempt to work around §3 by scripting the web UI.** It contradicts a stated CDC access
policy, and a data provenance chain that cannot be described honestly in a methods section fails
CLAUDE.md's first line ("every claim the site or paper makes must trace to a pinned, hashed upstream
source") more badly than a missing analytic does.

---

## Open questions this audit did not close

Recorded so they are not mistaken for settled.

1. **Whether per-county figures derived from restricted-use micro-data may be published.** The
   decisive open item. No output-review clause appears in the eight public Conditions of Use, and
   output disclosure review is the RDC's mechanism rather than this route's — but the DUA text itself
   was not read, so this is "no visible barrier," not clearance. A source the project can compute on
   but not publish from is useless given SPEC.md's per-county-page deliverable. See decision 2.
2. **Whether NCHS presentation standards bind the published output.**
   `presentation-standards-mortality-2024.pdf` suppresses rates based on fewer than 20 deaths. If that
   applies to derived published figures, it collides with SPEC.md §2.2's core premise that the
   exceedance model fills suppression holes — though publishing a modeled posterior is arguably not
   publishing a rate based on <20 deaths. Worth asking explicitly rather than assuming either way.
3. **D140's API behaviour** — see §4a. Unresolved, and moot now that §9 supersedes the query route.
4. **WAF sensitivity.** Sustained probing from one IP began returning HTTP 403 (Access Denied) on the
   web-application path after roughly 20 requests spread over ~15 minutes, while the API path kept
   working. Anything that ends up talking to WONDER should treat 403 as a back-off signal, not a bug
   to retry through.
5. **Not re-verified:** the §9 findings come from NCHS documentation read this session, not from a
   completed application. Page-review dates are recorded inline; NCHS revises these policies, so
   confirm current terms at application time rather than trusting this note.
