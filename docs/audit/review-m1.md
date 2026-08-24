# M1 review — `statistical-reviewer` pass on the Task 0 audit

Persona and scope per SPEC.md §5. Reviewed: `docs/audit.md` and all eight files in `docs/audit/`.
This is a critical read of what is written, not a re-verification of the external facts — no
upstream source was re-fetched. Findings are ordered most severe first.

---

**1. `docs/audit.md` row 0.3 — softens the detail file's most consequential finding. (understated)**
`03-cdc-wonder.md:330-336` says **M3 — SPEC.md's declared go/no-go — is "degraded"**, and that if
county counts can't be obtained M3 must "fall back to SCP's own 2019–2023 mortality rate and drop
the window-alignment claim (losing the stated methodological contribution)." The summary row says
only "Blocked as scoped, viable alternative found… needs a decision + ~4wk lead time." A reader of
audit.md alone does not learn that the window-aligned MIR — the entire methodological contribution
per SPEC.md §2.1 — is contingent on an unsigned federal DUA. Same omission for §2.4:
`03-cdc-wonder.md:344` flags that the trajectory analytic needs annual points with 2020 excludable
and that a period-aggregated substitute may not survive; audit.md never mentions §2.4 is affected.
**Fix:** state in the 0.3 row that M3 (the go/no-go) and §2.4 both depend on this, and add a line to
"Decisions needed" naming the fallback that loses the window-alignment claim.

**2. `05-nppes.md:279-283` — uses a 3,144-county universe, contradicting the corrected 3,142.
(inconsistent; correction not propagated)**
Both columns sum to 3,144: geocode-only 1,123 + 2,021 = 3,144; with fallback 1,174 + 1,970 = 3,144.
`07-adjacency.md:129` and the corrected `04` both establish 3,142. The zero-oncologist figure is a
headline in audit.md, so the denominator has to match. The percentages happen to round the same
either way, which is why this survived review.
**Fix:** recompute on the 3,142 SCP/TIGER2021 universe; state explicitly whether PR and the
`02261`/`51917` crosswalk were applied. 05 must use the same crosswalk as 07 or the county counts
won't join.

**3. `04-suppression-overlap.md:43-44` — the 07 correction is present but incomplete. (inconsistent)**
The correction block and table were updated to 3,142/2,979, but the "Consequence for M3" paragraph
immediately below still reads "**computable for 2,980 of 3,143 counties**." The stale numbers sit in
the section a downstream reader is most likely to quote. The correction was applied to the table
only.
**Fix:** change to 2,979 of 3,142.

**4. `04-suppression-overlap.md:22, 29-39` — three arithmetic/attribution problems in the loss
breakdown. (inconsistent / unsupported)**
 a. "Mortality-only loss is **100% Kansas (all 104 counties)**" — Kansas has **105** counties, so
 "all" cannot be right. Reconciling with the table: 3,142 − 3,028 = 114 counties missing incidence,
 of which 104 are mortality-only; the residual is consistent with Kansas's 105th county *also*
 having mortality suppressed. Honest statement: "104 of Kansas's 105 counties; the remaining one has
 mortality suppressed as well."
 b. The incidence-only state list sums to **48** (14+10+7+5+3+3+2+2+1+1), not the 49 in the table.
 One county is unaccounted for.
 c. **The "neither usable" bucket is never reported.** 2,979 + 49 + 104 = 3,132, leaving **10
 counties with neither incidence nor mortality** at the headline stratum. They need their own "no
 reliable estimate" reason on the site (SPEC.md §3) and appear nowhere in the audit.
**Fix:** re-run the crosstab, add the fourth row, reconcile the state list to its total.

**5. `docs/audit.md` — drops the audit's only near-boundary-violation finding. (gap, and it is this
persona's own mandate)**
`06-travel-time.md:83-96` establishes that the published 2SFCA scores' demand denominator
**Monte-Carlo-imputes suppressed county SCP incidence and disaggregates it to ZCTA** — "very close
to the operation SPEC.md §2.2 explicitly forbids" — and concludes: do not ingest
`Accessibility_*.csv.gz` as a headline number. The audit.md 0.6 row says only "Ingest a verified CC0
oncologist travel-time matrix (Liu et al. 2026)," which reads as endorsing the whole deposit. That
is the summary line most likely to cause the forbidden thing to get built.
**Fix:** name the files to ingest (`200km_9m_OD_list.csv.gz` + `Oncologist_FTE.csv.gz`) and the file
not to, with the reason, in the summary row itself.

