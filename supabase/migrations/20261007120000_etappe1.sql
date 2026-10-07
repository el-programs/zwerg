-- Zwerg · Etappe 1: Nutzer, Geräte, Ideen, Kommentare, Suchfelder
-- Grundsatz: Jede Tabelle hat Row Level Security. Nur die zwei Gesellschafter
-- (Einträge in public.profiles mit verknüpftem Login) dürfen Daten lesen oder schreiben.

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- Personen
-- ---------------------------------------------------------------------------
create table public.profiles (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique,
  user_id    uuid unique references auth.users (id) on delete set null,
  name       text not null,
  kuerzel    text not null,
  accent     text not null default 'petrol',
  theme      text not null default 'system' check (theme in ('system', 'hell', 'dunkel')),
  created_at timestamptz not null default now()
);

insert into public.profiles (slug, name, kuerzel) values
  ('florian', 'Florian', 'FH'),
  ('igor', 'Igor', 'IH');

-- ---------------------------------------------------------------------------
-- Geräte und Anmeldung (nur über die Edge Function "auth" beschreibbar)
-- ---------------------------------------------------------------------------
create table public.devices (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.profiles (id) on delete cascade,
  session_id    uuid not null unique,
  label         text not null,
  kind          text not null check (kind in ('passkey', 'qr')),
  credential_id text,
  created_at    timestamptz not null default now(),
  last_seen_at  timestamptz not null default now(),
  revoked_at    timestamptz
);

create table public.webauthn_credentials (
  id           text primary key,
  profile_id   uuid not null references public.profiles (id) on delete cascade,
  public_key   text not null,
  counter      bigint not null default 0,
  transports   text[] not null default '{}',
  created_at   timestamptz not null default now(),
  last_used_at timestamptz
);

create table public.webauthn_challenges (
  id         uuid primary key default gen_random_uuid(),
  challenge  text not null,
  purpose    text not null check (purpose in ('register', 'login')),
  profile_id uuid references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.invites (
  token_hash text primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_by uuid references public.profiles (id) on delete set null,
  expires_at timestamptz not null,
  used_at    timestamptz,
  created_at timestamptz not null default now()
);

create table public.device_links (
  id                uuid primary key default gen_random_uuid(),
  approve_code_hash text not null,
  poll_secret_hash  text not null,
  status            text not null default 'pending' check (status in ('pending', 'approved', 'consumed')),
  profile_id        uuid references public.profiles (id) on delete cascade,
  expires_at        timestamptz not null,
  created_at        timestamptz not null default now()
);

-- Mitglied = angemeldeter Gesellschafter, dessen Gerät nicht gesperrt wurde.
create or replace function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles where user_id = auth.uid())
     and not exists (
       select 1 from public.devices
       where revoked_at is not null
         and session_id::text = coalesce(auth.jwt() ->> 'session_id', '')
     );
$$;

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.profiles where user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Inhalte
-- ---------------------------------------------------------------------------
create table public.search_fields (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (length(name) between 1 and 80),
  sort       integer not null default 0,
  archived   boolean not null default false,
  created_at timestamptz not null default now()
);

insert into public.search_fields (name, sort) values
  ('Interessen', 10),
  ('Alltagsprobleme', 20),
  ('Trends', 30),
  ('Ausland/andere Branchen', 40),
  ('Unternehmensnachfolge', 50);

create table public.ideas (
  id              uuid primary key default gen_random_uuid(),
  title           text not null default '' check (length(title) <= 200),
  description     text not null default '' check (length(description) <= 20000),
  search_field_id uuid references public.search_fields (id) on delete set null,
  tags            text[] not null default '{}',
  links           jsonb not null default '[]'::jsonb,
  phase           smallint not null default 1 check (phase between 1 and 4),
  status          text not null default 'aktiv' check (status in ('aktiv', 'geparkt')),
  park_reason     text,
  created_by      uuid not null default public.current_profile_id() references public.profiles (id),
  created_at      timestamptz not null default now(),
  updated_by      uuid default public.current_profile_id() references public.profiles (id),
  updated_at      timestamptz not null default now()
);

create index ideas_created_at_idx on public.ideas (created_at desc);

create table public.comments (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  author_id  uuid not null default public.current_profile_id() references public.profiles (id),
  body       text not null check (length(body) between 1 and 10000),
  created_at timestamptz not null default now()
);

create index comments_idea_idx on public.comments (idea_id, created_at);

-- Wann hat wer eine Idee zuletzt angesehen? Grundlage für die "neu"-Markierung.
create table public.idea_reads (
  profile_id uuid not null default public.current_profile_id() references public.profiles (id) on delete cascade,
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  seen_at    timestamptz not null default now(),
  primary key (profile_id, idea_id)
);

