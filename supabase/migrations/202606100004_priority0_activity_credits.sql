create table if not exists public.activity_credits (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  barcode text,
  activity_type text not null default 'Activity',
  minutes integer not null check (minutes > 0),
  km_credit numeric(10,2) not null default 0,
  activity_date date not null default current_date,
  staff_label text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references public.app_users(id) on delete set null
);

alter table public.activity_credits enable row level security;

create policy "staff can view activity credits"
on public.activity_credits for select
using (public.user_has_school_role(school_id, array['owner','admin','coach']));

create policy "staff can create activity credits"
on public.activity_credits for insert
with check (public.user_has_school_role(school_id, array['owner','admin','coach']));

create or replace function public.record_activity_credit(
  p_school_id uuid,
  p_student_id uuid,
  p_barcode text,
  p_activity_type text,
  p_minutes integer,
  p_km_credit numeric,
  p_activity_date date,
  p_staff text,
  p_metadata jsonb default '{}'::jsonb
)
returns table (
  activity_credit_id uuid,
  km_credit numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_student_id uuid;
  inserted_id uuid;
  inserted_km numeric;
begin
  if not public.user_has_school_role(p_school_id, array['owner','admin','coach']) then
    raise exception 'not allowed';
  end if;

  if coalesce(p_minutes, 0) <= 0 then
    raise exception 'minutes must be greater than zero';
  end if;

  select id into resolved_student_id
  from public.students
  where school_id = p_school_id
    and active = true
    and (
      id = p_student_id
      or (coalesce(p_barcode, '') <> '' and barcode = p_barcode)
    )
  limit 1;

  if resolved_student_id is null then
    raise exception 'student not found';
  end if;

  insert into public.activity_credits (
    school_id,
    student_id,
    barcode,
    activity_type,
    minutes,
    km_credit,
    activity_date,
    staff_label,
    metadata,
    created_by
  ) values (
    p_school_id,
    resolved_student_id,
    p_barcode,
    coalesce(nullif(p_activity_type, ''), 'Activity'),
    p_minutes,
    coalesce(p_km_credit, 0),
    coalesce(p_activity_date, current_date),
    p_staff,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object('source', 'activity-credit'),
    auth.uid()
  )
  returning id, km_credit into inserted_id, inserted_km;

  insert into public.scan_audit_logs (
    school_id,
    student_id,
    barcode,
    source,
    success,
    duplicate,
    undo,
    message,
    metadata
  ) values (
    p_school_id,
    resolved_student_id,
    p_barcode,
    'activity-credit',
    true,
    false,
    false,
    'Activity credit recorded',
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'activity_credit_id', inserted_id,
      'activity_type', p_activity_type,
      'minutes', p_minutes,
      'km_credit', inserted_km,
      'staff', p_staff
    )
  );

  return query select inserted_id, inserted_km;
end;
$$;

create or replace view public.leaderboard_totals as
with lap_totals as (
  select
    school_id,
    student_id,
    count(id) filter (where undone_at is null) as lap_count,
    coalesce(sum(lap_distance_km) filter (where undone_at is null), 0)::numeric(10,2) as lap_km,
    max(scanned_at) as last_scanned_at
  from public.lap_entries
  group by school_id, student_id
),
adjustment_totals as (
  select
    school_id,
    student_id,
    coalesce(sum(delta_laps), 0) as adjusted_laps,
    coalesce(sum(delta_laps * lap_distance_km), 0)::numeric(10,2) as adjusted_km,
    max(created_at) as last_adjusted_at
  from public.manual_adjustments
  group by school_id, student_id
),
activity_totals as (
  select
    school_id,
    student_id,
    coalesce(sum(km_credit), 0)::numeric(10,2) as activity_km,
    max(created_at) as last_activity_at
  from public.activity_credits
  group by school_id, student_id
)
select
  s.school_id,
  s.id as student_id,
  s.barcode,
  coalesce(s.preferred_name, concat_ws(' ', s.first_name, s.last_name)) as student_name,
  s.year_group,
  s.class_name,
  greatest(0, coalesce(l.lap_count, 0) + coalesce(a.adjusted_laps, 0)) as total_laps,
  greatest(0, coalesce(l.lap_km, 0) + coalesce(a.adjusted_km, 0) + coalesce(ac.activity_km, 0))::numeric(10,2) as total_km,
  greatest(l.last_scanned_at, a.last_adjusted_at, ac.last_activity_at) as last_scanned_at
from public.students s
left join lap_totals l on l.student_id = s.id and l.school_id = s.school_id
left join adjustment_totals a on a.student_id = s.id and a.school_id = s.school_id
left join activity_totals ac on ac.student_id = s.id and ac.school_id = s.school_id
where s.active = true;
