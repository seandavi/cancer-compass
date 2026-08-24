# Task 0.7 — County adjacency for the BYM2/CAR model

**Status: answered. A matching adjacency structure is obtainable and was built and verified during
this audit.** Two things the spec did not anticipate: (a) the Census County Adjacency File exists
again but is published only in the *current* geographic vintage, which does **not** match the pinned
data, and (b) the graph is disconnected even after island counties are dealt with, which is a
modelling decision, not a data-cleaning one.

---

## 1. Is the classic National County Adjacency File still published?

**Yes — it was revived.** Fetched
`https://www.census.gov/geographies/reference-files/time-series/geo/county-adjacency.html`
(2026-08-24). The page states verbatim:

> "The Census Bureau resumed production and release of the County Adjacency File product in 2023 in
> response to multiple requests for this product. There was no release of this product between 2010
> and 2023."

Vintages offered: **2010, 2023, 2024, 2025**. Adjacency is defined as:

> "Counties are considered adjacent if they share an edge or have a point-to-point connection."

That is queen contiguity. Beginning with 2025 a `Length` field was added giving the shared boundary
length in metres, where zero means a point-only contact.

Downloaded and parsed all three modern vintages from
`https://www2.census.gov/geo/docs/reference/county_adjacency/county_adjacency{2023,2024,2025}.txt`
(2025 file: 1,062,648 bytes, `sha256 8233d2ae…2bf8fc87`; pipe-delimited, header
`County Name|County GEOID|Neighbor Name|Neighbor GEOID|Length`):

| Vintage | Rows | Distinct GEOIDs | Self-records | Zero-neighbour encoding |
|---|---:|---:|---:|---|
| 2023 | 22,197 | 3,235 | 3,235 | self-record only |
| 2024 | 22,196 | 3,236 | 3,236 | self-record only |
| 2025 | 18,968 | 3,235 | 0 | empty neighbour fields |

The 2025 file is the cleanest form (no self-loops; a zero-neighbour county appears as e.g.
`Hawaii County, HI|15001|||`).

### Why it is nevertheless unusable as-is

All three modern vintages carry **Connecticut planning regions**, not counties — verified directly
in the files: `09110` Capitol, `09120` Greater Bridgeport, `09130` Lower Connecticut River Valley,
`09140` Naugatuck Valley, `09150` Northeastern Connecticut, `09160` Northwest Hills, `09170` South
Central Connecticut, `09180` Southeastern Connecticut, `09190` Western Connecticut. The 2025 file
has **3,144** GEOIDs in states 01–56.

The pinned data uses **old Connecticut counties**. Verified directly against the pinned V3 parquet
files: `select distinct fips … where fips like '09%'` returns `09001` Fairfield, `09003` Hartford,
`09005` Litchfield, `09007` Middlesex, `09009` New Haven, `09011` New London, `09013` Tolland,
`09015` Windham — the pre-2022 set, consistent with `docs/audit/01-window-alignment.md` and with
`state-cancer-profile-scraper`'s documented choice to keep old Connecticut counties for consistency.

The 2010 vintage is old-Connecticut but is wrong in the other direction: it predates the Alaska,
South Dakota and Virginia county-equivalent changes of 2013–2019.

**So no published adjacency file matches the pinned FIPS vintage.** It has to be derived.

---

## 2. Deriving adjacency from TIGER/Line — done, and validated against the official file

Listed `https://www2.census.gov/geo/tiger/` — vintages run through **TIGER2025**. County shapefile
URLs tested with `curl -I`, all HTTP 200:

| Vintage | `COUNTY/tl_YYYY_us_county.zip` | Records | Records in states 01–56 | Connecticut |
|---|---:|---:|---:|---|
| 2021 | 82,328,531 B | 3,234 | **3,143** | **counties (09001–09015)** |
| 2022 | 83,324,165 B | 3,235 | 3,144 | planning regions |
| 2025 | 83,989,800 B | 3,235 | 3,144 | planning regions |

**TIGER2021 is the last vintage with Connecticut counties, and it has exactly 3,143 county units in
the 50 states + DC.** That is the vintage to pin.