**6. `01-window-alignment.md:17-21` — its prescribed fix is now known infeasible and the file doesn't
say so. (stale / unsupported as written)**
"The mortality rate used for MIR must be reconstructed from CDC WONDER… This confirms the spec's
premise and its prescribed fix; **no methodology change needed here**." `03-cdc-wonder.md:290-295`
establishes the opposite: WONDER cannot supply this at all (county access refused; and even with
access D158 publishes no county age-adjusted rates for 2021–2022), so the rate must be computed by
the project from counts plus SEER denominators — and 03b makes those counts contingent on a DUA. "No
methodology change needed" is the most misleading sentence in the audit set, because 0.1 is the file
someone will cite when writing the MIR methods.
**Fix:** add a forward-reference block (same pattern 04 used for 07) stating that the source and
construction of the window-aligned mortality rate is unresolved per 0.3/0.3b; the window finding
itself (2018–2022 vs 2019–2023) stands.

**7. `03b-mortality-alternatives.md:53-57` contradicts `02-counts-vs-rates.md:18-26`. (inconsistent)**
03b's fallback proposes "SCP's public 5-year county counts as the observed layer" for the exceedance
model. 02 established that `average_annual_count` **cannot** supply the BYM2's inputs, because
expected counts by indirect standardization need age-specific counts and per-year denominators. As
written, 03b's fallback is ruled out by 02's finding and the audit doesn't notice.
**Fix:** either show that SCP's age-stratified counts can support indirect standardization at the
5-year period level (a period-level, non-annual exceedance model is defensible — but it is a
*different* model from SPEC.md §2.2 and drops §2.4 entirely), or withdraw the fallback.

**8. `02-counts-vs-rates.md:6-8` — "byte-identical… confirmed by matching file sizes." (fake
precision)**
Matching file sizes is not byte-identity. The whole cross-check against
`cancer-compass/docs/research/data-schema-audit.md` rests on it, and 04 and 07 both hash files
properly, so the tool was in hand.
**Fix:** sha256 both, or downgrade the claim to "same size and same schema; not hash-verified."

**9. `06-travel-time.md` — no uncertainty treatment anywhere. (gap against SPEC.md §0)**
`05-nppes.md:319-323` handles this exactly right for a measure with no sampling error: refuses to
manufacture a CI, substitutes the measured staleness rate. 06 has no equivalent, despite identifying
real uncertainty sources itself — undisclosed OSM snapshot, unstated centroid definition
(population-weighted vs geometric, `06:111`), free-flow vs congested speeds, main-campus-only NCI
addresses that "systematically *overstate* distance" (`06:172-176`). Those are directional biases,
not noise, and none reaches the §6 consequences.
**Fix:** add a §6 item mirroring 05 §7.7 — a named list of biases with directions, plus the
block-group-to-county aggregation method.

**10. `06-travel-time.md:231-234` — collapses the distinction the same file just established.
(inconsistent)**
Item 5 gives "no oncologist within threshold (**11,148** ZCTAs at 45 min)" as one state and "not
routable (247)" as another — but §1 (`06:58-64`) proves 11,148 *contains* the 247, since 2SFCA=0
encodes both. The file's own 60-min arithmetic confirms it: 7,820 − 247 = 7,573. The 45-min figure
for the first state is 10,901.
**Fix:** 10,901 + 247, and note the same subtraction applies at every threshold.

**11. `06-travel-time.md:121-123` — the justification for not recomputing is asserted, not measured.
(unsupported)**
"A ~1-year-stale NPPES extract moves a drive-time-to-nearest-oncologist number very little." Nothing
measured, and it sits in tension with 05's measured 44.6%-stale-in-5-years result. It is also cheaply
checkable: 05 ran the full NPPES→geocode pipeline on the August 2026 file, so Liu's 9,967 practice
sites could be compared against ours directly. Related and unflagged: Liu et al. use **three**
taxonomy codes (`06:70-75`) while 05 recommends **six**, so consequence #2 puts two different
definitions of "oncologist" on the same county page without requiring a stated caveat.
**Fix:** run the site-count comparison or restate as an assumption ("assumed small; not measured"),
and add the two-definitions caveat to §6 item 2.

