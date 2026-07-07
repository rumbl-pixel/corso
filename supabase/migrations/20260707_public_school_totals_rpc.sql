-- Anon-safe aggregate for the public leaderboard (Option A): returns ONLY
-- school-level totals, never individual student rows. SECURITY DEFINER so it
-- can aggregate over leaderboard_totals (now security_invoker) without exposing
-- rows to the anon caller. No PII in the result.
create or replace function public.public_school_totals(p_school_id uuid)
returns table(enrolled bigint, active bigint, total_laps bigint, total_km numeric)
language sql
security definer
set search_path = public
as $$
  select
    count(*)::bigint                                   as enrolled,
    count(*) filter (where total_laps > 0)::bigint     as active,
    coalesce(sum(total_laps), 0)::bigint               as total_laps,
    coalesce(sum(total_km), 0)::numeric(12,2)          as total_km
  from public.leaderboard_totals
  where school_id = p_school_id;
$$;

revoke all on function public.public_school_totals(uuid) from public;
grant execute on function public.public_school_totals(uuid) to anon, authenticated;