- URL: `https://www2.census.gov/geo/tiger/TIGER2021/COUNTY/tl_2021_us_county.zip`
- 82,328,531 bytes, `last-modified: Wed, 22 Sep 2021 19:48:48 GMT`
- `sha256 26890ff92275ff1392cd205c7021ba510b7f63f2ff985ca327b9f5fd5e9ecc90`
- Contents: standard shapefile set, `.shp` is 129,655,820 B uncompressed, CRS NAD83 (EPSG:4269)

### Method validation

Queen contiguity was computed as a `ST_Intersects` self-join on the county polygons using the
already-installed **DuckDB `spatial` extension** (no geopandas/libpysal in this environment, and
none needed — `libpysal.weights.Queen` and `spdep::poly2nb` compute the same relation):

```sql
select a.GEOID, b.GEOID from counties a join counties b
  on a.GEOID < b.GEOID and st_intersects(a.geom, b.geom)
```

Run against **TIGER2025** and compared to the **official 2025 County Adjacency File**:

- computed: 9,286 undirected pairs
- official: 9,286 undirected pairs
- in computed but not official: **0**
- in official but not computed: **0**

**Exact agreement.** The derivation reproduces the Census product bit-for-bit on the vintage where
both exist, so applying the same computation to TIGER2021 is not an approximation — it is the
County Adjacency File the Census Bureau would have published for that vintage. Runtime ~50 s per
vintage; this is a build step, not a problem.

A useful side effect of using TIGER polygons: county boundaries extend over coastal water to the
state's jurisdictional limit, so **water-crossing neighbours come out for free**. Nantucket County
(`25019`) is adjacent to Dukes County (`25007`) with a 26,512 m shared boundary in the official
file, and the same edge appears in the computed graph. Alaska boroughs likewise all connect. No
manual island list is needed for anything except Hawaii.

---

## 3. FIPS crosswalk — the pinned data is *not* plain TIGER2021

Set-comparing the pinned SCP county FIPS against TIGER2021 (states 01–56) turned up three
differences each way, all real and all needing handling:

| In pinned SCP, not TIGER2021 | In TIGER2021, not SCP | Explanation |
|---|---|---|
| `02261` Valdez-Cordova Census Area, AK | `02063` Chugach, `02066` Copper River | SCP/NCI still uses pre-2019 Valdez-Cordova; TIGER split it in 2019 |
| `51917` "Bedford City and County, Virginia" | `51019` Bedford County | NCI merged pseudo-FIPS for Bedford County + the former Bedford city (`51515`, dissolved 2013) |
| `72001` "Puerto Rico" | — | **not a county** — the Puerto Rico *aggregate*, served under `areatype='By County'`. Confirmed: the same `reported_locale` 'Puerto Rico' appears with both `locale_type='county'` and `locale_type='state'`, and it is the only `72%` FIPS present |

Applying the crosswalk — dissolve `02063` ∪ `02066` → `02261`, relabel `51019` → `51917`, drop
`72001` — gives **3,142 units on both sides with zero symmetric difference**. Exact match.

> **Correction to `docs/audit/04-suppression-overlap.md`:** its "Total county FIPS 3,143" includes
> `72001`, which is Puerto Rico in aggregate rather than a county. The real modelling universe for
> this vintage is **3,142 counties**, and SPEC.md §3's "~3,143 county pages" should be 3,142.

### The delivered structure

Adjacency computed on the crosswalked geometry:

- **3,142 counties, 9,282 undirected edges (18,564 directed)**
- degree: min 0, mean 5.91, max 14
- written to `county_adjacency_scp_vintage.csv` (`g1,g2`, sorted, 9,282 rows,
  `sha256 dc72800d…aa958fde`) — reproducible from the pinned TIGER2021 zip plus the crosswalk above

---

## 4. Island / zero-neighbour counties, and the disconnected-graph problem

Under strict queen contiguity, **exactly three counties have zero neighbours**:

- `15001` Hawaii County, HI
- `15003` Honolulu County, HI
- `15007` Kauai County, HI

