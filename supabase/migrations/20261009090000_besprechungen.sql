-- Zwerg · Besprechungen mit Tagesordnungspunkten (Notiz und Ergebnis je Punkt)

create table public.meetings (
  id         uuid primary key default gen_random_uuid(),
  title      text not null default '' check (length(title) <= 200),
  held_on    date not null default current_date,
  start_time time,
  attendees  uuid[] not null default '{}',             -- Profile, die dabei waren
  guests     text not null default '' check (length(guests) <= 500),
  place      text not null default '' check (length(place) <= 200),
  idea_ids   uuid[] not null default '{}',             -- besprochene Notizen
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index meetings_date_idx on public.meetings (held_on desc, created_at desc);

create table public.meeting_items (
  id           uuid primary key default gen_random_uuid(),
  meeting_id   uuid not null references public.meetings (id) on delete cascade,
  sort         integer not null default 0,
  title        text not null default '' check (length(title) <= 300),
  notes        text not null default '' check (length(notes) <= 20000),
  result       text not null default '' check (length(result) <= 10000),
  carried_from uuid references public.meeting_items (id) on delete set null,
  created_by   uuid not null default public.current_profile_id() references public.profiles (id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index meeting_items_meeting_idx on public.meeting_items (meeting_id, sort);

-- Aufgaben und Entscheidungen können aus einer Besprechung stammen.
alter table public.tasks add column meeting_id uuid references public.meetings (id) on delete set null;
alter table public.decisions add column meeting_id uuid references public.meetings (id) on delete set null;

alter table public.meetings      enable row level security;
alter table public.meeting_items enable row level security;

create policy "Mitglieder lesen Besprechungen" on public.meetings for select to authenticated using (public.is_member());
create policy "Mitglieder legen Besprechungen an" on public.meetings for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Besprechungen" on public.meetings for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Besprechungen" on public.meetings for delete to authenticated using (public.is_member());

create policy "Mitglieder lesen Tagesordnungspunkte" on public.meeting_items for select to authenticated using (public.is_member());
create policy "Mitglieder legen Tagesordnungspunkte an" on public.meeting_items for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Tagesordnungspunkte" on public.meeting_items for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Tagesordnungspunkte" on public.meeting_items for delete to authenticated using (public.is_member());

grant select, insert, update, delete on public.meetings, public.meeting_items to authenticated;
grant all on public.meetings, public.meeting_items to service_role;

alter publication supabase_realtime add table public.meetings, public.meeting_items;
