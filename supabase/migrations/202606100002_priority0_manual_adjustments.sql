create table if not exists public.manual_adjustments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  barcode text,
  delta_laps integer not null check (delta_laps <> 0),
  reason text not null,
  staff_label text,
  lap_distance_km numeric(8,3) not null default 0.25,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references public.app_users(id) on delete set null
);

alter table public.manual_adjustments enable row level security;

create policy "staff can view manual adjustments"
on public.manual_adjustments for select
using (public.user_has_school_role(school_id, array['owner','admin','coach']));

create policy "staff can create manual adjustments"
on public.manual_adjustments for insert
with check (public.user_has_school_role(school_id, array['owner','admin','coach']));

create or replace function public.record_manual_adjustment(
  p_school_id uuid,
  p_student_id uuid,
  p_barcode text,
  p_delta_laps integer,
  p_reason text,
  p_staff text,
  p_lap_distance_km numeric,
  p_metadata jsonb default '{}'::jsonb
)
returns table (
  adjustment_id uuid,
  entries_created integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  resolved_student_id uuid;
  inserted_id uuid;
begin
  if not public.user_has_school_role(p_school_id, array['owner','admin','coach']) then
    raise exception 'not allowed';
  end if;

  if coalesce(p_delta_laps, 0) = 0 then
    raise exception 'delta_laps must not be zero';
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

  insert into public.manual_adjustments (
    school_id,
    student_id,
    barcode,
    delta_laps,
    reason,
    staff_label,
    lap_distance_km,
    metadata,
    created_by
  ) values (
    p_school_id,
    resolved_student_id,
    p_barcode,
    p_delta_laps,
    p_reason,
    p_staff,
    coalesce(p_lap_distance_km, 0.25),
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object('source', 'manual-adjustment'),
    auth.uid()
  )
  returning id into inserted_id;

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
    'manual-adjustment',
    true,
    false,
    p_delta_laps < 0,
    'Manual adjustment recorded',
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'adjustment_id', inserted_id,
      'delta_laps', p_delta_laps,
      'reason', p_reason,
      'staff', p_staff
    )
  );

  return query select inserted_id, abs(p_delta_laps);
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
)
select
  s.school_id,
  s.id as student_id,
  s.barcode,
  coalesce(s.preferred_name, concat_ws(' ', s.first_name, s.last_name)) as student_name,
  s.year_group,
  s.class_name,
  greatest(0, coalesce(l.lap_count, 0) + coalesce(a.adjusted_laps, 0)) as total_laps,
  greatest(0, coalesce(l.lap_km, 0) + coalesce(a.adjusted_km, 0))::numeric(10,2) as total_km,
  greatest(l.last_scanned_at, a.last_adjusted_at) as last_scanned_at
from public.students s
left join lap_totals l on l.student_id = s.id and l.school_id = s.school_id
left join adjustment_totals a on a.student_id = s.id and a.school_id = s.school_id
where s.active = true;
