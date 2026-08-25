# Cancer Compass — analytics and site spec

**Repo:** `cancer-compass`, separate from `state-cancer-profile-scraper`. Formerly developed under
the working name `county-cancer-atlas`; consolidated with an earlier, separate `cancer-compass`
prototype (a client-side Vite/DuckDB-WASM explorer) once it became clear both were converging on
the same datausa.io-style "one template per dimension, N pages" pattern, and that a findings paper
citing permanent per-entity URLs is better served by a static build than a live query engine. The
earlier prototype's audience research and IA patterns moved into `docs/research/` (see that
directory's README); its architecture did not — this spec's static/no-backend approach stands.
**Deliverables:** (1) three analytics that exist nowhere public, (2) a static site with pages for
geography (state + county), cancer site, and indicator/measure, per §3, (3) the findings paper
those analytics support.
**Depends on:** a *pinned* Zenodo version DOI from the archive repo. Never "latest."

**Out of scope:** tract-level anything, incidence-based exceedance modeling (see §2.2 — the data
doesn't support it), any causal claim about why a county's rates differ, any feature requiring a
backend, and any open-ended query/exploration UI — see §0. This project does not compete with
Cancer InFocus or ECCO on dashboard/exploration features; `docs/research/peer-tools-landscape.md`
is the landscape record behind that call.

---

## 0. Governing principles

**The site is not a dashboard.** Every incumbent in this space — Cancer InFocus, ArcGIS deployments, Domo — is a query interface. The differentiator is the opposite: one canonical, permanent, crawlable URL per county, fully prerendered, with a fixed stat set and no exploration UI. Data USA is the structural model.

**The analytics are the product; the site is the delivery mechanism.** If the analytics don't hold up, there's no site worth shipping.

**Uncertainty is displayed, not hidden.** This is the property that distinguishes the resource and the reason the framing survives contact with a reporter. Point estimates without intervals do not appear anywhere.

**Ownership.** Built on personal infrastructure and GitHub, cancer center credited as sponsor. Do not add institutional branding, domains, or auth to the build.

**Page scope is broader than "county," the name notwithstanding.** The site has three enumerable
dimensions — geography (state, county), cancer site, and indicator/measure — each with one
template rendered per member, per `docs/research/datausa-ia-patterns.md`'s reading of Data USA's
own structure. See §3 for the full page-type list. The three novel analytics (§2) are the
statistically load-bearing core of the geography and cancer-site pages, not a separate section of
the site.

---

## Task 0 — audit before building

Answers to `docs/audit.md`. Several are gating.

1. **Window alignment — gating for MIR.** Determine the exact five-year windows for the incidence and mortality tables in the pinned archive release. They differ. Report both.
2. **Counts vs rates — gating for §2.2.** Confirm what the archive actually carries: age-adjusted rates only, or rates plus case/death counts? Bayesian exceedance modeling needs counts and expected counts. If SCP publishes only rates, exceedance is feasible for mortality (counts available from CDC WONDER) and infeasible for incidence. Report before any modeling.
3. **CDC WONDER extraction.** Confirm programmatic access to annual county-level cancer mortality counts, 1999–present. Record the suppression threshold and how suppressed cells are encoded. Estimate extraction time — WONDER is rate-limited and this is a large pull.
4. **Suppression overlap.** Count counties with usable incidence, usable mortality, and both. MIR is only computable on the intersection, which is smaller than either. Report N and the geographic pattern of loss.
5. **NPI feasibility.** Confirm the NPPES bulk file is retrievable and identify the taxonomy codes for medical/hematology oncology, radiation oncology, surgical oncology, and gynecologic oncology. Confirm practice-address geocoding quality is adequate for county assignment.
6. **Travel-time build vs borrow.** Check whether the published ZCTA-level oncology travel-time and 2SFCA dataset can be ingested directly rather than recomputed. Ingesting is strongly preferred.
7. **Adjacency.** Obtain the county adjacency structure from TIGER for the CAR model. Note island counties with no neighbors — they need explicit handling, not silent dropping.

---

## 1. Data flow

```
pinned Zenodo version DOI  ──┐
CDC WONDER annual mortality ─┤
NPPES oncologist locations ──┼──> DuckDB build step ──> per-county JSON ──> Astro SSG ──> Cloudflare Pages
ClinicalTrials.gov sites ────┤
TIGER adjacency + geometry ──┘
```

Everything is precomputed at build. No client-side query engine, no runtime data fetch. DuckDB-WASM is deliberately deferred — revisit only if a cross-county comparison feature is added later, and treat it as a separate decision.

All upstream sources are pinned and hashed. A build is reproducible from the recorded source versions alone; record them in a build manifest committed with each deploy (`build/manifest.json`).

**Also deliberately deferred: routing this build step through the onclappc02 platform's DuckLake (`cdsci-lake`)** instead of the current pinned-file-to-local-DuckDB approach (see `~/Documents/git/monode/infrastructure/DUCKLAKE.md` for the write contract). Building off pinned data via an Astro static site removes the reason this project would need its *own* database — the ELT step is a one-shot batch job, not a service — but landing the curated extract in the shared lake would open integration with other platform consumers later. Not adopted now: it would add a producer/consumer contract this project doesn't need yet, and the pinned-file approach is simpler and already working. Revisit if a second consumer of this project's curated extract shows up, or if the project's own ELT logic gets complex enough to want the lake's MERGE-upsert conventions instead of ad hoc SQL scripts.

---

## 2. Analytics

### 2.1 Mortality-to-incidence ratio

The headline analytic. MIR is an established survival and care-access proxy where county survival data doesn't exist.

**The window problem is the whole methodological contribution.** SCP's incidence and mortality tables cover different five-year periods, so a naive ratio compares two different eras. Do not do that. Instead, construct the mortality rate from CDC WONDER restricted to *exactly* the incidence window, age-adjusted to the 2000 US standard to match SCP's standard. This is the defensible version and is worth stating explicitly in the paper as an improvement over how MIR is usually computed.

- Compute per county, per cancer site, sex-stratified where numerators allow.
- Propagate uncertainty. A ratio of two uncertain rates is more uncertain than either; report an interval, not a point.
- Report N of computable counties and the suppression-driven pattern of missingness.
- Interpretation guard: MIR is not survival. Elevated MIR is consistent with late detection, treatment access, case mix, or registry completeness differences. Never label it "survival" in code, column names, or copy.

### 2.2 Posterior exceedance probability

Replaces both the point estimate and the rank.

- Poisson-lognormal spatial model, BYM2 parameterization, fit with INLA (fall back to Stan if INLA proves awkward).
- Inputs: observed deaths and expected deaths by indirect standardization against national age-specific rates. Neighbor structure from TIGER adjacency.
- Outputs per county: posterior mean rate, 95% credible interval, and **P(county rate > national rate)**. The exceedance probability is the number shown to users.
- **Mortality only.** Incidence lacks the counts this requires (Task 0 item 2). Do not attempt an incidence version by back-computing counts from rates and populations — the suppression pattern makes that unreliable and it would be indefensible under review.
- This is what fills the suppression holes with something honest: small counties get a smoothed estimate with wide intervals rather than an asterisk.

### 2.3 Access measures

Three county-level indicators, all straightforward once sourced:

- **Oncologist density** per 100k from NPPES, by the taxonomy codes from Task 0 item 5. Report zero counts explicitly — counties with no oncologist at all are the finding, not missing data.
- **Travel time to nearest NCI-designated center** and to the nearest CoC-accredited program. Ingest the published dataset if viable.
- **Trial access**: geocoded ClinicalTrials.gov sites with active interventional cancer trials; count within county and within a 60-minute drive.

### 2.4 Presentation analytics

- **Funnel plot** per cancer site: observed vs expected with 95% and 99.8% control limits, the county highlighted. This replaces ranking entirely and shows visually why small counties can't be ranked.
- **Trajectory** from the CDC WONDER annual panel, not from SCP's AAPC scalar. Classify against the national trend — the useful signal is "rising while the nation falls," not "high." **2020 is displayed but excluded from any trend fit**, matching SCP's own handling. Any code path that fits through 2020 is a defect.

---

## 3. Site

**Stack:** Astro, static output, Cloudflare Pages. ~3,143 county pages plus 51 state pages is an ordinary build, not a scaling problem.

**URL scheme**, all FIPS/code-based, never display names, all with redirect paths for citation —
these go in a paper and cannot change:
- `/county/{state-abbr}/{county-slug}/` and `/state/{state-abbr}/` — geography profiles
- `/cancer/{site-slug}/` — cancer-site profiles
- `/measure/{measure-slug}/` — indicator/measure pages
- `/compare?geo=a,b,c` — comparison view (bounded, see below)

**Charts are build-time SVG.** No client-side charting library, no runtime JS for data display. Static SVG per page, generated in the build step.

**Page types**, per `docs/research/datausa-ia-patterns.md`'s reading of Data USA (one template per
dimension, enumerated), reconciled with this project's own analytics and editorial rules:

