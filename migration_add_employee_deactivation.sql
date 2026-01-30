alter table public.employees
add column if not exists is_active boolean not null default true,
add column if not exists deactivated_at timestamptz null;
