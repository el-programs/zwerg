-- Zwerg · Die 25 Ideen aus dem Brainstorming „Kassenleistungen“ werden zu 11 Ideen zusammengefasst.
-- Die alten Ideen werden gelöscht (nur die aus diesem Brainstorming), die neuen bekommen gemeinsame Steckbriefe
-- mit Leistungsbausteinen und Katalogen (angelegt von Igor, landen in der Vorauswahl), dazu neue Synergien.

-- 1) Alte Einzelideen löschen. „Ambulanter Pflegedienst“ heißt neu genauso, deshalb erst löschen, dann neu anlegen.
delete from public.ideas
where origin like $t$Brainstorming Kassenleistungen – Katalog:%$t$
  and title in ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Verhinderungs- und Betreuungsdienst stundenweise$t$, $t$Ambulanter Pflegedienst$t$, $t$Tagespflege für Senioren$t$, $t$Ambulant betreute Senioren-Wohngemeinschaft$t$, $t$Beratungsbesuche und Pflegekurse für Angehörige$t$, $t$Haushaltshilfe nach Krankenhaus oder Schwangerschaft$t$, $t$Hilfsmittel-Service für zu Hause$t$, $t$Montage, Wartung und Aufbereitung von Hilfsmitteln$t$, $t$Hausnotruf und Assistenzsysteme$t$, $t$Inkontinenz- und Pflegebedarf im Abo$t$, $t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$Therapiezentrum für Physio-, Ergo- und Sprachtherapie$t$, $t$Podologie-Praxis mit Hausbesuchen$t$, $t$Fahrdienst zu Arztterminen und Therapien$t$, $t$Hebammenzentrum$t$, $t$Abrechnungs- und Praxisservice für Arzt- und Zahnarztpraxen$t$, $t$Abrechnungszentrum für Pflege- und Heilmittelanbieter$t$, $t$Digitale Pflege- und Gesundheitsanwendungen$t$, $t$Servicedienste für Kliniken und Pflegeheime$t$, $t$Botendienst für Apotheken und Praxen$t$, $t$Sanitätshaus mit angestelltem Orthopädietechnik-Meister$t$, $t$Hörakustik-Fachgeschäft mit angestelltem Meister$t$, $t$Ambulante psychiatrische Pflege und Soziotherapie$t$, $t$Schulungsakademie für Alltagsbegleiter und Betreuungskräfte$t$);

-- 2) Neue, zusammengefasste Ideen
insert into public.ideas (title, description, search_field_id, business_model_id, benefit, offer, customers,
                          revenue_model, revenue_note, first_test, origin, created_by, updated_by, created_at, updated_at)
select v.title, v.description,
       (select id from public.search_fields where name = v.branche and not archived limit 1),
       (select id from public.business_models where name = $t$Gesundheit und Pflege (kassenfinanziert)$t$),
       v.benefit, v.offer, v.customers, v.revenue_model, v.revenue_note, v.first_test, v.origin, p.id, p.id,
       now() - make_interval(secs => v.pos), now() - make_interval(secs => v.pos)
