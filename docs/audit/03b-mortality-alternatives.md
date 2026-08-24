# Task 0.3 follow-up — alternatives to the WONDER county-level refusal

**Status: answered. One viable path found, with one thing still unverified.** Follow-on to
`docs/audit/03-cdc-wonder.md` (which found CDC WONDER refuses all sub-national queries via its API).
This surveys every other plausible source of annual county-level cancer mortality counts,
1999-present, across all 3,142 counties (per the corrected count in `04-suppression-overlap.md`).

## Ruled out, verified

| Source | Verdict | Why |
|---|---|---|
| NCHS public-use mortality micro-data | **No, 2005+** | Verified from the record-layout PDFs themselves: "excluding geographic identifiers goes into effect with the 2005 data year." County fields exist in the docs only under the *Territories* file layout, not the US layout. |
| Same, 1999–2004 | **No** | County exists but truncated: counties under 100,000 population collapse into one per-state bucket. Even the "good" years can't support a 3,142-county model. |
| NBER mortality mirror | **No** | Same NCHS bytes, same 2005+ restriction, verified directly. |
| data.cdc.gov / healthdata.gov | **No** | Socrata search for county-level annual cancer mortality returns nothing; the one cancer-adjacent hit (`vdpk-qzpr`) is state-level. |
| NCI State Cancer Profiles Historical Trends | **No** | Confirmed from the live form: state-only, no county option, no `areatype` parameter. |
| IHME/GHDx county cancer mortality (1980–2014, 2000–2019) | **Partial, and not preferred** | Real, free, no registration, annual, county-complete — but explicitly a **small-area-estimation model output**, not observed counts ("IHME research used... small area estimation models"). Building our own BYM2 model on modeled input would be fitting a model to another model's estimates. Non-commercial license. Ends 2014/2019, not present-day. |

## The one viable path: NCHS restricted-use vital statistics, Route A (not the RDC)

**`https://www.cdc.gov/nchs/nvss/nvss-restricted-data.htm`** lists a **"Deaths (Mortality) –
Multiple cause of death, states and all counties – Detailed"** file, confirmed from
`detailed-mortality-file-description.pdf` to carry Residence State FIPS, **County FIPS**, City FIPS,
Metro/Nonmetro, full ICD-10 cause fields, coverage **1989–latest, all counties**.

This is a **different route from the NCHS Research Data Center (RDC)**, which explicitly states it
"**never** approves projects to produce county-level... estimates" and charges a $3,000–4,500
management fee. Route A (the restricted-data DUA) is the one that actually offers county geography.

**Requirements, as documented:** a Project Review Form + CVs of everyone with access, emailed to
`nvssrestricteddata@cdc.gov`; an institutional Data Use Agreement signed by someone other than the
PI; ~4 weeks processing. **No stated fee.** Not an enclave — files are hosted at the requesting
institution (cloud storage explicitly prohibited). Disqualifying request types (single-state scope,
sub-county geography, commercial use) do not apply to us.

**What is not yet verified: the right to publish per-county aggregate results.** The eight public
Conditions of Use are all file-handling (destroy after project, no re-sharing, no re-identification)
— there is no stated output-review/publication-approval clause on this route, unlike the RDC. But
this was read from the public policy page, not the DUA instrument itself. **Get the actual DUA text
and confirm the republication right in writing before this milestone depends on it.**

Assume NCHS's own presentation standard applies regardless: rates based on fewer than 20 deaths are
suppressed with an asterisk (`presentation-standards-mortality-2024.pdf`) — a third suppression
threshold, distinct from both SCP's <16 and WONDER's <10/<20 rules already noted in
`03-cdc-wonder.md`.

## Consequence for M2/M4

1. **This is the recommended path**, not the CDC custom-data-request route `03-cdc-wonder.md`
   floated (which has no defined turnaround or scope commitment). File the Project Review Form and
   DUA request now — 4 weeks is a real critical-path item for M2.
2. **Before committing M4 to this data**, get written confirmation that county-level aggregate
   results (not raw records) are publishable. If that comes back no, the fallback is a two-layer
   compromise: SCP's public 5-year county counts as the observed layer (already in hand, all
   counties, all sites) plus IHME's county series used only as a temporal-shape prior, explicitly
   framed in the paper as modeled-on-modeled and weaker evidence — not silently blended in as if
   equivalent to observed counts.
3. This is a **project-owner decision**, not something to resolve by building around it — filing a
   federal data use agreement and waiting ~4 weeks changes the milestone timeline, and needs sign-off
   before M2 proceeds on this item.

## Sources

- NCHS Data Release Policy for Vital Statistics: https://www.cdc.gov/nchs/nvss/dvs_data_release.htm
- NCHS Restricted-Use Vital Statistics Data: https://www.cdc.gov/nchs/nvss/nvss-restricted-data.htm
- Detailed Mortality File description: https://www.cdc.gov/nchs/data/nvss/detailed-mortality-file-description.pdf
- NCHS Research Data Center, geographic variables: https://www.cdc.gov/rdc/nchs-geographic-variables/index.html
- NCHS presentation standards (2024): presentation-standards-mortality-2024.pdf
- NBER mortality data mirror: https://www.nber.org/research/data/mortality-data-vital-statistics-nchs-multiple-cause-death-data
- IHME/GHDx: https://ghdx.healthdata.org/record/ihme-data/united-states-cancer-mortality-rates-county-1980-2014 ; https://ghdx.healthdata.org/record/ihme-data/united-states-causes-death-life-expectancy-by-county-race-ethnicity-2000-2019
- SEER county population files: https://seer.cancer.gov/popdata/download.html (denominator side, already verified in `03-cdc-wonder.md`)
