-- Zwerg · Geschäftsmodell als Überbegriff je Idee, plus Übernahme der 28 Ideen aus dem Ideen-Interview

create table public.business_models (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (length(name) between 1 and 120),
  sort       integer not null default 0,
  archived   boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.business_models enable row level security;
create policy "Mitglieder lesen Geschäftsmodelle" on public.business_models
  for select to authenticated using (public.is_member());
create policy "Mitglieder legen Geschäftsmodelle an" on public.business_models
  for insert to authenticated with check (public.is_member());
create policy "Mitglieder ändern Geschäftsmodelle" on public.business_models
  for update to authenticated using (public.is_member()) with check (public.is_member());
grant select, insert, update on public.business_models to authenticated;
grant all on public.business_models to service_role;
alter publication supabase_realtime add table public.business_models;

insert into public.business_models (name, sort) values
  ($t$Digitale Dienste für Betriebe$t$, 10),
  ($t$Technische Dienstleistungen mit CAD$t$, 20),
  ($t$Eigene Produkte und Eigenmarke$t$, 30),
  ($t$Vermietung, Sharing und Selbstbedienung$t$, 40),
  ($t$An- und Verkauf$t$, 50),
  ($t$Dienstleistungen für Menschen und Haushalte$t$, 60),
  ($t$Dienstleistungen für Firmen$t$, 70),
  ($t$Bestehendes oder Konzept nutzen$t$, 80);

alter table public.ideas add column business_model_id uuid references public.business_models (id) on delete set null;

-- Die Ideen aus dem Interview, angelegt von Igor. Schon vorhandene Titel werden übersprungen.
insert into public.ideas (title, description, search_field_id, business_model_id, benefit, offer, customers,
                          revenue_model, revenue_note, first_test, origin, created_by, updated_by, created_at, updated_at)
select v.title, v.description, v.search_field_id, v.business_model_id, v.benefit, v.offer, v.customers,
       v.revenue_model, v.revenue_note, v.first_test, v.origin, p.id, p.id,
       now() - make_interval(secs => v.pos), now() - make_interval(secs => v.pos)
from (values
  ($t$Digitalisierungs-Service für Handwerksbetriebe$t$, $t$$t$, (select id from public.search_fields where name = $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Digitale Dienste für Betriebe$t$),
   $t$Kleine Handwerksbetriebe verlieren viel Zeit mit Papier, Excel und Rückrufen. Sie wollen digitaler werden, haben aber weder Zeit noch Know-how dafür.$t$, $t$Passende Software auswählen, einrichten und das Team schulen (Angebote, Rechnungen, Zeiterfassung, Terminplanung). Danach laufende Betreuung.$t$, $t$Handwerksbetriebe mit 3 bis 20 Mitarbeitenden in der Region$t$, array[$t$Dienstleistung$t$,$t$Abo$t$]::text[], $t$Einrichtungspauschale plus monatliche Betreuung$t$,
   $t$Drei Betrieben aus dem Bekanntenkreis eine kostenlose Analyse anbieten und fragen, was ihnen die Umsetzung wert wäre.$t$, $t$Ideen-Interview, Gruppe „Digitales für Handwerker“$t$, 0),
  ($t$Konfigurator-Websites für Handwerker$t$, $t$$t$, (select id from public.search_fields where name = $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Digitale Dienste für Betriebe$t$),
   $t$Kunden wollen vorab sehen, was etwas ungefähr kostet. Handwerker bekommen bessere, vorsortierte Anfragen.$t$, $t$Online-Konfiguratoren, z. B. für Carport, Treppe oder Zaun, mit Preisspanne und Anfrageformular, eingebunden in die Website des Betriebs.$t$, $t$Handwerks- und Fachbetriebe mit standardisierbaren Produkten$t$, array[$t$Abo$t$,$t$Dienstleistung$t$]::text[], $t$Einrichtung plus monatliche Gebühr$t$,
   $t$Einen Konfigurator für einen befreundeten Betrieb bauen und die Anfragen über drei Monate zählen.$t$, $t$Ideen-Interview, Gruppe „Digitales für Handwerker“$t$, 1),
  ($t$Regionales Portal für freie Handwerkertermine$t$, $t$$t$, (select id from public.search_fields where name = $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Digitale Dienste für Betriebe$t$),
   $t$Kunden finden kaum Handwerker, gleichzeitig haben Betriebe kurzfristig Lücken im Kalender.$t$, $t$Eine regionale Plattform, auf der Betriebe freie Kapazitäten eintragen und Kunden direkt anfragen.$t$, $t$Handwerksbetriebe und Privatkunden im Landkreis$t$, array[$t$Provision$t$,$t$Abo$t$]::text[], $t$Gebühr je vermitteltem Auftrag oder Monatsbeitrag für Betriebe$t$,
   $t$Eine einfache Seite mit fünf Betrieben starten, regional bewerben und die Anfragen in vier Wochen zählen.$t$, $t$Ideen-Interview, Gruppe „Digitales für Handwerker“$t$, 2),
  ($t$Digitale Wartungsprotokolle per QR-Code$t$, $t$$t$, (select id from public.search_fields where name = $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Digitale Dienste für Betriebe$t$),
   $t$Wartungen an Heizung, Toren, Feuerlöschern oder Maschinen sind auf Papier verstreut. Niemand weiß sofort, wann was zuletzt gemacht wurde.$t$, $t$Jede Anlage bekommt einen QR-Code. Scannen zeigt Historie, Anleitungen und nächste Fälligkeit, Handwerker tragen Wartungen direkt am Handy ein.$t$, $t$Hausverwaltungen, Handwerksbetriebe mit Wartungsverträgen, Firmen mit Anlagen$t$, array[$t$Abo$t$,$t$Dienstleistung$t$]::text[], $t$Monatsgebühr je Objekt plus Ersterfassung vor Ort$t$,
   $t$Für eine Hausverwaltung zehn Anlagen erfassen und nach drei Monaten fragen, ob sie es weiter nutzen will.$t$, $t$Ideen-Interview, Gruppe „Digitales für Handwerker“$t$, 3),
  ($t$3D-Druck- und Ersatzteil-Service$t$, $t$$t$, (select id from public.search_fields where name = $t$C - Verarbeitendes Gewerbe - Sekundär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Technische Dienstleistungen mit CAD$t$),
   $t$Ersatzteile sind oft nicht mehr lieferbar. Geräte und Maschinen landen wegen eines kleinen Kunststoffteils im Müll oder stehen still.$t$, $t$Defekte Teile vermessen, im CAD nachkonstruieren und in Kunststoff drucken, als Einzelstück oder Kleinserie.$t$, $t$Werkstätten, Maschinenbetreiber, Hausverwaltungen, Privatkunden$t$, array[$t$Verkauf$t$,$t$Dienstleistung$t$]::text[], $t$Konstruktion nach Aufwand plus Stückpreis$t$,
   $t$Mit einem geliehenen oder gebrauchten Drucker zehn reale Teile für Bekannte und Firmen nachbauen.$t$, $t$Ideen-Interview, Gruppe „Fertigung“$t$, 4),
  ($t$Montagehilfen und Vorrichtungen für Handwerker$t$, $t$$t$, (select id from public.search_fields where name = $t$C - Verarbeitendes Gewerbe - Sekundär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Eigene Produkte und Eigenmarke$t$),
   $t$Handwerker improvisieren bei wiederkehrenden Arbeiten. Eine gute Vorrichtung spart Zeit und macht das Ergebnis genauer.$t$, $t$Eigene Montagehilfen entwickeln (CAD) und in Kleinserie fertigen lassen (3D-Druck, Laser, Lohnfertiger).$t$, $t$Handwerker in Montage, Trockenbau und Elektro, Fachhändler$t$, array[$t$Verkauf$t$]::text[], $t$Onlineshop und Fachhandel$t$,
   $t$Fünf Handwerker fragen, welche Arbeit sie am meisten nervt. Einen Prototyp bauen und testen lassen.$t$, $t$Ideen-Interview, Gruppe „Fertigung“$t$, 5),
  ($t$Digitales Ersatzteillager für Firmen$t$, $t$$t$, (select id from public.search_fields where name = $t$C - Verarbeitendes Gewerbe - Sekundär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Technische Dienstleistungen mit CAD$t$),
   $t$Fällt ein kleines Kunststoff- oder Halteteil aus, steht oft eine ganze Maschine. Der Hersteller liefert nicht mehr oder braucht Wochen.$t$, $t$Kritische Verschleiß- und Ersatzteile vorsorglich scannen und als CAD-Datei sichern. Bei Bedarf fertigen wir das Teil kurzfristig im 3D-Druck oder lassen es fertigen.$t$, $t$Produktionsbetriebe, Werkstätten, Kommunen, Facility-Manager$t$, array[$t$Abo$t$,$t$Verkauf$t$]::text[], $t$Jahresgebühr je Teilekatalog plus Stückpreis im Bedarfsfall$t$,
   $t$Zwei Betrieben anbieten, ihre zehn häufigsten Problem-Teile kostenlos zu erfassen, und fragen, was ein Ausfalltag kostet.$t$, $t$Ideen-Interview, Weiterentwicklung des 3D-Druck-Service$t$, 6),
  ($t$Maßgefertigte Einlagen und Ordnungssysteme$t$, $t$$t$, (select id from public.search_fields where name = $t$C - Verarbeitendes Gewerbe - Sekundär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Eigene Produkte und Eigenmarke$t$),
   $t$Werkzeug fliegt im Koffer oder Fahrzeug durcheinander. Suchen kostet Zeit, und Fehlendes fällt erst auf der Baustelle auf.$t$, $t$Passgenaue Schaumstoff-, Holz- oder Kunststoffeinlagen für Koffer, Schubladen und Fahrzeugregale. Entwurf im CAD, Fertigung per Laser/CNC.$t$, $t$Handwerksbetriebe mit Fahrzeugflotte, Servicetechniker, Werkstätten$t$, array[$t$Verkauf$t$]::text[], $t$Stückpreis, Rahmenvertrag für Fuhrparks$t$,
   $t$Für fünf Handwerker eine Koffereinlage bauen und fragen, ob sie es für die ganze Flotte wollen.$t$, $t$Ideen-Interview, Gruppe „Fertigung“$t$, 7),
  ($t$Aufmaß und digitale Bestandspläne$t$, $t$$t$, (select id from public.search_fields where name = $t$N - Freiberufliche, wissenschaftliche und technische Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Technische Dienstleistungen mit CAD$t$),
   $t$Für viele Gebäude gibt es keine aktuellen Pläne. Vor Umbau, Verkauf oder Vermietung werden sie aber gebraucht.$t$, $t$Räume und Gebäude vermessen (Laser, 3D-Scan) und daraus maßstäbliche Grundrisse und Ansichten im CAD erstellen.$t$, $t$Vermieter, Makler, Hausverwaltungen, Handwerker, Architekten$t$, array[$t$Dienstleistung$t$]::text[], $t$Pauschale je Einheit oder je m²$t$,
   $t$Drei Maklern ein Probe-Aufmaß zum Selbstkostenpreis anbieten.$t$, $t$Ideen-Interview, knüpft an unsere CAD-Kenntnisse an$t$, 8),
  ($t$Werkzeugverleih per Schließfach-Automat$t$, $t$$t$, (select id from public.search_fields where name = $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Vermietung, Sharing und Selbstbedienung$t$),
   $t$Profi-Werkzeug wird selten gebraucht, kaufen lohnt sich nicht. Klassische Verleiher haben feste Öffnungszeiten.$t$, $t$Werkzeug und Geräte rund um die Uhr per App buchen und aus dem Schließfach holen, ohne Personal vor Ort.$t$, $t$Heimwerker, Hausbesitzer, kleine Handwerksbetriebe$t$, array[$t$Miete$t$,$t$Abo$t$]::text[], $t$Tagespreis plus Kaution, Abo für Vielnutzer$t$,
   $t$Zehn gefragte Geräte über Kleinanzeigen vermieten und auswerten, was wie oft gebucht wird.$t$, $t$Ideen-Interview, Gruppe „Vermietung ohne Personal“$t$, 9),
  ($t$Materialboxen für Handwerker$t$, $t$$t$, (select id from public.search_fields where name = $t$H - Verkehr und Lagerei - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Vermietung, Sharing und Selbstbedienung$t$),
   $t$Handwerker fahren für Material oft zum Händler oder zurück in den Betrieb. Lieferungen auf die Baustelle sind unsicher.$t$, $t$Abschließbare Lagerboxen an gut erreichbaren Standorten, rund um die Uhr per Code zugänglich. Händler können Material direkt hineinliefern.$t$, $t$Handwerksbetriebe, Baustoffhändler, Monteure ohne eigenes Lager$t$, array[$t$Miete$t$]::text[], $t$Monatsmiete je Box, Gebühr für Annahme von Lieferungen$t$,
   $t$Zehn Betriebe fragen, ob und zu welchem Preis sie eine Box mieten würden. Bei Interesse mit einer gemieteten Garage starten.$t$, $t$Ideen-Interview, Gruppe „Vermietung ohne Personal“$t$, 10),
  ($t$Mietwerkstatt per App (Selbstbedienung)$t$, $t$$t$, (select id from public.search_fields where name = $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Vermietung, Sharing und Selbstbedienung$t$),
   $t$Viele haben weder Platz noch Maschinen für größere Projekte. Gemeinschaftswerkstätten sind selten und haben feste Betreuungszeiten.$t$, $t$Eine ausgestattete Werkstatt, die stundenweise per App gebucht und per Code geöffnet wird. Kameras und Einweisungs-Nachweis sorgen für Sicherheit, Personal ist nicht vor Ort.$t$, $t$Heimwerker, Bastler, kleine Selbstständige ohne eigene Werkstatt$t$, array[$t$Miete$t$,$t$Abo$t$]::text[], $t$Stundenpreis, Monatsabo, Einweisung gegen Gebühr$t$,
   $t$Eine Umfrage in lokalen Gruppen und ein Probetag mit geliehenen Räumen, um Nachfrage und Zahlungsbereitschaft zu prüfen.$t$, $t$Ideen-Interview, Gruppe „Vermietung ohne Personal“, passt zu den Materialboxen am selben Standort$t$, 11),
  ($t$Mietservice für Baby- und Kinderausstattung$t$, $t$$t$, (select id from public.search_fields where name = $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Vermietung, Sharing und Selbstbedienung$t$),
   $t$Kinderwagen, Autositze, Betten und Laufgitter braucht man nur ein bis zwei Jahre, sie sind aber teuer. Gekauft stehen sie danach im Keller.$t$, $t$Geprüfte, gereinigte Ausstattung auf Zeit mieten, mit Lieferung, Aufbau und Abholung. Bei Bedarf Tausch auf die nächste Größe.$t$, $t$Junge Familien, Großeltern mit Enkel-Besuch, Ferienwohnungen$t$, array[$t$Miete$t$,$t$Abo$t$]::text[], $t$Monatsmiete je Teil oder Paket, Liefer- und Aufbaupauschale, Kaution$t$,
   $t$Zehn gefragte Teile gebraucht kaufen, über Hebammen, Kitas und Eltern-Gruppen anbieten und Mietdauer und Nachfrage auswerten.$t$, $t$Ideen-Brainstorming, Bedürfnis „bezahlbare Alternativen“, Gruppe „Vermietung“$t$, 12),
  ($t$24/7-Mikro-Fitnessstudio ohne Personal$t$, $t$$t$, (select id from public.search_fields where name = $t$S - Kunst, Sport und Erholung - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Vermietung, Sharing und Selbstbedienung$t$),
   $t$Viele wollen flexibel trainieren, ohne Wartezeiten, volle Studios oder lange Verträge. In kleineren Städten fehlen solche Angebote oft.$t$, $t$Ein kleines, gut ausgestattetes Studio, rund um die Uhr per App zugänglich. Kameras, Online-Einweisung und Notruf statt Personal vor Ort.$t$, $t$Berufstätige, Schichtarbeiter, Einsteiger, die ungestört trainieren wollen$t$, array[$t$Abo$t$]::text[], $t$Monatsbeitrag, monatlich kündbar; Tagespass für Gäste$t$,
   $t$Mit einer Umfrage in lokalen Gruppen und einer Landingpage Voranmeldungen sammeln. Ab etwa 80 Interessenten Standort und Geräte konkret planen.$t$, $t$Ideen-Interview, Gruppe „Vermietung ohne Personal“, Kombination mit der Mietwerkstatt denkbar$t$, 13),
  ($t$Fitnessgeräte im Miet-Abo für zu Hause$t$, $t$$t$, (select id from public.search_fields where name = $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Vermietung, Sharing und Selbstbedienung$t$),
   $t$Hochwertige Geräte sind teuer, und viele wissen nicht, ob sie dranbleiben. Gekaufte Geräte stehen oft ungenutzt herum.$t$, $t$Laufband, Rudergerät oder Indoor-Rad monatlich mieten, mit Lieferung, Aufbau und Abholung. Bei Bedarf Wechsel auf ein anderes Gerät.$t$, $t$Privathaushalte in der Region, Reha-Patienten, Firmen für Mitarbeiter-Angebote$t$, array[$t$Miete$t$,$t$Abo$t$]::text[], $t$Monatsmiete plus Liefer- und Aufbaupauschale, Mindestlaufzeit 3 Monate$t$,
   $t$Drei gebrauchte Geräte kaufen, regional anbieten und auswerten, wie schnell sie vermietet sind und wie lange Kunden bleiben.$t$, $t$Ideen-Interview, Fitness mit Mietmodell$t$, 14),
  ($t$Haushaltsauflösung mit Online-Wiederverkauf$t$, $t$$t$, (select id from public.search_fields where name = $t$T - Sonstige Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$An- und Verkauf$t$),
   $t$Angehörige sind bei Umzug ins Heim oder einem Todesfall überfordert. Viel Brauchbares landet im Müll.$t$, $t$Wohnungen besenrein räumen, Verwertbares online verkaufen und den Erlös mit dem Kunden verrechnen.$t$, $t$Angehörige, Seniorenheime, Hausverwaltungen, Nachlassverwalter$t$, array[$t$Dienstleistung$t$,$t$Verkauf$t$]::text[], $t$Pauschale abzüglich Verwertungserlös$t$,
   $t$Eine Auflösung im Bekanntenkreis durchführen und Zeit, Kosten und Erlös genau mitschreiben. Klären, ob Termine unter der Woche möglich sind.$t$, $t$Ideen-Interview, Gruppe „An- und Verkauf“$t$, 15),
  ($t$Retouren- und Restpostenhandel$t$, $t$$t$, (select id from public.search_fields where name = $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$An- und Verkauf$t$),
   $t$Händler werden Retouren und Restposten nicht los, Käufer suchen gute Ware zum günstigen Preis. Vieles würde sonst vernichtet.$t$, $t$Retourenpaletten und Restposten günstig einkaufen, prüfen, sortieren, bei Bedarf reparieren und einzeln online verkaufen.$t$, $t$Einkauf bei Onlinehändlern und Großhändlern, Verkauf an Privatkunden über Plattformen und den eigenen Shop$t$, array[$t$Verkauf$t$]::text[], $t$Marge zwischen Paletten-Einkaufspreis und Einzelverkauf$t$,
   $t$Zwei bis drei Paletten in einer Warengruppe kaufen und genau auswerten: Anteil verkäuflicher Ware, Arbeitszeit je Artikel, Erlös.$t$, $t$Ideen-Interview, Richtung An- und Verkauf. Braucht Lagerfläche und bindet Kapital in Ware.$t$, 16),
  ($t$Kommissionsverkauf für Privatleute$t$, $t$$t$, (select id from public.search_fields where name = $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$An- und Verkauf$t$),
   $t$Viele haben wertvolle Dinge herumstehen, aber keine Zeit oder Lust, Fotos zu machen, Anzeigen zu schreiben und mit Käufern zu verhandeln.$t$, $t$Wir holen die Gegenstände ab oder nehmen sie an, fotografieren sie professionell, verkaufen online und rechnen ab. Der Kunde muss sich um nichts kümmern.$t$, $t$Privathaushalte, Senioren, Erben, kleine Firmen mit ausrangierten Geräten$t$, array[$t$Provision$t$]::text[], $t$Anteil am Verkaufspreis (z. B. 25–40 %), Mindestgebühr je Artikel$t$,
   $t$Für Freunde und Bekannte zehn Gegenstände verkaufen und messen, wie lange es dauert und was übrig bleibt.$t$, $t$Ideen-Interview, Richtung An- und Verkauf, passt zur Haushaltsauflösung$t$, 17),
  ($t$Gebrauchte Küchen: Ankauf, Abbau und Wiedereinbau$t$, $t$$t$, (select id from public.search_fields where name = $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$An- und Verkauf$t$),
   $t$Neue Küchen sind teuer, gleichzeitig werden bei Umzug und Renovierung gut erhaltene Küchen entsorgt.$t$, $t$Gebrauchte Küchen ankaufen oder vermitteln, fachgerecht abbauen, beim neuen Besitzer anpassen und wieder einbauen, inklusive Arbeitsplatte und Anschlüssen (Elektro und Wasser durch Partnerbetriebe).$t$, $t$Verkäufer: Umziehende, Vermieter, Küchenstudios mit Ausstellungsküchen. Käufer: Mieter, Studierende, Vermieter, Sparfüchse.$t$, array[$t$Verkauf$t$,$t$Dienstleistung$t$]::text[], $t$Marge auf die Küche plus Pauschale für Abbau, Transport und Einbau$t$,
   $t$Eine Küche aus dem Bekanntenkreis oder von Kleinanzeigen übernehmen, wieder einbauen und Zeit, Kosten und Erlös genau mitschreiben.$t$, $t$Ideen-Brainstorming, Bedürfnis „bezahlbare Alternativen“, Gruppe „An- und Verkauf“$t$, 18),
  ($t$Alltags- und Digitalhilfe für Senioren$t$, $t$$t$, (select id from public.search_fields where name = $t$R - Gesundheits- und Sozialwesen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Dienstleistungen für Menschen und Haushalte$t$),
   $t$Ältere Menschen kommen mit Smartphone, Online-Terminen, Formularen und Erledigungen oft nicht mehr allein zurecht. Angehörige wohnen weit weg oder haben keine Zeit.$t$, $t$Hilfe zu Hause, regelmäßig oder bei Bedarf: Geräte einrichten und erklären, Termine buchen, Post sortieren, Einkäufe und Erledigungen organisieren.$t$, $t$Senioren und ihre Angehörigen; Pflegebedürftige mit Anspruch auf den Entlastungsbetrag der Pflegekasse$t$, array[$t$Dienstleistung$t$,$t$Abo$t$]::text[], $t$Stundensatz oder Monatspaket; mit Anerkennung des Landes Abrechnung über den Entlastungsbetrag$t$,
   $t$Bei der Pflegeberatung der Stadt und zwei Pflegediensten nachfragen, wie groß die Nachfrage ist, und fünf Senioren aus dem Bekanntenkreis probeweise betreuen.$t$, $t$Ideen-Interview, Bereich Soziales$t$, 19),
  ($t$Hundetagesstätte für Berufstätige$t$, $t$$t$, (select id from public.search_fields where name = $t$T - Sonstige Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Dienstleistungen für Menschen und Haushalte$t$),
   $t$Berufstätige Hundehalter wissen tagsüber nicht wohin mit ihrem Hund. Langes Alleinsein schadet dem Tier, und die Suche nach Betreuung belastet.$t$, $t$Betreuung von Hunden Mo–Fr tagsüber in Gruppen, mit Auslauf, Beschäftigung und Ruhezeiten. Optional mit Hol- und Bringdienst.$t$, $t$Berufstätige Hundehalter in der Stadt und im Umland$t$, array[$t$Abo$t$,$t$Dienstleistung$t$]::text[], $t$Monatspaket mit festen Tagen, Einzeltage zum Tagespreis, Fahrdienst gegen Aufpreis$t$,
   $t$Beim Veterinäramt die Voraussetzungen klären, Sachkunde-Kurs prüfen und in lokalen Hundegruppen Interessenten und Zahlungsbereitschaft abfragen.$t$, $t$Ideen-Interview, Bereich Tiere. Erlaubnis nach § 11 Tierschutzgesetz und passendes Gelände nötig.$t$, 20),
  ($t$Kfz-Zulassungsdienst für Autohäuser und Flotten$t$, $t$$t$, (select id from public.search_fields where name = $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Dienstleistungen für Firmen$t$),
   $t$An-, Um- und Abmeldungen kosten Autohäuser, Werkstätten und Firmen mit Fuhrpark viel Zeit, Wartezeit und Personal.$t$, $t$Wir übernehmen Zulassungen komplett: Unterlagen abholen, bei der Behörde erledigen (vor Ort oder online), Kennzeichen und Papiere zurückbringen.$t$, $t$Autohäuser, freie Werkstätten, Autovermietungen, Firmen mit Fuhrpark$t$, array[$t$Dienstleistung$t$]::text[], $t$Pauschale je Vorgang plus Gebühren, Rahmenvertrag für Vielnutzer$t$,
   $t$Fünf Autohäuser und Werkstätten in der Region fragen, wie sie Zulassungen heute erledigen und was ihnen ein externer Dienst wert wäre.$t$, $t$Ideen-Interview, Bereich Behördenservice$t$, 21),
  ($t$Fahrzeugpflege vor Ort beim Arbeitgeber$t$, $t$$t$, (select id from public.search_fields where name = $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Dienstleistungen für Firmen$t$),
   $t$Berufstätige haben kaum Zeit für die Autowäsche. Firmen suchen Zusatzleistungen für Mitarbeitende und wollen gepflegte Firmenfahrzeuge.$t$, $t$Innen- und Außenreinigung direkt auf dem Firmenparkplatz während der Arbeitszeit, mit wasserlosen oder wassersparenden Verfahren.$t$, $t$Firmen mit Fuhrpark, Arbeitgeber als Mitarbeiter-Benefit, Mitarbeitende als Selbstzahler$t$, array[$t$Dienstleistung$t$,$t$Abo$t$]::text[], $t$Preis je Fahrzeug, Monatspaket für Fuhrparks, Rahmenvertrag mit dem Arbeitgeber$t$,
   $t$Mit einem Arbeitgeber einen Aktionstag vereinbaren und zählen, wie viele Mitarbeitende buchen und ob sie wiederkommen.$t$, $t$Ideen-Interview, Bereich Mobilität. Vorgaben zum Abwasser bei der Stadt klären.$t$, 22),
  ($t$Haus-Check im Abo für Eigenheimbesitzer$t$, $t$$t$, (select id from public.search_fields where name = $t$T - Sonstige Dienstleistungen - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Dienstleistungen für Menschen und Haushalte$t$),
   $t$Kleine Wartungsarbeiten am Haus werden vergessen oder aufgeschoben, bis teure Schäden entstehen. Für Kleinkram findet man kaum noch Handwerker.$t$, $t$Zweimal im Jahr ein fester Termin: Dachrinnen, Heizung entlüften, Rauchmelder, Silikonfugen, Außenlicht, kleine Reparaturen. Mit Checkliste und Hinweis, wenn ein Fachbetrieb nötig ist.$t$, $t$Eigenheimbesitzer, besonders ältere Menschen und Berufstätige ohne Zeit$t$, array[$t$Abo$t$,$t$Dienstleistung$t$]::text[], $t$Jahresabo mit zwei Terminen, Zusatzarbeiten nach Aufwand$t$,
   $t$Zehn Hausbesitzern aus dem Bekanntenkreis einen Probe-Check anbieten und fragen, ob sie dafür ein Jahresabo abschließen würden.$t$, $t$Ideen-Brainstorming, Bedürfnis „Hilfe vor Ort“$t$, 23),
  ($t$Eigenmarke mit White-Label-Produkten$t$, $t$$t$, (select id from public.search_fields where name = $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Eigene Produkte und Eigenmarke$t$),
   $t$Kunden suchen in Nischen gut ausgewählte Produkte von einem Anbieter, dem sie vertrauen. Viele Nischen werden nur von austauschbaren No-Name-Angeboten ohne Beratung bedient.$t$, $t$Bestehende Standardprodukte eines Herstellers mit eigener Marke, Verpackung und Beschreibung in einer Nische verkaufen, z. B. Werkstatt-, Outdoor- oder Camping-Zubehör, mit guter Beratung und Service.$t$, $t$Privatkunden und kleine Betriebe in der gewählten Nische, online deutschlandweit$t$, array[$t$Verkauf$t$]::text[], $t$Marge zwischen Einkaufs- und Verkaufspreis; eigener Shop und Marktplätze$t$,
   $t$Drei Produkte in kleiner Menge bestellen, mit eigenem Label über einen Marktplatz anbieten und Nachfrage, Bewertungen und Marge auswerten.$t$, $t$Ideen-Gespräch zu White und Private Label; schneller, günstiger Einstieg, um den Markt zu testen. Achtung: Als Markeninhaber haftet ihr für das Produkt (Produkthaftung, CE-Kennzeichnung).$t$, 24),
  ($t$Eigenmarke mit Private-Label-Produkten$t$, $t$$t$, (select id from public.search_fields where name = $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$ and not archived limit 1),
   (select id from public.business_models where name = $t$Eigene Produkte und Eigenmarke$t$),
   $t$Viele Produkte sind austauschbar oder haben Schwächen, über die Kunden in Bewertungen klagen. Ein durchdachtes, verbessertes Produkt hebt sich deutlich ab.$t$, $t$Ein eigenes Produkt nach unseren Vorgaben (Entwurf im CAD, Material, Design) bei einem Hersteller exklusiv fertigen lassen und unter eigener Marke verkaufen.$t$, $t$Kunden in einer Nische, die wir gut kennen; Fachhandel als zweiter Vertriebsweg$t$, array[$t$Verkauf$t$]::text[], $t$Höhere Marge als bei White Label, dafür Entwicklungskosten und Mindestmengen$t$,
   $t$Schwächen bestehender Produkte aus Kundenbewertungen sammeln, Prototyp bauen, Muster beim Hersteller bestellen und Vorbestellungen sammeln.$t$, $t$Ideen-Gespräch; zweiter Schritt nach White Label, nutzt unsere CAD-Kenntnisse. Achtung: Mindestmengen binden Kapital; Produkthaftung und CE-Kennzeichnung beachten.$t$, 25),
  ($t$Unternehmensnachfolge – bestehenden Betrieb übernehmen$t$, $t$WO SUCHEN
- nexxt-change.org – offizielle Nachfolgebörse (Bundeswirtschaftsministerium/KfW), Suchprofil anlegen
- IHK und Handwerkskammer: eigene Nachfolgebörsen und kostenlose Nachfolgeberater
- Steuerberater, Banken und Sparkassen der Region – wissen oft von Abgabewilligen
- Direkt ansprechen: Betriebe, deren Inhaber kurz vor der Rente stehen

WER HILFT
- Steuerberater: Bewertung, Jahresabschlüsse prüfen, steuerlich beste Form der Übernahme
- Fachanwalt (Wirtschafts-/Gesellschaftsrecht): Kaufvertrag, Haftung, Übergang der Mitarbeitenden
- Hausbank und Bürgschaftsbank des Landes: Finanzierung und Absicherung
- Förderung: KfW-Förderkredite für Gründung und Nachfolge; Beratungsförderung über BAFA prüfen

WAS PRÜFEN (vor dem Kauf)
- Jahresabschlüsse der letzten 3 Jahre: Umsatz, Gewinn, Entwicklung
- Kundenstruktur: Hängt viel an wenigen Kunden oder am Inhaber persönlich?
- Verträge: Kunden, Lieferanten, Miete, Leasing – laufen sie weiter?
- Mitarbeitende: Wer bleibt? Mitarbeitende gehen bei Übernahme mit (§ 613a BGB)
- Zustand von Maschinen, Fahrzeugen, Software
- Haftungsrisiken: offene Gewährleistungen, Schulden, Rechtsstreitigkeiten
- Genehmigungen, Meisterpflicht oder Sachkunde nötig?

KAUFPREIS UND FINANZIERUNG
- Faustregel kleine Betriebe: etwa das 2- bis 4-Fache des bereinigten Jahresgewinns
- Unser Eigenkapital 10.000–50.000 € + Förderkredit + Ratenzahlung an den Verkäufer
- Einarbeitung durch den Verkäufer (3–12 Monate) vertraglich vereinbaren

ABLAUF
1. Suchprofil festlegen (Branche, Größe, Region, Preisrahmen)
2. Angebote sichten, Erstgespräche führen
3. Absichtserklärung und Vertraulichkeitsvereinbarung
4. Prüfung des Betriebs mit Steuerberater und Anwalt
5. Finanzierung klären, Kaufvertrag verhandeln
6. Übergabe mit Einarbeitung, Kunden gemeinsam informieren$t$, null,
   (select id from public.business_models where name = $t$Bestehendes oder Konzept nutzen$t$),
   $t$Inhaber ohne Nachfolger geben ihr Lebenswerk weiter, Kunden und Mitarbeitende behalten ihren Betrieb. Für uns gibt es ab dem ersten Tag Umsatz, Kunden und erprobte Abläufe.$t$, $t$Einen kleinen, gesunden Betrieb (B2B, Arbeit tagsüber) übernehmen, weiterführen und mit Organisation, Technik und Digitalem modernisieren.$t$, $t$Die bestehenden Kunden des Betriebs, dazu neue Firmen- und Privatkunden in der Region$t$, array[$t$Dienstleistung$t$,$t$Abo$t$,$t$Verkauf$t$]::text[], $t$Je nach Betrieb. Kaufpreis über Eigenkapital, KfW-Förderkredit und Ratenzahlung an den Verkäufer$t$,
   $t$Bei nexxt-change.org und den Börsen von IHK und Handwerkskammer ein Suchprofil anlegen und mit mindestens einem Inhaber sprechen.$t$, $t$Viele Inhaber gehen bald in Rente, ohne Nachfolger. Unternehmensnachfolge war von Anfang an eines unserer Suchfelder.$t$, 26),
  ($t$Neugründung mit Franchise (Dienstleistung)$t$, $t$NEUGRÜNDUNG MIT FRANCHISE – WICHTIGE PUNKTE

WO SUCHEN
- Deutscher Franchiseverband (franchiseverband.com): Systemübersicht, geprüfte Mitglieder
- Franchise-Messen und -Portale; IHK-Gründungsberatung
- Gezielt nach Dienstleistungs-Systemen ohne Abend-/Wochenendarbeit suchen

WER HILFT
- Fachanwalt für Franchiserecht: Vertrag vor Unterschrift prüfen lassen
- Steuerberater: Gebühren, Rentabilität, Rechtsform
- Hausbank / KfW: Förderkredite für Gründungen gelten auch für Franchise
- IHK-Gründungsberatung; BAFA-Beratungsförderung prüfen

WAS PRÜFEN
- Gebühren: Einstiegsgebühr, laufende Gebühr (oft % vom Umsatz), Werbeumlage
- Gebietsschutz: Gibt es ein eigenes Gebiet ohne Konkurrenz aus dem System?
- Vertragslaufzeit, Kündigung, was passiert beim Ausstieg
- Pflichten: Bezug von Waren, Mindestumsatz, Vorgaben zu Öffnungszeiten
- Leistung des Franchisegebers: Schulung, Marketing, Software, Einkauf
- Mit mindestens 3 bestehenden Partnern sprechen – auch mit ehemaligen
- Wirtschaftliche Kennzahlen echter Partner, nicht nur Musterrechnungen

UNTERSCHIED ZUR ÜBERNAHME
- Start bei null Kunden, dafür erprobtes Konzept und Marke
- Laufende Gebühren dauerhaft statt einmaligem Kaufpreis
- Weniger Gestaltungsfreiheit, dafür Unterstützung beim Aufbau

ABLAUF
1. Branche und Anforderungen festlegen (Kapital, Zeit, keine Randzeiten)
2. 3–5 Systeme vergleichen, Unterlagen anfordern
3. Gespräche mit bestehenden Partnern
4. Vertrag prüfen lassen, Finanzierung klären
5. Schulung beim Franchisegeber, Standort, Start$t$, null,
   (select id from public.business_models where name = $t$Bestehendes oder Konzept nutzen$t$),
   $t$Ein erprobtes Konzept mit Marke, Abläufen und Einkaufsvorteilen senkt das Risiko der Gründung.$t$, $t$Regionaler Partner eines Franchisesystems werden, z. B. in Reinigungstechnik, Smart-Home oder Gebäudeservice.$t$, $t$Abhängig vom System, bevorzugt Firmenkunden$t$, array[$t$Dienstleistung$t$]::text[], $t$Einstiegsgebühr und laufende Gebühr an den Franchisegeber$t$,
   $t$Drei Systeme vergleichen, z. B. über den Deutschen Franchiseverband, und mit bestehenden Partnern sprechen.$t$, $t$Ideen-Interview, Abgrenzung zur Übernahme$t$, 27)
) as v(title, description, search_field_id, business_model_id, benefit, offer, customers,
       revenue_model, revenue_note, first_test, origin, pos)
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.ideas i where lower(i.title) = lower(v.title));
