# Task 0.4 — Suppression overlap (incidence ∩ mortality)

**Status: answered.** Computed directly against the pinned V3 parquet files (downloaded from
`https://zenodo.org/records/22085273/files/`, sha256-recorded in the build manifest — see M2),
at the headline stratum: `locale_type='county'`, `cancer='All Cancer Sites'`, `sex='Both Sexes'`,
`race='All Races (includes Hispanic)'`, `age='All Ages'`, and (incidence only) `stage='All Stages'`.

| Metric | N | % of 3,143 counties |
|---|---:|---:|
| Total county FIPS | 3,143 | 100% |
| Incidence usable | 3,029 | 96.4% |
| Mortality usable | 3,084 | 98.1% |
| **Both usable — MIR computable** | **2,980** | **94.8%** |
| Incidence only (mortality missing) | 49 | 1.6% |
| Mortality only (incidence missing) | 104 | 3.3% |

**Geographic pattern of loss:**

- **Mortality-only loss is 100% Kansas** (all 104 counties) — Kansas withholds county-level
  incidence by state law (confirmed independently in
  `cancer-compass/docs/research/data-schema-audit.md`: all 202,230 `withheld_state_law` incidence
  rows are Kansas). This is a complete, permanent, single-state gap, not scattered suppression —
  the site (SPEC.md §3) already plans an explicit Kansas explanation page for exactly this reason.
- **Incidence-only loss (mortality suppressed) is scattered across low-population
  rural/Western/Great Plains states**: Nebraska (14), Texas (10, its sparse panhandle/west-Texas
  counties), Alaska (7), Montana (5), North Dakota (3), South Dakota (3), Utah (2), Idaho (2),
  Colorado (1), New Mexico (1). This is ordinary small-count suppression (<16 deaths, per
  `cancer-compass/docs/research/epi-view-conventions.md` §7), concentrated in exactly the small,
  rural counties the exceedance model (M4) exists to serve — reinforcing that the BYM2 smoothing is
  solving a real problem, not a cosmetic one.

**Consequence for M3 (MIR):** headline all-sites MIR is computable for 2,980 of 3,143 counties
(94.8%) before per-cancer-site stratification, which will push the computable set smaller for rare
sites. Kansas's 104 counties need an explicit "no reliable estimate — county-level incidence
withheld by state law" state distinct from ordinary suppression (SPEC.md §3 already anticipates
this). Per-site N will need to be recomputed once cancer-site stratification is applied; this
number is the headline/all-sites ceiling, not the final per-site N.
