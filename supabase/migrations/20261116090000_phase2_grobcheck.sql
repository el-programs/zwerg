-- Zwerg · Phase 2 in zwei Teilen: 2a Grobcheck mit Ampel-Kriterien je Idee und Wahl von Favorit/Nachrückern,
-- 2b Machbarkeitsprüfung des Favoriten. Bei No-Go rückt der nächste Nachrücker nach.

-- Kriterien je Idee (Grobcheck), erweiterbar
create table public.idea_checks (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  sort       integer not null default 0,
  question   text not null check (length(question) between 1 and 500),
  status     text not null default 'offen' check (status in ('offen', 'gut', 'schwierig', 'ko')),
  note       text not null default '' check (length(note) <= 10000),
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  updated_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idea_checks_idea_idx on public.idea_checks (idea_id, sort);

alter table public.idea_checks enable row level security;
create policy "Mitglieder lesen Grobcheck" on public.idea_checks for select to authenticated using (public.is_member());
create policy "Mitglieder legen Grobcheck an" on public.idea_checks for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Grobcheck" on public.idea_checks for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Grobcheck" on public.idea_checks for delete to authenticated using (public.is_member());
grant select, insert, update, delete on public.idea_checks to authenticated;
grant all on public.idea_checks to service_role;
alter publication supabase_realtime add table public.idea_checks;

-- Auswahl in Phase 2 je Idee: Fazit, Rolle (Favorit, Nachrücker, nach Prüfung verworfen) und Begründung
alter table public.ideas
  add column check_fazit text not null default '' check (length(check_fazit) <= 20000),
  add column selection text check (selection in ('favorit', 'nachruecker', 'verworfen')),
  add column selection_rank integer,
  add column selection_note text not null default '' check (length(selection_note) <= 5000);

-- Phase 2 neu beschreiben
update public.phases set
  name = $t$Auswahl und Machbarkeit$t$,
  goal = $t$2a Grobcheck: Jede Idee für sich mit eigenen Kriterien (Ampel und Notiz) einschätzen und Favorit sowie Nachrücker festlegen – nach Ampeln oder Bauchgefühl. 2b Machbarkeitsprüfung: Nur den Favoriten genau prüfen.$t$,
  result = $t$Ein geprüfter Gründungskandidat für Phase 3 – bei No-Go rückt der nächste Nachrücker in 2b nach.$t$,
  hints = $t$Die Ideen werden nicht gegeneinander verrechnet. Haltet in den Notizen fest, wie ihr gedacht habt – das hilft später bei jeder Entscheidung. Für 2b einen Zeitrahmen setzen (z. B. 6–8 Wochen).$t$,
  criteria = $t$[{"id":"p2a","text":"2a: Grobcheck – Kriterien je Idee mit Ampel und Notiz eingeschätzt","done":false},{"id":"p2b","text":"2a: Fazit je Idee festgehalten","done":false},{"id":"p2c","text":"2a: Favorit und Nachrücker festgelegt und begründet","done":false},{"id":"p2d","text":"2b: Machbarkeitsprüfung des Favoriten (Recht, Markt, Kunden, Business Case)","done":false},{"id":"p2e","text":"2b: Go oder No-Go entschieden und protokolliert","done":false}]$t$::jsonb
where nr = 2;

-- Kriterien für die vier Ideen der engeren Wahl
insert into public.idea_checks (idea_id, sort, question, created_by)
select i.id, v.sort, v.question, p.id
from (values
  ($t$Gesundheits-Logistik$t$, 1, $t$Bekommen wir als neuer Anbieter Verträge mit den Krankenkassen?$t$),
  ($t$Gesundheits-Logistik$t$, 2, $t$Tragen die Vergütungssätze der Kassen die Kosten eines Fahrzeugs mit Fahrer?$t$),
  ($t$Gesundheits-Logistik$t$, 3, $t$Gibt es genug feste Serienfahrten (Dialyse, Tagespflege) als Grundlast?$t$),
  ($t$Gesundheits-Logistik$t$, 4, $t$Sind Genehmigung und Fachkundeprüfung in vertretbarer Zeit machbar?$t$),
  ($t$Gesundheits-Logistik$t$, 5, $t$Finden wir zuverlässige Fahrer, auch für frühe und späte Fahrten?$t$),
  ($t$Gesundheits-Logistik$t$, 6, $t$Wie stark ist die Konkurrenz vor Ort (Taxis, Fahrdienste, Wohlfahrtsverbände)?$t$),
  ($t$Gesundheits-Logistik$t$, 7, $t$Zahlen Apotheken und Tagespflegen genug für Boten- und Fahrdienste?$t$),
  ($t$Gesundheits-Logistik$t$, 8, $t$Ist das Startkapital für 1–2 Fahrzeuge (Kauf oder Leasing) tragbar?$t$),
  ($t$Gesundheits-Logistik$t$, 9, $t$Wie viel eigene Zeit kostet Organisation und Disposition?$t$),
  ($t$Gesundheits-Logistik$t$, 10, $t$Wie groß ist das Risiko, wenn ein großer Auftraggeber wegfällt?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 1, $t$Ist die Öffnung ohne Personal abends und sonntags rechtlich erlaubt?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 2, $t$Gibt es ein bezahlbares Ladenlokal in einem passenden Wohngebiet?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 3, $t$Fehlt im Umkreis ein Abendangebot – oder gibt es Tankstelle und Kiosk?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 4, $t$Reicht die Zahl der Haushalte im Umkreis für den nötigen Tagesumsatz?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 5, $t$Können wir die Technik (Zugang, Kasse, Kameras, Warenwirtschaft) zuverlässig selbst zusammenstellen?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 6, $t$Wie hoch schätzen wir Diebstahl und Vandalismus ein?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 7, $t$Sind Einkaufskonditionen mit ausreichender Marge möglich?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 8, $t$Ist das Startkapital von 30–60 T€ realistisch ausreichend?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 9, $t$Wie lösen wir das Befüllen am Wochenende?$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, 10, $t$Lässt sich das Konzept auf weitere Standorte übertragen?$t$),
  ($t$App-Entwicklung mit KI$t$, 1, $t$Gibt es Nischen mit teuren oder unbeliebten Apps, die wir besser und günstiger machen können?$t$),
  ($t$App-Entwicklung mit KI$t$, 2, $t$Würden Kunden zu einem kleinen, neuen Anbieter wechseln?$t$),
  ($t$App-Entwicklung mit KI$t$, 3, $t$Schaffen wir mit KI eine erste Version in überschaubarer Zeit?$t$),
  ($t$App-Entwicklung mit KI$t$, 4, $t$Können wir Sicherheit, Datenschutz und Updates dauerhaft gewährleisten?$t$),
  ($t$App-Entwicklung mit KI$t$, 5, $t$Erreichen wir erste Kunden über unsere Firma und Vereine?$t$),
  ($t$App-Entwicklung mit KI$t$, 6, $t$Was kostet uns ein neuer Kunde in Werbung und Vertrieb?$t$),
  ($t$App-Entwicklung mit KI$t$, 7, $t$Ist der Support neben allem anderen zeitlich machbar?$t$),
  ($t$App-Entwicklung mit KI$t$, 8, $t$Passt eher eine große eigene App oder mehrere kleine Apps zu uns?$t$),
  ($t$App-Entwicklung mit KI$t$, 9, $t$Wie hoch sind die laufenden Kosten (Server, App-Stores, Versicherung)?$t$),
  ($t$App-Entwicklung mit KI$t$, 10, $t$Können wir unsere eigenen Ideen (Minimarkt, Logistik) als erste Referenz nutzen?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 1, $t$Finden wir mit dem Produkt-Raster ein Produkt mit Nachfrage und wenig Konkurrenz?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 2, $t$Erreicht das Produkt mindestens 40 % Marge vor Werbung und 20 % netto zum Start?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 3, $t$Finden wir einen zuverlässigen Lieferanten mit guter Qualität?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 4, $t$Sind die rechtlichen Pflichten beherrschbar (Produktsicherheit, Verpackungsregister, ggf. CE)?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 5, $t$Können wir uns vom Wettbewerb abheben (Verbesserung, Set, Marke)?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 6, $t$Reichen 10–30 T€ für die erste Ware inklusive Werbung?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 7, $t$Wie hoch ist das Risiko von Restbeständen, wenn sich das Produkt schlecht verkauft?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 8, $t$Wie abhängig sind wir von Amazon – und wie gut funktionieren Onlineshop und B2B als zweites Standbein?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 9, $t$Wie viel eigene Zeit kosten Einkauf, Listing, Werbung und Kundenservice?$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, 10, $t$Lässt sich daraus eine Marke mit mehreren Produkten aufbauen?$t$)
) as v(title, sort, question)
join public.ideas i on lower(i.title) = lower(v.title)
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.idea_checks c where c.idea_id = i.id);