(`15005` Kalawao and `15009` Maui are adjacent to each other — Kalawao is on Molokai, inside Maui
County's water extent — so they form a pair, not singletons.) Independently confirmed against the
official 2023 file, whose only self-only records in the 50 states + DC are these same three.

Nantucket, the Alaska boroughs, and every other water-crossing case already have neighbours (§2).
**Hawaii is the entire island problem.**

But the harder finding is that fixing Hawaii does not make the graph connected. Component structure
of the delivered graph:

| Component | Size | Contents |
|---|---:|---|
| 1 | 3,108 | CONUS + DC |
| 2 | 29 | all Alaska boroughs / census areas |
| 3 | 2 | `15005` Kalawao, `15009` Maui |
| 4–6 | 1 each | `15001`, `15003`, `15007` |

**Alaska is a separate connected component and no amount of island bookkeeping changes that.** Any
US-wide county CAR/BYM2 model is a disconnected-graph model. This is a modelling specification
issue, not a data defect, and it must be handled explicitly.

### The standard fix — and it is *not* inventing edges

The canonical reference is **Freni-Sterrantino A, Ventrucci M, Rue H. "A note on intrinsic
Conditional Autoregressive models for disconnected graphs." *Spatial and Spatio-temporal
Epidemiology* 2018;26:25–34** ([arXiv:1705.04854](https://arxiv.org/abs/1705.04854)). Its worked
example is precisely this situation: Scottish lip cancer, where Orkney, Shetland and the Outer
Hebrides are singletons.

The paper explicitly rejects both of the tempting shortcuts. On drawing artificial edges — the
approach Breslow et al. took for the Scottish data, "obtained by editing new edges to connect the
islands" — and on WinBUGS/GeoBUGS's default of zeroing singleton random effects, it says:

> "We argue that removing the singletons is needless for the definition of a suitable intrinsic CAR
> model. Our recommended solution is to avoid this and to assign the island-specific random effects
> a normal prior with zero mean and variance equal to κ⁻¹."

and on the zeroing default:

> "it seems too restrictive, in the sense that even though a singleton random effect xᵢ cannot
> capture spatially structured variability because it has no local mean to shrink to, xᵢ should at
> least be allowed to model unstructured variability, hence shrinking towards a global mean."

Its three numbered recommendations:

1. *"We recommend to scale intrinsic CAR models defined with regard to connected graphs."*
2. *"We recommend to scale intrinsic CAR models defined with regard to disconnected graphs."*
3. *"We recommend to use a sum-to-zero constraint for each connected component of size larger than
   one."*

Singletons get a N(0, κ⁻¹) prior so that, after scaling, "the precision parameter has the same
interpretation for all sub-graphs, also for the singleton."

**This is directly supported in R-INLA and needs no custom code.** The paper's own implementation
note: BYM2 "specifically accommodates scaling for connected or disconnected graph," and

> "We flag as true the options: `scale.model` to scale the graph and the `adjust.for.con.comp` to
> adjust for more than one connected component."

So the fix is two flags on the `f(..., model="bym2")` term, not a hand-curated neighbour list.

### Why the alternatives were rejected

- **Nearest-neighbour distance fallback for the three Hawaii singletons.** Technically easy —
  minimum polygon-edge distances computed during this audit: Honolulu↔Maui 30.8 km, Hawaii↔Maui
  33.2 km, Honolulu↔Kauai 110.9 km, Kauai↔Maui 229.4 km, Hawaii↔Kauai 409.2 km. Adding a chain
  reduces the graph to 3 components (3,108 / 29 / 5). But it is exactly the "editing new edges"
  the reference argues against, it asserts a smoothing relationship across 30–400 km of ocean that
  no epidemiological mechanism supports, and it still leaves the graph disconnected — so it buys
  nothing while adding an indefensible modelling assumption. *Note: centroid distance is actively
  misleading here — Honolulu County's centroid sits ~588 km from Kauai's because the county
  includes the Northwestern Hawaiian Islands. Use polygon-edge distance if this is ever revisited.*
- **Dropping Alaska and Hawaii**, which is what much of the county-level literature does (e.g.
  [CDC PCD 2024 hot/cold-spot analysis](https://www.cdc.gov/pcd/issues/2024/24_0046.htm) restricts
  to the contiguous states). Not available here: SPEC.md §3 requires a page for every county, and
  SPEC.md §2.2 exists specifically to give small rural counties an honest estimate. Silently
  dropping 32 counties would violate both.

---

## 5. Consequence for M4 (SPEC.md §2.2, CAR/BYM2 exceedance model)

1. **Pin TIGER2021, not the latest TIGER.** `tl_2021_us_county.zip`,
   `sha256 26890ff9…5e9ecc90`. TIGER2022 onward would silently swap Connecticut's 8 counties for 9
   planning regions and break the FIPS join against the pinned SCP extract. Record it in the build
   manifest with that hash.
2. **Do not use the published County Adjacency File.** It only exists in vintages that mismatch
   (2023–2025 = planning regions; 2010 = pre-2013 Alaska/SD/VA). Derive adjacency instead. The
   derivation is validated to reproduce the official file exactly (§2), so nothing is lost — and
   the 2025 file remains useful as a regression fixture for the derivation code.
3. **The FIPS crosswalk is mandatory, not cosmetic.** Dissolve `02063`+`02066` → `02261`, relabel
   `51019` → `51917`, exclude `72001`. Without it the model silently loses or misjoins three
   counties. A build assertion that the adjacency node set exactly equals the SCP county FIPS set
   (3,142, zero symmetric difference) is the right check, and it passes today.
4. **Model spec: `model="bym2"` with `scale.model=TRUE` and `adjust.for.con.comp=TRUE`.** This is
   the whole island fix. Alaska (29), the Maui/Kalawao pair (2) and the three Hawaii singletons are
   handled by the scaling and per-component sum-to-zero constraints; the singletons still get an
   unstructured random effect rather than being zeroed out. Cite Freni-Sterrantino et al. 2018 in
   the methods section.
5. **Add no artificial edges.** Not for Hawaii, not for Alaska↔CONUS. If a future reviewer asks,
   the answer is Recommendation 3 of the reference plus the 30–409 km ocean distances above.
6. **`statistical-reviewer` (SPEC.md §5) already checks "the CAR model's neighbor structure handles
   island counties."** The concrete assertions it should make: node set is exactly the 3,142 SCP
   county FIPS; 9,282 undirected edges; exactly 3 zero-degree nodes (`15001`, `15003`, `15007`); 6
   connected components with sizes 3108/29/2/1/1/1; and `adjust.for.con.comp=TRUE` is set. A build
   that produces a *connected* county graph has a bug — most likely a wrong TIGER vintage.
7. **Interpretation caveat for the three Hawaii singletons plus Kalawao/Maui.** Their posteriors
   borrow no spatial strength, so their credible intervals will be wide and driven by their own
   counts and the global mean. That is honest and consistent with SPEC.md §0's uncertainty rule,
   but per SPEC.md §3 these pages should say so rather than presenting an interval that looks
   like the mainland's. (Kalawao County's population is ~80, so it will be suppressed in the
   observed data regardless — see `docs/audit/04-suppression-overlap.md`.)

---

## Sources

- Census Bureau, County Adjacency File landing page —
  `https://www.census.gov/geographies/reference-files/time-series/geo/county-adjacency.html`
  (fetched 2026-08-24)
- `https://www2.census.gov/geo/docs/reference/county_adjacency/county_adjacency2025.txt`
  (and `…2024.txt`, `…2023.txt`), downloaded and parsed 2026-08-24
- TIGER/Line directory index `https://www2.census.gov/geo/tiger/` (vintages through TIGER2025)
- `https://www2.census.gov/geo/tiger/TIGER2021/COUNTY/tl_2021_us_county.zip`, downloaded 2026-08-24
- Pinned Zenodo V3 parquet files, `10.5281/zenodo.22085273` — queried for the Connecticut and
  Alaska/Virginia FIPS vintage
- Freni-Sterrantino A, Ventrucci M, Rue H. *A note on intrinsic Conditional Autoregressive models
  for disconnected graphs.* Spatial and Spatio-temporal Epidemiology 2018;26:25–34.
  [arXiv:1705.04854](https://arxiv.org/abs/1705.04854) — quotations taken from the arXiv PDF
- Riebler A, Sørbye SH, Simpson D, Rue H. *An intuitive Bayesian spatial model for disease mapping
  that accounts for scaling.* (BYM2 parameterization, cited as [8] in the above)
- [CDC Preventing Chronic Disease 2024;21:24_0046](https://www.cdc.gov/pcd/issues/2024/24_0046.htm)
  — example of the contiguous-states-only convention this project cannot adopt
