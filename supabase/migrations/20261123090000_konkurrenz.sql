-- Zwerg · Konkurrenz je Idee: Anbieter mit Bereich, Art, Preisen, Stärken und Schwächen,
-- dazu je Idee die Freitexte „Unsere Abgrenzung“ und „Allgemeine Notizen“.

create table public.idea_competitors (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  sort       integer not null default 0,
  name       text not null check (length(name) between 1 and 200),
  url        text not null default '' check (length(url) <= 500),
  area       text not null default '' check (length(area) <= 100),   -- Bereich, z. B. Webseiten, App-Vorbild
  kind       text not null default '' check (length(kind) <= 100),   -- Art, z. B. Agentur, Freelancer
  prices     text not null default '' check (length(prices) <= 2000),
  strengths  text not null default '' check (length(strengths) <= 4000),
  weaknesses text not null default '' check (length(weaknesses) <= 4000),
  note       text not null default '' check (length(note) <= 8000),
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  updated_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idea_competitors_idea_idx on public.idea_competitors (idea_id, sort);

alter table public.idea_competitors enable row level security;
create policy "Mitglieder lesen Konkurrenz" on public.idea_competitors for select to authenticated using (public.is_member());
create policy "Mitglieder legen Konkurrenz an" on public.idea_competitors for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Konkurrenz" on public.idea_competitors for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Konkurrenz" on public.idea_competitors for delete to authenticated using (public.is_member());
grant select, insert, update, delete on public.idea_competitors to authenticated;
grant all on public.idea_competitors to service_role;
alter publication supabase_realtime add table public.idea_competitors;

alter table public.ideas
  add column competition_edge text not null default '' check (length(competition_edge) <= 20000),
  add column competition_notes text not null default '' check (length(competition_notes) <= 20000);
