-- Zwerg · Brainstorming „Was passiert nach 20 Uhr?“: fünf Ideen mit Steckbrief (angelegt von Igor, landen in der Vorauswahl) und Synergien.

insert into public.ideas (title, description, search_field_id, business_model_id, benefit, offer, customers,
                          revenue_model, revenue_note, first_test, origin, created_by, updated_by, created_at, updated_at)
select v.title, v.description,
       (select id from public.search_fields where name = v.branche and not archived limit 1),
       (select id from public.business_models where name = v.gruppe),
       v.benefit, v.offer, v.customers, v.revenue_model, v.revenue_note, v.first_test,
       $t$Brainstorming „Was passiert nach 20 Uhr?“ – in Bayern hat abends fast alles geschlossen.$t$, p.id, p.id,
       now() - make_interval(secs => v.pos), now() - make_interval(secs => v.pos)
from (values
  ($t$24/7-Minimarkt ohne Personal$t$, $t$WAS PRÜFEN
- Bayerisches Ladenschlussgesetz: Regeln für personallose digitale Kleinstläden (Fläche, Sonn- und Feiertage) genau klären
- Sortiment: Alkohol und Tabak nur mit Altersprüfung (z. B. per Ausweis-App)
- Technik: Zugangssystem, Selbstbedienungskasse, Kameras, Warenwirtschaft mit Nachbestellung
- Befüllung tagsüber durch Minijobber; Diebstahlquote realistisch einplanen
- Förderung: Bayern fördert Dorfläden und Nahversorgung; Standort ggf. von der Gemeinde$t$, $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$, $t$Vermietung, Sharing und Selbstbedienung$t$, $t$Wer nach 20 Uhr oder am Wochenende etwas braucht, steht in Bayern vor verschlossenen Türen. Dörfer ohne eigenen Laden bekommen wieder eine Nahversorgung.$t$, $t$Kleiner Laden oder Container mit Lebensmitteln, Getränken, Drogerieartikeln und regionalen Produkten. Zugang per App oder Bankkarte, Bezahlung an der Selbstbedienungskasse, Videoüberwachung.$t$, $t$Berufstätige, Pendler, Dörfer ohne Laden, Gemeinden (oft mit Förderung), Neubaugebiete$t$, array[$t$Verkauf$t$]::text[], $t$Marge auf die Waren; ggf. Zuschuss der Gemeinde für die Nahversorgung$t$, $t$Mit zwei Gemeinden ohne Laden sprechen und eine Umfrage machen, was Bürger abends am häufigsten vermissen.$t$, 0),
  ($t$Abholstationen für örtliche Geschäfte$t$, $t$WAS PRÜFEN
- Apotheken: Abgabe verschreibungspflichtiger Medikamente nur unter strengen Bedingungen
- Kühlfächer für Lebensmittel und Medikamente
- Hersteller von Schließfachanlagen vergleichen (Kauf oder Miete), Software mit Codes und Benachrichtigung
- Standortgenehmigung, Strom, Vandalismusschutz$t$, $t$H - Verkehr und Lagerei - Tertiär$t$, $t$Vermietung, Sharing und Selbstbedienung$t$, $t$Kunden holen Bestellungen aus Apotheke, Reinigung, Buchhandlung oder Baumarkt nach Feierabend ab. Händler verkaufen mehr, ohne länger zu öffnen.$t$, $t$Schließfachanlagen an gut erreichbaren Orten (Bahnhof, Parkplatz, Ortsmitte), die mehrere Geschäfte gemeinsam nutzen. Händler legen tagsüber ein, Kunden öffnen per Code rund um die Uhr. Gekühlte Fächer für Lebensmittel.$t$, $t$Örtliche Händler, Apotheken, Reinigungen, Bäcker und Metzger, Hofläden; deren Kunden$t$, array[$t$Abo$t$, $t$Miete$t$]::text[], $t$Monatsgebühr je Händler plus Gebühr je Abholung; Standortmiete teilen$t$, $t$Mit fünf Händlern in einer Ortsmitte sprechen, ob sie eine gemeinsame Station nutzen und was sie zahlen würden.$t$, 1),
  ($t$Räume zur Selbstbuchung$t$, $t$WAS PRÜFEN
- Nutzungsänderung und Lärmschutz: Lage ohne direkte Nachbarn (Gewerbegebiet)
- Hausordnung, Kaution, Kameras im Eingangsbereich, Reinigung am nächsten Tag
- Versammlungsstättenregeln je nach Größe; Brandschutz
- Technik und Licht: Synergie mit „Bühnen und Technik Planung & Beratung“$t$, $t$M - Grundstücks- und Wohnungswesen - Tertiär$t$, $t$Vermietung, Sharing und Selbstbedienung$t$, $t$Abends fehlen Orte zum Feiern, Spielen oder Proben, die man spontan und günstig mieten kann. Die Buchung läuft per App, ohne dass jemand vor Ort sein muss.$t$, $t$Ausgestattete Räume stundenweise per App buchen und per Code öffnen: Party- und Spieleraum, Kinoraum mit Beamer, Proberaum für Bands, Karaoke.$t$, $t$Jugendliche und junge Erwachsene, Familien für Geburtstage, Vereine, Bands, Firmen für Teamabende$t$, array[$t$Miete$t$]::text[], $t$Stundenpreis je Raum, Zusatzpakete (Getränke, Technik, Endreinigung)$t$, $t$Einen Raum probeweise anmieten, auf einer einfachen Buchungsseite anbieten und die Anfragen in vier Wochen zählen.$t$, 2),
  ($t$24/7-Lern- und Arbeitsraum$t$, $t$WAS PRÜFEN
- Standort nahe Hochschule oder Bahnhof
- Zugangssystem, Kameras, Lärmregeln, Reinigung
- Kombinierbar mit den Räumen zur Selbstbuchung (gleiche Technik, gleiche Immobilie)$t$, $t$M - Grundstücks- und Wohnungswesen - Tertiär$t$, $t$Vermietung, Sharing und Selbstbedienung$t$, $t$Studenten, Pendler und Selbständige brauchen einen ruhigen Ort zum Lernen oder Arbeiten – auch nach 20 Uhr, wenn Bibliotheken zu sind.$t$, $t$Arbeitsplätze mit WLAN, Kaffee und Telefonboxen, Zugang rund um die Uhr per App; Tages-, Monats- und Nachtpässe; Besprechungsraum stundenweise.$t$, $t$Studenten und Schüler vor Prüfungen, Pendler im Homeoffice, Selbständige, kleine Firmen$t$, array[$t$Abo$t$, $t$Miete$t$]::text[], $t$Monatsabo, Tagespässe, Raummiete stundenweise$t$, $t$Ein Wochenende lang einen Raum testen und in Hochschul- und Pendlergruppen bewerben.$t$, 3),
  ($t$Notdienst-Vermittlung für Haus und Wohnung$t$, $t$WAS PRÜFEN
- Wir selbst arbeiten tagsüber: Partner übernehmen die Einsätze, die Telefonannahme nachts läuft über einen Callcenter-Partner oder eine Rufumleitung
- Partner sorgfältig prüfen (Ruf der Branche), Festpreise vertraglich sichern
- Haftung als Vermittler, AGB
- Synergie: eigener Handwerksbetrieb als Partner$t$, $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$, $t$Dienstleistungen für Menschen und Haushalte$t$, $t$Wer nachts einen Rohrbruch hat oder sich ausgesperrt hat, findet kaum einen seriösen Notdienst und zahlt oft Wucherpreise. Eine regionale Vermittlung mit geprüften Partnern und festen Preisen schafft Vertrauen.$t$, $t$Regionale Notdienst-Plattform mit Telefonnummer und App: Schlüssel, Rohrbruch, Heizungsausfall, Sturmschaden. Geprüfte Partnerbetriebe mit transparenten Festpreisen.$t$, $t$Haushalte, Hausverwaltungen, Vermieter; Handwerksbetriebe als Partner$t$, array[$t$Provision$t$, $t$Abo$t$]::text[], $t$Vermittlungsprovision je Einsatz, Monatsbeitrag der Partner, Notdienst-Abo für Hausverwaltungen$t$, $t$Mit fünf Handwerksbetrieben sprechen, ob sie nachts Einsätze übernehmen würden, und eine Hausverwaltung fragen, wie sie Notfälle heute löst.$t$, 4)
) as v(title, description, branche, gruppe, benefit, offer, customers, revenue_model, revenue_note, first_test, pos)
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.ideas i where lower(i.title) = lower(v.title));

