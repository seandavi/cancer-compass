# Research carried over from the original `cancer-compass` prototype

This directory's five files were written during an earlier, separate phase of this project, when
`cancer-compass` was a client-side Vite + DuckDB-WASM explorer (a different repo, since renamed to
`cancer-compass-vite-prototype` and retired — its content merged into this repo rather than
continuing as a separate product; see the consolidation discussion in this repo's history/PR trail
for why).

The audience research, epidemiological conventions, and IA patterns here remain fully valid and
inform this site's page design — that's why they moved over. One thing has changed: the delivery
architecture. These docs sometimes discuss DuckDB-WASM feasibility as *the* delivery mechanism;
this site instead uses DuckDB as an **offline build-time tool** (see `../../build/`) producing
fully static, prerendered pages (SPEC.md §0's "not a dashboard" principle). Read the content for
audience/design intent, not for architecture.

- `datausa-ia-patterns.md` — page-type and IA reference informing the Astro page templates
- `peer-tools-landscape.md` — competitive landscape (State Cancer Profiles, SEER*Explorer, CDC
  USCS, IHME GBD); also the record behind this project's explicit choice not to compete with
  Cancer InFocus or ECCO on dashboard/exploration features
- `epi-view-conventions.md` — the site's epidemiological style guide (suppression, uncertainty,
  rankings, disparity framing); cited throughout `../audit/`
- `personas.md` — audience personas; reconciled with SPEC.md §4's stricter editorial rules
  (no individual-risk framing, no rankings) applied site-wide, not just to the new analytics
- `data-schema-audit.md` — early SCP schema audit; superseded in most respects by the more
  rigorous, vintage-pinned audits in `../audit/`, kept for historical cross-reference
