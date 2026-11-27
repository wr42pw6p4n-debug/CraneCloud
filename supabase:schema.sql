-- CraneCloud starting schema. Apply only in a NEW, separate Supabase project.
-- This is a foundation, not a production security review.
create extension if not exists pgcrypto;
create table public.companies(id uuid primary key default gen_random_uuid(),name text not null,created_at timestamptz not null default now());
create table public.company_members(company_id uuid not null references public.companies(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,role text not null default 'engineer' check(role in('owner','manager','engineer','read_only')),created_at timestamptz not null default now(),primary key(company_id,user_id));
create table public.customers(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id) on delete cascade,name text not null,contact_name text,email text,phone text,address text,created_at timestamptz not null default now());
create table public.sites(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id) on delete cascade,customer_id uuid not null references public.customers(id) on delete cascade,name text not null,address text,created_at timestamptz not null default now());
create table public.assets(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id) on delete cascade,customer_id uuid not null references public.customers(id) on delete restrict,site_id uuid references public.sites(id) on delete set null,asset_ref text not null,description text not null,serial_number text,swl text,manufacturer text,model text,next_examination_due date,created_at timestamptz not null default now(),unique(company_id,asset_ref));
create table public.jobs(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id) on delete cascade,customer_id uuid references public.customers(id) on delete set null,asset_id uuid references public.assets(id) on delete set null,job_ref text not null,job_type text not null,description text,status text not null default 'open',assigned_user_id uuid references auth.users(id) on delete set null,scheduled_at timestamptz,completed_at timestamptz,created_at timestamptz not null default now(),unique(company_id,job_ref));
create table public.reports(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id) on delete cascade,customer_id uuid references public.customers(id) on delete set null,asset_id uuid not null references public.assets(id) on delete restrict,job_id uuid references public.jobs(id) on delete set null,report_ref text not null,report_type text not null check(report_type in('service','thorough_examination','repair','breakdown')),visit_date date not null,engineer_user_id uuid references auth.users(id) on delete set null,findings text,actions_required text,report_status text not null default 'draft' check(report_status in('draft','complete','void')),created_at timestamptz not null default now(),unique(company_id,report_ref));
create or replace function public.is_company_member(target_company uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.company_members m where m.company_id=target_company and m.user_id=auth.uid()); $$;
alter table public.companies enable row level security;
alter table public.company_members enable row level security;
alter table public.customers enable row level security;
alter table public.sites enable row level security;
alter table public.assets enable row level security;
alter table public.jobs enable row level security;
alter table public.reports enable row level security;
create policy "members read own companies" on public.companies for select using(public.is_company_member(id));
create policy "members read company membership" on public.company_members for select using(public.is_company_member(company_id));
create policy "members manage customers" on public.customers for all using(public.is_company_member(company_id)) with check(public.is_company_member(company_id));
create policy "members manage sites" on public.sites for all using(public.is_company_member(company_id)) with check(public.is_company_member(company_id));
create policy "members manage assets" on public.assets for all using(public.is_company_member(company_id)) with check(public.is_company_member(company_id));
create policy "members manage jobs" on public.jobs for all using(public.is_company_member(company_id)) with check(public.is_company_member(company_id));
create policy "members manage reports" on public.reports for all using(public.is_company_member(company_id)) with check(public.is_company_member(company_id));
-- Before production, implement secure company onboarding and invitations, role-specific write policies,
-- immutable audit history, storage policies, backup/retention controls and an independent security review.
