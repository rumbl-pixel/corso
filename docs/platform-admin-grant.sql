-- Corso platform admin grant template.
-- Create Jeremy's Supabase Auth user first, then replace the placeholders below.
-- This is the only access path intended for the Corso owner / platform admin.

insert into public.app_users (
  id,
  display_name
) values (
  'REPLACE-WITH-JEREMY-AUTH-USER-UUID',
  'Jeremy Mancini'
)
on conflict (id) do update set
  display_name = excluded.display_name,
  updated_at = now();

insert into public.platform_admins (
  user_id,
  role,
  active
) values (
  'REPLACE-WITH-JEREMY-AUTH-USER-UUID',
  'platform_admin',
  true
)
on conflict (user_id) do update set
  role = 'platform_admin',
  active = true,
  updated_at = now();
