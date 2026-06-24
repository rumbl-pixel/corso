# Supabase Staging Checklist

Use fake staging data only until Priority 0 is complete.

## 0. Check Local Readiness

Before applying migrations or running live-style checks, run:

```bash
npm run check:staging-readiness
```

This checks the local Supabase CLI, Docker Desktop, required staging files, and the public environment values needed for the hosted staging check. It does not print secret values.

## 1. Create Staging Project

Install the Supabase CLI before running the local commands below. Create a Supabase project for staging, then apply the migrations:

```bash
npm install
npm run supabase:start
```

For hosted staging, create a Supabase project for staging, then apply the migrations:

```bash
supabase link --project-ref your-staging-project-ref
supabase db push
```

For local Supabase testing:

```bash
supabase start
supabase db reset
npm run supabase:lint
```

## 2. Seed Fake Data

Apply the staging seed after migrations through the Supabase SQL editor, or with `psql` connected to the staging database:

```bash
psql "$SUPABASE_DB_URL" -f supabase/seed.staging.sql
```

The staging school id is:

```text
10000000-0000-4000-8000-000000000001
```

## 3. Create Staging Coach Login

Create your test staff user in Supabase Auth first. The login screen uses a 4-digit Site code plus an assigned username, so set `siteCode` or `schoolSites` in `config.js` to point the code to the staging school id. Create the Supabase Auth user with the internal email pattern from `config.js`: `username@authUsernameDomain` (for example `coach01@corso.local`). For staging, use role `coach` rather than owner/admin so we prove ordinary coach-level access works.

After creating the Auth user, copy that user's UUID and run the template in `docs/staging-coach-staff.sql` after replacing:

- `REPLACE-WITH-AUTH-USER-UUID`
- `REPLACE-WITH-COACH-EMAIL` using the internal username email

This creates:

- an `app_users` row
- a `school_users` row for the staging school with role `coach`
- a `staff_invites` audit row marked `accepted`

## 4. Deploy Edge Functions

## 4. Optional Platform Admin Grant

For owner-only testing, create the Corso owner Auth user, then run `docs/platform-admin-grant.sql` after replacing:

- `REPLACE-WITH-OWNER-AUTH-USER-UUID`
- `REPLACE-WITH-OWNER-EMAIL`

Do not use this for schools. School users should stay coach-only and school-scoped.

## 5. Deploy Edge Functions

Deploy the browser-facing function routes:

```bash
supabase functions deploy student_auth
supabase functions deploy csv_import
supabase functions deploy guardian_access
```

Set required server-side secrets for Edge Functions in Supabase:

```bash
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

Service-role keys belong only in Supabase Edge Function secrets, never in `config.js` or static files.

## 6. Run Live-Style Check

From this repo, run:

```bash
SUPABASE_URL=https://your-project.supabase.co \
SUPABASE_ANON_KEY=your-public-anon-key \
RUN_CLUB_SCHOOL_ID=10000000-0000-4000-8000-000000000001 \
RUN_CLUB_STUDENT_CHECK_CODE=STAGING1 \
npm run check:supabase-live-style
```

Expected result:

```json
{
  "ok": true
}
```

## 7. RLS Sanity Checks

Before connecting real screens to staging:

- platform admin login should show platform access and be reserved for the Corso owner
- coach login should show only the configured staging school
- anon REST reads should fail or return no private school data unless allowed by policy
- staff-authenticated reads should return only the staging school
- `student_auth` should return only the barcode-matched staging student
- `csv_import` should validate rows in `dry_run` before upserting
- `guardian_access` should return only the guardian-link matched child profile and write an access audit row

Do not enter real student data until Priority 0 is complete.
