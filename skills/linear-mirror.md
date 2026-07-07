---
name: linear-mirror
description: Mirror a completed Corso build leg into Linear as issues so ticket status matches reality.
---

# Linear Mirror

**When to use:** after a multi-task build leg lands (and usually after it's pushed), so Linear reflects what shipped. Linear is the source of truth for ticket status; the Obsidian vault is the readable mirror.

## Context a new model needs

- Linear team: **Corso** (prefix `COR-`). Projects seen so far: "July 20 School Beta Launch" (roadmap tickets T1–T19 ↔ COR-5..COR-22 area) and "Carnival Day" (carnival legs).
- Access is via the Linear MCP connector (`mcp__...__save_issue`, `list_issues`, etc.). It requires OAuth; in a non-interactive session it may be unauthenticated — in that case, record the mapping in the vault instead and tell the user to re-auth via claude.ai connector settings.
- One Linear issue per build task, not per commit.

## Steps, in order

1. Gather the shipped tasks: the build plan/spec (docs/superpowers/plans + specs) and `git log` for the leg's commit range.
2. Pick the right project (roadmap ticket → July 20 project; carnival work → Carnival Day project; new leg → create/ask).
3. For each task, create or update an issue: title = the task name, description = what shipped + commit hash + any QA-caught bugs, status = **Done** for landed work.
4. Keep IDs sequential and note the resulting range (e.g. "COR-39..COR-45").
5. Record the mapping in the vault Project Log entry for the session (see session-logging skill), e.g. "mirrored to Linear as COR-39..COR-45 (all Done)".

## Real example of a good final output (Project Log, 2026-07-06)

> Built as 7 tasks, each verified + committed to `main` (commits `482a53e`..`31d2315`). **Pushed + deployed** to both demo URLs on 2026-07-06, and mirrored to the [Carnival Day](https://linear.app/corso-run/project/carnival-day-2dd23695965b) Linear project as **COR-39..COR-45** (all Done).

Each of the 7 issues carried the task's one-line scope (e.g. "field-size points (1st of N = N, independent default or per-carnival tiered)") and its commit hash, and was closed as Done because the work had already shipped.

## Mistakes to avoid (observed and corrected in this repo)

- **Leaving mirrored issues open.** These are retrospective records of shipped work — set them Done immediately, or Linear reads as a pile of pending work that doesn't exist.
- **Wrong project bucket.** Carnival work went to its own "Carnival Day" project, not the July 20 launch board; check before creating.
- **Mirroring before the work is final.** Mirror after commit (ideally after push); a mirrored-then-reverted task pollutes the board.
- **Blocking on auth.** If the connector is unauthenticated, don't stall — write the mapping into the vault Project Log and flag the re-auth to the user.
- **Deferred items need a note, not silence.** When a ticket is assessed and parked (e.g. security items moved to a later milestone), write the reasoning onto the ticket itself so the deferral survives context loss.
