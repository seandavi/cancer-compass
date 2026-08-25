# User personas

Not carried over from `state-cancer-profile-scraper` — that repo's only "personas" are QA
review roles for its own manuscript (`data-provenance-reviewer`, `manuscript-reviewer`,
SPEC.md §4), which don't transfer to an app's target users. These are written fresh, each
grounded in a real, citable audience already surfaced by the research in this directory or
by the scraper repo's own landscape review — no invented user types.

Each persona lists: who they are, what they come to Cancer Compass to do, which page types
from `datausa-ia-patterns.md` serve them, and which guardrail from `epi-view-conventions.md`
matters most for them specifically (so a page can't ship "generically safe" — it has to be
safe for the persona actually reading it).

---

## 1. Cancer center Community Outreach & Engagement (COE) staff

**Who:** Community outreach coordinator or catchment-area epidemiologist at an NCI-designated
cancer center, producing the catchment-area cancer-burden characterization NCI's 2017
Community Outreach and Engagement requirement obliges every such center to maintain
(`state-cancer-profile-scraper/docs/landscape-literature.md:130-132`).

**Why this persona is well-founded, not invented:** the adjacent tool built for exactly this
job, Cancer InFocus, is licensed by 35 institutions including 26 NCI-designated cancer
centers, and 91.7% of adopters report gathering more data and 72.0% report less effort
disseminating it than their prior (by-hand, "tedious and inefficient") process
(`state-cancer-profile-scraper/docs/landscape-literature.md:126-150`, citing Burus et al.).
That's a quantified, peer-reviewed demand signal for this exact job, not a guess.

**Comes to Cancer Compass to:** pull a county (or multi-county catchment area) profile —
burden by site, demographics, risk/screening context — for a grant report or community needs
assessment, and export the numbers/charts.

**Pages used:** Geography profile (primary), Comparison view (catchment area vs. state/nation).

**Guardrail that matters most:** suppression handling. A catchment area is often a handful of
rural counties — exactly where county-level cells hit the <16-case suppression threshold most
often (`epi-view-conventions.md` §7). A tool that silently blanks or zeroes a suppressed county
produces a wrong number in someone's federal grant report.

---

## 2. State or local health department cancer-control planner

**Who:** Named directly as State Cancer Profiles' own target audience — "health planners,
policy makers, and cancer information providers" (`peer-tools-landscape.md` §1, quoting SCP's
own brochure).

**Comes to Cancer Compass to:** find where cancer burden is high *and* rising (SCP's own
"priority index" concept — rate already high, trend rising — `epi-view-conventions.md` §6, §10
item 5), to target where a state cancer plan's limited resources go next, and to check whether
a county's risk-factor prevalence (smoking, screening uptake) plausibly explains its rate.

**Pages used:** Geography profile, Cancer site profile (state choropleth + ranked table),
rate/trend cross-classification.

**Frustration this replaces:** SCP itself is single-area, single-measure, form-submit
architecture — no multi-state selection, no bivariate risk-factor-vs-outcome view even though
its own data invites one (`peer-tools-landscape.md` §1 usability gaps, §"Opportunities" item 1).
This persona is the direct beneficiary of the cross-topic view the peer-tools research flagged
as the biggest open opportunity.

**Guardrail that matters most:** rankings must carry rank uncertainty. This persona is the one
most likely to act on a ranking, and SCP's own published cautions exist because "ranks for
relatively rare diseases or less populated areas may be essentially meaningless"
(`epi-view-conventions.md` §6).

---

## 3. Epidemiologist / public health researcher

**Who:** Someone who wants the data itself, not a canned chart — the audience the scraper repo
was built for in the first place. Its own reuse-value argument is written for this reader:
analysis-ready bulk Parquet instead of SCP's per-query CSV, decoded suppression instead of
asterisks-in-numeric-columns, and single-query cross-topic joins
(`state-cancer-profile-scraper/SPEC.md` §6, "Analysis-ready bulk access").

**Comes to Cancer Compass to:** filter to a precise cross-tab (site × race × stage × geography),
confirm exact rate/AAPC definitions, check which data vintage a number came from, and export the
current filtered selection as CSV/Parquet rather than a screenshot.

**Pages used:** Indicator/measure page, a `/methods` page (age-adjustment standard, suppression
rule, joinpoint AAPC definition — `epi-view-conventions.md` §1–2, §7–8), plus raw export from any
page.

**Guardrail that matters most:** every value must carry its data period, source (NPCR/SEER vs.
SEER-only, BRFSS, ACS), and — uniquely valuable here since the peer tools listed as good ideas
in `peer-tools-landscape.md` §"Opportunities" item 8 — its data *vintage*, since this reader is
the one who will actually notice if two numbers on the same page came from different releases.

---

## 4. Health journalist / data communicator

**Who:** Writing a story that needs a defensible, quotable statistic — "this county's colorectal
cancer rate is 1.4× the state average and rising" — for a general audience.

**Comes to Cancer Compass to:** find a genuinely notable, correctly-qualified fact fast, and get
a chart or number they can cite or embed without having independently learned what CI\*Rank or
AAPC significance means.

**Pages used:** Geography profile's "notable here" callout block (borrowed from County Health
Rankings' Areas of Strength/Explore pattern, `datausa-ia-patterns.md` §6), Cancer site profile.

