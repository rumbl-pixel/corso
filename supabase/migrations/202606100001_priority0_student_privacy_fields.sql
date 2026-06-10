alter table public.students
  add column if not exists house text,
  add column if not exists team text,
  add column if not exists pseudonym text,
  add column if not exists consent_status text not null default 'pending',
  add column if not exists hide_public_name boolean not null default false,
  add column if not exists share_certificates_publicly boolean not null default false;
