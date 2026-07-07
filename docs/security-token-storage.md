# Token storage decision (COR-16)

Status: accepted, 2026-07-07. Gating item for the real-student-data milestone.

## What is stored

`runClubAdminSession` (localStorage) holds the coach session: identity fields,
school/site scoping, and in live mode the Supabase **access token** and its
`expires_at`. Demo mode stores the literal string `demo-token`. Student and
parent "sessions" store only the student barcode / nothing — no auth tokens.

## Why localStorage (and not the alternatives)

- **httpOnly cookies:** not possible. Corso is a static app on GitHub
  Pages/Cloudflare Pages — there is no server to set or read cookies.
- **sessionStorage:** per-tab. The dashboard, kiosk, scanner, and student
  profile pages all read `runClubAdminSession` and are routinely opened in
  separate tabs on club day; sessionStorage would sign the coach out of every
  tab but the first. Rejected on UX grounds.
- **In-memory only:** lost on every navigation between the multi-page portals.

localStorage is the best available architecture for this host. The residual
risk is that any XSS on the origin can read the token.

## Mitigations in place

- **No refresh token persisted.** `admin.js` deliberately drops
  `refresh_token` from the session (it was never used by any code). A stolen
  access token expires on Supabase's schedule (~1 hour); it cannot be renewed.
- **Excluded from exports.** `exportDemoSnapshot` in `admin-dashboard.js`
  skips `runClubAdminSession`, so tokens never land in exported JSON files.
- **Never logged.** No `console.*` call in served pages touches the session.
- **School-boundary wipe.** Signing into a different school wipes cached
  `rc_*` data before the new session is written (`establishSession`).
- **Server-side authority.** All live data access is enforced by Supabase RLS
  scoped to the token's user and school — the token grants no more than the
  signed-in coach already has.

## Related (COR-18)

Guardian access codes are masked in the admin list view (reveal per row on
demand), the parent portal access log stores only the last 4 characters of an
attempted code, and the guardian code itself is never persisted on the parent
device after verification.