from (values
  ($t$Alltags- und Entlastungsdienst$t$, $t$LEISTUNGSBAUSTEINE
- Alltagshilfe: Haushalt, Einkauf, Begleitung, Betreuung
  Katalog: Angebote zur Unterstützung im Alltag (§ 45a SGB XI, Landesverordnung), Entlastungsbetrag (§ 45b SGB XI)
- Verhinderungs- und Betreuungsdienst: Stundenweise Betreuung, wenn Angehörige verhindert sind
  Katalog: Verhinderungspflege (§ 39 SGB XI), gemeinsamer Jahresbetrag (§ 42a SGB XI)
- Haushaltshilfe: Kinderbetreuung, Kochen, Haushalt für die Dauer der Verordnung
  Katalog: § 38 SGB V, § 24h SGB V (Schwangerschaft)

VORAUSSETZUNGEN
Anerkennung durch die Landesstelle, Schulung der Mitarbeiter (je nach Land rund 30–160 Stunden), Verträge mit den Krankenkassen für die Haushaltshilfe, Abrechnung mit IK-Nummer.

PERSONAL
Alltagsbegleiter und Haushaltshilfen ohne Pflegeausbildung, eine fachliche Leitung (je nach Land Pflege- oder Sozialberuf).$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Pflegebedürftige bleiben länger selbständig zu Hause, Familien werden entlastet. Mehrere Kassenbudgets, die oft ungenutzt verfallen, finanzieren das Angebot.$t$, $t$Hilfe im Haushalt, Einkauf, Begleitung und Betreuung – regelmäßig oder stundenweise, wenn Angehörige verhindert sind; Haushaltshilfe für Familien nach Krankenhaus oder in der Schwangerschaft.$t$, $t$Menschen mit Pflegegrad und ihre Angehörigen, Familien mit Kindern bei Krankheit oder Schwangerschaft, Pflegeberatungsstellen als Vermittler$t$, array[$t$Dienstleistung$t$]::text[], $t$Stundensätze, abgerechnet über Entlastungsbetrag (rund 131 €/Monat), Verhinderungspflege bzw. gemeinsamen Jahresbetrag und Haushaltshilfe der Krankenkasse; darüber hinaus privat$t$, $t$Anerkennungsvoraussetzungen im Bundesland prüfen und bei zwei Pflegeberatungsstellen nach Wartelisten fragen.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: Angebote zur Unterstützung im Alltag (§ 45a SGB XI, Landesverordnung), Entlastungsbetrag (§ 45b SGB XI); Verhinderungspflege (§ 39 SGB XI), gemeinsamer Jahresbetrag (§ 42a SGB XI); § 38 SGB V, § 24h SGB V (Schwangerschaft)$t$, 0),
  ($t$Ambulanter Pflegedienst$t$, $t$LEISTUNGSBAUSTEINE
- Pflegesachleistungen: Grundpflege, Hauswirtschaft
  Katalog: Vergütungsvereinbarungen nach § 89 SGB XI
- Häusliche Krankenpflege: Medikamente, Verbände, Injektionen
  Katalog: HKP-Leistungsverzeichnis (§ 132a SGB V)
- Beratungsbesuche: Pflichtberatung für Pflegegeld-Bezieher
  Katalog: § 37 Abs. 3 SGB XI
- Psychiatrische Pflege und Soziotherapie: Hausbesuche bei psychisch Erkrankten
  Katalog: HKP – psychiatrische Pflege, § 37a SGB V

VORAUSSETZUNGEN
Versorgungsvertrag mit den Pflegekassen (§ 72 SGB XI), Vertrag mit den Krankenkassen, verantwortliche Pflegefachkraft mit Weiterbildung, Qualitätsprüfungen, Erreichbarkeit rund um die Uhr.

PERSONAL
Pflegedienstleitung und Stellvertretung, Pflegefach- und Pflegehilfskräfte, für die psychiatrische Pflege Fachweiterbildung Psychiatrie, Verwaltung.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Menschen werden zu Hause gepflegt statt im Heim. Der Bedarf wächst dauerhaft, viele Dienste nehmen keine neuen Kunden mehr auf.$t$, $t$Grundpflege und hauswirtschaftliche Versorgung, Behandlungspflege nach ärztlicher Verordnung, Pflicht-Beratungsbesuche für Pflegegeld-Bezieher, spezialisierte psychiatrische Pflege.$t$, $t$Pflegebedürftige und Kranke im Einzugsgebiet, Pflegegeld-Bezieher, Ärzte und Kliniken als Zuweiser$t$, array[$t$Dienstleistung$t$]::text[], $t$Leistungskomplexe bzw. Zeitvergütung nach Landesvertrag, HKP-Vergütung der Krankenkassen, Pauschale je Beratungsbesuch$t$, $t$Mit einer erfahrenen Pflegedienstleitung sprechen, ob sie mitgründen würde; Wartelisten der Dienste vor Ort erfragen. Alternativ einen bestehenden Dienst übernehmen.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: Vergütungsvereinbarungen nach § 89 SGB XI; HKP-Leistungsverzeichnis (§ 132a SGB V); § 37 Abs. 3 SGB XI; HKP – psychiatrische Pflege, § 37a SGB V$t$, 1),
  ($t$Tagespflege und Pflege-WG$t$, $t$LEISTUNGSBAUSTEINE
- Tagespflege: Betreuung tagsüber mit Fahrdienst
  Katalog: Teilstationäre Pflege (§ 41 SGB XI), Pflegesatzvereinbarung
- Senioren-Wohngemeinschaft: Eigenes Zimmer, gemeinsamer Haushalt
  Katalog: Wohngruppenzuschlag (§ 38a SGB XI), Pflege nach § 89 SGB XI

VORAUSSETZUNGEN
Versorgungsvertrag für die Tagespflege, barrierefreie Immobilie, Landesrecht zu Wohnformen (die WG darf nicht als Heim gelten), freie Wahl des Pflegedienstes in der WG.

PERSONAL
Pflegefachkraft als Leitung der Tagespflege, Pflege- und Betreuungskräfte, Präsenzkräfte in der WG, Fahrer.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Eine Alternative zum Heim: tagsüber betreut in Gemeinschaft oder dauerhaft in einer kleinen Wohngemeinschaft. Angehörige können weiter arbeiten.$t$, $t$Tagespflege werktags etwa 8–16 Uhr mit Fahrdienst, Mahlzeiten und Aktivierung; ambulant betreute Wohngemeinschaft für 6–12 Pflegebedürftige mit Präsenzkraft.$t$, $t$Pflegebedürftige mit Pflegegrad 2–5, Angehörige, Betreuer, Sozialdienste der Kliniken$t$, array[$t$Dienstleistung$t$, $t$Miete$t$]::text[], $t$Tagessatz der Pflegekasse in der Tagespflege; Miete je WG-Zimmer, Wohngruppenzuschlag (rund 224 €/Monat je Bewohner), Pflegeleistungen$t$, $t$Bedarf mit dem Pflegestützpunkt klären und eine passende Immobilie für beide Nutzungen durchrechnen.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: Teilstationäre Pflege (§ 41 SGB XI), Pflegesatzvereinbarung; Wohngruppenzuschlag (§ 38a SGB XI), Pflege nach § 89 SGB XI$t$, 2),
  ($t$Hilfsmittel-Versorgung$t$, $t$LEISTUNGSBAUSTEINE
- Hilfsmittel für zu Hause: Liefern, aufbauen, einweisen
  Katalog: GKV-Hilfsmittelverzeichnis PG 04 Bade-/Duschhilfen, PG 10 Gehhilfen, PG 19 Krankenpflegeartikel, PG 33 Toilettenhilfen; Pflegehilfsmittelverzeichnis PG 50
- Pflegebedarf im Abo: Monatliche Lieferung, Antrag bei der Kasse
  Katalog: GKV-Hilfsmittelverzeichnis PG 15 Inkontinenzhilfen; Pflegehilfsmittelverzeichnis PG 54
- Aufbereitung und Wartung: Reinigen, prüfen, reparieren für den Wiedereinsatz
  Katalog: GKV-Hilfsmittelverzeichnis PG 18 Kranken-/Behindertenfahrzeuge, PG 22 Mobilitätshilfen; Pflegehilfsmittelverzeichnis PG 50

VORAUSSETZUNGEN
Präqualifizierung je Versorgungsbereich, Beitritt zu den Hilfsmittelverträgen, Lager und Lieferfahrzeug, Hygienekonzept für die Aufbereitung, Prüfungen nach Medizinprodukte-Betreiberverordnung.

PERSONAL
Geschulte Monteure und Fahrer, ein Techniker, eine Fachkraft für die Präqualifizierung (z. B. Pflegekraft oder Sanitätshaus-Erfahrung).$t$, $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$, $t$Pflegebedürftige bekommen Rollator, Badewannenlifter, Pflegebett und Pflegebedarf schnell nach Hause – ohne Weg ins Sanitätshaus. Sanitätshäuser und Kassen bekommen einen Partner für Aufbereitung und Wiedereinsatz.$t$, $t$Lieferung, Aufbau, Einweisung und Abholung von Standard-Hilfsmitteln; monatliches Abo für Pflegebedarf und Inkontinenzartikel; Reinigung, Prüfung und Aufbereitung gebrauchter Hilfsmittel.$t$, $t$Versicherte mit Verordnung, Pflegedienste, Kliniken (Entlassmanagement), Sanitätshäuser, Krankenkassen mit Hilfsmittelpool$t$, array[$t$Verkauf$t$, $t$Miete$t$, $t$Abo$t$, $t$Dienstleistung$t$]::text[], $t$Vertragspreise und Versorgungspauschalen der Kassen, Monatspauschale Pflegebedarf (bis 42 €), Pauschalen je Aufbereitung$t$, $t$Präqualifizierungsanforderungen anfordern und drei Pflegedienste sowie zwei Sanitätshäuser nach Lieferzeiten und ausgelagerten Arbeiten fragen.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: GKV-Hilfsmittelverzeichnis PG 04 Bade-/Duschhilfen, PG 10 Gehhilfen, PG 19 Krankenpflegeartikel, PG 33 Toilettenhilfen; Pflegehilfsmittelverzeichnis PG 50; GKV-Hilfsmittelverzeichnis PG 15 Inkontinenzhilfen; Pflegehilfsmittelverzeichnis PG 54; GKV-Hilfsmittelverzeichnis PG 18 Kranken-/Behindertenfahrzeuge, PG 22 Mobilitätshilfen; Pflegehilfsmittelverzeichnis PG 50$t$, 3),
  ($t$Barrierefreies Zuhause$t$, $t$LEISTUNGSBAUSTEINE
- Wohnumfeldverbesserung: Bad, Eingang, Türen
  Katalog: § 40 Abs. 4 SGB XI, KfW „Altersgerecht umbauen“
- Montage von Hilfsmitteln: Einbau im Auftrag von Sanitätshäusern
  Katalog: GKV-Hilfsmittelverzeichnis PG 22 Mobilitätshilfen (Lifter, Rampen), PG 04 (Haltegriffe); Pflegehilfsmittelverzeichnis PG 50

VORAUSSETZUNGEN
Meisterpflicht für Sanitär (angestellter Meister oder Partnerbetrieb); Fliesen und Trockenbau zulassungsfrei; Herstellerschulungen für Lifter.

PERSONAL
Handwerker und Hilfskräfte, ein Sanitärmeister.$t$, $t$F - Baugewerbe - Sekundär$t$, $t$Pflegebedürftige können zu Hause bleiben, weil Bad, Eingang und Treppen passen. Die Pflegekasse zahlt bis zu 4.180 € je Maßnahme, dazu kommt KfW-Förderung.$t$, $t$Beratung und Antrag bei der Pflegekasse, Umbau aus einer Hand (bodengleiche Dusche, Türverbreiterung, Rampen, Haltegriffe), Montage von Decken- und Wandliftern, Vermittlung von Treppenliften.$t$, $t$Pflegebedürftige und Angehörige, Pflegeberater, Hausverwaltungen, Sanitätshäuser (Montage im Auftrag)$t$, array[$t$Dienstleistung$t$]::text[], $t$Festpreise je Maßnahme, finanziert über Zuschuss und Eigenanteil; Montagepauschalen für Sanitätshäuser$t$, $t$Drei Pflegeberatungsstellen fragen, an wen sie heute verweisen und wie lange Kunden auf einen Umbau warten.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: § 40 Abs. 4 SGB XI, KfW „Altersgerecht umbauen“; GKV-Hilfsmittelverzeichnis PG 22 Mobilitätshilfen (Lifter, Rampen), PG 04 (Haltegriffe); Pflegehilfsmittelverzeichnis PG 50$t$, 4),
  ($t$Sicher zu Hause – Notruf, Assistenz und Pflege-Apps$t$, $t$LEISTUNGSBAUSTEINE
- Hausnotruf und Assistenzsysteme: Notrufgerät, Sensorik, Einsatzdienst
  Katalog: Pflegehilfsmittelverzeichnis PG 52
- Pflege- und Gesundheits-Apps: Eigene App mit Kassenvergütung
  Katalog: DiPA-Verzeichnis (§ 40a SGB XI), DiGA-Verzeichnis (§ 33a SGB V)

VORAUSSETZUNGEN
Vertrag mit den Pflegekassen, Notrufzentrale rund um die Uhr (Partner); für Apps Zulassung beim BfArM mit Nutzennachweis (aufwendig).

PERSONAL
Techniker für Installation, Entwickler, Pflegefachkraft als fachliche Begleitung, Einsatzkräfte (Partner).$t$, $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$, $t$Allein lebende Senioren rufen per Knopfdruck Hilfe, Sensoren erkennen Stürze, Apps unterstützen Pflege und Gesundheit – bezahlt von der Kasse.$t$, $t$Hausnotruf mit Notrufzentrale (Partner) und Einsatzdienst, Assistenzsysteme wie Sturzerkennung oder Herdabschaltung, eigene zugelassene Pflege- oder Gesundheits-App.$t$, $t$Senioren mit Pflegegrad, Angehörige, betreutes Wohnen, Wohnungsgesellschaften, Pflegekassen$t$, array[$t$Abo$t$, $t$Dienstleistung$t$]::text[], $t$Monatspauschale der Pflegekasse für den Hausnotruf (rund 25,50 €), Vergütung der App nach Aufnahme ins Verzeichnis, Zusatzleistungen privat$t$, $t$Mit einer Notrufzentrale über eine Partnerschaft sprechen und die gelisteten Pflege-Apps auf Lücken prüfen.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: Pflegehilfsmittelverzeichnis PG 52; DiPA-Verzeichnis (§ 40a SGB XI), DiGA-Verzeichnis (§ 33a SGB V)$t$, 5),
  ($t$Gesundheits-Fachhandel mit Meister$t$, $t$LEISTUNGSBAUSTEINE
- Sanitätshaus: Maßanfertigung, Werkstatt
  Katalog: GKV-Hilfsmittelverzeichnis PG 05 Bandagen, PG 08 Einlagen, PG 17 Kompression, PG 23 Orthesen
- Hörakustik: Hörtest, Anpassung, Service
  Katalog: GKV-Hilfsmittelverzeichnis PG 13 Hörhilfen

VORAUSSETZUNGEN
Orthopädietechnik- und Hörakustiker-Meister (Meisterpflicht), Ladenlokal mit Werkstatt und Messraum, Präqualifizierung.

PERSONAL
Orthopädietechnik-Meister, Hörakustiker-Meister, Fachverkäufer.$t$, $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$, $t$Patienten bekommen Bandagen, Kompression, Orthesen und Hörgeräte mit Anpassung vor Ort. Viele Fachgeschäfte auf dem Land schließen mangels Nachfolger.$t$, $t$Sanitätshaus mit Werkstatt und Hörakustik unter einem Dach, Kompressions- und Hörgeräteversorgung auch als Hausbesuch in Pflegeheimen.$t$, $t$Patienten mit Verordnung, Senioren, Pflegeheime, Fach- und HNO-Ärzte als Verordner$t$, array[$t$Verkauf$t$, $t$Dienstleistung$t$]::text[], $t$Vertragspreise und Festbeträge der Kassen, Eigenanteile für höherwertige Produkte, Servicepakete$t$, $t$Prüfen, ob ein Sanitätshaus oder Hörakustiker in der Region einen Nachfolger sucht.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: GKV-Hilfsmittelverzeichnis PG 05 Bandagen, PG 08 Einlagen, PG 17 Kompression, PG 23 Orthesen; GKV-Hilfsmittelverzeichnis PG 13 Hörhilfen$t$, 6),
  ($t$Gesundheitszentrum für Therapie und Geburt$t$, $t$LEISTUNGSBAUSTEINE
- Physio-, Ergo- und Sprachtherapie: Praxis und Hausbesuche
  Katalog: Heilmittelpositionsnummernverzeichnis, Verträge nach § 125 SGB V
- Podologie: Medizinische Fußpflege, v. a. bei Diabetes
  Katalog: Heilmittelpositionsnummernverzeichnis (podologische Therapie)
- Hebammenzentrum: Räume, Kurse, Organisation für Hebammen
  Katalog: Hebammenhilfevertrag mit Vergütungsverzeichnis (§ 134a SGB V)

VORAUSSETZUNGEN
Zulassung je Fachrichtung mit fachlicher Leitung, Praxisräume nach Vorgaben; Hebammen bleiben meist freiberuflich. Engpass: Fachkräftemangel.

PERSONAL
Therapeuten, Podologen, freiberufliche Hebammen, Rezeption und Abrechnung.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Patienten warten Wochen auf Therapie, Schwangere finden kaum eine Hebamme, Diabetiker kaum einen Podologen. Ein Zentrum bündelt diese Berufe unter einem Dach.$t$, $t$Praxis mit angestellten Physio-, Ergo- und Sprachtherapeuten sowie Podologen, Hausbesuche in Pflegeheimen; Räume, Kurse und Abrechnungsservice für freiberufliche Hebammen.$t$, $t$Patienten mit Heilmittelverordnung, Diabetiker, Pflegeheime, Schwangere und junge Familien, freiberufliche Hebammen$t$, array[$t$Dienstleistung$t$, $t$Miete$t$]::text[], $t$Vergütung je Behandlung nach Bundesvertrag, Hausbesuchspauschalen, Raummiete und Servicepauschale der Hebammen, Kurse$t$, $t$Zulassungsbedingungen klären und mit je drei Therapeuten und Hebammen sprechen, unter welchen Bedingungen sie mitmachen würden.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: Heilmittelpositionsnummernverzeichnis, Verträge nach § 125 SGB V; Heilmittelpositionsnummernverzeichnis (podologische Therapie); Hebammenhilfevertrag mit Vergütungsverzeichnis (§ 134a SGB V)$t$, 7),
  ($t$Gesundheits-Logistik$t$, $t$LEISTUNGSBAUSTEINE
- Krankenfahrten: Fahrten zu Arzt, Dialyse, Therapie
  Katalog: § 60 SGB V, Krankentransport-Richtlinie, Verträge mit den Krankenkassen
- Botendienst: Medikamente und Laborproben
  Katalog: Indirekt über die Arzneimittelversorgung (Botendienst der Apotheken)
- Klinik-Servicedienste: Hol- und Bringdienst, Bettenaufbereitung
  Katalog: Indirekt über die Klinikfinanzierung (G-DRG, PEPP) und Pflegesätze der Heime

VORAUSSETZUNGEN
Genehmigung für Krankenfahrten bzw. Mietwagen, Personenbeförderungsschein, rollstuhlgerechte Fahrzeuge, Kühlkette, Hygieneschulungen; Klinikdienste teils im Schichtbetrieb.

PERSONAL
Fahrer mit Personenbeförderungsschein, Servicekräfte ohne Pflegeausbildung.$t$, $t$H - Verkehr und Lagerei - Tertiär$t$, $t$Patienten kommen zuverlässig zu Dialyse, Therapie und Arzt, Medikamente kommen am selben Tag nach Hause, Kliniken entlasten ihre Pflegekräfte.$t$, $t$Sitzende Krankenfahrten und Rollstuhlfahrten, Botendienst für Apotheken und Laborproben, Hol- und Bringdienst sowie Bettenaufbereitung in Kliniken und Heimen.$t$, $t$Patienten mit Verordnung, Dialysezentren, Tagespflegen, Apotheken, Praxen und Labore, Kliniken und Pflegeheime$t$, array[$t$Dienstleistung$t$]::text[], $t$Vergütung je Fahrt nach Kassenvertrag, Pauschalen je Tour, Rahmenverträge mit Kliniken$t$, $t$Bei zwei Dialysezentren, drei Apotheken und einer Klinik nachfragen, was heute fehlt und was es kostet.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: § 60 SGB V, Krankentransport-Richtlinie, Verträge mit den Krankenkassen; Indirekt über die Arzneimittelversorgung (Botendienst der Apotheken); Indirekt über die Klinikfinanzierung (G-DRG, PEPP) und Pflegesätze der Heime$t$, 8),
  ($t$Abrechnungs- und Verwaltungsservice im Gesundheitswesen$t$, $t$LEISTUNGSBAUSTEINE
- Praxis-Abrechnung: Vollständige Abrechnung, Mehrerlös finden
  Katalog: EBM (ärztlich), BEMA (zahnärztlich), ergänzend GOÄ/GOZ
- Abrechnungszentrum: Heilmittel, Hilfsmittel, HKP, Pflegesachleistungen
  Katalog: Abrechnung nach § 302 SGB V und § 105 SGB XI

VORAUSSETZUNGEN
Fundiertes Abrechnungswissen, Datenaustausch mit den Kassen, Abrechnungssoftware, Datenschutz und Auftragsverarbeitung; Vorfinanzierung nur mit Finanzpartner.

PERSONAL
Zahnmedizinische Verwaltungsassistentin, Medizinische Fachangestellte mit Abrechnungserfahrung, Abrechnungsfachkräfte, IT.$t$, $t$N - Freiberufliche, wissenschaftliche und technische Dienstleistungen - Tertiär$t$, $t$Praxen, Pflegedienste und Therapeuten verlieren Zeit und Geld mit der Abrechnung und finden kaum Fachpersonal. Ein externer Service rechnet vollständig ab und zahlt schnell aus.$t$, $t$Abrechnung für Arzt- und Zahnarztpraxen mit Prüfung auf vergessene Leistungen; Kassenabrechnung für Pflegedienste, Alltagshilfen, Therapeuten und Hilfsmittel-Lieferanten; Mahnwesen, optional Vorfinanzierung, Schulungen.$t$, $t$Arzt- und Zahnarztpraxen, MVZ, Pflegedienste, Alltagshilfen, Therapiepraxen, Hilfsmittel-Lieferanten$t$, array[$t$Dienstleistung$t$, $t$Abo$t$, $t$Provision$t$]::text[], $t$Monatspauschale oder Prozentsatz vom abgerechneten Umsatz bzw. vom Mehrerlös$t$, $t$Zwei Praxen eine kostenlose Prüfung eines Quartals anbieten und drei kleine Pflegedienste nach ihren Abrechnungskosten fragen.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: EBM (ärztlich), BEMA (zahnärztlich), ergänzend GOÄ/GOZ; Abrechnung nach § 302 SGB V und § 105 SGB XI$t$, 9),
  ($t$Pflege-Akademie$t$, $t$LEISTUNGSBAUSTEINE
- Pflegekurse für Angehörige: Gruppenkurse und Schulungen zu Hause
  Katalog: § 45 SGB XI, Verträge mit den Pflegekassen
- Qualifizierung Betreuungskräfte: Kurse für Alltagsbegleiter und Betreuungskräfte
  Katalog: Landesverordnungen zu § 45a SGB XI, Richtlinie für Betreuungskräfte (§ 53b SGB XI)

VORAUSSETZUNGEN
Vertrag mit den Pflegekassen für Angehörigenkurse, Anerkennung der Lehrgänge, für Bildungsgutscheine AZAV-Zertifizierung, Schulungsräume.

PERSONAL
Dozenten (Pflegefachkräfte, Pädagogen), Kursorganisation.$t$, $t$Q - Erziehung und Unterricht - Tertiär$t$, $t$Angehörige lernen, richtig zu pflegen; Quereinsteiger finden einen Weg in die Branche; Pflegedienste und Alltagshilfen bekommen geschultes Personal.$t$, $t$Pflegekurse für Angehörige (in Gruppen und zu Hause), Qualifizierung von Alltagsbegleitern und Betreuungskräften, Basiskurse Pflegehilfe, Erste Hilfe und Hygiene, Inhouse-Schulungen.$t$, $t$Pflegende Angehörige, Quereinsteiger, Arbeitsagentur und Jobcenter (Bildungsgutschein), Pflegedienste, Heime, Alltagshilfen$t$, array[$t$Dienstleistung$t$]::text[], $t$Vergütung der Pflegekassen für Angehörigenkurse, Kursgebühren, Bildungsgutscheine$t$, $t$Klären, welche Kurse im Land anerkannt sind, und einen ersten Kurs für die Mitarbeiter des eigenen Entlastungsdienstes durchführen.$t$, $t$Brainstorming Kassenleistungen (zusammengefasst) – Kataloge: § 45 SGB XI, Verträge mit den Pflegekassen; Landesverordnungen zu § 45a SGB XI, Richtlinie für Betreuungskräfte (§ 53b SGB XI)$t$, 10)
) as v(title, description, branche, benefit, offer, customers, revenue_model, revenue_note, first_test, origin, pos)
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.ideas i where lower(i.title) = lower(v.title));

