# Task 0 audit — summary

Per SPEC.md, Task 0 gates the rest of the build. All seven items are answered; full detail and
citations are in `docs/audit/*.md`. This file is the index and the go/no-go read.

**A `statistical-reviewer` pass (SPEC.md §5, `docs/audit/review-m1.md`) has been run against this
audit and its findings incorporated below and into the individual files.** Its overall verdict on
the first draft: not yet M1-done, due to propagation/summarization failures more than data errors.
Those are fixed in this revision — see "Corrections" below for what changed and why.

| # | Item | Verdict | Detail |
|---|---|---|---|
| 0.1 | Window alignment | **The window finding stands; the prescribed fix does not.** Incidence 2018–2022, mortality 2019–2023 — confirmed. But constructing the *window-aligned mortality rate* SPEC.md §2.1 needs is now unresolved (see 0.3), not a solved problem with one remaining data pull. | [`01-window-alignment.md`](audit/01-window-alignment.md) |
| 0.2 | Counts vs rates | **Answered, corrects a stale spec premise** — but the mortality-only exceedance constraint itself is unchanged, only its stated reason was wrong. SCP has counts for both incidence and mortality, but only as 5-yr averages. | [`02-counts-vs-rates.md`](audit/02-counts-vs-rates.md) |
| 0.3 | CDC WONDER extraction | **Blocked as scoped — and this is the audit's real go/no-go risk, not a routine blocker.** WONDER's API refuses all county-level queries by policy, and even with access its 2018–2024 database publishes no county age-adjusted rates. **Both M3 (the spec's declared go/no-go milestone) and M4 depend on resolving this.** A viable alternative exists (NCHS restricted-use "Death – All Counties" file, DUA route, not the RDC, ~4wk lead time) but needs a project-owner decision and written confirmation that per-county aggregate publication is permitted — if that comes back no, M3 loses its stated methodological contribution and M4 has no known data source. | [`03-cdc-wonder.md`](audit/03-cdc-wonder.md), [`03b-mortality-alternatives.md`](audit/03b-mortality-alternatives.md) |
| 0.4 | Suppression overlap | **Answered, re-run with the corrected 3,142-county universe.** 2,979/3,142 counties (94.8%) usable-data-computable at headline stratum (not the same as MIR-computable today — see 0.1/0.3). "Mortality usable, incidence missing" is Kansas's withholding (104 of its 105 counties); "incidence usable, mortality missing" (49) is scattered rural small-count suppression; a newly-reported "neither usable" bucket (10 counties, the least-populous in the country) needs its own site state. | [`04-suppression-overlap.md`](audit/04-suppression-overlap.md) |
| 0.5 | NPPES feasibility | **Answered, no blockers, recomputed on the corrected 3,142-county universe.** Full pipeline run end to end. Recommended two-stage county assignment gives **62.6%** of counties with zero oncologists (not "62–64%"/"62.7%" — those were a rejected geocode-only method and the pre-correction universe; use 62.6%). The headline oncologist definition is **seven** taxonomy codes, not six — pediatric hematology-oncology (`2080P0207X`) is included, justified by 4,034 providers whose only oncology code is pediatric; a six-code sensitivity check moves the headline only 0.3pp (62.9%), so the choice isn't load-bearing for the headline but is for ~8 counties whose only oncology presence is pediatric. **New scope question**: 181 providers (mostly Puerto Rico) fall outside the 3,142-county universe entirely — PR has oncologists but gets no county page under the current scope (see "Decisions needed" below). | [`05-nppes.md`](audit/05-nppes.md) |
| 0.6 | Travel-time build vs borrow | **Split verdict.** Ingest exactly `200km_9m_OD_list.csv.gz` + `Oncologist_FTE.csv.gz` from Liu et al. 2026 (CC0) for oncologist travel time — **not** `Accessibility_*.csv.gz`, whose 2SFCA scores are denominated on Monte Carlo-imputed suppressed SCP incidence for a different window (2016–2020) than our pinned 2018–2022, using the same back-computation SPEC.md §2.2 forbids. Build NCI-center travel time ourselves (~1–2 days, OSRM, all 76 centers — an earlier draft's "Basic Laboratory" exclusion was checked and found incorrect, see file). CoC-accredited program locations have no public bulk source and should be descoped from §2.3 with a stated reason. | [`06-travel-time.md`](audit/06-travel-time.md) |
| 0.7 | TIGER adjacency | **Answered.** No published Census adjacency file matches the pinned FIPS vintage — derived from TIGER2021, validated to reproduce the official 2025 file exactly. Graph is permanently disconnected: Alaska is its own 29-county component (not just Hawaii's singletons) — standard BYM2 flags (`scale.model`, `adjust.for.con.comp`) handle it, no artificial edges. | [`07-adjacency.md`](audit/07-adjacency.md) |

## Corrections made during the audit (recorded here so they aren't lost)

- **County universe is 3,142, not 3,143** — `72001` is a Puerto Rico aggregate served under
  `areatype='By County'`, not an actual county (found by 0.7, propagated into 0.4; still pending
  in 0.5, see above). SPEC.md §3's "~3,143 county pages" should read 3,142.
- **SPEC.md §2.2's premise that incidence lacks counts is outdated** (0.2) — the real reason an
  annual mortality panel is still required for M4 is that SCP's counts are 5-year averages, not
  an annual panel, not that incidence lacks counts entirely. **The mortality-only constraint
  itself is unchanged and independently justified** — nothing in this audit proposes or computes
  an incidence-based exceedance.
- **0.1's prescribed fix ("reconstruct from CDC WONDER") does not survive 0.3's finding.** The
  window-alignment *finding* (the two windows differ) stands; the *construction* of the aligned
  mortality rate is now an open item depending on the DUA decision below, not a closed one.
- **A "neither usable" bucket of 10 counties** (0.4) was missing from the first pass entirely —
  the least-populous counties in the country (Loving TX, Kalawao HI, King TX, Kenedy TX, Hinsdale
  CO, San Juan CO, Thomas NE, Billings ND, Slope ND, Wallace KS), where both incidence and
  mortality are suppressed at the headline stratum. These need their own site state, distinct
  from Kansas's policy-driven withholding.
- **The NCI travel-time facility file does not distinguish Basic Laboratory centers** — an
  earlier draft of 0.6 claimed it did and recommended excluding them ("66–68 sites"). Re-parsed
  directly: the file's actual `type` values are Comprehensive Cancer Center (57), Cancer Center
  (10), and Pediatric Cancer Center (9) — all 76 are used, no exclusion applies.

## Decisions needed before M2 proceeds (project-owner calls, not build decisions)

1. **Mortality data source for M3/M4 — highest-stakes decision in this audit.** File the NCHS
   restricted-use Data Use Agreement request now (~4wk lead time is a critical-path item) and get
   written confirmation that publishing per-county aggregate results is permitted before M4 (and
   M3's window-alignment claim) depends on it. If that confirmation doesn't come, M3 as specified
   has no known path to the mortality rate it needs, and M4 has no known data source — this is a
   decision to make now, not a risk to discover after M2 is built. See 0.3/0.3b.
2. **§2.3 scope for CoC-accredited programs.** No public bulk source exists. Recommend descoping
   with a stated reason (SPEC.md should be edited to say so) rather than silently dropping it.
   See 0.6.
3. **Taxonomy include/exclude list for "oncologist."** Seven codes recommended in 0.5 (five core
   plus a legacy radiation-oncology code, `2085R0203X`, that undercounts by ~10% if dropped, and
   pediatric hematology-oncology, `2080P0207X`, included in the headline). Record the list as
   data in the build manifest, not a hard-coded literal. Note the ingested Liu et al. travel-time
   matrix (0.6) uses a *different*, narrower three-code definition — both appearing on one county
   page needs an explicit caveat, not silent reconciling.
4. **Connecticut needs the same explicit-gap treatment as Kansas and Indiana** (found in 0.3, not
   in SPEC.md's original list): 2022+ mortality counts exist but population denominators don't
   (CT switched to planning regions), so age-adjusted rates aren't computable. SPEC.md §3 and §8
   name only Kansas and Indiana — add Connecticut.
5. **Puerto Rico's page scope** (found in 0.5): it has real oncologists (181 NPPES providers) but
   falls entirely outside the 3,142-county modeling universe (it has no county-equivalent FIPS in
   the pinned SCP extract's county tier — see 0.7). Decide now whether PR gets any page at all
   (and what it can honestly show, given it's out of scope for MIR/exceedance/adjacency) rather
   than discovering the gap during M7 site build.

## Other findings that don't gate M2 but must reach the M6 methods section

- **Four different suppression thresholds are now in play**, not one: SCP <16 (0.3, 0.4),
  WONDER counts <10 / unreliable <20 (0.3), and NCHS's own presentation standard <20 (0.3b).
  They don't coincide and none should be assumed to stand in for another.
- **The bridged-race (pre-2021) → single-race (2021+) seam in NVSS mortality data** (0.3) is a
  real methodological discontinuity in any 1999–present panel and must be disclosed, not smoothed
  over, regardless of which mortality-data path is chosen.
- **Alaska's Valdez-Cordova FIPS crosswalk (`02261` ↔ `02063`+`02066`) is mandatory** wherever
  county-level data from a source other than the pinned SCP extract is joined in (0.6, 0.7) — it
  is not specific to the adjacency file.

## Not yet done

- Literature cross-check for NPPES address-quality precedent (0.5's "Open item") — doesn't gate
  M5, should close before the M6 methods section.
- Confirming whether CDC WONDER's D140 (Compressed Mortality, 1999–2016) has different API
  behavior than D76/D158 — low stakes, its year range doesn't reach the present regardless.
- The window-aligned mortality rate's confidence interval must be *constructed* by this project
  (not read off a source), and D76 vs. D158 use different interval methods (normal-approximation
  vs. Fay-Feuer per 0.3) — which method to propagate through the MIR ratio (SPEC.md §2.1) is an
  open statistical decision, not yet made.