**Guardrail that matters most:** this persona is exactly who over-claims a ranking or a
crude-vs-age-adjusted comparison, so the narrative-sentence generation this app borrows from
Data USA's "prose is generated from the same variables as the chart" pattern
(`datausa-ia-patterns.md` §5 item 2) has to *itself* encode the rising/falling-by-CI rule and the
rate-ratio threshold (`epi-view-conventions.md` §2, §8) — the guardrail belongs in the sentence
template, not as a caveat this reader is expected to apply themselves.

---

## 5. Interested resident ("how does my county compare?")

**Who:** No public-health background, arrived from a search engine or a shared link, wants one
county looked up in plain language. This is the audience Data USA's whole design is legible to
without a stats background, and the one State Cancer Profiles' raw rate tables and CI\*Rank
jargon are least accessible to (`peer-tools-landscape.md` §1; `datausa-ia-patterns.md` §5).

**Comes to Cancer Compass to:** look up one place, get a short plain-language answer, leave.

**Pages used:** Geography profile hero + "notable here" block only — this persona is the reason
that block has to work standing alone, without requiring a trip through the methods page.

**Guardrail that matters most:** suppressed/unstable cells need an *informative* empty state
("not enough data to estimate reliably at this level of detail — try the state view"), not a
blank chart or a silent zero — this reader has no prior model of registry suppression to fall
back on (`epi-view-conventions.md` §7 guardrails, last bullet).

---

## 6. Patient or caregiver

**Who:** Someone recently diagnosed, or a family member/caregiver, searching for their own
county or state after a diagnosis — a distinct stake from persona 5's casual curiosity. This is
exactly the audience ACS's own patient-facing *Cancer Facts & Figures* is written for, framing
population rates in accessible terms rather than registry jargon
(`epi-view-conventions.md` source index, ACS Cancer Facts & Figures 2026).

**Comes to Cancer Compass to:** understand whether their area's rate for their cancer site is
"high," look at risk-factor/screening context, and — the thing they must *not* be able to walk
away believing — estimate their own outlook from a population statistic.

**Pages used:** Cancer site profile, Geography profile's risk/screening section.

**Guardrail that matters most, and one this app doesn't yet have a component for:** a population
age-adjusted rate is not a personal risk or prognosis, and this dataset has no survival measure
at all (`peer-tools-landscape.md` §2 lists survival as explicitly out of scope for this extract).
Every cancer-site and geography page this persona lands on needs a plain-language line saying
so, plus an outbound link to a clinical resource (e.g. NCI's own patient-facing statistics
guidance) — the single guardrail on this list that isn't "present the number correctly," it's
"this is not the number you're actually looking for, and here's where that number lives."
Disparity views this persona reads (`epi-view-conventions.md` §5) also need the "describes places,
not the people in them" framing held to especially tightly here, since the reader is a person,
not a population.

---

## 7. Care provider (clinician, nurse navigator, population-health staff)

**Who:** A primary care clinician, oncology nurse navigator, or practice/health-system
population-health staffer who wants local burden and screening data to inform a screening
conversation, a community outreach push, or a practice-level quality initiative — distinct from
persona 2 (health-department planner) in that the unit of action is a patient panel or practice
population, not a jurisdiction's policy.

**Comes to Cancer Compass to:** check whether their county's screening prevalence for a
screen-detectable cancer (colorectal, breast, cervical) lags a benchmark, and whether that
county's late-stage rate for the same site is elevated — the standard screening-effectiveness
proxy this dataset actually supports (`epi-view-conventions.md` §3, §9: late-stage incidence as a
population-level indicator of screening effectiveness, since mortality is far less sensitive to
screening intensity than incidence).

**Pages used:** Geography profile's Risk Factors & Screening section (with the Healthy People
2030 reference line called out in `epi-view-conventions.md` §4), Cancer site profile's stage
section.

**Guardrail that matters most:** the ecological-fallacy caveat on any screening-vs-outcome view
is load-bearing for this persona specifically, because the natural next step — using an
area-level correlation to justify a claim about their individual patients — is exactly the
inference `epi-view-conventions.md` §4 says the data doesn't support ("associations are between
places, not people"). The screening-prevalence number is also BRFSS survey data on a lag from a
different population than their own patient panel, which needs to stay visible, not folded into
a single implied "screening rate here."

---

## Cross-persona takeaway

Personas 1–3 need the same underlying data at different grains (catchment area, state, precise
cross-tab); 4, 5, and 7 need the same narrative/callout layer built to a stricter honesty
standard than any peer tool currently enforces, each for its own reason (over-claiming a story,
no statistical background, or the pull toward an individual-level inference the data can't
support). Persona 6 is the sharpest case: the one reader for whom the correct answer to their
actual question is "not on this site," and the app has to say that plainly rather than let a
population rate stand in for it. Practically: build the query/join layer once for 1–3, and treat
the narrative-sentence + notable-callout layer for 4, 5, and 7 — plus an explicit not-a-prognosis
disclaimer for 6 — as the one place in the app where the epidemiological guardrails in
`epi-view-conventions.md` are non-negotiable at first release, even if other polish waits.