-- 3) Synergien
insert into public.idea_synergies (idea_a, idea_b, note, created_by)
select least(a.id, b.id), greatest(a.id, b.id), v.note, p.id
from (values
  ($t$Alltags- und Entlastungsdienst$t$, $t$Ambulanter Pflegedienst$t$, $t$Entlastungsdienst als Einstieg, Pflegedienst als Ausbau; Kunden wachsen mit$t$),
  ($t$Alltags- und Entlastungsdienst$t$, $t$Pflege-Akademie$t$, $t$Eigene Mitarbeiter schulen; Akademie als zweites Standbein$t$),
  ($t$Alltags- und Entlastungsdienst$t$, $t$Sicher zu Hause – Notruf, Assistenz und Pflege-Apps$t$, $t$Gleiche Zielgruppe: allein lebende Pflegebedürftige$t$),
  ($t$Alltags- und Entlastungsdienst$t$, $t$Hilfsmittel-Versorgung$t$, $t$Pflegebedarf-Abo für alle Kunden des Entlastungsdienstes$t$),
  ($t$Alltags- und Entlastungsdienst$t$, $t$Tagespflege und Pflege-WG$t$, $t$Entlastung zu Hause oder tageweise in der Tagespflege$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Tagespflege und Pflege-WG$t$, $t$Pflegedienst versorgt die WG; gleiche Pflegedienstleitung für die Tagespflege$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Hilfsmittel-Versorgung$t$, $t$Pflegedienst erkennt den Bedarf, Hilfsmittel-Versorgung liefert$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Pflege-Akademie$t$, $t$Pflegekurse und Beratungsbesuche mit denselben Pflegefachkräften$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Abrechnungs- und Verwaltungsservice im Gesundheitswesen$t$, $t$Eigene Abrechnung als Grundlage für den Service für andere$t$),
  ($t$Tagespflege und Pflege-WG$t$, $t$Gesundheits-Logistik$t$, $t$Tagespflege braucht täglich Fahrdienst$t$),
  ($t$Tagespflege und Pflege-WG$t$, $t$Barrierefreies Zuhause$t$, $t$Barrierefreier Umbau der Tagespflege- und WG-Räume$t$),
  ($t$Tagespflege und Pflege-WG$t$, $t$Sicher zu Hause – Notruf, Assistenz und Pflege-Apps$t$, $t$Notruf- und Assistenzsysteme in der WG$t$),
  ($t$Hilfsmittel-Versorgung$t$, $t$Barrierefreies Zuhause$t$, $t$Hilfsmittel liefern und montieren, Umbau aus einer Hand$t$),
  ($t$Hilfsmittel-Versorgung$t$, $t$Gesundheits-Fachhandel mit Meister$t$, $t$Hilfsmittel-Versorgung als Einstieg, Fachhandel als Ausbau$t$),
  ($t$Hilfsmittel-Versorgung$t$, $t$Gesundheits-Logistik$t$, $t$Gleiche Fahrzeuge und Touren$t$),
  ($t$Hilfsmittel-Versorgung$t$, $t$Sicher zu Hause – Notruf, Assistenz und Pflege-Apps$t$, $t$Hausnotruf ist ebenfalls ein Pflegehilfsmittel; gleiche Präqualifizierung und Kunden$t$),
  ($t$Gesundheitszentrum für Therapie und Geburt$t$, $t$Gesundheits-Logistik$t$, $t$Patienten zur Therapie fahren$t$),
  ($t$Gesundheitszentrum für Therapie und Geburt$t$, $t$Abrechnungs- und Verwaltungsservice im Gesundheitswesen$t$, $t$Eigenes Zentrum als erster Kunde des Abrechnungsservice$t$),
  ($t$Gesundheitszentrum für Therapie und Geburt$t$, $t$Alltags- und Entlastungsdienst$t$, $t$Haushaltshilfe für Familien in Schwangerschaft und Wochenbett$t$),
  ($t$Gesundheits-Fachhandel mit Meister$t$, $t$Gesundheitszentrum für Therapie und Geburt$t$, $t$Gleiche Patienten und verordnende Ärzte, gemeinsamer Standort möglich$t$),
  ($t$Pflege-Akademie$t$, $t$Gesundheitszentrum für Therapie und Geburt$t$, $t$Geburtsvorbereitungs- und Präventionskurse in denselben Räumen$t$),
  ($t$Alltags- und Entlastungsdienst$t$, $t$Alltags- und Digitalhilfe für Senioren$t$, $t$Gleiche Zielgruppe; mit Anerkennung zahlt die Pflegekasse$t$),
  ($t$Sicher zu Hause – Notruf, Assistenz und Pflege-Apps$t$, $t$Alltags- und Digitalhilfe für Senioren$t$, $t$Technik für Senioren einrichten und betreuen$t$),
  ($t$Barrierefreies Zuhause$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Eigene Handwerker für Umbau und Montage$t$),
  ($t$Hilfsmittel-Versorgung$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Monteure und Fahrer aus dem Handwerksbetrieb$t$),
  ($t$Barrierefreies Zuhause$t$, $t$Haus-Check im Abo für Eigenheimbesitzer$t$, $t$Haus-Check erkennt Umbaubedarf bei älteren Eigentümern$t$),
  ($t$Barrierefreies Zuhause$t$, $t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$Gleiche Gewerke; barrierefreie Renovierung für Vermieter$t$),
  ($t$Sicher zu Hause – Notruf, Assistenz und Pflege-Apps$t$, $t$App-Entwicklung mit KI$t$, $t$Gleiches Entwicklungs-Know-how$t$),
  ($t$Abrechnungs- und Verwaltungsservice im Gesundheitswesen$t$, $t$App-Entwicklung mit KI$t$, $t$Eigene Abrechnungssoftware als Grundlage$t$),
  ($t$Gesundheits-Fachhandel mit Meister$t$, $t$Unternehmensnachfolge – bestehenden Betrieb übernehmen$t$, $t$Bestehendes Fachgeschäft übernehmen statt neu gründen$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Unternehmensnachfolge – bestehenden Betrieb übernehmen$t$, $t$Bestehenden Pflegedienst übernehmen statt neu gründen$t$),
  ($t$Hilfsmittel-Versorgung$t$, $t$Werkzeugverleih per Schließfach-Automat$t$, $t$Ausgabe kleiner Hilfsmittel per Schließfach$t$),
  ($t$Hilfsmittel-Versorgung$t$, $t$Abholstationen für örtliche Geschäfte$t$, $t$Kleine Hilfsmittel und Pflegebedarf per Schließfach ausgeben$t$),
  ($t$Gesundheits-Logistik$t$, $t$Abholstationen für örtliche Geschäfte$t$, $t$Abholstation als Alternative zur Botenfahrt$t$)
) as v(ta, tb, note)
join public.ideas a on lower(a.title) = lower(v.ta)
join public.ideas b on lower(b.title) = lower(v.tb)
cross join (select id from public.profiles where slug = 'igor') p
on conflict (idea_a, idea_b) do nothing;
