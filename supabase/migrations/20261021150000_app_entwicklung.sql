-- Zwerg · Neue Gruppe „Eigene Software und Apps“ und die Idee „App-Entwicklung mit KI“ (angelegt von Florian)

insert into public.business_models (name, sort)
select $t$Eigene Software und Apps$t$, 100
where not exists (select 1 from public.business_models where name = $t$Eigene Software und Apps$t$);

insert into public.ideas (title, description, search_field_id, business_model_id, benefit, offer, customers,
                          revenue_model, revenue_note, first_test, origin, created_by, updated_by)
select $t$App-Entwicklung mit KI$t$,
       $t$MÖGLICHE ANWENDUNGEN (noch offen)
- Gerüstbau-App: Aufmaß, Gerüstbuch und Prüfprotokolle, Freigabe per Foto, Materialliste, Abrechnung nach Standzeit
- Vereins-App: Mitglieder, Beiträge, Termine, Platz- und Hallenbelegung, Nachrichten an Mitglieder
- Weitere Nischen: Branchen mit viel Papier und ohne passende Software

VORGEHEN
1. Eine Nische wählen, in der wir Kunden direkt erreichen (z. B. über unsere jetzige Firma oder eigene Vereine)
2. Mit 5–10 möglichen Kunden die größten Probleme klären
3. Kleine erste Version mit KI-Unterstützung bauen, mit 2–3 Pilotkunden testen
4. Erst danach Preise festlegen und ausbauen

WAS PRÜFEN
- Wettbewerb: Gibt es schon Branchensoftware? Was kostet sie, was fehlt?
- Datenschutz (DSGVO): Auftragsverarbeitung, Hosting in der EU
- Laufender Aufwand: Support, Updates, Betrieb – ein Abo muss das tragen
- Haftung: AGB, Haftungsbegrenzung, ggf. IT-Haftpflichtversicherung
- Abhängigkeit von KI-Werkzeugen: Code muss uns gehören und verständlich bleiben$t$,
       (select id from public.search_fields where name = $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$ and not archived limit 1),
       (select id from public.business_models where name = $t$Eigene Software und Apps$t$),
       $t$Kleine Firmen und Vereine bekommen eine einfache, passgenaue App für ihre Abläufe statt Papier, Excel oder teurer Standardsoftware, die nicht passt.$t$,
       $t$Eigene Apps für eine bestimmte Branche oder Zielgruppe entwickeln, mit KI-Unterstützung schnell und günstig umgesetzt. Beispiele: Gerüstbau-App für Gerüstbaufirmen, Management-App für Vereine.$t$,
       $t$Je nach Anwendung: z. B. Gerüstbaufirmen, kleine und größere Vereine, andere Handwerks- und Dienstleistungsbetriebe$t$,
       array[$t$Abo$t$,$t$Dienstleistung$t$]::text[],
       $t$Monatliches Abo je Firma oder Verein, dazu Einrichtung und Anpassungen gegen Pauschale$t$,
       $t$Fünf Gerüstbaufirmen oder Vereinsvorstände fragen, was sie heute am meisten Zeit kostet, und eine klickbare Vorschau zeigen.$t$,
       $t$Idee von Florian; Erfahrungen aus der Entwicklung von Zwerg zeigen, wie schnell sich mit KI eine App bauen lässt.$t$,
       p.id, p.id
from (select id from public.profiles where slug = 'florian') p
where not exists (select 1 from public.ideas i where lower(i.title) = lower($t$App-Entwicklung mit KI$t$));
