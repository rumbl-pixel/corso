# Corso - Education Compliance Readiness Notes

Last reviewed: 2026-06-22

This is an engineering readiness guide, not legal advice. Before real student data is used, each school should confirm its own Department, sector, and leadership requirements.

## Vendor Compliance Posture

Corso should present itself like a school software vendor, not like an app that can certify a school as compliant by itself.

The platform can automatically verify technical controls such as demo mode, backend readiness, school scoping, public Supabase configuration, privacy policy links, and evidence-pack export availability.

The platform cannot automatically certify school compliance. School leadership still needs to sign off parent communication, online-service or acceptable-use alignment, ST4S-style review requirements, retention rules, breach contacts, and real roster cutover.

## School Admin Signup Sheet

Corso now includes a school admin signup and use attestation sheet inside the Compliance workspace. This records the authorised school contact, school/site details, review date, and the core operating commitments before real student data is used.

The signup sheet should be completed by an authorised school representative. It asks the school to confirm authority to configure Corso, agreement to abide by Corso policy and applicable school/Department/privacy/child-safety/data-retention expectations, parent or guardian communication where required, authorised student data use only, limited staff access, and school-managed retention/incident pathways.

The saved signup sheet can be exported as evidence. It is not a legal approval by itself; it is the platform-side record that the school understands and accepts the operating posture before live use.

Recommended status wording:

- "Technical blockers remain" when automated checks fail.
- "Signup sheet required" when technical checks pass but the school admin signup and use attestation has not been saved.
- "Technically ready for school sign-off" when automated checks pass but school attestations are incomplete.
- "Ready for school approval record" when automated checks and school sign-off items are recorded.

Avoid wording such as "School is compliant" unless a school or Department review has formally made that determination outside the app.

## Authoritative Sources Reviewed

- WA Department of Education, Students Online in Public Schools Policy and Procedures:
  - https://www.education.wa.edu.au/web/policies/-/students-online-in-public-schools-policy
  - https://www.education.wa.edu.au/web/policies/-/students-online-in-public-schools-procedures
- WA Department of Education, Information Breach Policy and Procedures:
  - https://www.education.wa.edu.au/web/policies/-/information-breach-policy
  - https://www.education.wa.edu.au/web/policies/-/information-breach-procedures
- WA Department of Education, Duty of Care for Public School Students Policy:
  - https://www.education.wa.edu.au/web/policies/-/duty-of-care-for-public-school-students-policy
- OAIC, Australian Privacy Principles and APP 11:
  - https://www.oaic.gov.au/privacy/australian-privacy-principles
  - https://www.oaic.gov.au/privacy/australian-privacy-principles/australian-privacy-principles-guidelines/chapter-11-app-11-security-of-personal-information
- OAIC, Data breach preparation and response:
  - https://www.oaic.gov.au/privacy/privacy-guidance-for-organisations-and-government-agencies/preventing-preparing-for-and-responding-to-data-breaches/data-breach-preparation-and-response/part-1-data-breaches-and-the-australian-privacy-act
- Safer Technologies 4 Schools:
  - https://st4s.edu.au/
  - https://st4s.edu.au/general-information/

## Platform Alignment So Far

- Data minimisation: the platform is designed around student name, year, class, barcode/access code, run participation, awards, school/team settings, training assignments, and limited safety notes.
- Access boundaries: school-scoped data, invite-only staff/coach access, parent/guardian child-only access, and student own-profile-only access are documented and partially implemented.
- No advertising model: the product commitment is no ads, no advertising trackers, no selling student data, and no cross-school sharing.
- Backend guardrails: live data mode blocks sensitive writes unless backend readiness checks are passed.
- Audit posture: scan, import, adjustment, export, guardian, medical, training, and team-selection flows have audit or audit-ready paths.
- Medical safety notes are practical run-club references only and should mirror official school health plans.

## Gaps Before Real School/Department Approval

- Department/vendor review: obtain school leadership approval and, where required, Department review before using Corso with real student data.
- ST4S readiness: prepare a supplier-style evidence pack for security, privacy, interoperability, and online safety review.
- Parent/guardian communication: provide a clear collection notice explaining what is collected, why, who can see it, where it is stored, and how families can ask for access/correction/deletion.
- Consent and acceptable-use alignment: confirm whether the school treats Corso as an online service requiring parent permission, acceptable-use wording, or inclusion in existing school online-services communication.
- Breach response: identify the school Information Custodian/contact pathway, escalation steps, evidence collection, notification decision process, and breach register process.
- Data processing record: maintain a plain-English data inventory covering fields, purpose, storage, retention, exports, sub-processors, and deletion.
- Production secrets: keep service-role keys off the frontend; confirm Edge Functions and Row Level Security are reviewed.
- Real retention rules: decide term/year retention, export, archival, de-identification, and deletion timing with the school.
- AI boundary: keep Mini Coach rule-based and staff-reviewed until school approval covers any external AI processing or model provider.

## Go-Live Evidence Pack To Prepare

- Product summary and screenshots of admin, student, parent, kiosk, reports, sports, training, and programming flows.
- Data map: every student/guardian/staff field, storage location, purpose, and who can access it.
- Security summary: authentication model, role model, school scoping, RLS policy summary, audit logs, backup/export process, and incident response.
- Parent notice draft and staff operating procedure.
- Breach response runbook with school contact names inserted.
- ST4S readiness notes or completed ST4S supplier readiness material.
- Test evidence from laptop, iPad/phone, scanner/kiosk, parent, and student flows using demo data only.
