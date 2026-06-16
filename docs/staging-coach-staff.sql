-- Staging staff role template.
-- Create the staff user in Supabase Auth first, then replace the placeholders below.
-- Use role 'coach' for the first staging login unless a wider admin/owner test is required.

insert into public.app_users (
  id,
  display_name
) values (
  'REPLACE-WITH-AUTH-USER-UUID',
  'Staging Coach'
)
on conflict (id) do update set
  display_name = excluded.display_name,
  updated_at = now();

insert into public.school_users (
  school_id,
  user_id,
  role
) values (
  '10000000-0000-4000-8000-000000000001',
  'REPLACE-WITH-AUTH-USER-UUID',
  'coach'
)
on conflict (school_id, user_id, role) do nothing;

insert into public.staff_invites (
  school_id,
  email,
  role,
  status,
  metadata
) values (
  '10000000-0000-4000-8000-000000000001',
  'REPLACE-WITH-COACH-EMAIL',
  'coach',
  'accepted',
  jsonb_build_object('source', 'staging-coach-template')
)
on conflict (school_id, email, role) do update set
  status = excluded.status,
  metadata = excluded.metadata,
  updated_at = now();
