create or replace function public.record_training_event(
  p_school_id uuid,
  p_assignment_id uuid,
  p_student_id uuid,
  p_event_type text,
  p_title text,
  p_metadata jsonb default '{}'::jsonb
)
returns table (
  event_id uuid,
  event_type text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_id uuid;
begin
  if p_event_type not in ('opened','reviewed') then
    raise exception 'invalid training event type';
  end if;

  if not exists (
    select 1
    from public.training_assignments ta
    join public.training_assignment_students tas on tas.assignment_id = ta.id
    where ta.school_id = p_school_id
      and ta.id = p_assignment_id
      and tas.student_id = p_student_id
  ) then
    raise exception 'training assignment not found for student';
  end if;

  if p_event_type = 'opened' then
    insert into public.training_link_events (
      school_id,
      assignment_id,
      student_id,
      metadata
    ) values (
      p_school_id,
      p_assignment_id,
      p_student_id,
      coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object('source', 'training-event', 'event_type', p_event_type)
    )
    returning id into inserted_id;
  else
    inserted_id := gen_random_uuid();
  end if;

  insert into public.scan_audit_logs (
    school_id,
    student_id,
    source,
    success,
    duplicate,
    undo,
    message,
    metadata
  ) values (
    p_school_id,
    p_student_id,
    'training-event',
    true,
    false,
    false,
    case when p_event_type = 'opened' then 'Training link opened' else 'Training marked reviewed' end,
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'assignment_id', p_assignment_id,
      'event_id', inserted_id,
      'event_type', p_event_type,
      'title', p_title
    )
  );

  return query select inserted_id, p_event_type;
end;
$$;
