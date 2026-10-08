-- Zwerg · Etappe 4: Phasensteuerung, Aufgaben, Business Case, Pilot-Feedback, Entscheidungsprotokoll

-- ---------------------------------------------------------------------------
-- Phasen (Ziele, Ergebnisse, Abschlusskriterien und Hinweise sind bearbeitbar)
-- ---------------------------------------------------------------------------
create table public.phases (
  nr         smallint primary key check (nr between 1 and 4),
  name       text not null check (length(name) between 1 and 80),
  goal       text not null default '',
  result     text not null default '',
  hints      text not null default '',
  criteria   jsonb not null default '[]'::jsonb, -- [{ id, text, done, done_by, done_at }]
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);

insert into public.phases (nr, name, goal, result, hints, criteria) values
  (1, 'Ideenfindung',
   'Breit sammeln ohne Bewertung, danach filtern und bewerten.',
   '2–3 Favoriten',
   'Erst sammeln, dann bewerten – nicht zu früh aussortieren. Nutzt alle Suchfelder und notiert auch halbe Ideen.',
   '[{"id":"p1a","text":"Mindestens 20 Ideen gesammelt","done":false},
     {"id":"p1b","text":"Gemeinsame Gewichtung festgelegt","done":false},
     {"id":"p1c","text":"Ideen getrennt und gemeinsam bewertet","done":false},
     {"id":"p1d","text":"2–3 Favoriten markiert","done":false}]'),
  (2, 'Machbarkeitsprüfung und Auswahl',
   'Markt, Wettbewerb und Business Case der Favoriten prüfen.',
   'Eine Idee als Gründungskandidat – oder Rückkehr zu Phase 1',
   'Lieber früh eine Idee verwerfen als spät. Die Rückkehr zu Phase 1 ist ein gutes Ergebnis, kein Scheitern.',
   '[{"id":"p2a","text":"Zielkunden und Marktgröße beschrieben","done":false},
     {"id":"p2b","text":"Wettbewerber recherchiert","done":false},
     {"id":"p2c","text":"Business Case mit drei Szenarien gerechnet","done":false},
     {"id":"p2d","text":"Mit mindestens 5 potenziellen Kunden gesprochen","done":false},
     {"id":"p2e","text":"Entscheidung für einen Gründungskandidaten protokolliert","done":false}]'),
  (3, 'Pilot- und Vorbereitungsphase',
   'Mit echten Kunden bei geringem Risiko testen; parallel Businessplan, Finanzierung und Rechtsform vorbereiten.',
   'Gründungsentscheidung auf Basis echter Kundenreaktionen',
   'Pilot so klein wie möglich halten und vorher festlegen, woran ihr Erfolg messt. Steuerberater früh einbinden.',
   '[{"id":"p3a","text":"Erfolgskriterien für den Pilot festgelegt","done":false},
     {"id":"p3b","text":"Pilot mit echten Kunden durchgeführt","done":false},
     {"id":"p3c","text":"Pilot-Feedback ausgewertet","done":false},
     {"id":"p3d","text":"Businessplan erstellt","done":false},
     {"id":"p3e","text":"Finanzierung geklärt","done":false},
     {"id":"p3f","text":"Rechtsform gewählt (mit Steuerberater/Notar)","done":false},
     {"id":"p3g","text":"Go/No-Go-Entscheidung protokolliert","done":false}]'),
  (4, 'Gründung',
   'Formale Gründung und Aufbau.',
   'Die neue Firma ist gegründet und arbeitsfähig',
   'Reihenfolge mit dem Notar und Steuerberater abstimmen. Fristen und Kosten im Blick behalten.',
   '[{"id":"p4a","text":"Gesellschaftsvertrag und Notartermin","done":false},
     {"id":"p4b","text":"Eintrag ins Handelsregister","done":false},
     {"id":"p4c","text":"Gewerbe angemeldet","done":false},
     {"id":"p4d","text":"Geschäftskonto eröffnet","done":false},
     {"id":"p4e","text":"Steuerliche Erfassung beim Finanzamt","done":false},
     {"id":"p4f","text":"Versicherungen abgeschlossen","done":false},
     {"id":"p4g","text":"Erste Kunden bzw. Aufträge","done":false}]');

create table public.app_state (
  id            smallint primary key default 1 check (id = 1),
  current_phase smallint not null default 1 check (current_phase between 1 and 4),
  updated_by    uuid references public.profiles (id),
  updated_at    timestamptz not null default now()
);
insert into public.app_state (id) values (1);

-- ---------------------------------------------------------------------------
-- Aufgaben
-- ---------------------------------------------------------------------------
create table public.tasks (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (length(title) between 1 and 300),
  notes      text not null default '' check (length(notes) <= 5000),
  assignee   uuid references public.profiles (id) on delete set null,
  due_date   date,
  status     text not null default 'offen' check (status in ('offen', 'in_arbeit', 'erledigt')),
  idea_id    uuid references public.ideas (id) on delete set null,
  phase      smallint check (phase between 1 and 4),
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  done_at    timestamptz
);
create index tasks_due_idx on public.tasks (status, due_date);

