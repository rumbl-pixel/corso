-- Hardening: remove the anon EXECUTE grant from staff-only write RPCs. Each
-- already self-authorizes via user_has_school_role (a coach/admin/owner check),
-- so anon could never succeed anyway; in live mode these are called by an
-- authenticated coach session (incl. the kiosk, which runs behind staff auth).
--
-- Deliberately NOT touched (remain anon-executable by design):
--   * record_training_event  - student-facing (passwordless students record
--     'opened'/'reviewed' via the anon key; guarded by assignment<->student link)
--   * public_school_totals    - anon-safe public aggregate (no PII), Option A
--   * user_has_school_role / user_school_ids / is_platform_admin - RLS policy
--     primitives; the querying role must keep EXECUTE or policy evaluation fails
-- authenticated grants are left intact (coaches call these; self-authorizing).
--
-- Result: SECURITY DEFINER functions anon-executable drop 19 -> 5 (all intentional).
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'create_student_notification','create_training_assignment','issue_guardian_link',
        'record_activity_credit','record_athletics_result','record_lap_scan',
        'record_manual_adjustment','record_scan_undo','save_athletics_team_selection',
        'save_coach_note','save_cross_country_course','set_athletics_consent_status',
        'set_guardian_link_status','set_student_medical_notes')
  loop
    execute format('revoke execute on function %s from anon', r.sig);
  end loop;
end $$;
