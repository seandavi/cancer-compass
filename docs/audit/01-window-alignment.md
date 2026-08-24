# Task 0.1 — Window alignment

**Status: answered. Gating for MIR (SPEC.md §2.1) — confirms the windows differ, as the spec assumed.**

Source: `notes_incidence.txt` and `notes_mortality.txt`, shipped inside the pinned Zenodo
version DOI `10.5281/zenodo.22085273` (vintage V3), fetched directly from
`https://zenodo.org/records/22085273/files/notes_incidence.txt` and `.../notes_mortality.txt`.

- **Incidence window: 2018–2022** ("All Cancer Sites (All Stages^), 2018-2022").
- **Mortality window: 2019–2023** ("All Cancer Sites, 2019-2023").

The windows are offset by exactly one year, sharing four of five years — consistent with
`state-cancer-profile-scraper`'s own documented behavior for consecutive vintages of the same
topic. Both are age-adjusted to the 2000 US standard population (incidence: 19 age groups NPCR /
20 SEER; mortality: 20 age groups) per the same notes files.

**Consequence for SPEC.md §2.1:** a naive incidence-rate ÷ mortality-rate ratio compares 2018–2022
against 2019–2023 — different eras. The mortality rate used for MIR must be reconstructed from
CDC WONDER restricted to exactly 2018–2022 (the incidence window), age-adjusted to the 2000 US
standard to match, not read directly from SCP's published 2019–2023 mortality rate. This confirms
the spec's premise and its prescribed fix; no methodology change needed here.
