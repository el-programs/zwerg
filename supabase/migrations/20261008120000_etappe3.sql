-- Zwerg · Etappe 3: KI-Unterstützung (Claude API) mit Stufen je Person und Kostenbremse.
-- Der API-Schlüssel liegt ausschließlich als Secret der Edge Function "ki" – nie in der Datenbank oder im Browser.

alter table public.profiles
  add column ai_level text not null default 'anfrage' check (ai_level in ('aus', 'anfrage', 'aktiv'));
grant update (ai_level) on public.profiles to authenticated;

-- Gemeinsame Einstellungen (genau eine Zeile)
create table public.ai_settings (
  id                smallint primary key default 1 check (id = 1),
  model             text not null default 'claude-opus-5-5' check (model in ('claude-opus-5-5', 'claude-sonnet-5-5')),
  monthly_limit_eur numeric(8, 2) not null default 10 check (monthly_limit_eur between 0 and 500),
  updated_by        uuid references public.profiles (id),
  updated_at        timestamptz not null default now()
);
insert into public.ai_settings (id) values (1);

-- Verbrauch je Aufruf (schreibt nur die Edge Function)
create table public.ai_usage (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid references public.profiles (id) on delete set null,
  kind          text not null,
  model         text not null,
  input_tokens  integer not null default 0,
  output_tokens integer not null default 0,
  searches      integer not null default 0,
  cost_eur      numeric(10, 4) not null default 0,
  created_at    timestamptz not null default now()
);
create index ai_usage_created_idx on public.ai_usage (created_at);

-- Ergebnisse: Ideen-Vorschläge, kritische Einschätzung, Marktrecherche
create table public.ai_results (
  id              uuid primary key default gen_random_uuid(),
  kind            text not null check (kind in ('vorschlaege', 'einschaetzung', 'recherche')),
  idea_id         uuid references public.ideas (id) on delete cascade,
  search_field_id uuid references public.search_fields (id) on delete set null,
  prompt          text not null default '',
  status          text not null default 'laeuft' check (status in ('laeuft', 'fertig', 'fehler')),
  content         jsonb,
  error           text,
  model           text,
  cost_eur        numeric(10, 4) not null default 0,
  created_by      uuid references public.profiles (id) on delete set null,
  created_at      timestamptz not null default now(),
  finished_at     timestamptz
);
create index ai_results_idea_idx on public.ai_results (idea_id, created_at desc);

-- Chat-Sparring je Idee (für beide sichtbar)
create table public.ai_chat (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  profile_id uuid references public.profiles (id) on delete set null,
  role       text not null check (role in ('user', 'assistant')),
  content    text not null default '',
  status     text not null default 'fertig' check (status in ('laeuft', 'fertig', 'fehler')),
  created_at timestamptz not null default now()
);
create index ai_chat_idea_idx on public.ai_chat (idea_id, created_at);

alter table public.ai_settings enable row level security;
alter table public.ai_usage    enable row level security;
alter table public.ai_results  enable row level security;
alter table public.ai_chat     enable row level security;

create policy "Mitglieder lesen KI-Einstellungen" on public.ai_settings
  for select to authenticated using (public.is_member());
create policy "Mitglieder ändern KI-Einstellungen" on public.ai_settings
  for update to authenticated using (public.is_member()) with check (public.is_member());

create policy "Mitglieder sehen KI-Verbrauch" on public.ai_usage
  for select to authenticated using (public.is_member());

create policy "Mitglieder sehen KI-Ergebnisse" on public.ai_results
  for select to authenticated using (public.is_member());
create policy "Mitglieder löschen KI-Ergebnisse" on public.ai_results
  for delete to authenticated using (public.is_member());

create policy "Mitglieder sehen KI-Chat" on public.ai_chat
  for select to authenticated using (public.is_member());
create policy "Mitglieder löschen KI-Chat" on public.ai_chat
  for delete to authenticated using (public.is_member());

grant select on public.ai_settings to authenticated;
grant update (model, monthly_limit_eur, updated_by, updated_at) on public.ai_settings to authenticated;
grant select on public.ai_usage to authenticated;
grant select, delete on public.ai_results to authenticated;
grant select, delete on public.ai_chat to authenticated;
grant all on public.ai_settings, public.ai_usage, public.ai_results, public.ai_chat to service_role;

alter publication supabase_realtime add table
  public.ai_settings, public.ai_usage, public.ai_results, public.ai_chat;
