-- Platform admin + school coach access model.
-- Privacy posture:
-- - Corso owner access is platform-level, not stored as a school role.
-- - Schools receive coach-only staff access scoped to their own school_id.
-- - RLS helper functions keep platform admin override explicit and auditable.

create table if not exists public.platform_admins (
  user_id uuid primary key references public.app_users(id) on delete cascade,
  role text not null default 'platform_admin' check (role = 'platform_admin'),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.platform_admins enable row level security;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.platform_admins
    where user_id = auth.uid()
      and active = true
      and role = 'platform_admin'
  )
$$;

create policy "platform admins can view platform admin grants"
on public.platform_admins for select
using (public.is_platform_admin());

create policy "platform admins can manage schools"
on public.schools for all
using (public.is_platform_admin())
with check (public.is_platform_admin());

create or replace function public.user_school_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select id
  from public.schools
  where public.is_platform_admin()
  union
  select school_id
  from public.school_users
  where user_id = auth.uid()
$$;

create or replace function public.user_has_school_role(target_school_id uuid, allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_platform_admin()
    or exists (
      select 1
      from public.school_users
      where user_id = auth.uid()
        and school_id = target_school_id
        and role = any(allowed_roles)
    )
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'school_users'
      and constraint_name = 'school_users_role_check'
  ) then
    alter table public.school_users drop constraint school_users_role_check;
  end if;
end $$;

update public.school_users
set role = 'coach'
where role in ('owner','admin');

alter table public.school_users
add constraint school_users_role_check
check (role in ('coach','parent','student'));

do $$
begin
  if exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'staff_invites'
      and constraint_name = 'staff_invites_role_check'
  ) then
    alter table public.staff_invites drop constraint staff_invites_role_check;
  end if;
end $$;

update public.staff_invites
set role = 'coach'
where role in ('owner','admin');

alter table public.staff_invites
add constraint staff_invites_role_check
check (role = 'coach');
