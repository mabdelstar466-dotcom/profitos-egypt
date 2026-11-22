-- GlowSignal hosted SaaS schema (Supabase Postgres)
-- Safe to re-run: policies and functions are recreated idempotently.
-- Apply only after creating a Supabase project. Never expose the service_role key.
-- Store pseudonymous lead/order references only; do not store customer names or phone numbers.

create extension if not exists pgcrypto;

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 100),
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','analyst','viewer')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.campaign_daily (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  report_date date,
  campaign_name text not null,
  spend numeric(14,2) not null default 0 check (spend >= 0),
  impressions bigint not null default 0 check (impressions >= 0),
  clicks bigint not null default 0 check (clicks >= 0),
  messages bigint not null default 0 check (messages >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.lead_records (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  lead_ref text not null,
  created_at timestamptz,
  campaign_name text not null,
  lead_status text not null default 'new',
  objection text,
  agent_label text,
  first_response_minutes numeric(10,2) check (first_response_minutes is null or first_response_minutes >= 0),
  inserted_at timestamptz not null default now(),
  unique (workspace_id, lead_ref)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  order_ref text not null,
  lead_ref text,
  campaign_name text not null,
  order_status text not null,
  order_value numeric(14,2) not null default 0 check (order_value >= 0),
  product_cost numeric(14,2) not null default 0 check (product_cost >= 0),
  shipping_cost numeric(14,2) not null default 0 check (shipping_cost >= 0),
  return_cost numeric(14,2) not null default 0 check (return_cost >= 0),
  payment_fees numeric(14,2) not null default 0 check (payment_fees >= 0),
  inserted_at timestamptz not null default now(),
  unique (workspace_id, order_ref)
);

create index if not exists idx_campaign_daily_workspace_date on public.campaign_daily(workspace_id, report_date);
create index if not exists idx_campaign_daily_workspace_name on public.campaign_daily(workspace_id, campaign_name);
create index if not exists idx_leads_workspace_created on public.lead_records(workspace_id, created_at);
create index if not exists idx_leads_workspace_campaign on public.lead_records(workspace_id, campaign_name);
create index if not exists idx_orders_workspace_status on public.orders(workspace_id, order_status);
create index if not exists idx_orders_workspace_campaign on public.orders(workspace_id, campaign_name);

alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.campaign_daily enable row level security;
alter table public.lead_records enable row level security;
alter table public.orders enable row level security;

create or replace function public.is_workspace_member(target_workspace uuid)
returns boolean language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.workspace_members
    where workspace_id = target_workspace and user_id = auth.uid()
  );
$$;

create or replace function public.create_workspace(workspace_name text)
returns uuid language plpgsql security definer set search_path = public
as $$
declare new_workspace_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if char_length(trim(workspace_name)) < 2 or char_length(trim(workspace_name)) > 100 then
    raise exception 'Workspace name must be 2-100 characters';
  end if;
  insert into public.workspaces(name, owner_id)
  values (trim(workspace_name), auth.uid())
  returning id into new_workspace_id;
  insert into public.workspace_members(workspace_id, user_id, role)
  values (new_workspace_id, auth.uid(), 'owner');
  return new_workspace_id;
end;
$$;

revoke all on function public.is_workspace_member(uuid) from public;
revoke all on function public.create_workspace(text) from public;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.create_workspace(text) to authenticated;

drop policy if exists "members can read workspaces" on public.workspaces;
create policy "members can read workspaces" on public.workspaces
for select to authenticated using (public.is_workspace_member(id));
drop policy if exists "owners can update workspaces" on public.workspaces;
create policy "owners can update workspaces" on public.workspaces
for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "owners can delete workspaces" on public.workspaces;
create policy "owners can delete workspaces" on public.workspaces
for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "members can read own memberships" on public.workspace_members;
create policy "members can read own memberships" on public.workspace_members
for select to authenticated using (user_id = auth.uid());

drop policy if exists "members can read campaigns" on public.campaign_daily;
create policy "members can read campaigns" on public.campaign_daily
for select to authenticated using (public.is_workspace_member(workspace_id));
drop policy if exists "members can add campaigns" on public.campaign_daily;
create policy "members can add campaigns" on public.campaign_daily
for insert to authenticated with check (public.is_workspace_member(workspace_id));
drop policy if exists "members can update campaigns" on public.campaign_daily;
create policy "members can update campaigns" on public.campaign_daily
for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
drop policy if exists "members can delete campaigns" on public.campaign_daily;
create policy "members can delete campaigns" on public.campaign_daily
for delete to authenticated using (public.is_workspace_member(workspace_id));

