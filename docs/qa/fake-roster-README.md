# T8 — Fake Roster Import Rehearsal

Fixture for the beta-readiness roster-import rehearsal (Linear COR-12 / T8). Fake data only — no real students.

## How to run

1. In the admin dashboard, go to **Import → CSV Roster Import**.
2. (Recommended for predictable counts) First reset to the seeded demo roster: **Help → Reset demo data**. This loads the 8 default demo students (James Smith, Sarah Johnson, etc.).
3. Upload `fake-roster.csv` and click **Import students**.
4. Read the import summary and confirm it matches "Expected result" below.
5. Check the **Students** list — spot-check a few names, and confirm the new classes (`1B`, `2B`, `5A`, `6B`) were auto-created.

## What this fixture proves (the three things T8 asks for)

**1. Import mapping + auto class creation** — 28 valid students across Years 1–6. Four of the classes (`1B`, `2B`, `5A`, `6B`) are NOT in the default class set, so a successful import proves classes are created automatically.

**2. Duplicate handling** — two deliberate duplicates near the end of the file:
- `Riley,Fitzgerald,Year 5,5B` appears twice with the same house → the second is skipped as a duplicate.
- `James,Smith,Year 5,5B,Blue` matches a seeded demo student → still skipped as a duplicate (no second James), but because the seeded James has no house, his `house` is backfilled to `Blue` and the skip reason reads **"Already exists in roster (house updated to Blue)"** (only if you loaded the demo roster in step 2). This proves the house-backfill path: existing students are never duplicated, but a differing house value in the CSV updates their house and nothing else.

**3. Invalid-row handling (the "rollback"/safety part)** — the last row `Daniel,Osei,Year 3,` is missing `classname` → counted as **invalid** and skipped. The rest of the import still succeeds; one bad row doesn't poison the batch.

## Expected result

Run against the **seeded demo roster** (step 2 done):

| Metric | Count |
|---|---|
| Added | 28 |
| Duplicates skipped | 2 (Riley within-file + James Smith vs existing) |
| Invalid skipped | 1 (Daniel Osei, missing class) |
| House updates | 1 (James Smith backfilled to Blue) |

Run against an **empty roster** instead: Added 29, Duplicates 1, Invalid 1, House updates 0 (James Smith no longer collides with anything).

## Schema reference (from the live parser)

- Required header, case-insensitive, spaces ignored: `firstname,lastname,yeargroup,classname`
- Optional 5th column: `house` (or `faction` — either header name works, case-insensitive). Free text, trimmed. New students get it as their house; rows matching an existing student update ONLY that student's house (blank house values never overwrite). Omit the column entirely and the import behaves exactly as before.
- `yeargroup` like `Year 5`; `classname` like `5B` (uppercased on import)
- Barcode/student ID is auto-generated; do not include it
- Duplicate key = firstname + lastname + yeargroup + classname
- Extra columns are ignored, so a real Compass export with more columns still imports (or use the separate Compass import card)

## Scale note

28 rows is deliberately small and fast to eyeball. Real imports should stay batched under ~500 rows per pass (standing project constraint) — if you ever rehearse a large import, split it.