insert into public.idea_synergies (idea_a, idea_b, note, created_by)
select least(a.id, b.id), greatest(a.id, b.id), v.note, p.id
from (values
  ($t$24/7-Minimarkt ohne Personal$t$, $t$Abholstationen für örtliche Geschäfte$t$, $t$Abholfächer im Minimarkt, gleiche Zugangstechnik und Standorte$t$),
  ($t$Räume zur Selbstbuchung$t$, $t$24/7-Lern- und Arbeitsraum$t$, $t$Gleiche Immobilie und Buchungstechnik; tagsüber arbeiten, abends feiern$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, $t$Räume zur Selbstbuchung$t$, $t$Getränke und Snacks für die Raumgäste aus dem Minimarkt$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, $t$24/7-Mikro-Fitnessstudio ohne Personal$t$, $t$Gleiche Zugangs- und Kameratechnik, gemeinsame Standorte$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, $t$Retouren- und Restpostenhandel$t$, $t$Restposten als günstiges Zusatzsortiment$t$),
  ($t$Abholstationen für örtliche Geschäfte$t$, $t$Werkzeugverleih per Schließfach-Automat$t$, $t$Gleiche Schließfachtechnik und Software$t$),
  ($t$Abholstationen für örtliche Geschäfte$t$, $t$Materialboxen für Handwerker$t$, $t$Gleiches Prinzip: Ausgabe per Schließfach rund um die Uhr$t$),
  ($t$Abholstationen für örtliche Geschäfte$t$, $t$Botendienst für Apotheken und Praxen$t$, $t$Abholstation als Alternative zur Botenfahrt$t$),
  ($t$Abholstationen für örtliche Geschäfte$t$, $t$Hilfsmittel-Service für zu Hause$t$, $t$Kleine Hilfsmittel per Schließfach ausgeben$t$),
  ($t$Räume zur Selbstbuchung$t$, $t$Mietwerkstatt per App (Selbstbedienung)$t$, $t$Gleiches Modell: Räume per App buchen und per Code öffnen$t$),
  ($t$Räume zur Selbstbuchung$t$, $t$Bühnen und Technik Planung & Beratung$t$, $t$Licht- und Tontechnik für die Räume$t$),
  ($t$24/7-Lern- und Arbeitsraum$t$, $t$Mietwerkstatt per App (Selbstbedienung)$t$, $t$Gleiche Buchungs- und Zugangstechnik$t$),
  ($t$24/7-Lern- und Arbeitsraum$t$, $t$App-Entwicklung mit KI$t$, $t$Eigene Buchungs- und Zugangs-App für alle Selbstbedienungsangebote$t$),
  ($t$24/7-Minimarkt ohne Personal$t$, $t$App-Entwicklung mit KI$t$, $t$Eigene App für Zugang, Kasse und Nachbestellung$t$),
  ($t$Notdienst-Vermittlung für Haus und Wohnung$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Eigener Betrieb als Partner für Einsätze$t$),
  ($t$Notdienst-Vermittlung für Haus und Wohnung$t$, $t$Haus-Check im Abo für Eigenheimbesitzer$t$, $t$Notdienst als Zusatzleistung im Haus-Check-Abo$t$),
  ($t$Notdienst-Vermittlung für Haus und Wohnung$t$, $t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$Gleiche Kunden: Hausverwaltungen$t$)
) as v(ta, tb, note)
join public.ideas a on lower(a.title) = lower(v.ta)
join public.ideas b on lower(b.title) = lower(v.tb)
cross join (select id from public.profiles where slug = 'igor') p
on conflict (idea_a, idea_b) do nothing;
