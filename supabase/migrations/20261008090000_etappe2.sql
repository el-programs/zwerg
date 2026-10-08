-- Zwerg · Etappe 2: Bewertungsmatrix, Gewichtung, KO-Kriterien, Favoriten, Parkplatz
-- Grundsatz: Eigene Gewichtungen und Bewertungen sind für den Partner unsichtbar,
-- bis man selbst abgegeben hat. Das erzwingt die Datenbank, nicht nur die App.

-- ---------------------------------------------------------------------------
-- Ideen: Parkplatz und Favoriten
-- ---------------------------------------------------------------------------
alter table public.ideas
  add column parked_at   timestamptz,
  add column parked_by   uuid references public.profiles (id),
  add column is_favorite boolean not null default false;

-- ---------------------------------------------------------------------------
-- Bewertungsfaktoren und KO-Kriterien (für beide gemeinsam, bearbeitbar)
-- ---------------------------------------------------------------------------
create table public.criteria (
  id           uuid primary key default gen_random_uuid(),
  name         text not null check (length(name) between 1 and 80),
  description  text not null default '' check (length(description) <= 300),
  sort         integer not null default 0,
  archived     boolean not null default false,
  joint_weight smallint check (joint_weight between 0 and 5),
  created_at   timestamptz not null default now()
);

insert into public.criteria (name, description, sort) values
  ('Leidenschaft/Interesse', 'Begeistert uns das Thema auch noch in fünf Jahren?', 10),
  ('Finanzen/Investment', 'Wie gut ist der Kapitalbedarf für uns tragbar?', 20),
  ('Qualifizierung', 'Bringen wir das nötige Wissen und Können mit?', 30),
  ('Komplexität der Prozesskette', 'Wie einfach sind Einkauf, Herstellung, Vertrieb?', 40),
  ('Skalierbarkeit/Start', 'Klein starten und später wachsen – wie gut geht das?', 50),
  ('Selbständigkeit/Partnerschaften/Hilfe', 'Können wir es selbst stemmen oder gibt es gute Partner?', 60),
  ('Zukunftssicherheit', 'Gibt es das Geschäft auch in zehn Jahren noch?', 70),
  ('Marge', 'Wie viel bleibt pro Verkauf übrig?', 80),
  ('Moral/Ethik/Umwelt', 'Können wir guten Gewissens dahinterstehen?', 90),
  ('Aktionsradius/Standort', 'Passt das Einzugsgebiet zu uns und unserem Standort?', 100),
  ('Marktgröße/Nachfrage', 'Gibt es genug zahlende Kunden?', 110),
  ('Wettbewerb/Alleinstellung', 'Wie gut können wir uns abheben?', 120),
  ('Zeitaufwand neben dem Hauptgeschäft', 'Wie gut lässt es sich nebenher betreiben?', 130),
  ('Risiko/Kapitalbindung', 'Wie gering sind Risiko und gebundenes Kapital?', 140),
  ('Rechtliche Hürden', 'Wie einfach sind Genehmigungen, Haftung, Vorschriften?', 150),
  ('Testbarkeit', 'Wie leicht lässt sich die Idee günstig mit echten Kunden testen?', 160);

create table public.ko_criteria (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (length(name) between 1 and 120),
  description text not null default '' check (length(description) <= 300),
  sort        integer not null default 0,
  archived    boolean not null default false,
  created_at  timestamptz not null default now()
);

insert into public.ko_criteria (name, sort) values
  ('Startkapital übersteigt unser Budget deutlich', 10),
  ('Rechtlich nicht zulässig oder Genehmigung unrealistisch', 20),
  ('Nicht neben dem Hauptgeschäft machbar', 30),
  ('Widerspricht unseren Werten', 40);

-- ---------------------------------------------------------------------------
-- Gewichtung: erst jeder für sich, dann gemeinsam (criteria.joint_weight)
-- ---------------------------------------------------------------------------
create table public.weight_submissions (
  profile_id   uuid primary key default public.current_profile_id() references public.profiles (id) on delete cascade,
  submitted_at timestamptz not null default now()
);