**A. Geography profile** (state + county), in order:
1. Place name, population, rural-urban classification, demographic/risk-factor context
2. Exceedance probability for all-cancer mortality, stated in words before numbers
3. Funnel plot placing the place against expectation
4. MIR, with its interpretation guard adjacent, not in a footnote
5. Access indicators
6. Trajectory
7. Data provenance: pinned DOI, SCP vintage, access dates, methods link

**B. Cancer-site profile** — geographic distribution, demographics, stage, risk-factor context for
one site, plus which places show credible exceedance for that specific site (funnel plot filtered
to the site, linking back into A).

**C. Indicator/measure page — one measure, all geographies, mapped.** The original design for this
(borrowed from KFF's pattern: a sortable ranked table) is disallowed by §4's "no ranking headline"
rule and is **not built as originally conceived.** Use the funnel-plot pattern instead — observed
vs. expected, the viewer's place highlighted — so a reader sees where a place sits without a
false-precision rank.

**D. Comparison view** — a handful of named places (own county vs. state vs. nation vs. explicit
peers), never an open sortable leaderboard. This is still a place-picking tool, not a query
interface — §0 applies here too.

**Every suppressed or unmodeled value renders as a first-class "no reliable estimate" state** with the reason. Not blank, not zero, not a dash. This will be common in exactly the rural counties that matter most.

**Kansas prohibits county-level release entirely, and Indiana is missing from some years.** Those pages must exist and explain the absence rather than 404. **Connecticut does not need this treatment** — its 2022+ planning-region switch breaks some sources' county population denominators, but SEER's population file (already this project's denominator source) resolves it upstream; disclose the reallocation in methods, don't build a gap page for it. See `docs/audit/03-cdc-wonder.md` §8.

---

## 4. Editorial rules

Non-negotiable, and enforced by a reviewer persona. Applies to every page type in §3, not just
the county pages — including the pages serving `docs/research/personas.md`'s broader audiences
(resident, patient/caregiver). The rules below are the right standard for any reader of population
cancer statistics, not a planner-specific concession.

- **Framing is "where to focus effort," not "cancer rates where you live."** The audience is planners, health departments, and local reporters.
- **No ranking headline.** No "worst counties," no top-N list, no sortable national table. The funnel plot exists precisely so ranking isn't necessary.
- **No causal language.** Correlation displays are ecological, confounded, and lagged — smoking prevalence today against incidence reflecting exposure decades ago. If a demographic or risk-factor correlation is displayed at all, it carries that caveat inline.
- **No individual risk framing.** Nothing addressed to "your risk." County rates say nothing about a person.
- **Uncertainty adjacent to every estimate.** Never in a tooltip, never in a footnote.

---

## 5. Reviewer personas

**`statistical-reviewer`** — checks that intervals accompany every estimate, that the MIR window alignment is actually implemented and not assumed, that 2020 is excluded from trend fits, that the CAR model's neighbor structure handles island counties, and that no incidence-based exceedance sneaked in.

**`editorial-reviewer`** — checks copy against §4. Flags ranking language, causal verbs, second-person risk framing, and any estimate presented without uncertainty.

---

## 6. Milestones

- **M1** — Task 0 audit. Gated on review.
- **M2** — data assembly: pinned archive ingest, WONDER extraction, NPPES, trials, adjacency. Build manifest with source versions and hashes.
- **M3** — MIR with window alignment. **This is the go/no-go.** If the map isn't interpretable, stop and report before building anything else.
- **M4** — CAR model and exceedance probabilities.
- **M5** — access measures.
- **M6** — findings paper draft. Target CEBP; JNCI Cancer Spectrum or JCO CCI as alternates.
- **M7** — site build.
- **M8** — launch, timed to the paper.

M3 gates M4–M8. Nothing ships before the paper.

---

## 7. AI use ledger

Same schema and conventions as the archive repo: `ledger/ai-sessions.ndjson`, session granularity, `disposition` and `notes` as the fields that carry the provenance. The findings paper gets the same generated supplemental table.

---

## 8. Definition of done

- MIR computed on aligned windows, with intervals and reported N.
- Exceedance probabilities for all counties with a modeled estimate, including those SCP suppresses.
- Funnel plots render; no ranking surface exists anywhere in the site — including the
  indicator/measure pages (§3.C), which replace the originally-planned sortable table.
- Geography, cancer-site, and indicator/measure pages (§3.A–D) all build from the same pinned
  sources; no page type is a special case exempt from the manifest/reproducibility rule.
- Every page builds from a pinned DOI and a recorded source manifest; a rebuild from the manifest is byte-reproducible.
- Kansas and Indiana pages exist and explain their gaps.
- Editorial reviewer passes clean on a full crawl of generated copy.
- Findings paper submitted before the site is public.
