create or replace function public.create_training_assignment(
  p_school_id uuid,
  p_title text,
  p_url text,
  p_notes text,
  p_due_date date,
  p_assigned_student_ids uuid[],
  p_created_by_label text,
  p_metadata jsonb default '{}'::jsonb
)
returns table (
  assignment_id uuid,
  assigned_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_id uuid;
  assigned_count integer;
begin
  if not public.user_has_school_role(p_school_id, array['owner','admin','coach']) then
    raise exception 'not allowed';
  end if;

  if coalesce(trim(p_title), '') = '' then
    raise exception 'title is required';
  end if;

  if coalesce(trim(p_url), '') = '' then
    raise exception 'url is required';
  end if;

  if coalesce(array_length(p_assigned_student_ids, 1), 0) = 0 then
    raise exception 'at least one student is required';
  end if;

  insert into public.training_assignments (
    school_id,
    title,
    url,
    notes,
    due_date,
    created_by
  ) values (
    p_school_id,
    p_title,
    p_url,
    p_notes,
    p_due_date,
    auth.uid()
  )
  returning id into inserted_id;

  insert into public.training_assignment_students (assignment_id, student_id)
  select inserted_id, s.id
  from public.students s
  where s.school_id = p_school_id
    and s.active = true
    and s.id = any(p_assigned_student_ids)
  on conflict do nothing;

  select count(*) into assigned_count
  from public.training_assignment_students
  where assignment_id = inserted_id;

  insert into public.scan_audit_logs (
    school_id,
    source,
    success,
    duplicate,
    undo,
    message,
    metadata
  ) values (
    p_school_id,
    'training-assignment',
    true,
    false,
    false,
    'Training assignment created',
    coalesce(p_metadata, '{}'::jsonb) || jsonb_build_object(
      'assignment_id', inserted_id,
      'title', p_title,
      'assigned_count', assigned_count,
      'created_by_label', p_created_by_label
    )
  );

  return query select inserted_id, assigned_count;
end;
$$;
