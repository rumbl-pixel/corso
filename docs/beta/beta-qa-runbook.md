# July 20 Beta — QA Runbook (Jeremy's remaining tasks)

Written 2026-07-15. Everything Claude could build/verify in software is done; this
is the short list of things that need real hands, real hardware, or a credential
Claude isn't allowed to touch. Each item says **what Claude already verified** so you
can trust the software won't be the failure point — you're only confirming the
physical layer.

**Fastest path:** you do NOT need the coach password (T1) for most of this. Log in
with the **one-tap DEMO button** on the staff login and run T3–T8 in one sitting.
Only T2 needs the real coach account.

---

## 0. Log in (do this once)

1. Open the deployed app → **Staff login** (`admin.html`).
2. Click **"Open demo dashboard — no login"** (or type `DEMO` in either field).
3. You're in the dashboard on demo data. This session also unlocks the kiosk.

---

## T1 — Set the coach password  *(yours only — credential; ~30 sec)*

Claude verified: the `coach01@corso.local` account is healthy (exists, has a
password, last signed in 2026-06-30). The only snag is the password-reset email
goes to a `.local` address that can't receive mail — so reset-by-email is a dead end.

**Do this (no email needed):**
1. Supabase → **Authentication → Users** → **Add user → Create new user**.
2. Email `coach02@corso.local` (or delete + recreate `coach01`), set a password you
   choose, tick **Auto Confirm User**, save.

Claude can't do this step — creating accounts / setting passwords is a credential
action it's not permitted to perform. It's genuinely ~30 seconds.

## T2 — Coach login proof  *(yours — needs T1; ~1 min)*

1. Staff login with the **Site code**, the coach username, and the password from T1
   (NOT the DEMO button — this is the real-auth path).
2. Pass = you reach the dashboard and it says you're signed in as that coach.

---

## T3 — Phone camera scan  *(yours — physical; ~2 min)*

Claude verified: the camera path (`getUserMedia` + `BarcodeDetector`) is wired in
`kiosk.js`. Chrome on Android supports `BarcodeDetector`; the real test is a real
camera reading a real barcode, which only a device can do.

1. On an **Android phone in Chrome**, open the kiosk (`kiosk.html`) while logged in.
2. Tap **"Tap to start camera scan"**, allow camera, point at a printed barcode card.
3. Pass = the big banner shows "✓ Lap logged for {name}" and you hear the success beep.

## T4 — iPad camera scan  *(yours — physical; ~1 min)*

Claude verified: `kiosk.js` explicitly checks `'BarcodeDetector' in window` and shows
the fallback message when it's missing. **Safari/iPad has no BarcodeDetector**, so the
correct behaviour is the fallback message — not a working camera scan.

1. On the **iPad in Safari**, open the kiosk, tap **"Tap to start camera scan"**.
2. Pass = you see the message *"This browser does not support camera barcode scanning
   yet. Use a Bluetooth scanner or Chrome on Android."* (That is success — it proves
   the fallback works; then use the Bluetooth scanner, T5.)

## T5 — Bluetooth scanner  *(yours — physical; ~2 min)*

Claude verified: the kiosk keeps a hidden input focused and routes HID scanner input
(characters + Enter) through `handleScan` → the same lap-logging path as everything
else. Software is fine; you're confirming the physical scanner pairs and types.

1. Pair the Bluetooth barcode scanner to the device (it acts as a keyboard).
2. Open the kiosk (logged in), scan a printed card.
3. Pass = a lap logs (banner + beep) with no need to tap any field first.

## T6 — Barcode card print  *(yours — printer; ~3 min)*

Claude verified: the generator + print flow is wired (**"Generate & print barcode /
QR cards"** button under the **"Print Barcode / QR ID Cards"** section). Cards render
one code per student; software is fine — you're confirming they print legibly.

1. Dashboard → **School Admin → Import** area → **"Print Barcode / QR ID Cards"**.
2. Click **"Generate & print barcode / QR cards"**, pick a size, print on card stock.
3. Pass = a printed card's barcode scans cleanly in T3/T5.

## T7 — Award certificate print  *(yours — printer; ~2 min)*

Claude verified: the **"Print certificates"** button and print flow exist (the old
stuck-loading bug was already fixed). You're confirming the physical printout.

1. Dashboard → the **Awards / Certificates** area → **"Print certificates"**.
2. Pass = the certificate opens in a print dialog and prints correctly.

## T8 — Fake roster import  *(mostly done — Claude verified the logic end-to-end)*

Claude verified: ran the **exact import parser** over `docs/beta/fake-roster-import.csv`
in Node — result **40 added / 1 duplicate / 0 invalid**, with the unmatched faction
(`Purple`) flagged not dropped and the blank-gender row imported. The only thing left
is clicking it through the real UI (Claude will do this in-browser the moment the
preview tool is back up — it's been down this session).

**To run it yourself (~2 min):**
1. First seed factions: **Settings → Factions → "Use Red / Blue / Green / Yellow"**
   (otherwise housed students show as unmatched).
2. **School Admin → Import → "CSV Roster Import"** → choose `docs/beta/fake-roster-import.csv`
   → **Import students**.
3. Pass = summary reads **Added 40 · Duplicates 1 · Invalid 0**; `docs/beta/fake-roster-import-README.md`
   has the full expected behaviour.

---

## After the beta — real-data gate (NOT before July 20)

These are Milestone B, gated on beta feedback + approval. Don't do them for the demo beta.

- **Enable leaked-password protection** — Supabase → Auth → Policies (staff only;
  students are passwordless). Linked from the readiness tracker.
- **Disable the universal DEMO login** — this is a one-line config change
  (`demoMode: false` in `config.js`); ask Claude to make + ship it when real data is
  approved. Do NOT do this before the demo beta or you lock yourself out of DEMO.
- **School + parent sign-off** — the real go/no-go. Human decision, no fixed date.

---

## What Claude will finish the moment the browser preview tool is back

The preview tool (needed for in-app click-throughs) has been unavailable this session.
When it returns, Claude can do, without you: **T8** end-to-end in the UI; and the
**software halves** of T4 (confirm the fallback message renders), T5 (confirm typed
scanner input logs a lap), and T7 (confirm the certificate print dialog opens). That
leaves you only the irreducibly-physical confirmations (real camera, real scanner,
real paper) and the credential task (T1/T2).
