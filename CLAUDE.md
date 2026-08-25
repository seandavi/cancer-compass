# cancer-compass

**Every claim the site or paper makes must trace to a pinned, hashed upstream source.**
Never build against `hf://datasets/seandavis/state-cancer-profiles` "latest" or an
unpinned Zenodo concept DOI — always the specific version DOI recorded in the build
manifest. Same discipline for CDC WONDER, NPPES, ClinicalTrials.gov, and TIGER pulls:
record what was fetched and when.

## What this repo is

Three analytics that don't exist anywhere public today (window-aligned MIR, posterior
exceedance probability via a BYM2 spatial model, and access-to-care measures), delivered
as a fully static, prerendered site (Astro → Cloudflare Pages, no backend, no
client-side query engine) with pages per geography, cancer site, and indicator/measure,
and the findings paper those analytics support. See `SPEC.md` for the full plan; audit
findings that gate the build live in `docs/audit.md`.

Formerly developed under the working name `county-cancer-atlas`, consolidated with an
earlier separate `cancer-compass` prototype (now archived as
`seandavi/cancer-compass-vite-prototype`) — that prototype's audience/IA research moved
into `docs/research/`, its Vite/DuckDB-WASM architecture did not. See `SPEC.md`'s header
for why (paper-citable permanent URLs favor a static build over a live query engine).

Depends on `state-cancer-profile-scraper`'s archive as a pinned Zenodo version DOI —
never latest, never HF's mutable main branch. That repo produces the extract; this repo
consumes one frozen version of it.

## Conventions

- **Task 0 (the audit) gates everything.** Several of its answers determine whether
  parts of §2 (analytics) are even feasible — don't build against an assumption the
  audit hasn't confirmed. Spec claims that predate the audit may be stale; verify against
  the pinned data and the live upstream APIs before trusting them.
- **No ranking surface, ever.** The funnel plot exists specifically so a sortable
  top-N table is never needed. If a feature request implies one, it's out of scope.
- **No causal or individual-risk language** in copy, chart labels, or code comments/names.
  MIR is not "survival." An exceedance probability is not "your risk."
- **Uncertainty is never optional.** No point estimate renders without an interval, and
  no suppressed/unmodeled cell renders as blank, zero, or a dash — always an explicit
  "no reliable estimate" state with the reason.
- **2020 is excluded from any trend fit**, matching SCP's own handling, but still
  displayed as a point. A code path that fits a trend through 2020 is a defect.
- **All charts are static, build-time SVG.** No client-side charting library.
- **URLs are permanent, across all page types** (`/county/...`, `/state/...`, `/cancer/...`,
  `/measure/...` — see SPEC.md §3). Slugs come from FIPS or a stable code, never display names.
  These go in a citable paper; treat them as immutable once launched.
- **No open-ended query/comparison UI.** The `/compare` page (SPEC.md §3.D) is bounded to a
  handful of named places — it is not a general pivot-table or exploration tool. That's a
  deliberate choice not to compete with Cancer InFocus or ECCO on dashboard features; see
  `docs/research/peer-tools-landscape.md`.