create table public.personal_weights (
  profile_id   uuid not null default public.current_profile_id() references public.profiles (id) on delete cascade,
  criterion_id uuid not null references public.criteria (id) on delete cascade,
  weight       smallint not null check (weight between 0 and 5),
  updated_at   timestamptz not null default now(),
  primary key (profile_id, criterion_id)
);

-- ---------------------------------------------------------------------------
-- Bewertung je Idee: erst jeder für sich, dann gemeinsam
-- ---------------------------------------------------------------------------
create table public.rating_submissions (
  idea_id      uuid not null references public.ideas (id) on delete cascade,
  profile_id   uuid not null default public.current_profile_id() references public.profiles (id) on delete cascade,
  submitted_at timestamptz not null default now(),
  primary key (idea_id, profile_id)
);

create table public.ratings (
  idea_id      uuid not null references public.ideas (id) on delete cascade,
  profile_id   uuid not null default public.current_profile_id() references public.profiles (id) on delete cascade,
  criterion_id uuid not null references public.criteria (id) on delete cascade,
  score        smallint not null check (score between 1 and 5),
  note         text not null default '' check (length(note) <= 2000),
  updated_at   timestamptz not null default now(),
  primary key (idea_id, profile_id, criterion_id)
);

create table public.personal_ko (
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  profile_id uuid not null default public.current_profile_id() references public.profiles (id) on delete cascade,
  ko_id      uuid not null references public.ko_criteria (id) on delete cascade,
  primary key (idea_id, profile_id, ko_id)
);

create table public.joint_ratings (
  idea_id      uuid not null references public.ideas (id) on delete cascade,
  criterion_id uuid not null references public.criteria (id) on delete cascade,
  score        smallint not null check (score between 1 and 5),
  note         text not null default '' check (length(note) <= 2000),
  updated_by   uuid default public.current_profile_id() references public.profiles (id),
  updated_at   timestamptz not null default now(),
  primary key (idea_id, criterion_id)
);

create table public.idea_evaluations (
  idea_id      uuid primary key references public.ideas (id) on delete cascade,
  ko_ids       uuid[] not null default '{}',
  ko_note      text not null default '' check (length(ko_note) <= 2000),
  finalized_at timestamptz,
  finalized_by uuid references public.profiles (id),
  updated_at   timestamptz not null default now()
);

-- Hat die angemeldete Person schon abgegeben?
create or replace function public.has_submitted_weights()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.weight_submissions where profile_id = public.current_profile_id());
$$;

create or replace function public.has_submitted_rating(p_idea uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.rating_submissions
    where idea_id = p_idea and profile_id = public.current_profile_id()
  );
$$;

