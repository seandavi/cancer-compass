# Task 0.4 — Suppression overlap (incidence ∩ mortality)

**Status: answered, re-run 2026-08-24 on the statistical-reviewer's findings** (see
`review-m1.md` #2-4, #19). The original run counted `72001` (Puerto Rico, a county-tier
aggregate, not a county — see `07-adjacency.md`) as a county, its state-list table was truncated
to the top 10 states and silently dropped one, and a stale pre-correction number survived in the
"Consequence" paragraph below the corrected table. All three are fixed in this version by
re-running the query rather than patching the prose.

Computed directly against the pinned V3 parquet files (downloaded from
`https://zenodo.org/records/22085273/files/`, sha256-recorded in the build manifest — see M2),
excluding `fips='72001'`, at the headline stratum: `locale_type='county'`,
`cancer='All Cancer Sites'`, `sex='Both Sexes'`, `race='All Races (includes Hispanic)'`,
`age='All Ages'`, and (incidence only) `stage='All Stages'`.

| Metric | N | % of 3,142 counties |
|---|---:|---:|
| Total county FIPS | 3,142 | 100% |
| Incidence usable | 3,028 | 96.4% |
| Mortality usable | 3,083 | 98.1% |
| **Both usable — MIR computable** | **2,979** | **94.8%** |
| Incidence usable, mortality missing | 49 | 1.6% |
| Mortality usable, incidence missing | 104 | 3.3% |
| **Neither usable** | **10** | **0.3%** |

2,979 + 49 + 104 + 10 = 3,142. Closed.

**Geographic pattern of loss:**

- **"Mortality usable, incidence missing" is Kansas's entire county-level incidence
  withholding, minus one county that lands in "neither."** Kansas has 105 counties;
  **zero** have usable county-level incidence at this stratum (confirmed:
  `count(*) FROM inc_ok WHERE state='Kansas'` = 0). Of those 105, **104** have usable mortality
  (the "mortality usable, incidence missing" bucket) and **1** (Wallace County, `20199`) also
  has mortality suppressed, landing it in "neither" instead. Kansas withholds county-level
  incidence by state law (confirmed independently in
  `docs/research/data-schema-audit.md`: all 202,230 `withheld_state_law`
  incidence rows are Kansas) — a complete, permanent, single-state policy gap, not scattered
  suppression. The site (SPEC.md §3) already plans an explicit Kansas explanation page.
- **"Incidence usable, mortality missing" (49 counties) is ordinary small-count mortality
  suppression** (<16 deaths — quoted verbatim from the pinned release's own `notes_mortality.txt`
  in `docs/audit/03-cdc-wonder.md`; corroborated in
  `docs/research/epi-view-conventions.md` §7), scattered across low-population
  rural/Western/Great Plains states — full list, not a top-N
  excerpt: Nebraska 14, Texas 10, Alaska 7, Montana 5, South Dakota 3, North Dakota 3, Utah 2,
  Idaho 2, New Mexico 1, Colorado 1, Nevada 1. (14+10+7+5+3+3+2+2+1+1+1 = 49.)
- **"Neither usable" (10 counties) — new in this revision, not reported in the original run.**
  All ten are among the least populous counties in the country: Loving County TX (`48301`,
  ~64 residents), Kenedy County TX (`48261`), King County TX (`48269`), Kalawao County HI
  (`15005`, ~80 residents — also the graph-adjacency singleton pair discussed in
  `07-adjacency.md`), Hinsdale County CO (`08053`), San Juan County CO (`08111`), Thomas County
  NE (`31171`), Billings County ND (`38007`), Slope County ND (`38087`), and Wallace County KS
  (`20199`, the Kansas exception above). These need their own "no reliable estimate — both
  incidence and mortality suppressed at this level of detail" state on the site (SPEC.md §3);
  they are not covered by the Kansas-specific messaging.

**Consequence for M3 (MIR):** headline all-sites MIR is computable for **2,979 of 3,142**
counties (94.8%) before per-cancer-site stratification, which will push the computable set
smaller for rare sites. Kansas's 104 counties (plus Wallace County via "neither") need an
explicit "no reliable estimate — county-level incidence withheld by state law" state distinct
from the 10 "neither" counties' ordinary small-count suppression. Per-site N will need to be
recomputed once cancer-site stratification is applied; this number is the headline/all-sites
ceiling, not the final per-site N. **Separately, and more consequentially per
`03-cdc-wonder.md`/`03b-mortality-alternatives.md`: even where both rates are "usable" here, the
window-aligned mortality rate MIR actually needs (2018–2022, not SCP's published 2019–2023)
cannot currently be constructed at all — this table describes SCP data availability, not
MIR-readiness.** See `01-window-alignment.md`'s forward-reference for why "usable" here does not
mean "MIR is computable today."
