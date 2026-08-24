#!/usr/bin/env python3
"""Batch-geocode distinct oncologist practice addresses to county FIPS via the Census
Bureau's free batch geocoder. Documented limit is 10,000 records per batch
(https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html).

Input: build/cache/nppes/distinct_addresses.csv (id, addr1, city, state, zip) — no header
consumed by the API itself; the API wants a headerless id,street,city,state,zip file per batch.

Output: build/cache/nppes/geocoded.csv (id, match_status, match_type, matched_address,
county_fips, state_fips)
"""
import csv
import sys
import time
import urllib.request
import urllib.error

IN_PATH = "build/cache/nppes/distinct_addresses.csv"
OUT_PATH = "build/cache/nppes/geocoded.csv"
BATCH_URL = "https://geocoding.geo.census.gov/geocoder/geographies/addressbatch"
BATCH_SIZE = 10000


def chunks(rows, n):
    for i in range(0, len(rows), n):
        yield rows[i : i + n]


def post_batch(rows):
    boundary = "----geocodebatch"
    body = []

    def add_field(name, value):
        body.append(f"--{boundary}\r\n".encode())
        body.append(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode())
        body.append(f"{value}\r\n".encode())

    def add_file(name, filename, content):
        body.append(f"--{boundary}\r\n".encode())
        body.append(
            f'Content-Disposition: form-data; name="{name}"; filename="{filename}"\r\n'.encode()
        )
        body.append(b"Content-Type: text/csv\r\n\r\n")
        body.append(content)
        body.append(b"\r\n")

    csv_lines = "\n".join(
        f'{r["id"]},"{r["addr1"]}","{r["city"]}","{r["state"]}","{r["zip"]}"' for r in rows
    )
    add_file("addressFile", "batch.csv", csv_lines.encode())
    add_field("benchmark", "Public_AR_Current")
    add_field("vintage", "Current_Current")
    body.append(f"--{boundary}--\r\n".encode())
    payload = b"".join(body)

    req = urllib.request.Request(
        BATCH_URL,
        data=payload,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        return resp.read().decode("utf-8", errors="replace")


def parse_response(text):
    reader = csv.reader(text.splitlines())
    out = []
    for row in reader:
        if len(row) < 3:
            continue
        # No_Match / Tie rows have only 3 columns (id, input_address, status) — record them as
        # unresolved rather than silently dropping them; a dropped row and a resolved-to-nothing
        # row are different failure modes and must not be conflated.
        rec_id, _input_addr, match_status = row[0], row[1], row[2]
        match_type = row[3] if len(row) > 3 else ""
        matched_address = row[4] if len(row) > 4 else ""
        # Columns after matched_address vary; geographies output appends state/county/tract/block
        # FIPS near the end. County FIPS (5-digit) and state FIPS (2-digit) are the fields we need.
        state_fips = county_fips = ""
        if len(row) >= 10 and match_status == "Match":
            # Typical order: ..., lon/lat, tigerline id, side, STATE, COUNTY, TRACT, BLOCK
            state_fips = row[8] if len(row) > 8 else ""
            county_fips = row[9] if len(row) > 9 else ""
        out.append(
            {
                "id": rec_id,
                "match_status": match_status,
                "match_type": match_type,
                "matched_address": matched_address,
                "state_fips": state_fips,
                "county_fips": county_fips,
            }
        )
    return out


def main():
    with open(IN_PATH, newline="") as f:
        rows = list(csv.DictReader(f))

    all_results = []
    batches = list(chunks(rows, BATCH_SIZE))
    for i, batch in enumerate(batches, 1):
        print(f"batch {i}/{len(batches)}: {len(batch)} addresses", file=sys.stderr)
        for attempt in range(3):
            try:
                text = post_batch(batch)
                break
            except (urllib.error.URLError, TimeoutError) as e:
                print(f"  attempt {attempt+1} failed: {e}", file=sys.stderr)
                time.sleep(5)
        else:
            raise RuntimeError(f"batch {i} failed after 3 attempts")
        results = parse_response(text)
        print(f"  got {len(results)} results", file=sys.stderr)
        all_results.extend(results)

    with open(OUT_PATH, "w", newline="") as f:
        writer = csv.DictWriter(
            f, fieldnames=["id", "match_status", "match_type", "matched_address", "state_fips", "county_fips"]
        )
        writer.writeheader()
        writer.writerows(all_results)
    print(f"wrote {len(all_results)} rows to {OUT_PATH}", file=sys.stderr)


if __name__ == "__main__":
    main()