**12. `04-suppression-overlap.md:38-39` and `03-cdc-wonder.md:156-158` — the load-bearing "<16" SCP
threshold traces to another repo's doc, not the pinned source. (unsupported chain)**
Both cite `cancer-compass/docs/research/epi-view-conventions.md §7`. The threshold defines the
missingness reasons the site must render and appears in the paper's methods.
`01-window-alignment.md:5-7` shows `notes_incidence.txt` / `notes_mortality.txt` are fetchable
directly from the pinned Zenodo record — the primary source is one HTTP request away.
**Fix:** quote the rule verbatim from the pinned notes files; keep the secondary citation as
corroboration.

**13. `02-counts-vs-rates.md` + `docs/audit.md:21-23` — "corrects SPEC.md §2.2's premise" invites the
wrong edit. (boundary risk)**
SPEC.md §2.2's mortality-only rule rests on "incidence lacks the counts this requires." The audit
correctly shows that stated premise is outdated, but neither file says in terms that **the
prohibition itself still stands** on independent grounds (no annual panel; suppression pattern makes
back-computation indefensible). Someone editing SPEC.md from audit.md's correction list could
plausibly conclude the incidence-exceedance prohibition is obsolete. No file actually computes or
proposes an incidence exceedance — the boundary is intact — but the summary leaves the door ajar.
**Fix:** one sentence in both: the mortality-only constraint is unchanged; only the stated reason
changes.