revoke execute on function public.has_submitted_weights() from public, anon;
revoke execute on function public.has_submitted_rating(uuid) from public, anon;
grant execute on function public.has_submitted_weights() to authenticated, service_role;
grant execute on function public.has_submitted_rating(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.criteria           enable row level security;
alter table public.ko_criteria        enable row level security;
alter table public.weight_submissions enable row level security;
alter table public.personal_weights   enable row level security;
alter table public.rating_submissions enable row level security;
alter table public.ratings            enable row level security;
alter table public.personal_ko        enable row level security;
alter table public.joint_ratings      enable row level security;
alter table public.idea_evaluations   enable row level security;

create policy "Mitglieder lesen Faktoren" on public.criteria
  for select to authenticated using (public.is_member());
create policy "Mitglieder legen Faktoren an" on public.criteria
  for insert to authenticated with check (public.is_member());
create policy "Mitglieder ändern Faktoren" on public.criteria
  for update to authenticated using (public.is_member()) with check (public.is_member());

create policy "Mitglieder lesen KO-Kriterien" on public.ko_criteria
  for select to authenticated using (public.is_member());
create policy "Mitglieder legen KO-Kriterien an" on public.ko_criteria
  for insert to authenticated with check (public.is_member());
create policy "Mitglieder ändern KO-Kriterien" on public.ko_criteria
  for update to authenticated using (public.is_member()) with check (public.is_member());

-- Abgabe-Status ist für beide sichtbar ("Florian hat abgegeben").
create policy "Mitglieder sehen Gewichtungs-Abgaben" on public.weight_submissions
  for select to authenticated using (public.is_member());
create policy "Eigene Gewichtung abgeben" on public.weight_submissions
  for insert to authenticated
  with check (public.is_member() and profile_id = public.current_profile_id());

-- Gewichte des Partners erst nach eigener Abgabe sichtbar.
create policy "Gewichte lesen" on public.personal_weights
  for select to authenticated
  using (public.is_member() and (profile_id = public.current_profile_id() or public.has_submitted_weights()));
create policy "Eigene Gewichte schreiben" on public.personal_weights
  for insert to authenticated
  with check (public.is_member() and profile_id = public.current_profile_id());
create policy "Eigene Gewichte ändern" on public.personal_weights
  for update to authenticated
  using (public.is_member() and profile_id = public.current_profile_id())
  with check (profile_id = public.current_profile_id());

create policy "Mitglieder sehen Bewertungs-Abgaben" on public.rating_submissions
  for select to authenticated using (public.is_member());
create policy "Eigene Bewertung abgeben" on public.rating_submissions
  for insert to authenticated
  with check (public.is_member() and profile_id = public.current_profile_id());

-- Bewertungen des Partners erst nach eigener Abgabe für diese Idee sichtbar.
create policy "Bewertungen lesen" on public.ratings
  for select to authenticated
  using (public.is_member() and (profile_id = public.current_profile_id() or public.has_submitted_rating(idea_id)));
create policy "Eigene Bewertungen schreiben" on public.ratings
  for insert to authenticated
  with check (public.is_member() and profile_id = public.current_profile_id());
create policy "Eigene Bewertungen ändern" on public.ratings
  for update to authenticated
  using (public.is_member() and profile_id = public.current_profile_id())
  with check (profile_id = public.current_profile_id());

create policy "KO-Markierungen lesen" on public.personal_ko
  for select to authenticated
  using (public.is_member() and (profile_id = public.current_profile_id() or public.has_submitted_rating(idea_id)));
create policy "Eigene KO-Markierungen setzen" on public.personal_ko
  for insert to authenticated
  with check (public.is_member() and profile_id = public.current_profile_id());
create policy "Eigene KO-Markierungen entfernen" on public.personal_ko
  for delete to authenticated
  using (public.is_member() and profile_id = public.current_profile_id());

create policy "Gemeinsame Bewertung lesen" on public.joint_ratings
  for select to authenticated using (public.is_member() and public.has_submitted_rating(idea_id));
create policy "Gemeinsame Bewertung schreiben" on public.joint_ratings
  for insert to authenticated with check (public.is_member() and public.has_submitted_rating(idea_id));
create policy "Gemeinsame Bewertung ändern" on public.joint_ratings
  for update to authenticated
  using (public.is_member() and public.has_submitted_rating(idea_id))
  with check (public.is_member());

create policy "Endbewertung lesen" on public.idea_evaluations
  for select to authenticated using (public.is_member());
create policy "Endbewertung anlegen" on public.idea_evaluations
  for insert to authenticated with check (public.is_member() and public.has_submitted_rating(idea_id));
create policy "Endbewertung ändern" on public.idea_evaluations
  for update to authenticated
  using (public.is_member() and public.has_submitted_rating(idea_id))
  with check (public.is_member());

-- ---------------------------------------------------------------------------
-- Rechte
-- ---------------------------------------------------------------------------
grant select, insert, update on public.criteria to authenticated;
grant select, insert, update on public.ko_criteria to authenticated;
grant select, insert on public.weight_submissions to authenticated;
grant select, insert, update on public.personal_weights to authenticated;
grant select, insert on public.rating_submissions to authenticated;
grant select, insert, update on public.ratings to authenticated;
grant select, insert, delete on public.personal_ko to authenticated;
grant select, insert, update on public.joint_ratings to authenticated;
grant select, insert, update on public.idea_evaluations to authenticated;
grant all on
  public.criteria, public.ko_criteria, public.weight_submissions, public.personal_weights,
  public.rating_submissions, public.ratings, public.personal_ko, public.joint_ratings,
  public.idea_evaluations
  to service_role;

-- ---------------------------------------------------------------------------
-- Live-Abgleich
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table
  public.criteria, public.ko_criteria, public.weight_submissions, public.personal_weights,
  public.rating_submissions, public.ratings, public.personal_ko, public.joint_ratings,
  public.idea_evaluations;
