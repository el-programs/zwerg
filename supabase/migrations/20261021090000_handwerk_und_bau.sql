-- Zwerg · Neue Gruppe „Handwerk und Bau“ und die Idee „Handwerksbetrieb mit Hilfskräften“ (angelegt von Igor)

insert into public.business_models (name, sort)
select $t$Handwerk und Bau$t$, 90
where not exists (select 1 from public.business_models where name = $t$Handwerk und Bau$t$);

insert into public.ideas (title, description, search_field_id, business_model_id, benefit, offer, customers,
                          revenue_model, revenue_note, first_test, origin, created_by, updated_by)
select $t$Handwerksbetrieb mit Hilfskräften$t$,
       $t$AUFBAU IN STUFEN
1. Start: 2–3 Hilfskräfte für einfache, zulassungsfreie Arbeiten
2. Später: größere Aufträge, Fachkräfte mit Ausbildung einstellen
3. Langfristig: eigene Gewerke, ggf. mit Meister (angestellt oder selbst)

QUALITÄT
- Ein Bauleiter (in unserer jetzigen Firma angestellt) kontrolliert die Arbeiten und gibt sie frei
- Klare Arbeitsanweisungen und Fotodokumentation je Auftrag

WAS PRÜFEN
- Meisterpflicht: Viele Gewerke sind zulassungspflichtig (Anlage A der Handwerksordnung). Zulassungsfreie Tätigkeiten
  (z. B. Montage, Abbruch, Entrümpelung, Hilfsarbeiten im Trockenbau) mit der Handwerkskammer abklären
- Eintragung bei der Handwerkskammer bzw. Gewerbeanmeldung
- Versicherungen: Betriebshaftpflicht, Berufsgenossenschaft BG BAU
- Mindestlohn bzw. Branchenmindestlohn, Arbeitsschutz und Unterweisungen
- Abgrenzung zur jetzigen Firma: Verrechnung der Bauleiter-Stunden, Verträge zwischen beiden Firmen
- Fahrzeug, Werkzeug und Lager$t$,
       (select id from public.search_fields where name = $t$F - Baugewerbe - Sekundär$t$ and not archived limit 1),
       (select id from public.business_models where name = $t$Handwerk und Bau$t$),
       $t$Kunden bekommen einfache Arbeiten schnell und zuverlässig erledigt, mit Kontrolle durch einen erfahrenen Bauleiter. Unsere jetzige Firma kann Aufträge an die eigenen Leute geben statt an Fremdfirmen.$t$,
       $t$Einfache Bau- und Handwerksarbeiten wie Montage, Abbruch, Entrümpelung, Vorarbeiten und Hilfsarbeiten auf Baustellen. Später größere Aufträge mit Fachkräften.$t$,
       $t$Zuerst unsere jetzige Firma und deren Bauprojekte, dann andere Bauunternehmen, Hausverwaltungen und Privatkunden in der Region$t$,
       array[$t$Dienstleistung$t$]::text[],
       $t$Stundensätze oder Pauschalen je Auftrag; Rahmenvertrag mit unserer jetzigen Firma$t$,
       $t$Mit einer Hilfskraft (Minijob oder befristet) drei Monate lang Aufträge aus unseren eigenen Bauprojekten übernehmen und Stunden, Qualität und Gewinn auswerten.$t$,
       $t$Idee von Igor; ein Bauleiter für unsere jetzige Firma ist ohnehin geplant und kann die Arbeiten kontrollieren.$t$,
       p.id, p.id
from (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.ideas i where lower(i.title) = lower($t$Handwerksbetrieb mit Hilfskräften$t$));
