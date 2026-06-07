# PWA Installable Scanning Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Gwynne Park Run Club installable on phones and iPads with an app manifest, local icons, and a lightweight service worker cache.

**Architecture:** Add static PWA assets at the site root and register the service worker from browser pages. Keep scan behavior unchanged; this is only the installable app shell.

**Tech Stack:** Static HTML/CSS/JS, web app manifest, service worker cache, Node smoke tests.

---

### Task 1: Add PWA Metadata And Icons

**Files:**
- Create: `manifest.webmanifest`
- Create: `assets/app-icon-192.png`
- Create: `assets/app-icon-512.png`
- Modify: main HTML pages

- [x] Add app manifest with name, short name, start URL, display mode, theme colors, and icons.
- [x] Generate PNG icons from the official Gwynne Park logo.
- [x] Link manifest and theme color from all user-facing HTML pages.

### Task 2: Add Service Worker Shell

**Files:**
- Create: `service-worker.js`
- Create: `pwa.js`
- Modify: main HTML pages

- [x] Cache core shell pages, scripts, styles, and assets.
- [x] Register the service worker only when supported and served from HTTP/HTTPS.
- [x] Keep runtime failures silent so old browsers still work.

### Task 3: Tests And Roadmap

**Files:**
- Modify: `tests/portal-smoke.test.js`
- Modify: `FEATURES.md`

- [x] Add smoke tests for manifest links, service worker registration, manifest content, and icon files.
- [x] Mark `2.1` done and update progress snapshot.
- [x] Run `npm test`, `git diff --check`, commit, and push.