-- ---------------------------------------------------------------------------
-- Business Case je Idee: drei Szenarien
-- ---------------------------------------------------------------------------
create table public.business_cases (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null unique references public.ideas (id) on delete cascade,
  scenarios  jsonb not null default '{}'::jsonb, -- { vorsichtig: {...}, realistisch: {...}, optimistisch: {...} }
  notes      text not null default '' check (length(notes) <= 10000),
  unit       text not null default 'Stück' check (length(unit) <= 30),
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Pilot-Feedback: Kundengespräche und Testergebnisse
-- ---------------------------------------------------------------------------
create table public.pilot_feedback (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  kind       text not null default 'gespraech' check (kind in ('gespraech', 'test', 'umfrage', 'sonstiges')),
  contact    text not null default '' check (length(contact) <= 200),
  held_on    date not null default current_date,
  summary    text not null default '' check (length(summary) <= 10000),
  problem    smallint check (problem between 1 and 5),
  interest   smallint check (interest between 1 and 5),
  price      text not null default '' check (length(price) <= 300),
  quote      text not null default '' check (length(quote) <= 2000),
  learnings  text not null default '' check (length(learnings) <= 5000),
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  created_at timestamptz not null default now()
);
create index pilot_feedback_idea_idx on public.pilot_feedback (idea_id, held_on desc);

-- ---------------------------------------------------------------------------
-- Entscheidungsprotokoll
-- ---------------------------------------------------------------------------
create table public.decisions (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (length(title) between 1 and 300),
  decision   text not null default '' check (length(decision) <= 10000),
  reason     text not null default '' check (length(reason) <= 10000),
  decided_on date not null default current_date,
  idea_id    uuid references public.ideas (id) on delete set null,
  phase      smallint check (phase between 1 and 4),
  automatic  boolean not null default false,
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index decisions_date_idx on public.decisions (decided_on desc, created_at desc);

-- ---------------------------------------------------------------------------
-- Row Level Security und Rechte
-- ---------------------------------------------------------------------------
alter table public.phases         enable row level security;
alter table public.app_state      enable row level security;
alter table public.tasks          enable row level security;
alter table public.business_cases enable row level security;
alter table public.pilot_feedback enable row level security;
alter table public.decisions      enable row level security;

create policy "Mitglieder lesen Phasen" on public.phases for select to authenticated using (public.is_member());
create policy "Mitglieder ändern Phasen" on public.phases for update to authenticated using (public.is_member()) with check (public.is_member());

create policy "Mitglieder lesen Projektstand" on public.app_state for select to authenticated using (public.is_member());
create policy "Mitglieder ändern Projektstand" on public.app_state for update to authenticated using (public.is_member()) with check (public.is_member());

create policy "Mitglieder lesen Aufgaben" on public.tasks for select to authenticated using (public.is_member());
create policy "Mitglieder legen Aufgaben an" on public.tasks for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Aufgaben" on public.tasks for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Aufgaben" on public.tasks for delete to authenticated using (public.is_member());

create policy "Mitglieder lesen Business Cases" on public.business_cases for select to authenticated using (public.is_member());
create policy "Mitglieder legen Business Cases an" on public.business_cases for insert to authenticated with check (public.is_member());
create policy "Mitglieder ändern Business Cases" on public.business_cases for update to authenticated using (public.is_member()) with check (public.is_member());

create policy "Mitglieder lesen Pilot-Feedback" on public.pilot_feedback for select to authenticated using (public.is_member());
create policy "Mitglieder erfassen Pilot-Feedback" on public.pilot_feedback for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Pilot-Feedback" on public.pilot_feedback for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Pilot-Feedback" on public.pilot_feedback for delete to authenticated using (public.is_member());

-- Entscheidungen bleiben nachvollziehbar: ändern und löschen nur durch die Person, die sie eingetragen hat.
create policy "Mitglieder lesen Entscheidungen" on public.decisions for select to authenticated using (public.is_member());
create policy "Mitglieder protokollieren Entscheidungen" on public.decisions for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Eigene Entscheidungen ändern" on public.decisions for update to authenticated
  using (public.is_member() and created_by = public.current_profile_id()) with check (created_by = public.current_profile_id());
create policy "Eigene Entscheidungen löschen" on public.decisions for delete to authenticated
  using (public.is_member() and created_by = public.current_profile_id());

grant select, update on public.phases to authenticated;
grant select, update on public.app_state to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;
grant select, insert, update on public.business_cases to authenticated;
grant select, insert, update, delete on public.pilot_feedback to authenticated;
grant select, insert, update, delete on public.decisions to authenticated;
grant all on public.phases, public.app_state, public.tasks, public.business_cases, public.pilot_feedback, public.decisions
  to service_role;

alter publication supabase_realtime add table
  public.phases, public.app_state, public.tasks, public.business_cases, public.pilot_feedback, public.decisions;