drop policy if exists "members can read leads" on public.lead_records;
create policy "members can read leads" on public.lead_records
for select to authenticated using (public.is_workspace_member(workspace_id));
drop policy if exists "members can add leads" on public.lead_records;
create policy "members can add leads" on public.lead_records
for insert to authenticated with check (public.is_workspace_member(workspace_id));
drop policy if exists "members can update leads" on public.lead_records;
create policy "members can update leads" on public.lead_records
for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
drop policy if exists "members can delete leads" on public.lead_records;
create policy "members can delete leads" on public.lead_records
for delete to authenticated using (public.is_workspace_member(workspace_id));

drop policy if exists "members can read orders" on public.orders;
create policy "members can read orders" on public.orders
for select to authenticated using (public.is_workspace_member(workspace_id));
drop policy if exists "members can add orders" on public.orders;
create policy "members can add orders" on public.orders
for insert to authenticated with check (public.is_workspace_member(workspace_id));
drop policy if exists "members can update orders" on public.orders;
create policy "members can update orders" on public.orders
for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
drop policy if exists "members can delete orders" on public.orders;
create policy "members can delete orders" on public.orders
for delete to authenticated using (public.is_workspace_member(workspace_id));

-- Future billing tables must be writable only by trusted server-side functions/webhooks.


-- The project was created without automatic Data API grants for new tables.
-- Allow authenticated users to reach these tables through Supabase Data API;
-- Row Level Security policies above still control which rows they can access.
grant usage on schema public to authenticated;
grant select, update, delete on public.workspaces to authenticated;
grant select on public.workspace_members to authenticated;
grant select, insert, update, delete on public.campaign_daily to authenticated;
grant select, insert, update, delete on public.lead_records to authenticated;
grant select, insert, update, delete on public.orders to authenticated;


-- Replace a workspace snapshot atomically. This avoids client-side delete/insert gaps.
create or replace function public.replace_workspace_data(
  target_workspace uuid,
  campaigns_payload jsonb,
  leads_payload jsonb,
  orders_payload jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or not public.is_workspace_member(target_workspace) then
    raise exception 'Workspace access denied';
  end if;
  if jsonb_typeof(coalesce(campaigns_payload, '[]'::jsonb)) <> 'array'
     or jsonb_typeof(coalesce(leads_payload, '[]'::jsonb)) <> 'array'
     or jsonb_typeof(coalesce(orders_payload, '[]'::jsonb)) <> 'array' then
    raise exception 'Workspace data must be JSON arrays';
  end if;

  delete from public.orders where workspace_id = target_workspace;
  delete from public.lead_records where workspace_id = target_workspace;
  delete from public.campaign_daily where workspace_id = target_workspace;

  insert into public.campaign_daily
    (workspace_id, report_date, campaign_name, spend, impressions, clicks, messages)
  select target_workspace, x.report_date, x.campaign_name,
         coalesce(x.spend, 0), coalesce(x.impressions, 0),
         coalesce(x.clicks, 0), coalesce(x.messages, 0)
  from jsonb_to_recordset(coalesce(campaigns_payload, '[]'::jsonb)) as x(
    report_date date, campaign_name text, spend numeric,
    impressions bigint, clicks bigint, messages bigint
  );

  insert into public.lead_records
    (workspace_id, lead_ref, created_at, campaign_name, lead_status,
     objection, agent_label, first_response_minutes)
  select target_workspace, x.lead_ref, x.created_at, x.campaign_name,
         coalesce(x.lead_status, 'new'), x.objection, x.agent_label,
         coalesce(x.first_response_minutes, 0)
  from jsonb_to_recordset(coalesce(leads_payload, '[]'::jsonb)) as x(
    lead_ref text, created_at timestamptz, campaign_name text,
    lead_status text, objection text, agent_label text,
    first_response_minutes numeric
  );

  insert into public.orders
    (workspace_id, order_ref, lead_ref, campaign_name, order_status,
     order_value, product_cost, shipping_cost, return_cost, payment_fees)
  select target_workspace, x.order_ref, x.lead_ref, x.campaign_name,
         coalesce(x.order_status, 'pending'), coalesce(x.order_value, 0),
         coalesce(x.product_cost, 0), coalesce(x.shipping_cost, 0),
         coalesce(x.return_cost, 0), coalesce(x.payment_fees, 0)
  from jsonb_to_recordset(coalesce(orders_payload, '[]'::jsonb)) as x(
    order_ref text, lead_ref text, campaign_name text, order_status text,
    order_value numeric, product_cost numeric, shipping_cost numeric,
    return_cost numeric, payment_fees numeric
  );
end;
$$;

revoke all on function public.replace_workspace_data(uuid, jsonb, jsonb, jsonb) from public;
grant execute on function public.replace_workspace_data(uuid, jsonb, jsonb, jsonb) to authenticated;
