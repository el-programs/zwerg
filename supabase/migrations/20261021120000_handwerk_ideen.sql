-- Zwerg · Drei weitere Ideen in der Gruppe „Handwerk und Bau“ (angelegt von Igor). Vorhandene Titel werden übersprungen.

insert into public.ideas (title, description, search_field_id, business_model_id, benefit, offer, customers,
                          revenue_model, revenue_note, first_test, origin, created_by, updated_by, created_at, updated_at)
select v.title, v.description,
       (select id from public.search_fields where name = $t$F - Baugewerbe - Sekundär$t$ and not archived limit 1),
       (select id from public.business_models where name = $t$Handwerk und Bau$t$),
       v.benefit, v.offer, v.customers, v.revenue_model, v.revenue_note, v.first_test, v.origin, p.id, p.id,
       now() - make_interval(secs => v.pos), now() - make_interval(secs => v.pos)
from (values
  ($t$Baustellenservice$t$, $t$WAS PRÜFEN
- Entsorgung: Abfallarten trennen, Nachweise, ggf. Anzeige als Sammler/Beförderer von Abfällen
- Fahrzeug mit Anhänger, ggf. Führerschein BE; Container über Entsorger statt eigener
- Verkehrssicherung: Absperrungen im öffentlichen Raum brauchen eine Genehmigung (Straßenverkehrsbehörde)
- Versicherung: Betriebshaftpflicht, Berufsgenossenschaft BG BAU
- Zulassungsfrei, keine Meisterpflicht$t$,
   $t$Fachfirmen konzentrieren sich auf ihre eigentliche Arbeit. Die Baustelle ist sauber, sicher und rechtzeitig bereit, teure Fachkräfte räumen nicht mehr selbst auf.$t$,
   $t$Baustellen einrichten (Bauzaun, Schilder, Wege, Container stellen lassen), laufend aufräumen, Bauschutt sortieren und entsorgen, Endreinigung vor der Übergabe.$t$,
   $t$Unsere jetzige Firma, Bauunternehmen und Bauträger, Generalunternehmer in der Region$t$,
   array[$t$Dienstleistung$t$]::text[], $t$Stundensätze oder Pauschale je Baustelle; Rahmenvertrag mit unserer jetzigen Firma$t$,
   $t$Zwei Baustellen der jetzigen Firma mit einer Hilfskraft betreuen und erfassen, wie viele Fachkraft-Stunden dadurch frei werden.$t$,
   $t$Brainstorming Handwerk und Bau; passt zum Handwerksbetrieb mit Hilfskräften und zum geplanten Bauleiter.$t$, 0),
  ($t$Rückbau und Entkernung$t$, $t$WAS PRÜFEN
- Schadstoffe: Asbest, alte Mineralwolle, PAK – nur mit Sachkunde (TRGS 519) und Anzeige; sonst ausschließen und an Fachfirmen geben
- Statik: Keine tragenden Teile ohne Freigabe von Statiker oder Bauleiter entfernen
- Entsorgung: Abfälle trennen (Gewerbeabfallverordnung), Nachweise
- Werkzeug: Abbruchhammer, Staubschutz, Absaugung – mieten statt kaufen am Anfang
- Arbeitsschutz: Unterweisung, Schutzausrüstung, BG BAU
- Zulassungsfrei, soweit nur zurückgebaut wird$t$,
   $t$Sanierungen starten schneller, weil die Räume pünktlich leer und vorbereitet sind. Fachfirmen müssen keine eigenen Leute für Abbrucharbeiten abstellen.$t$,
   $t$Innenräume entkernen: Bodenbeläge, Fliesen, nichttragende Wände, Decken, alte Installationen und Einbauten entfernen. Material sortieren und entsorgen.$t$,
   $t$Unsere jetzige Firma, Bauunternehmen, Sanierer, Hausverwaltungen und private Bauherren vor einer Renovierung$t$,
   array[$t$Dienstleistung$t$]::text[], $t$Pauschale je m² oder je Raum, Entsorgung extra$t$,
   $t$Einen Rückbau aus einem eigenen Bauprojekt übernehmen, Zeit und Kosten genau erfassen und daraus einen Preis je m² ableiten.$t$,
   $t$Brainstorming Handwerk und Bau; einfache Arbeit, gut mit Hilfskräften umsetzbar.$t$, 1),
  ($t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$WAS PRÜFEN
- Meisterpflicht: Maler- und Bodenlegerarbeiten sind teils zulassungsfrei, Fliesen ebenfalls; Elektro und Sanitär sind zulassungspflichtig und gehen an Partnerfirmen
- Zuverlässige Termine sind das Wichtigste für Vermieter: feste Zeitfenster, Abnahmeprotokoll mit Fotos
- Material: Einkauf über Großhändler, Standardfarben und -böden festlegen
- Versicherung: Betriebshaftpflicht (Schäden in der Wohnung), BG BAU
- Preisliste je Wohnungsgröße, damit Angebote schnell gehen$t$,
   $t$Vermieter verlieren keine Miete durch Leerstand, weil die Wohnung in wenigen Tagen wieder vermietbar ist. Ein Ansprechpartner statt mehrerer Handwerker.$t$,
   $t$Renovierung aus einer Hand zwischen Auszug und Einzug: streichen, Böden erneuern, Kleinreparaturen, Reinigung. Fachgewerke über Partnerfirmen.$t$,
   $t$Hausverwaltungen, Wohnungsgesellschaften, private Vermieter mit mehreren Wohnungen$t$,
   array[$t$Dienstleistung$t$]::text[], $t$Festpreise je Wohnungsgröße plus Zusatzleistungen; Rahmenvertrag mit Hausverwaltungen$t$,
   $t$Drei Hausverwaltungen ansprechen und eine Probe-Renovierung zum Festpreis anbieten.$t$,
   $t$Brainstorming Handwerk und Bau; wiederkehrende Aufträge, gute Grundlast für die Hilfskräfte.$t$, 2)
) as v(title, description, benefit, offer, customers, revenue_model, revenue_note, first_test, origin, pos)
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.ideas i where lower(i.title) = lower(v.title));
