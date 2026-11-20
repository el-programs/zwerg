-- Zwerg · Gründungscheck (Phase 2b) mit Prüfpunkten je Idee (Gründungsplan, Budget und Kalkulation,
-- Klärungspunkte, Go/No-Go) und einer Kostentabelle. „App-Entwicklung mit KI“ wird zur „KI-Firma“ (Arbeitstitel)
-- mit neuem Steckbrief; die Beispielkataloge stehen gegliedert (## Stufe, ### Gruppe) in „Weitere Gedanken“.

create table public.idea_steps (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  section    text not null check (section in ('plan', 'budget', 'klaerung', 'gonogo')),
  sort       integer not null default 0,
  title      text not null check (length(title) between 1 and 500),
  status     text not null default 'offen' check (status in ('offen', 'in_arbeit', 'erledigt', 'ja', 'nein')),
  result     text not null default '' check (length(result) <= 20000),
  assignee   uuid references public.profiles (id) on delete set null,
  due_date   date,
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  updated_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idea_steps_idea_idx on public.idea_steps (idea_id, section, sort);

create table public.idea_costs (
  id         uuid primary key default gen_random_uuid(),
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  sort       integer not null default 0,
  kind       text not null default 'einmalig' check (kind in ('einmalig', 'monatlich')),
  label      text not null check (length(label) between 1 and 300),
  amount     numeric(12, 2),
  note       text not null default '' check (length(note) <= 2000),
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idea_costs_idea_idx on public.idea_costs (idea_id, sort);

alter table public.idea_steps enable row level security;
alter table public.idea_costs enable row level security;
create policy "Mitglieder lesen Gründungscheck" on public.idea_steps for select to authenticated using (public.is_member());
create policy "Mitglieder legen Gründungscheck an" on public.idea_steps for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Gründungscheck" on public.idea_steps for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Gründungscheck" on public.idea_steps for delete to authenticated using (public.is_member());
create policy "Mitglieder lesen Kosten" on public.idea_costs for select to authenticated using (public.is_member());
create policy "Mitglieder legen Kosten an" on public.idea_costs for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Kosten" on public.idea_costs for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Kosten" on public.idea_costs for delete to authenticated using (public.is_member());
grant select, insert, update, delete on public.idea_steps, public.idea_costs to authenticated;
grant all on public.idea_steps, public.idea_costs to service_role;
alter publication supabase_realtime add table public.idea_steps, public.idea_costs;

-- „App-Entwicklung mit KI“ wird zur „KI-Firma“: neuer Titel und neuer Steckbrief
update public.ideas set
  title = $t$KI-Firma$t$,
  benefit = $t$Firmen, Vereine, Selbständige und Privatkunden bekommen digitale Lösungen schnell, günstig und passgenau – möglich, weil wir KI konsequent als Werkzeug einsetzen.$t$,
  offer = $t$Kleine bis leichte digitale Umsetzungen mit KI in vier Bereichen: Webseiten & Landingpages, Medien & Design (Bild, Grafik, Ton, Video), kleine Apps & Tools, Büro-Unterstützung. Aufbau in drei Stufen: Dienstleistung, digitale Produkte, eigene Software im Abo.$t$,
  customers = $t$Alle: kleine Firmen und Handwerk, Vereine und Organisationen, Selbständige und Gründer, Privatkunden – Dienstleistungen regional, Produkte online deutschlandweit$t$,
  revenue_model = array[$t$Dienstleistung$t$, $t$Verkauf$t$, $t$Abo$t$]::text[],
  revenue_note = $t$Pakete zum Festpreis plus Aufwand für Sonderwünsche; Verkauf digitaler Produkte im eigenen Shop; Abo für eigene Software mit Testzugang oder Einrichtung$t$,
  first_test = $t$Je Produktbereich ein Probeprojekt (z. B. für Bekannte) mit gemessenem Zeitaufwand, dazu ein Preisvergleich mit anderen Anbietern.$t$,
  origin = $t$Ursprünglich „App-Entwicklung mit KI“ (Idee von Florian), erweitert im Brainstorming „KI für digitale Produkte“ zu einer eigenständigen KI-Firma. Erfahrung aus der Entwicklung von Zwerg.$t$,
  description = $t$## Stand zur Gründung
- Eigene Website und 1–2 Social-Media-Kanäle
- Vier Produktbereiche: Webseiten & Landingpages · Medien & Design (Bild, Grafik, Ton, Video) · kleine Apps & Tools · Büro-Unterstützung (Name noch offen)
- Offene Entscheidung: eine große eigene App oder 1–3 kleine Apps als günstige Alternative zu bestehenden – vor der Gründung entwickelt

## Rahmen
- Eigenständige neue Firma, gegründet vor dem ersten Auftrag; Rechtsform offen (Haftungsbegrenzung sinnvoll, z. B. UG)
- Teilzeit 15–30 Std./Woche, Startkapital 5–20 T€
- KI steht im Auftritt im Mittelpunkt
- Kunden: alle – Dienstleistungen regional, Produkte online deutschlandweit
- Einnahmen kurz- und langfristig: Aufträge, Produktverkäufe, Abos

## Stufe 1 – Dienstleistung (Beispiele)
Pakete zum Festpreis, Sonderwünsche nach Aufwand. Kunden über Online-Sichtbarkeit. Weiter zu Stufe 2, wenn sich Anfragen wiederholen.
### Websites
- Visitenkarten-Website (1 Seite) für Selbständige und Handwerker
- Firmenwebsite mit 5–10 Seiten, Kontaktformular, Google-Profil
- Landingpage für Produkt, Aktion oder Veranstaltung
- Vereinswebsite mit Terminen, Mannschaften, Mitgliedsantrag
- Website-Relaunch: alte Seite modernisieren, Texte überarbeiten
- Mehrsprachige Website mit KI-Übersetzung und Prüfung
- Barrierefreiheits-Check und Anpassung
- Website-Pflege im Monatspaket
### Onlineshops
- Kleiner Shop für Hofläden, Handwerker, Hobbyverkäufer
- Shop-Einrichtung auf fertigen Systemen (z. B. Shopify, WooCommerce)
- Produktdaten anlegen: Texte, Kategorien, Varianten, Bilder in großer Menge
- Anbindung an Marktplätze (Amazon, eBay, Etsy)
- Rechtssichere Grundausstattung über Partner (Impressum, AGB, Datenschutz)
- Gutschein- und Buchungsshop für Dienstleister
### Texte mit KI
- Website-Texte, Über-uns, Leistungsbeschreibungen
- Produktbeschreibungen in großer Menge, auch für Marktplätze
- Suchmaschinen-Optimierung: Seitentitel, Beschreibungen, Fachartikel
- Newsletter und Kundenmailings im Monatspaket
- Stellenanzeigen und Karriereseiten
- Präsentationen, Flyer- und Broschürentexte
- Social-Media-Beiträge als Monatspaket
### Medien und Design
- Produktfotos auf neuem Hintergrund, Produktbilder in Serie
- Teamfotos und Porträts aufbereiten, einheitlicher Stil
- Grafiken für Social Media, Banner, Anzeigen
- Logos und kleine Erscheinungsbilder
- Illustrationen für Websites, Flyer, Präsentationen
- Bildbearbeitung: alte Fotos restaurieren, Objekte entfernen
- Kurze Produkt- und Imagevideos, Erklär- und Schulungsvideos mit KI-Sprecher
- Ton: Jingles, Sprachaufnahmen, Podcast-Schnitt, Transkripte
### Kleine Apps und Tools
- Interne Werkzeuge: Excel-Ersatz, Formulare, Freigaben, Checklisten
- Prototypen und Klick-Dummys für Gründer und Firmen
- Rechner und Generatoren (Angebots-, Preisrechner, QR-Generator)
- Kleine Web-Apps für einen klar umrissenen Zweck
### Büro-Unterstützung
- Abläufe automatisieren: Angebote, Rechnungen, E-Mails, Ablage
- Vorlagen und digitale Formulare
- Dokumente automatisch auslesen (Lieferscheine, Rechnungen)
- Digitale Organisation: Ablage, Kalender, Aufgaben
### Rund um die Online-Präsenz
- Google-Unternehmensprofil einrichten und pflegen
- Antworten auf Google-Bewertungen
- QR-Codes, digitale Speisekarten, digitale Visitenkarten
- Domain, E-Mail-Postfächer und Hosting einrichten
### Paket-Beispiele
- „Start“: Visitenkarten-Website, Google-Profil, 5 Produktfotos
- „Shop Start“: kleiner Shop mit bis zu 30 Produkten, Texten und Bildern
- „Sichtbar“: monatlich 4 Social-Media-Beiträge, 1 Newsletter, Bewertungsantworten
- „Relaunch“: bestehende Website neu, mit neuen Texten und Bildern

## Stufe 2 – Digitale Produkte (Beispiele)
Verkauf im eigenen Shop und an Dienstleistungskunden. Trägt, wenn sich Produkte ohne unser Zutun verkaufen.
### Vorlagen
- Excel- und Google-Sheets-Vorlagen: Haushaltsbuch, Angebot und Rechnung, Projektplan, Urlaubsplaner
- Notion-Vorlagen: Firmen-Wiki, Aufgabenverwaltung, Content-Planer
- Checklisten: Gründung, Website-Start, Datenschutz für Vereine
- Dokumentvorlagen: Bewerbung, Lebenslauf, Vereinsprotokoll, Präsentationen
- Canva-Vorlagen: Social-Media-Beiträge, Flyer, Speisekarten
### Prompt- und Workflow-Pakete
- KI-Prompts für Berufe: Handwerker, Makler, Vereinsvorstände, Lehrer, Gastronomen
- Fertige Abläufe, z. B. „Produktbeschreibungen in Serie“
- Prompt-Sammlungen für Bildgeneratoren
### Kurse
- „KI für Selbständige“, „KI im Büro“, „KI im Verein“
- „Eigene Website mit KI in einem Wochenende“
- „Produktfotos mit dem Handy und KI“
- Mini-Kurse als Einstieg, Aufbaukurse als Paket
- Aufgezeichnete Workshops als Kurs
### E-Books und Ratgeber
- Praxisratgeber zu KI-Werkzeugen für bestimmte Berufe
- Leitfäden: „Onlineshop starten“, „Google-Profil richtig nutzen“
- Kurzratgeber als Einstieg, ausführliches Handbuch
### Grafiken und Druckvorlagen
- Icon-Pakete, Illustrationen, Hintergründe
- Poster und Wandbilder zum Selbstdrucken
- Etiketten, Aufkleber, Einladungen, Kalender, Planer
- Mockups zum Präsentieren von Produkten
### Bündel und Abos
- Themenpakete, z. B. „Alles für den Vereinsauftritt“
- Mitgliedschaft mit monatlich neuen Vorlagen und Prompts

## Stufe 3 – Eigene Software im Abo (Beispiele)
Entsteht aus wiederholten Kundenwünschen und einer Nischen-Analyse. Verkauf online mit Testzugang oder mit Einrichtung; ab einer Kundenzahl mit Mitarbeiter für Support und Entwicklung.
### Branchen- und Vereinssoftware
- Vereinsverwaltung: Mitglieder, Beiträge, Termine, Belegung, Nachrichten
- Nischen-Apps für Branchen mit teurer Software (z. B. Gerüstbau, Gebäudereinigung, Hausverwaltung, Fahr- und Tanzschulen)
- Schichtplanung für kleine Betriebe
### Buchung und Termine
- Online-Terminbuchung für Friseure, Praxen, Werkstätten, Berater
- Raum- und Gerätebuchung für Vereine, Firmen, Gemeinden
- Kursverwaltung mit Anmeldung, Warteliste, Bezahlung
### Prüfung und Dokumentation
- Prüf- und Wartungsprotokolle per QR-Code mit Erinnerung
- Digitale Checklisten und Abnahmeprotokolle mit Foto und Unterschrift
- Mängelmanagement für Bau und Hausverwaltung
### Büro und Finanzen
- Angebots- und Rechnungs-App mit Spracheingabe
- Zeiterfassung für kleine Teams
- Belegerfassung per Foto mit Weitergabe an den Steuerberater
### Personal
- Bewerbermanagement mit KI-Vorauswahl
- Einarbeitungs-Checklisten und Mitarbeiter-Wissensdatenbank
### Kleine Werkzeuge
- Browser-Erweiterungen (Textverbesserung, Übersetzung, Formular-Ausfüller)
- Mini-Apps mit Einmalpreis

## Weitere Möglichkeiten (außerhalb der Stufen)
- KI-Wissensdatenbank für Firmen, Fördermittel- und Ausschreibungssuche
- KI-Einführung als Beratung, Workshops, KI-Sprechstunde im Abo, Begleitung zu Datenschutz und KI-Verordnung
- Übersetzungen und Lokalisierung mit Prüfung
- Dashboards, Marktrecherche, Auswertung von Bewertungen und Umfragen
- KI-Gründerwerkstatt: Ideen anderer zu einem fertigen Prototyp bringen
- Personalisierte Produkte (Kinderbücher, Lieder, Poster)$t$,
  updated_at = now()
where lower(title) = lower($t$App-Entwicklung mit KI$t$);

-- Prüfpunkte des Gründungschecks für die KI-Firma
insert into public.idea_steps (idea_id, section, sort, title, created_by)
select i.id, v.section, v.sort, v.title, p.id
from (values
  ($t$plan$t$, 1, $t$Startangebot: je Produktbereich 2–3 Einstiegsangebote mit Preisrahmen festlegen$t$),
  ($t$plan$t$, 2, $t$Namen für den Bereich „Büro-Unterstützung“ festlegen$t$),
  ($t$plan$t$, 3, $t$Markt- und Preis-Check je Produktbereich: Was verlangen andere, gibt es Nachfrage?$t$),
  ($t$plan$t$, 4, $t$Probeprojekt je Produktbereich mit gemessenem Zeitaufwand$t$),
  ($t$plan$t$, 5, $t$App-Recherche: Kandidaten für 1–3 kleine Apps und für eine große eigene App$t$),
  ($t$plan$t$, 6, $t$Auswahlkriterien für Apps anwenden: Zahlungsbereitschaft, Konkurrenzpreis, Bewertungen, Aufwand, rechtliche Abgrenzung, Vertriebsweg$t$),
  ($t$plan$t$, 7, $t$Entscheidung: große eigene App oder 1–3 kleine – und welche$t$),
  ($t$plan$t$, 8, $t$Fahrplan: Schritte bis zur Gründung in Reihenfolge (Angebot, Apps, Website, Social Media, Vorlagen, Gründung)$t$),
  ($t$plan$t$, 9, $t$Website und 1–2 Social-Media-Kanäle planen$t$),
  ($t$plan$t$, 10, $t$Zeitplan: Dauer je Schritt, Meilensteine und Gründungstermin$t$),
  ($t$budget$t$, 1, $t$Budget bis zur Gründung (Kostentabelle „einmalig“)$t$),
  ($t$budget$t$, 2, $t$Laufende Kosten nach der Gründung (Kostentabelle „monatlich“)$t$),
  ($t$budget$t$, 3, $t$Wie viele Monate halten wir ohne Umsatz durch?$t$),
  ($t$budget$t$, 4, $t$Preiskalkulation der Einstiegsangebote auf Basis der Probeprojekte$t$),
  ($t$budget$t$, 5, $t$Vorsichtige Umsatzerwartung für die ersten Monate$t$),
  ($t$klaerung$t$, 1, $t$Jetzige Firma: Wettbewerbsverbot und Nebentätigkeit prüfen$t$),
  ($t$klaerung$t$, 2, $t$Rechtsform mit dem Steuerberater klären$t$),
  ($t$klaerung$t$, 3, $t$Versicherung anfragen (Vermögensschaden- bzw. IT-Haftpflicht)$t$),
  ($t$klaerung$t$, 4, $t$Name, Marke und Domain auf Verfügbarkeit prüfen$t$),
  ($t$klaerung$t$, 5, $t$App-Stores: Firmenkonto, D-U-N-S-Nummer, Web-App als Alternative$t$),
  ($t$klaerung$t$, 6, $t$Recht: AGB, Datenschutz, Urheberrecht und Kennzeichnung bei KI-Inhalten$t$),
  ($t$gonogo$t$, 1, $t$Das Budget bis zur Gründung passt in unseren Rahmen (5–20 T€)$t$),
  ($t$gonogo$t$, 2, $t$Der Gründungstermin ist bei unserem Zeitbudget realistisch$t$),
  ($t$gonogo$t$, 3, $t$Die App-Entscheidung ist begründet und umsetzbar$t$),
  ($t$gonogo$t$, 4, $t$Die Probeprojekte zeigen, dass die Preise aufgehen$t$),
  ($t$gonogo$t$, 5, $t$Es gibt keine Hürde durch die jetzige Firma$t$)
) as v(section, sort, title)
join public.ideas i on i.title = $t$KI-Firma$t$
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.idea_steps s where s.idea_id = i.id);

-- Typische Kostenpositionen (Beträge tragt ihr selbst ein)
insert into public.idea_costs (idea_id, kind, sort, label, created_by)
select i.id, v.kind, v.sort, v.label, p.id
from (values
  ($t$einmalig$t$, 1, $t$KI-Werkzeuge und Software (Einrichtung, Jahreslizenzen)$t$),
  ($t$einmalig$t$, 2, $t$Logo und Erscheinungsbild$t$),
  ($t$einmalig$t$, 3, $t$Eigene Website (Domain, Vorlage, Einrichtung)$t$),
  ($t$einmalig$t$, 4, $t$Rechtsberatung und Vorlagen (AGB, Datenschutz, Verträge)$t$),
  ($t$einmalig$t$, 5, $t$Steuerberater (Gründungsberatung)$t$),
  ($t$einmalig$t$, 6, $t$Notar und Handelsregister$t$),
  ($t$einmalig$t$, 7, $t$Stammkapital (Einlage, wird nicht verbraucht)$t$),
  ($t$einmalig$t$, 8, $t$Markenanmeldung$t$),
  ($t$einmalig$t$, 9, $t$App-Store-Konten (Apple jährlich, Google einmalig)$t$),
  ($t$einmalig$t$, 10, $t$Hardware (Rechner, Mikrofon, Kamera)$t$),
  ($t$monatlich$t$, 11, $t$KI-Abos$t$),
  ($t$monatlich$t$, 12, $t$Hosting, Server, Datenbank$t$),
  ($t$monatlich$t$, 13, $t$Versicherung$t$),
  ($t$monatlich$t$, 14, $t$Steuerberater und Buchhaltung$t$),
  ($t$monatlich$t$, 15, $t$Software (Buchhaltung, Design, Büro)$t$),
  ($t$monatlich$t$, 16, $t$Werbung und Social Media$t$),
  ($t$monatlich$t$, 17, $t$Telefon und Internet$t$)
) as v(kind, sort, label)
join public.ideas i on i.title = $t$KI-Firma$t$
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.idea_costs c where c.idea_id = i.id);
