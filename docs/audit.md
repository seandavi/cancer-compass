# Task 0 audit — summary

Per SPEC.md, Task 0 gates the rest of the build. All seven items are answered; full detail and
citations are in `docs/audit/*.md`. This file is the index and the go/no-go read.

| # | Item | Verdict | Detail |
|---|---|---|---|
| 0.1 | Window alignment | **Answered.** Incidence 2018–2022, mortality 2019–2023. | [`01-window-alignment.md`](audit/01-window-alignment.md) |
| 0.2 | Counts vs rates | **Answered, corrects a stale spec premise.** SCP has counts for both incidence and mortality, but only as 5-yr averages — WONDER/NCHS still needed for M4, for a different reason than SPEC.md states. | [`02-counts-vs-rates.md`](audit/02-counts-vs-rates.md) |
| 0.3 | CDC WONDER extraction | **Blocked as scoped, viable alternative found.** WONDER's API refuses all county-level queries by policy. NCHS restricted-use "Death – All Counties" file (DUA route, not the RDC) is the path — needs a decision + ~4wk lead time. | [`03-cdc-wonder.md`](audit/03-cdc-wonder.md), [`03b-mortality-alternatives.md`](audit/03b-mortality-alternatives.md) |
| 0.4 | Suppression overlap | **Answered, corrected.** 2,979/3,142 counties (94.8%) MIR-computable at headline stratum. Mortality-only loss is 100% Kansas; incidence-only loss is scattered rural small-count suppression. | [`04-suppression-overlap.md`](audit/04-suppression-overlap.md) |
| 0.5 | NPPES feasibility | **Answered, no blockers.** Full pipeline run end to end. 62–64% of counties have zero oncologists across the four target specialties. | [`05-nppes.md`](audit/05-nppes.md) |
| 0.6 | Travel-time build vs borrow | **Split verdict.** Ingest a verified CC0 oncologist travel-time matrix (Liu et al. 2026); build NCI-center travel time ourselves (~1-2 days, OSRM); CoC-accredited program locations have no public bulk source and should be descoped from §2.3 with a stated reason. | [`06-travel-time.md`](audit/06-travel-time.md) |
| 0.7 | TIGER adjacency | **Answered.** No published Census adjacency file matches the pinned FIPS vintage — derived from TIGER2021, validated to reproduce the official 2025 file exactly. Graph is permanently disconnected (AK, HI); standard BYM2 flags handle it, no artificial edges. | [`07-adjacency.md`](audit/07-adjacency.md) |

## Corrections made during the audit (recorded here so they aren't lost)

- **County universe is 3,142, not 3,143** — `72001` is a Puerto Rico aggregate served under
  `areatype='By County'`, not an actual county (found by 0.7, propagated back into 0.4).
  SPEC.md §3's "~3,143 county pages" should read 3,142.
- **SPEC.md §2.2's premise that incidence lacks counts is outdated** (0.2) — the real reason
  WONDER/NCHS is still required for M4 is that SCP's counts are 5-year averages, not an annual
  panel, not that incidence lacks counts entirely.

## Decisions needed before M2 proceeds (project-owner calls, not build decisions)

1. **Mortality data source for M4/M3.** File the NCHS restricted-use Data Use Agreement request
   now (~4wk lead time is a critical-path item) and get written confirmation that publishing
   per-county aggregate results is permitted before M4 depends on it. See 0.3b.
2. **§2.3 scope for CoC-accredited programs.** No public bulk source exists. Recommend descoping
   with a stated reason (SPEC.md should be edited to say so) rather than silently dropping it.
   See 0.6.
3. **Taxonomy include/exclude list for "oncologist."** Six codes recommended in 0.5, including
   one easy-to-miss legacy code (`2085R0203X`) that undercounts radiation oncology by ~10% if
   dropped. Record the list as data in the build manifest, not a hard-coded literal.

## Not yet done

- Literature cross-check for NPPES address-quality precedent (0.5's "Open item") — doesn't gate
  M5, should close before the M6 methods section.
- `statistical-reviewer` pass on this summary and its sources (SPEC.md §5) — in progress.
