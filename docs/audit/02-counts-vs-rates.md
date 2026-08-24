# Task 0.2 — Counts vs rates

**Status: answered, and it corrects a premise in SPEC.md §2.2.**

Verified directly against the pinned V3 parquet files (`10.5281/zenodo.22085273`), cross-checked
against `cancer-compass/docs/research/data-schema-audit.md` (same vintage, audited earlier from
the HF mirror, byte-identical to the Zenodo files — confirmed by matching file sizes).

**SCP's extract carries counts, not only rates, for both incidence and mortality.** Both
`state_cancer_profiles_incidence.parquet` and `state_cancer_profiles_mortality.parquet` have an
`average_annual_count` column (case/death counts), populated exactly when the rate is populated.
SPEC.md §2.2 assumed "If SCP publishes only rates... exceedance is feasible for mortality (counts
available from CDC WONDER) and infeasible for incidence" — the "rates only" premise is outdated as
written; this may be the thing the earlier conversation flagged as possibly stale.

**This does not change the spec's conclusion, for a different reason.** `average_annual_count` is
a **5-year annualized average** (one number per county × cancer × sex × race × age × stage cell for
the whole 2018–2022 or 2019–2023 window), not an annual panel. The BYM2 exceedance model (§2.2) and
the trajectory analytic (§2.4) both need a true annual count series — expected counts by indirect
standardization require age-specific counts and population denominators per year, and the trend
classification needs multi-year points with 2020 identifiable and excludable. SCP's single
5-year-average count cannot supply either. **CDC WONDER remains necessary for M4, for the same
reason SPEC.md gives, just not the reason it states.** Recommend the manuscript describe this
precisely: SCP provides period-average counts (useful for the MIR denominator/numerator and for
uncertainty on the ratio itself, §2.1), while WONDER provides the annual panel the spatial and
trend models require.

**Practical note for #4 (suppression overlap) and M3 (MIR):** because `average_annual_count` exists
for incidence, the MIR uncertainty calculation (§2.1 "propagate uncertainty... a ratio of two
uncertain rates") can use SCP's own incidence numerator/count directly rather than needing a second
WONDER pull for incidence counts — WONDER is only required for the mortality side of MIR (to get
the window-aligned 2018–2022 mortality rate) and for the M4 model (mortality annual panel).
