# Cloudflare Pages Deployment Runbook

Use this for the July 20 beta target. Deploy demo data only until Supabase Auth, RLS, school approval, and privacy sign-off are complete.

## Recommended Project

- Cloudflare Pages project name: `corso-platform`
- Temporary beta URL: `https://corso-platform.pages.dev`
- Production custom domain later: decide after domain purchase/ownership.
- Build output folder: `dist-pages`

## Option A - GitHub Connected Deploy

This is the recommended path once Jeremy is logged in to Cloudflare.

1. Open Cloudflare Dashboard.
2. Go to Workers & Pages.
3. Select Create application.
4. Select Pages.
5. Connect the GitHub repo:
   - `rumbl-pixel/runclub-platform`
6. Build settings:
   - Framework preset: None
   - Build command: `npm run cloudflare:check`
   - Build output directory: `dist-pages`
   - Root directory: `/`
7. Environment variables:
   - Leave Supabase production values blank for demo beta.
   - Do not add service-role keys.
8. Deploy.
9. Open the generated `pages.dev` URL.
10. Confirm:
    - Beta banner is visible.
    - About and Privacy pages open.
    - Admin demo opens.
    - Kiosk opens.
    - No real student data is present.

## Option B - Wrangler Direct Upload

Use this from the local repo if you want to deploy from the terminal.

```powershell
cd C:\Users\jerem\Documents\Codex\runclub-platform
npm test
npm run build:cloudflare
npx wrangler login
npx wrangler pages project create corso-platform --production-branch main
npx wrangler pages deploy dist-pages --project-name corso-platform --branch main
```

If the project already exists, skip the `project create` command.

If login says port `8976` is already in use, run:

```powershell
npx wrangler login --callback-port 8977
```

## Current Local Prep Status

Completed on 2026-06-25:

- `wrangler.toml` added.
- `_headers` added.
- `npm run cloudflare:check` passes.
- `npm run build:cloudflare` creates `dist-pages`.
- Generated `dist-pages` bundle was served locally and public pages loaded without missing images, console errors, or horizontal overflow.

Still required:

- Jeremy must log in to Cloudflare.
- Create/connect the Cloudflare Pages project.
- Deploy the `dist-pages` bundle.
- Check the real `pages.dev` URL on phone/iPad/laptop.

## Safety Checks Before Sharing The Beta Link

Run:

```powershell
npm test
node --check admin-dashboard.js
node --check theme.js
npm run build:cloudflare
git diff --check
```

Then manually check:

- Home page beta banner.
- About page.
- Privacy Policy.
- Admin Help beta toolkit.
- Student profile with demo student only.
- Kiosk page.
- Phone-width layout.

## Must Not Happen Yet

- Do not import real student rosters.
- Do not enter real medical notes.
- Do not turn off `demoMode` until Supabase production readiness is proven.
- Do not add Supabase service-role keys to browser files or Cloudflare Pages public variables.
- Do not claim school compliance is automatic.

## After Hosted Beta Is Live

1. Send the demo link to 1-3 trusted testers.
2. Ask them to follow `docs/beta-tester-checklist.md`.
3. Record feedback before adding new features.
4. Complete real device testing:
   - phone camera scan
   - iPad camera scan
   - Bluetooth scanner
   - barcode card printing
5. Move to Supabase Auth/RLS hardening only after the hosted beta behaves properly.
