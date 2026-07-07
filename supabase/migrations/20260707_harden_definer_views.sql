-- Option A: individual leaderboard/progress rows become staff-only.
-- Views default to definer (owner) rights; security_invoker makes them obey
-- the caller's RLS. Staff keep access via existing school-role policies;
-- the guardian/parent edge function uses the service role and is unaffected;
-- anonymous public-leaderboard reads now return nothing (by design -- the
-- logged-out leaderboard will show school aggregates only, no student names).
alter view public.leaderboard_totals       set (security_invoker = on);
alter view public.student_progress_summary  set (security_invoker = on);
