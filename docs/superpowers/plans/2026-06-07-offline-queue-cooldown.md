# Offline Queue And Duplicate Cooldown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Priority 2.2 and 2.3 by improving offline queue review/retry states and adding an admin-configurable duplicate scan cooldown.

**Architecture:** Keep this local-first. Store admin scan settings in `localStorage`, use shared `RunClubScan.logLap()` for direct scans and offline queue sync, and persist per-batch scan results on `rc_offline_queue` so admins can review/retry/clear/export batches.

**Tech Stack:** Static HTML/CSS/JS, localStorage, existing Node smoke tests.

---

### Task 1: Duplicate Cooldown Setting

**Files:**
- Modify: `admin-dashboard.html`
- Modify: `admin-dashboard.js`
- Modify: `tests/portal-smoke.test.js`

- [x] Add scanner settings controls for duplicate cooldown seconds.
- [x] Persist the setting in localStorage with a safe default.
- [x] Use the setting for admin scans and offline queue sync.

### Task 2: Offline Queue Review And Retry

**Files:**
- Modify: `admin-dashboard.js`
- Modify: `styles.css`
- Modify: `tests/portal-smoke.test.js`

- [x] Render clearer batch status summaries.
- [x] Store per-scan result status after sync.
- [x] Add Sync batch, Retry failed scans, Clear synced batch, and Download batch CSV actions.
- [x] Route sync through `RunClubScan.logLap()` for duplicate protection and audit consistency.

### Task 3: Roadmap And Verification

**Files:**
- Modify: `FEATURES.md`
- Modify: this plan file

- [x] Mark 2.2 and 2.3 complete.
- [x] Run build, tests, diff check, commit, and push.
