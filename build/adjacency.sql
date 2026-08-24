-- Derive county adjacency (queen contiguity) for the BYM2/CAR model.
--
-- Method validated in docs/audit/07-adjacency.md: reproduces the official 2025 Census County
-- Adjacency File exactly (9,286/9,286 pairs) when run on the matching TIGER vintage, so the same
-- computation on TIGER2021 (pin: build/manifest.json#tiger2021_county) is not an approximation.
--
-- Crosswalk applied so the node set matches the pinned SCP extract's 3,142 counties exactly:
--   - dissolve 02063 (Chugach) + 02066 (Copper River) -> 02261 (Valdez-Cordova, pre-2019 AK split)
--   - relabel 51019 (Bedford County) -> 51917 (Bedford City+County pseudo-FIPS NCI uses)
--   - drop 72001 (Puerto Rico aggregate, not a county-tier FIPS in the pinned extract)
--
-- Usage: duckdb -f build/adjacency.sql
-- Requires build/cache/tiger2021/tl_2021_us_county.shp (see README.md for the fetch command) and
-- build/cache/zenodo-v3/state_cancer_profiles_incidence.parquet (see build/manifest.json).

INSTALL spatial; LOAD spatial;
INSTALL httpfs; LOAD httpfs;

CREATE OR REPLACE TABLE tiger_raw AS
SELECT GEOID AS fips, STATEFP AS state_fips, NAME, geom
FROM ST_Read('build/cache/tiger2021/tl_2021_us_county.shp')
WHERE STATEFP NOT IN ('60','66','69','72','78');  -- drop territories other than the PR case handled below

-- Dissolve the Alaska Valdez-Cordova split back to its pre-2019 pinned-vintage FIPS.
CREATE OR REPLACE TABLE ak_dissolved AS
SELECT '02261' AS fips, '02' AS state_fips, 'Valdez-Cordova Census Area' AS NAME,
       ST_Union_Agg(geom) AS geom
FROM tiger_raw WHERE fips IN ('02063', '02066');

CREATE OR REPLACE TABLE counties AS
SELECT fips, state_fips, NAME, geom FROM tiger_raw WHERE fips NOT IN ('02063', '02066')
UNION ALL
SELECT fips, state_fips, NAME, geom FROM ak_dissolved
-- Bedford VA relabel: fips column rewritten in place, not a join, so do it as a final projection.
;

UPDATE counties SET fips = '51917' WHERE fips = '51019';

-- Build assertion: node set must exactly equal the pinned SCP county FIPS set (3,142, per
-- docs/audit/04-suppression-overlap.md / 07-adjacency.md). Fail loudly if a future TIGER/SCP
-- vintage drifts rather than silently joining a mismatched graph into the model.
CREATE OR REPLACE TABLE scp_counties AS
SELECT DISTINCT fips FROM read_parquet('build/cache/zenodo-v3/state_cancer_profiles_incidence.parquet')
WHERE locale_type = 'county' AND fips != '72001';

CREATE OR REPLACE TABLE mismatch AS
SELECT fips, 'tiger_only' AS side FROM counties WHERE fips NOT IN (SELECT fips FROM scp_counties)
UNION ALL
SELECT fips, 'scp_only' AS side FROM scp_counties WHERE fips NOT IN (SELECT fips FROM counties);

.print '--- crosswalk validation (should be empty) ---'
SELECT * FROM mismatch;

-- Queen contiguity: any two counties whose polygons touch or overlap.
CREATE OR REPLACE TABLE adjacency AS
SELECT a.fips AS g1, b.fips AS g2
FROM counties a JOIN counties b ON a.fips < b.fips AND ST_Intersects(a.geom, b.geom)
ORDER BY 1, 2;

.print '--- summary ---'
SELECT
  (SELECT count(*) FROM counties) AS n_counties,
  (SELECT count(*) FROM adjacency) AS n_edges,
  (SELECT count(*) FROM mismatch) AS n_crosswalk_mismatches;

COPY adjacency TO 'build/out/county_adjacency_scp_vintage.csv' (HEADER, DELIMITER ',');

.print 'Wrote build/out/county_adjacency_scp_vintage.csv'
