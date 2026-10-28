-- Zwerg · Steckbrief für „Bühnen und Technik Planung & Beratung“ (aus dem Interview vom 28.10.2026).
-- Nur leere Felder werden gefüllt; was schon eingetragen ist, bleibt erhalten. Dazu passende Synergien.

update public.ideas set
  benefit = case when coalesce(benefit, '') = '' then $t$Kommunen, Schulen, Kulturhäuser und Veranstalter bekommen Licht-, Ton- und Bühnentechnik, die zu ihrem Bedarf passt, sicher ist und im Budget bleibt – geplant von einem unabhängigen Ansprechpartner statt vom Verkäufer eines Herstellers.$t$ else benefit end,
  offer = case when coalesce(offer, '') = '' then $t$Planung und Beratung für Licht-, Ton- und mobile Bühnentechnik: Bestandsaufnahme, Konzept, CAD-Pläne, Ausschreibungsunterlagen, Bauleitung und Abnahme. Später dazu: Ausführung mit eigenem Team, Mietpark mit Selbstabholung und Schulungen zur sicheren Bedienung.$t$ else offer end,
  customers = case when coalesce(customers, '') = '' then $t$Kommunen, Schulen und Stadthallen; Theater und Kulturhäuser; Architekten und Planer (als Fachplaner im Bauprojekt); Eventfirmen und Veranstalter in der Region$t$ else customers end,
  revenue_model = case when coalesce(cardinality(revenue_model), 0) = 0 then array[$t$Dienstleistung$t$, $t$Miete$t$]::text[] else revenue_model end,
  revenue_note = case when coalesce(revenue_note, '') = '' then $t$Honorar nach Stunden oder Pauschale je Projekt, Miete für Technikpakete, Schulungen je Teilnehmer$t$ else revenue_note end,
  first_test = case when coalesce(first_test, '') = '' then $t$Zuerst mit Alex und Jonathan klären, ob und wie sie mitmachen. Dann drei Stadthallen, Schulen oder Kulturhäuser in der Region anschreiben, eine kostenlose Bestandsaufnahme ihrer Technik anbieten und zählen, wie viele daraus einen bezahlten Auftrag machen würden.$t$ else first_test end,
  origin = case when coalesce(origin, '') = '' then $t$Idee von Igor; das Fachwissen bringen Alex und Jonathan mit (Fachkräfte für Veranstaltungstechnik).$t$ else origin end,
  description = case when coalesce(description, '') = '' then $t$AUFBAU IN STUFEN
1. Start: Planung und Beratung – wenig Kapital, nutzt das Fachwissen von Alex und Jonathan
2. Dann: Bauleitung und Abnahme, Schulungen für Hausmeister, Lehrkräfte und Vereine
3. Später: Ausführung mit eigenem Team (Synergie zum Handwerksbetrieb mit Hilfskräften), Mietpark mit Selbstabholung für Vereine und Schulen

OFFENE PUNKTE
- Rolle von Alex und Jonathan klären: Partner, Angestellte oder freie Mitarbeiter
- Qualifikation: Für bestimmte Aufgaben (z. B. Verantwortliche für Veranstaltungstechnik nach Versammlungsstättenverordnung, Planung für öffentliche Bauherren) wird oft ein Meister oder Ingenieur verlangt – prüfen, wo die Fachkraft-Ausbildung reicht und wo Weiterbildung nötig ist
- Haftung: Berufshaftpflicht für Planer, klare Verträge zur Abgrenzung von Planung und Ausführung
- Kundenkontakte fehlen noch: über das Netzwerk von Alex und Jonathan, Architekturbüros und Kommunen aufbauen
- Öffentliche Aufträge laufen oft über Ausschreibungen – Vergabeplattformen beobachten
- Arbeitszeit: Planung tagsüber; Abnahmen und Einweisungen am Veranstaltungstag nur als Ausnahme

WEITERE MÖGLICHKEITEN
- Prüfdienst für Bühnen-, Licht- und Tontechnik (DGUV Vorschrift 17/18) als wiederkehrender Umsatz
- Umrüstung alter Saalbeleuchtung auf LED, oft gefördert$t$ else description end,
  search_field_id = coalesce(search_field_id, (select id from public.search_fields where name = $t$N - Freiberufliche, wissenschaftliche und technische Dienstleistungen - Tertiär$t$ and not archived limit 1)),
  business_model_id = coalesce(business_model_id, (select id from public.business_models where name = $t$Technische Dienstleistungen mit CAD$t$)),
  updated_at = now()
where lower(title) = lower($t$Bühnen und Technik Planung & Beratung$t$);

insert into public.idea_synergies (idea_a, idea_b, note, created_by)
select least(a.id, b.id), greatest(a.id, b.id), v.note, p.id
from (values
  ($t$Handwerksbetrieb mit Hilfskräften$t$, $t$Montage und Einbau der geplanten Technik durch das eigene Team$t$),
  ($t$Aufmaß und digitale Bestandspläne$t$, $t$Bestandsaufnahme von Sälen und Bühnen im CAD als erster Schritt jeder Planung$t$),
  ($t$Werkzeugverleih per Schließfach-Automat$t$, $t$Gleiches Prinzip für den Mietpark: Technikpakete tagsüber zur Selbstabholung$t$)
) as v(other, note)
join public.ideas a on lower(a.title) = lower($t$Bühnen und Technik Planung & Beratung$t$)
join public.ideas b on b.title = v.other
cross join (select id from public.profiles where slug = 'igor') p
on conflict (idea_a, idea_b) do nothing;
