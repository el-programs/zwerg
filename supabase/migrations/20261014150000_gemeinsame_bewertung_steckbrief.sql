-- Zwerg · Gemeinsame Bewertung in einem Durchgang, Fragen mit Antwortskala, Steckbrief je Idee

-- 1) Gemeinsame Bewertung ohne vorherige Einzelabgabe
drop policy "Gemeinsame Bewertung lesen" on public.joint_ratings;
drop policy "Gemeinsame Bewertung schreiben" on public.joint_ratings;
drop policy "Gemeinsame Bewertung ändern" on public.joint_ratings;
create policy "Gemeinsame Bewertung lesen" on public.joint_ratings
  for select to authenticated using (public.is_member());
create policy "Gemeinsame Bewertung schreiben" on public.joint_ratings
  for insert to authenticated with check (public.is_member());
create policy "Gemeinsame Bewertung ändern" on public.joint_ratings
  for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Gemeinsame Bewertung löschen" on public.joint_ratings
  for delete to authenticated using (public.is_member());
grant delete on public.joint_ratings to authenticated;

drop policy "Endbewertung lesen" on public.idea_evaluations;
drop policy "Endbewertung anlegen" on public.idea_evaluations;
drop policy "Endbewertung ändern" on public.idea_evaluations;
create policy "Endbewertung lesen" on public.idea_evaluations
  for select to authenticated using (public.is_member());
create policy "Endbewertung anlegen" on public.idea_evaluations
  for insert to authenticated with check (public.is_member());
create policy "Endbewertung ändern" on public.idea_evaluations
  for update to authenticated using (public.is_member()) with check (public.is_member());

-- 2) Bewertungsfaktoren: Frage (in „description“) und Antwortskala
--    menge     = keine · wenig · mittel · viel · sehr viel
--    qualitaet = sehr schlecht · schlecht · mittel · gut · sehr gut
--    Gespeichert wird weiter 1–5; gerechnet wird mit 0–4 Punkten (Wert − 1).
alter table public.criteria add column scale text not null default 'qualitaet'
  check (scale in ('menge', 'qualitaet'));

update public.criteria c set description = v.frage, scale = v.skala
from (values
  ('Leidenschaft/Interesse', 'Wie viel Leidenschaft haben wir für die Idee?', 'menge'),
  ('Finanzen/Investment', 'Wie gut können wir den Kapitalbedarf stemmen?', 'qualitaet'),
  ('Qualifizierung', 'Wie viel des nötigen Wissens bringen wir mit?', 'menge'),
  ('Komplexität der Prozesskette', 'Wie einfach sind Einkauf, Herstellung und Vertrieb?', 'qualitaet'),
  ('Skalierbarkeit/Start', 'Wie gut lässt sich klein starten und später wachsen?', 'qualitaet'),
  ('Selbständigkeit/Partnerschaften/Hilfe', 'Wie gut können wir es selbst oder mit Partnern stemmen?', 'qualitaet'),
  ('Zukunftssicherheit', 'Wie zukunftssicher ist das Geschäft?', 'qualitaet'),
  ('Marge', 'Wie viel Marge bleibt pro Verkauf?', 'menge'),
  ('Moral/Ethik/Umwelt', 'Wie gut können wir guten Gewissens dahinterstehen?', 'qualitaet'),
  ('Aktionsradius/Standort', 'Wie gut passt das Einzugsgebiet zu unserem Standort?', 'qualitaet'),
  ('Marktgröße/Nachfrage', 'Wie viel zahlungsbereite Nachfrage gibt es?', 'menge'),
  ('Wettbewerb/Alleinstellung', 'Wie gut können wir uns vom Wettbewerb abheben?', 'qualitaet'),
  ('Zeitaufwand neben dem Hauptgeschäft', 'Wie gut lässt es sich neben dem Hauptgeschäft betreiben?', 'qualitaet'),
  ('Risiko/Kapitalbindung', 'Wie gut können wir Risiko und Kapitalbindung tragen?', 'qualitaet'),
  ('Rechtliche Hürden', 'Wie einfach sind Genehmigungen, Haftung und Vorschriften?', 'qualitaet'),
  ('Testbarkeit', 'Wie leicht lässt sich die Idee testen?', 'qualitaet')
) as v(name, frage, skala)
where c.name = v.name;

-- 3) Steckbrief je Idee
alter table public.ideas
  add column benefit       text   not null default '' check (length(benefit) <= 5000),
  add column offer         text   not null default '' check (length(offer) <= 5000),
  add column customers     text   not null default '' check (length(customers) <= 5000),
  add column revenue_model text[] not null default '{}',
  add column revenue_note  text   not null default '' check (length(revenue_note) <= 2000),
  add column first_test    text   not null default '' check (length(first_test) <= 5000),
  add column origin        text   not null default '' check (length(origin) <= 5000);