create or replace function public.touch_idea()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  new.updated_by := public.current_profile_id();
  new.created_by := old.created_by;
  new.created_at := old.created_at;
  return new;
end;
$$;

create trigger ideas_touch before update on public.ideas
  for each row execute function public.touch_idea();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles             enable row level security;
alter table public.devices              enable row level security;
alter table public.webauthn_credentials enable row level security;
alter table public.webauthn_challenges  enable row level security;
alter table public.invites              enable row level security;
alter table public.device_links         enable row level security;
alter table public.search_fields        enable row level security;
alter table public.ideas                enable row level security;
alter table public.comments             enable row level security;
alter table public.idea_reads           enable row level security;

-- Anmeldedaten: keine Richtlinien = kein Zugriff aus dem Browser.
-- (webauthn_credentials, webauthn_challenges, invites, device_links)

create policy "Mitglieder sehen Personen" on public.profiles
  for select to authenticated using (public.is_member());
create policy "Eigene Einstellungen ändern" on public.profiles
  for update to authenticated using (public.is_member() and user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Mitglieder sehen Geräte" on public.devices
  for select to authenticated using (public.is_member());

create policy "Mitglieder lesen Suchfelder" on public.search_fields
  for select to authenticated using (public.is_member());
create policy "Mitglieder legen Suchfelder an" on public.search_fields
  for insert to authenticated with check (public.is_member());
create policy "Mitglieder ändern Suchfelder" on public.search_fields
  for update to authenticated using (public.is_member()) with check (public.is_member());

create policy "Mitglieder lesen Ideen" on public.ideas
  for select to authenticated using (public.is_member());
create policy "Mitglieder legen Ideen an" on public.ideas
  for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Ideen" on public.ideas
  for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Ideen" on public.ideas
  for delete to authenticated using (public.is_member());

create policy "Mitglieder lesen Kommentare" on public.comments
  for select to authenticated using (public.is_member());
create policy "Mitglieder schreiben Kommentare" on public.comments
  for insert to authenticated
  with check (public.is_member() and author_id = public.current_profile_id());
create policy "Eigene Kommentare ändern" on public.comments
  for update to authenticated
  using (public.is_member() and author_id = public.current_profile_id())
  with check (author_id = public.current_profile_id());
create policy "Eigene Kommentare löschen" on public.comments
  for delete to authenticated
  using (public.is_member() and author_id = public.current_profile_id());

create policy "Eigene Lesemarken" on public.idea_reads
  for all to authenticated
  using (public.is_member() and profile_id = public.current_profile_id())
  with check (public.is_member() and profile_id = public.current_profile_id());

-- ---------------------------------------------------------------------------
-- Rechte: Tabellen werden nicht automatisch freigegeben, daher hier einzeln.
-- Nicht angemeldete Besucher (anon) erhalten keinerlei Tabellenzugriff.
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (accent, theme) on public.profiles to authenticated;
grant select on public.devices to authenticated;
grant select, insert, update on public.search_fields to authenticated;
grant select, insert, update, delete on public.ideas to authenticated;
grant select, insert, update, delete on public.comments to authenticated;
grant select, insert, update, delete on public.idea_reads to authenticated;

grant all on all tables in schema public to service_role;

revoke execute on function public.is_member() from public, anon;
revoke execute on function public.current_profile_id() from public, anon;
grant execute on function public.is_member() to authenticated, service_role;
grant execute on function public.current_profile_id() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Live-Abgleich
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table
  public.ideas, public.comments, public.search_fields, public.profiles, public.devices;

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

-- Wird alle paar Tage von GitHub aufgerufen, damit das kostenlose Projekt nicht pausiert.
create or replace function public.ping()
returns text
language sql
stable
as $$ select 'ok'::text $$;
revoke execute on function public.ping() from public;
grant execute on function public.ping() to anon, authenticated;

-- Einmalig im SQL-Editor ausführen: liefert je Person einen Einrichtungs-Link (7 Tage gültig).
create or replace function public.create_setup_links()
returns table (person text, link text)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  p record;
  token text;
begin
  for p in select * from public.profiles order by name loop
    token := encode(extensions.gen_random_bytes(24), 'hex');
    insert into public.invites (token_hash, profile_id, expires_at)
    values (encode(extensions.digest(token, 'sha256'), 'hex'), p.id, now() + interval '7 days');
    person := p.name;
    link := 'https://el-programs.github.io/zwerg/#/einladung/' || token;
    return next;
  end loop;
end;
$$;
revoke execute on function public.create_setup_links() from public, anon, authenticated;