**14. `05-nppes.md` — the code set behind the headline is never pinned down. (traceability)**
Three denominators with three qualifiers: 48,112 records "carrying at least one **target** code"
(`05:116`), 38,811 Entity Type 1, and 37,778 "Entity Type 1 records with a **core** oncology code"
(`05:137`). 48,112 exceeds the sum of the five core codes' `any` counts (45,759), so "target" must
include `2085R0203X` and probably `2080P0207X` — inference, not statement. The entire
62.7%-zero-oncologist finding depends on which set produced 37,778.
**Fix:** state the exact code list behind 37,778, and whether pediatric hematology-oncology is in or
out (§2 says "include, but count separately"; §7's six-code list excludes it).

**15. `05-nppes.md:337` — "12.5% of providers placed by ZIP rather than street match."
(inconsistent)**
§6 gives 10.9% ZIP-fallback and 1.5% unresolved. 12.5% conflates "placed less precisely" with "not
placed at all" — and unresolved providers are the state §7 item 6 rightly insists must be distinct
from a measured zero.
**Fix:** "10.9% placed by ZIP, 1.5% unplaced." Same correction to §7 item 7's "12.5% non-exact
geocode share."

**16. `03b-mortality-alternatives.md:55-57` — the IHME "temporal-shape prior" fallback is design
overreach. (overreach)**
The audit's job for 0.3 was to establish whether county mortality counts are obtainable. Proposing a
specific hierarchical construction — IHME small-area-model output as a prior inside our own BYM2,
whose published output is an exceedance probability — is an M4 modelling decision made in an audit
document, on a source the same table rules out three rows earlier as "fitting a model to another
model's estimates." The file does flag it as weaker evidence, which is honest, but it should not be
pre-committed here.
**Fix:** keep the finding (IHME exists, is modeled output, is not equivalent to observed counts);
drop the prescribed construction or mark it as an option requiring its own review.

**17. `07-adjacency.md:256-261` — the disconnected-component caveat covers singletons but not Alaska.
(gap)**
Item 7 correctly warns that the three Hawaii singletons plus Kalawao/Maui borrow no spatial strength
and should say so on their pages. Alaska's 29-county component has the same structural issue — with
per-component sum-to-zero (`07:196-198`), Alaska's spatial effect cannot borrow toward the national
level through the graph, so P(county > national) for Alaska rests on a different amount of borrowed
strength than for a CONUS county. Since the exceedance probability is *the number shown to users*
(SPEC.md §2.2), cross-component comparability is a first-class interpretation issue.
**Fix:** extend item 7 to name Alaska, and add "component id / borrowed-strength class" to the
per-county output so the page can state it.

**18. `docs/audit.md` — four M2-gating findings from 03 don't appear in the summary. (gap)**
(a) **Connecticut breaks in 2022** — counts exist, denominators don't; `03:296-300` says "CT joins
Kansas and Indiana as a page that must exist and explain itself." SPEC.md §3 and the §8
definition-of-done name only Kansas and Indiana, so this needs an explicit spec edit and belongs in
"Decisions needed." (b) **Four incompatible suppression thresholds** now in play — SCP <16, WONDER
counts <10, WONDER unreliable <20, NCHS presentation standard <20 — a modelling and copy constraint,
not a footnote. (c) The **bridged-race → single-race seam at 2020/2021**, which `03:348` says must be
a disclosed limitation. (d) The **`02261` Alaska crosswalk**, which 07 makes mandatory and 03
independently confirms.
**Fix:** add these to audit.md, at least as a short "spec edits required" block alongside the
existing corrections block.

**19. Smaller items, one line each:**

- `06:176` "leaving 66–68 sites" and `06:203` "~67 clinical NCI destinations" — the shapefile was
  downloaded and parsed and carries a `type` field, so the exact count of Basic Laboratory centers is
  knowable. Give exact N per type. (fake precision)
- `02:22-23` "for the same reason SPEC.md gives, just not the reason it states" is
  self-contradictory; intended meaning is "same conclusion, different reason." (clarity, in a bolded
  sentence)
- `04:29-36` "Mortality-only loss" / "Incidence-only loss" read backwards — Kansas is where
  *incidence* is lost. `audit.md:11` repeats the phrasing verbatim. Rename to "mortality available,
  incidence missing." (clarity; the kind of label that flips a sentence in the paper)
- `06:150` uses `CenPop2020_Mean_CO.txt` (3,221 rows) with no note that PR must be dropped and the
  `02261`/`51917` crosswalk applied to reach 3,142 — a fourth county universe in circulation.
  (consistency)
- `audit.md:12` "62–64%" bundles the rejected geocode-only method into the headline range; the
  recommended two-stage method gives one number, 62.7%. (precision)
- `03:180-188` D140's API behaviour is left explicitly **unresolved**, and audit.md's "Not yet done"
  doesn't list it. (gap; low stakes, the year range disqualifies it anyway)
- **Not tracked anywhere:** now that the window-aligned mortality rate must be *computed* by us
  rather than read from WONDER, its confidence interval must also be constructed by us — and
  `03:144-149` flags that D76 and D158 use different interval methods (normal-approximation vs
  Fay-Feuer). SPEC.md §2.1 requires propagating that interval through a ratio. Which method, and how
  it propagates, is an open statistical item that belongs in "Not yet done."

---

## What's clean

`07-adjacency.md` is the strongest file in the set — every number checks arithmetically (components
sum to 3,142; mean degree 5.91 = 2×9,282/3,142; the crosswalk closes 3,143→3,142 on both sides), the
derivation is validated against the official file rather than asserted, and the island handling cites
the correct primary reference and explicitly refuses artificial edges. Findings 17 and 19 are
additions, not corrections.

`05-nppes.md:319-323` is the model for how the rest of the audit should treat uncertainty: it names
the CLAUDE.md rule, explains why a CI would be fabricated, and substitutes a measured staleness rate.

`03-cdc-wonder.md:229-231` labels its own extraction estimate "hypothetical" rather than letting a
dead number look live.

`06-travel-time.md:83-96` catching the imputed-incidence denominator is the finding most likely to
have prevented an actual §2.2 boundary violation — it just needs to survive into the summary.

---

## Overall verdict

Not yet M1-done — findings 1–6 are propagation and summarization failures that would mislead the next
milestone (a stale "no methodology change needed" on MIR, a wrong county denominator behind a
headline finding, an incomplete correction, and a summary that hides the go/no-go risk); fix those
plus the arithmetic in 4, and the rest can be tracked as M6 methods items.
