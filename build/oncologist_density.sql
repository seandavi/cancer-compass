-- County-level oncologist density (SPEC.md §2.3), per docs/audit/05-nppes.md's validated
-- methodology. Two-stage county assignment: Census batch-geocoder street match, ZIP-fallback
-- (largest land-share county) for the remainder, unplaced otherwise. Applies the same FIPS
-- crosswalk as build/adjacency.sql so oncologist counts join cleanly onto the 3,142-county
-- modeling universe.
--
-- Prerequisites (see build/README.md): build/cache/nppes/oncologists.parquet (taxonomy-filtered
-- NPPES extract), build/cache/nppes/distinct_addresses.csv + geocoded.csv (from
-- build/geocode_addresses.py), build/cache/zcta_county_rel.txt (ZCTA-to-county relationship file).
--
-- Usage: duckdb -f build/oncologist_density.sql

CREATE OR REPLACE TABLE onc AS SELECT * FROM read_parquet('build/cache/nppes/oncologists.parquet');

CREATE OR REPLACE TABLE addr_ids AS
SELECT row_number() OVER () AS id, addr1, city, state, zip
FROM (SELECT DISTINCT addr1, city, state, zip FROM onc);

CREATE OR REPLACE TABLE geocoded AS
SELECT id::BIGINT AS id, match_status, state_fips, county_fips
FROM read_csv('build/cache/nppes/geocoded.csv', header=true, all_varchar=true);

-- ZIP fallback: largest-land-share county per 5-digit ZIP (ZCTA proxy — NPPES ZIPs are not
-- always exact ZCTAs but this is the documented, freely-scriptable substitute per
-- docs/audit/05-nppes.md §3, used only for providers the geocoder didn't resolve).
CREATE OR REPLACE TABLE zip_county_best AS
SELECT GEOID_ZCTA5_20 AS zip, GEOID_COUNTY_20 AS county_fips
FROM (
  SELECT *, row_number() OVER (PARTITION BY GEOID_ZCTA5_20 ORDER BY AREALAND_PART DESC) AS rn
  FROM read_csv('build/cache/zcta_county_rel.txt', header=true, delim='|', all_varchar=true)
) WHERE rn = 1;

CREATE OR REPLACE TABLE provider_county AS
SELECT
  o.npi,
  a.id AS addr_id,
  g.match_status,
  CASE
    WHEN g.match_status = 'Match' THEN g.state_fips || g.county_fips
    ELSE zc.county_fips
  END AS raw_fips,
  CASE
    WHEN g.match_status = 'Match' THEN 'geocode'
    WHEN zc.county_fips IS NOT NULL THEN 'zip_fallback'
    ELSE 'unplaced'
  END AS assignment_method
FROM onc o
JOIN addr_ids a ON o.addr1 = a.addr1 AND o.city = a.city AND o.state = a.state AND o.zip = a.zip
LEFT JOIN geocoded g ON a.id = g.id
LEFT JOIN zip_county_best zc ON substr(o.zip, 1, 5) = zc.zip;

-- Same crosswalk as build/adjacency.sql, so county keys match the 3,142-county modeling universe.
CREATE OR REPLACE TABLE provider_county_xwalk AS
SELECT
  npi, addr_id, assignment_method,
  CASE
    WHEN raw_fips IN ('02063', '02066') THEN '02261'
    WHEN raw_fips = '51019' THEN '51917'
    ELSE raw_fips
  END AS fips
FROM provider_county;

.print '--- assignment method breakdown ---'
SELECT assignment_method, count(*), round(100.0*count(*)/sum(count(*)) OVER (), 1) AS pct
FROM provider_county_xwalk GROUP BY 1 ORDER BY 2 DESC;

.print '--- providers outside the 3,142-county universe (e.g. Puerto Rico, per docs/audit/05-nppes.md) ---'
SELECT count(*) FROM provider_county_xwalk pcx
WHERE pcx.fips NOT IN (SELECT DISTINCT fips FROM read_parquet('build/cache/zenodo-v3/state_cancer_profiles_incidence.parquet') WHERE locale_type='county' AND fips != '72001')
  AND pcx.fips IS NOT NULL;

CREATE OR REPLACE TABLE county_oncologist_density AS
SELECT fips, count(*) AS n_oncologists,
       sum(CASE WHEN assignment_method = 'geocode' THEN 1 ELSE 0 END) AS n_geocode,
       sum(CASE WHEN assignment_method = 'zip_fallback' THEN 1 ELSE 0 END) AS n_zip_fallback
FROM provider_county_xwalk
WHERE fips IS NOT NULL
GROUP BY fips;

.print '--- county coverage ---'
WITH universe AS (
  SELECT DISTINCT fips FROM read_parquet('build/cache/zenodo-v3/state_cancer_profiles_incidence.parquet')
  WHERE locale_type = 'county' AND fips != '72001'
)
SELECT
  count(*) AS total_counties,
  sum(CASE WHEN cod.n_oncologists IS NULL THEN 1 ELSE 0 END) AS zero_oncologist_counties,
  round(100.0 * sum(CASE WHEN cod.n_oncologists IS NULL THEN 1 ELSE 0 END) / count(*), 1) AS pct_zero
FROM universe u LEFT JOIN county_oncologist_density cod ON u.fips = cod.fips;

COPY county_oncologist_density TO 'build/out/county_oncologist_density.csv' (HEADER, DELIMITER ',');
.print 'Wrote build/out/county_oncologist_density.csv'
