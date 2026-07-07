# Fake Roster Import Rehearsal (T8 / COR-12)

Rehearsal file for the July 20 school beta. **Demo data only — every row is a
fictional "Test StudentNN"; no real student names.** Claude prepped the CSV;
Jeremy runs the import manually on a device.

File: `docs/beta/fake-roster-import.csv` — 41 data rows (40 unique students +
1 deliberate duplicate), Years 1–6, mixed genders, factions Red / Blue /
Green / Yellow (matches the mock-carnival seed and the "Use Red / Blue /
Green / Yellow" seed button).

Header row (exactly what the importer expects; `house` and `gender` are optional columns):

```
firstname,lastname,yeargroup,classname,house,gender
```

## Before you import

In **School Admin > Settings > Factions / Houses**, click
**"Use Red / Blue / Green / Yellow"** so the configured faction list matches
the CSV. (If the list is empty, every housed student shows as "unmatched".)

## Import steps

1. Open `admin-dashboard.html` and log in as admin.
2. Go to **School Admin > Import** tab (the tab strip under the admin hub).
3. In the **"CSV Roster Import"** card (the first card, not the Compass one),
   choose `fake-roster-import.csv` in the **CSV file** picker.
4. Click **"Import students"**.

## What you should see

The import summary grid should show:

| Added | Duplicates | Invalid | House updates | Total roster |
|-------|------------|---------|---------------|--------------|
| 40    | 1          | 0       | 0             | existing + 40 |

Plus a "Skipped rows" details list with one entry:
`Row 42: Test Student05 - Already exists in roster`.

Faction spread after import: Red 10, Yellow 10, Green 10, Blue 9, Purple 1.

## Deliberate edge cases (all should be handled, not crash)

| Row | Case | Expected behaviour |
|-----|------|--------------------|
| 38 (Test Student37) | Faction `Purple`, not in the configured list | Imported with house "Purple". Flagged for review in Settings > Factions / Houses ("Students with a faction not in this list: …") and shown as "(unmatched)" in the student edit dropdown — not dropped. |
| 39 (Test Student38) | Blank `gender` cell | Imported normally with no gender set. |
| 42 | Exact duplicate of Test Student05 (row 6) | Skipped, counted under Duplicates, listed in Skipped rows. |

Gender values deliberately use mixed formats (`M`, `B`, `Girl`, `Female`) —
the importer normalises all of `boy/b/m/male` and `girl/g/f/female`.
`yeargroup` is free text; "Year 1"–"Year 6" matches the template format.

## Clearing the data afterwards

**School Admin > Help > "Reset demo data"** (red button in the Demo-only
card). It clears all local Corso data in that browser — students, scans,
training, sports, settings overrides — and reloads the seeded sample state.
Export a demo snapshot first (button next to it) if you want to keep anything.
To remove just a few students instead, delete them from the Students tab.
