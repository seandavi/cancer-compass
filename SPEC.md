# County cancer atlas — analytics and site spec

**Repo:** new, separate from `state-cancer-profile-scraper`. Working name `county-cancer-atlas`.
**Deliverables:** (1) three analytics that exist nowhere public, (2) a static per-county profile site, (3) the findings paper those analytics support.
**Depends on:** a *pinned* Zenodo version DOI from the archive repo. Never "latest."

**Out of scope:** tract-level anything, incidence-based exceedance modeling (see §2.2 — the data doesn't support it), any causal claim about why a county's rates differ, any feature requiring a backend.

---

## 0. Governing principles

**The site is not a dashboard.** Every incumbent in this space — Cancer InFocus, ArcGIS deployments, Domo — is a query interface. The differentiator is the opposite: one canonical, permanent, crawlable URL per county, fully prerendered, with a fixed stat set and no exploration UI. Data USA is the structural model.

**The analytics are the product; the site is the delivery mechanism.** If the analytics don't hold up, there's no site worth shipping.

**Uncertainty is displayed, not hidden.** This is the property that distinguishes the resource and the reason the framing survives contact with a reporter. Point estimates without intervals do not appear anywhere.

**Ownership.** Built on personal infrastructure and GitHub, cancer center credited as sponsor. Do not add institutional branding, domains, or auth to the build.

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

All upstream sources are pinned and hashed. A build is reproducible from the recorded source versions alone; record them in a build manifest committed with each deploy.

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

**URL scheme:** `/county/{state-abbr}/{county-slug}/` — stable, guessable, permanent. Slugs come from FIPS, never from display names, and a FIPS-based redirect path exists for citation. These URLs go in a paper; they cannot change.

**Charts are build-time SVG.** No client-side charting library, no runtime JS for data display. Static SVG per page, generated in the build step.

**Page structure**, in order:
1. County name, population, rural-urban classification
2. Exceedance probability for all-cancer mortality, stated in words before numbers
3. Funnel plot placing the county against expectation
4. MIR, with its interpretation guard adjacent, not in a footnote
5. Access indicators
6. Trajectory
7. Data provenance: pinned DOI, SCP vintage, access dates, methods link

**Every suppressed or unmodeled value renders as a first-class "no reliable estimate" state** with the reason. Not blank, not zero, not a dash. This will be common in exactly the rural counties that matter most.

**Kansas prohibits county-level release entirely, and Indiana is missing from some years.** Those pages must exist and explain the absence rather than 404.

---

## 4. Editorial rules

Non-negotiable, and enforced by a reviewer persona.

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
- Funnel plots render; no ranking surface exists anywhere in the site.
- Every page builds from a pinned DOI and a recorded source manifest; a rebuild from the manifest is byte-reproducible.
- Kansas and Indiana pages exist and explain their gaps.
- Editorial reviewer passes clean on a full crawl of generated copy.
- Findings paper submitted before the site is public.
