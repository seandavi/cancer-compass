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
against 2019–2023 — different eras. This part stands: the windows really do differ, exactly as
SPEC.md assumed. **The prescribed fix does not stand as written.** SPEC.md's fix was "reconstruct
the mortality rate from CDC WONDER restricted to exactly 2018–2022." `docs/audit/03-cdc-wonder.md`
and `03b-mortality-alternatives.md` establish that this specific route is not available: WONDER's
API refuses all county-level queries by policy, and even with access, WONDER's own
2018-2024-covering database (D158) publishes no county age-adjusted rates or populations, only
raw counts. Constructing the window-aligned mortality rate now depends on obtaining county death
*counts* via a different route entirely (the NCHS restricted-use Data Use Agreement, per 03b) plus
SEER's population files, and computing the rate and its interval ourselves — a materially bigger
undertaking than "pull a rate from WONDER." Treat this file's finding (the windows differ) as
settled; treat the construction of the aligned mortality rate as unresolved pending 03/03b's
open decision.
