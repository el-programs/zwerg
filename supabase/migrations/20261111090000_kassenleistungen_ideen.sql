-- Zwerg · Brainstorming „Kassenleistungen“: Geschäftsideen rund um Leistungen, die Kranken- und Pflegekassen bezahlen.
-- Neue Gruppe, 25 Ideen mit Steckbrief und Katalogangabe (angelegt von Igor, landen in der Vorauswahl), dazu Synergien.

insert into public.business_models (name, sort)
select $t$Gesundheit und Pflege (kassenfinanziert)$t$, 110
where not exists (select 1 from public.business_models where name = $t$Gesundheit und Pflege (kassenfinanziert)$t$);

insert into public.ideas (title, description, search_field_id, business_model_id, benefit, offer, customers,
                          revenue_model, revenue_note, first_test, origin, created_by, updated_by, created_at, updated_at)
select v.title, v.description,
       (select id from public.search_fields where name = v.branche and not archived limit 1),
       (select id from public.business_models where name = $t$Gesundheit und Pflege (kassenfinanziert)$t$),
       v.benefit, v.offer, v.customers, v.revenue_model, v.revenue_note, v.first_test, v.origin, p.id, p.id,
       now() - make_interval(secs => v.pos), now() - make_interval(secs => v.pos)
from (values
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$KATALOG
Angebote zur Unterstützung im Alltag (§ 45a SGB XI, Anerkennung nach Landesverordnung); Abrechnung über den Entlastungsbetrag (§ 45b SGB XI)

VORAUSSETZUNGEN
Anerkennung durch die zuständige Landesstelle, Konzept, Schulung der Mitarbeiter (je nach Land rund 30–160 Stunden), Abrechnung mit IK-Nummer.

PERSONAL
Alltagsbegleiter ohne Pflegeausbildung, eine fachliche Leitung (je nach Land z. B. Pflege- oder Sozialberuf).$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Pflegebedürftige bleiben länger selbständig zu Hause, Angehörige werden entlastet. Die Pflegekasse zahlt bis zu rund 131 € im Monat je Person, die oft ungenutzt verfallen.$t$, $t$Hilfe im Haushalt, Einkaufen, Begleitung zu Terminen und Spaziergänge, Gesellschaft und Betreuung, direkt mit der Pflegekasse abgerechnet.$t$, $t$Menschen mit Pflegegrad 1–5 und ihre Angehörigen in der Region$t$, array[$t$Dienstleistung$t$]::text[], $t$Stundensatz, abgerechnet über den Entlastungsbetrag; darüber hinaus privat$t$, $t$Anerkennungsvoraussetzungen im eigenen Bundesland prüfen und mit zwei Pflegeberatungsstellen sprechen, wie groß die Wartelisten sind.$t$, $t$Brainstorming Kassenleistungen – Katalog: Angebote zur Unterstützung im Alltag (§ 45a SGB XI, Anerkennung nach Landesverordnung); Abrechnung über den Entlastungsbetrag (§ 45b SGB XI)$t$, 0),
  ($t$Verhinderungs- und Betreuungsdienst stundenweise$t$, $t$KATALOG
Verhinderungspflege (§ 39 SGB XI) und gemeinsamer Jahresbetrag für Verhinderungs- und Kurzzeitpflege (§ 42a SGB XI)

VORAUSSETZUNGEN
Für die Abrechnung reicht meist die Bestätigung der Pflege durch eine geeignete Kraft; als Dienst bessere Akzeptanz mit Anerkennung wie bei der Alltagshilfe.

PERSONAL
Betreuungskräfte; dieselben Leute wie bei der Alltagshilfe.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Pflegende Angehörige bekommen planbar freie Stunden, ohne dass der Pflegebedürftige allein ist. Die Kasse zahlt dafür einen eigenen Jahresbetrag, der oft nicht ausgeschöpft wird.$t$, $t$Stundenweise Betreuung zu Hause während Arztterminen, Erholung oder Urlaub der Angehörigen, auch regelmäßig an festen Tagen.$t$, $t$Familien, die einen Angehörigen mit Pflegegrad 2–5 zu Hause pflegen$t$, array[$t$Dienstleistung$t$]::text[], $t$Stundensatz, abgerechnet über die Verhinderungspflege bzw. den Jahresbetrag$t$, $t$Bei 10 pflegenden Angehörigen nachfragen, ob und wofür sie den Jahresbetrag nutzen.$t$, $t$Brainstorming Kassenleistungen – Katalog: Verhinderungspflege (§ 39 SGB XI) und gemeinsamer Jahresbetrag für Verhinderungs- und Kurzzeitpflege (§ 42a SGB XI)$t$, 1),
  ($t$Ambulanter Pflegedienst$t$, $t$KATALOG
Vergütungsvereinbarungen für Pflegesachleistungen (§ 89 SGB XI) und Leistungsverzeichnis Häusliche Krankenpflege (§ 132a SGB V)

VORAUSSETZUNGEN
Versorgungsvertrag mit den Pflegekassen (§ 72 SGB XI), Vertrag mit den Krankenkassen, verantwortliche Pflegefachkraft mit Weiterbildung, Qualitätsprüfungen, Bereitschaft rund um die Uhr.

PERSONAL
Pflegedienstleitung und Stellvertretung (Pflegefachkräfte), Pflegefachkräfte, Pflegehilfskräfte, Verwaltung.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Menschen werden zu Hause gepflegt statt im Heim. Hoher, dauerhaft wachsender Bedarf; viele Dienste nehmen keine neuen Kunden mehr auf.$t$, $t$Grundpflege, Behandlungspflege nach ärztlicher Verordnung (Medikamente, Verbände, Spritzen), hauswirtschaftliche Versorgung.$t$, $t$Pflegebedürftige und Kranke in einem festen Einzugsgebiet, zuweisende Ärzte, Kliniken (Entlassmanagement)$t$, array[$t$Dienstleistung$t$]::text[], $t$Leistungskomplexe bzw. Zeitvergütung nach Landesvertrag; Behandlungspflege nach HKP-Vertrag mit den Krankenkassen$t$, $t$Mit einer erfahrenen Pflegedienstleitung sprechen, ob sie mitgründen würde, und die Wartelisten der Dienste vor Ort erfragen.$t$, $t$Brainstorming Kassenleistungen – Katalog: Vergütungsvereinbarungen für Pflegesachleistungen (§ 89 SGB XI) und Leistungsverzeichnis Häusliche Krankenpflege (§ 132a SGB V)$t$, 2),
  ($t$Tagespflege für Senioren$t$, $t$KATALOG
Teilstationäre Pflege (§ 41 SGB XI), Vergütung nach Pflegesatzvereinbarung

VORAUSSETZUNGEN
Versorgungsvertrag, geeignete barrierefreie Räume, Fahrzeuge, verantwortliche Pflegefachkraft; Investition in Umbau und Ausstattung.

PERSONAL
Pflegefachkraft als Leitung, Pflege- und Betreuungskräfte, Fahrer.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Pflegebedürftige verbringen den Tag betreut in Gemeinschaft, Angehörige können weiter arbeiten. Feste Öffnungszeiten tagsüber an Werktagen.$t$, $t$Betreuung von etwa 8 bis 16 Uhr mit Fahrdienst, Mahlzeiten, Aktivierung und Pflege.$t$, $t$Pflegebedürftige mit Pflegegrad 2–5, deren Angehörige berufstätig oder erschöpft sind$t$, array[$t$Dienstleistung$t$]::text[], $t$Tagessatz je Pflegegrad über die Pflegekasse, Eigenanteil für Verpflegung und Investitionskosten$t$, $t$Bedarfsanalyse mit der Pflegestützpunkt-Beratung und eine passende Immobilie (Erdgeschoss, ca. 300–400 m²) suchen.$t$, $t$Brainstorming Kassenleistungen – Katalog: Teilstationäre Pflege (§ 41 SGB XI), Vergütung nach Pflegesatzvereinbarung$t$, 3),
  ($t$Ambulant betreute Senioren-Wohngemeinschaft$t$, $t$KATALOG
Wohngruppenzuschlag (§ 38a SGB XI) plus Leistungen des Pflegedienstes (§ 89 SGB XI) und Entlastungsbetrag

VORAUSSETZUNGEN
Landesrecht zu Wohnformen (Heimgesetz-Nachfolger) genau beachten, damit die WG nicht als Heim gilt; freie Wahl des Pflegedienstes.

PERSONAL
Präsenzkräfte für die Alltagsorganisation; Pflege über einen Pflegedienst.$t$, $t$M - Grundstücks- und Wohnungswesen - Tertiär$t$, $t$Eine Alternative zum Heim: eigenes Zimmer, gemeinsamer Haushalt, Betreuung rund um die Uhr in kleiner Gruppe.$t$, $t$Vermietung einer großen Wohnung an 6–12 Pflegebedürftige, Organisation der Präsenzkraft; Pflege durch einen (eigenen oder fremden) Pflegedienst.$t$, $t$Pflegebedürftige und Angehörige, Betreuer, Sozialdienste der Kliniken$t$, array[$t$Miete$t$, $t$Dienstleistung$t$]::text[], $t$Miete je Zimmer, Betreuungspauschale aus dem Wohngruppenzuschlag (rund 224 € je Bewohner und Monat), Pflegeleistungen$t$, $t$Heimaufsicht und Pflegekasse zu den Regeln im Bundesland fragen und eine passende Immobilie durchrechnen.$t$, $t$Brainstorming Kassenleistungen – Katalog: Wohngruppenzuschlag (§ 38a SGB XI) plus Leistungen des Pflegedienstes (§ 89 SGB XI) und Entlastungsbetrag$t$, 4),
  ($t$Beratungsbesuche und Pflegekurse für Angehörige$t$, $t$KATALOG
Beratungsbesuche (§ 37 Abs. 3 SGB XI) und Pflegekurse für Angehörige (§ 45 SGB XI)

VORAUSSETZUNGEN
Anerkennung als Beratungsstelle bzw. Vertrag mit der Pflegekasse; Pflegefachkräfte mit Beratungskompetenz.

PERSONAL
Pflegefachkräfte (auch in Teilzeit oder als Rentner gut planbar, tagsüber).$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Wer Pflegegeld bezieht, muss regelmäßig einen Beratungsbesuch nachweisen; Angehörige wollen lernen, richtig zu pflegen.$t$, $t$Pflichtberatungsbesuche zu Hause, Pflegekurse in Gruppen und individuelle Schulungen in der Häuslichkeit.$t$, $t$Pflegegeld-Bezieher, pflegende Angehörige, Pflegekassen (Verträge für Kurse)$t$, array[$t$Dienstleistung$t$]::text[], $t$Fester Betrag je Beratungsbesuch von der Pflegekasse, Vergütung für Kurse nach Vertrag$t$, $t$Bei zwei Pflegekassen nachfragen, wie die Zulassung als Beratungsstelle und als Kursanbieter läuft.$t$, $t$Brainstorming Kassenleistungen – Katalog: Beratungsbesuche (§ 37 Abs. 3 SGB XI) und Pflegekurse für Angehörige (§ 45 SGB XI)$t$, 5),
  ($t$Haushaltshilfe nach Krankenhaus oder Schwangerschaft$t$, $t$KATALOG
Haushaltshilfe der Krankenkasse (§ 38 SGB V, § 24h SGB V bei Schwangerschaft)

VORAUSSETZUNGEN
Vertrag mit den Krankenkassen, zuverlässige Erreichbarkeit, Hygieneschulung.

PERSONAL
Haushaltshilfen, idealerweise mit Erfahrung in Kinderbetreuung.$t$, $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$, $t$Familien bekommen Hilfe, wenn ein Elternteil krank, im Krankenhaus oder in der Schwangerschaft ausfällt. Die Krankenkasse zahlt.$t$, $t$Kinderbetreuung, Kochen, Wäsche und Haushalt für die Dauer der Verordnung.$t$, $t$Familien mit Kindern unter 12 Jahren, Schwangere und Wöchnerinnen, Patienten nach Klinikaufenthalt$t$, array[$t$Dienstleistung$t$]::text[], $t$Stundensatz nach Vertrag mit den Krankenkassen$t$, $t$Mit zwei Krankenkassen klären, ob sie Verträge mit neuen Anbietern schließen und wie hoch die Sätze sind.$t$, $t$Brainstorming Kassenleistungen – Katalog: Haushaltshilfe der Krankenkasse (§ 38 SGB V, § 24h SGB V bei Schwangerschaft)$t$, 6),
  ($t$Hilfsmittel-Service für zu Hause$t$, $t$KATALOG
GKV-Hilfsmittelverzeichnis: PG 04 Bade- und Duschhilfen, PG 10 Gehhilfen, PG 19 Krankenpflegeartikel, PG 33 Toilettenhilfen; Pflegehilfsmittelverzeichnis PG 50 (Pflegebetten)

VORAUSSETZUNGEN
Präqualifizierung je Versorgungsbereich, Beitritt zu den Hilfsmittelverträgen der Kassen, Lager, Lieferfahrzeug.

PERSONAL
Geschulte Monteure und Fahrer; für die Präqualifizierung oft eine Fachkraft (z. B. Pflegekraft oder Sanitätshaus-Erfahrung).$t$, $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$, $t$Pflegebedürftige bekommen Rollator, Badewannenlifter, Toilettenstuhl oder Pflegebett schnell nach Hause geliefert, aufgebaut und erklärt – ohne Weg ins Sanitätshaus.$t$, $t$Lieferung, Aufbau, Einweisung und Abholung von Standard-Hilfsmitteln, Abrechnung direkt mit der Kasse; Mietbestand der Kassen verwalten.$t$, $t$Versicherte mit Verordnung, Pflegedienste, Kliniken (Entlassmanagement), Hausarztpraxen$t$, array[$t$Verkauf$t$, $t$Miete$t$, $t$Dienstleistung$t$]::text[], $t$Vertragspreise bzw. Versorgungspauschalen der Kassen; Miete für Pflegebetten$t$, $t$Die Präqualifizierungsanforderungen für die vier Produktgruppen anfordern und drei Pflegedienste fragen, wie zufrieden sie mit den Lieferzeiten sind.$t$, $t$Brainstorming Kassenleistungen – Katalog: GKV-Hilfsmittelverzeichnis: PG 04 Bade- und Duschhilfen, PG 10 Gehhilfen, PG 19 Krankenpflegeartikel, PG 33 Toilettenhilfen; Pflegehilfsmittelverzeichnis PG 50 (Pflegebetten)$t$, 7),
  ($t$Montage, Wartung und Aufbereitung von Hilfsmitteln$t$, $t$KATALOG
GKV-Hilfsmittelverzeichnis: PG 18 Kranken-/Behindertenfahrzeuge, PG 22 Mobilitätshilfen (Lifter, Rampen); Pflegehilfsmittelverzeichnis PG 50 (Pflegebetten, Treppenfahrzeuge)

VORAUSSETZUNGEN
Herstellerschulungen, Hygienekonzept für die Aufbereitung, Werkstatt und Fahrzeuge; Prüfungen nach Medizinprodukte-Betreiberverordnung.

PERSONAL
Handwerklich geschickte Monteure, ein Techniker für Prüfungen.$t$, $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$, $t$Sanitätshäuser und Kassen bekommen einen zuverlässigen Partner, der Hilfsmittel einbaut, prüft und wieder einsatzbereit macht – ein Engpass in der Branche.$t$, $t$Montage von Deckenliftern, Wandliftern, Rampen und Griffen; sicherheitstechnische Kontrollen; Reinigung, Desinfektion und Reparatur gebrauchter Hilfsmittel für den Wiedereinsatz.$t$, $t$Sanitätshäuser, Hilfsmittel-Leistungserbringer, Krankenkassen mit eigenem Hilfsmittelpool, Pflegeheime$t$, array[$t$Dienstleistung$t$]::text[], $t$Pauschalen je Montage, Prüfung oder Aufbereitung; Rahmenverträge$t$, $t$Fünf Sanitätshäuser fragen, was sie heute für Montage und Aufbereitung auslagern und zu welchen Preisen.$t$, $t$Brainstorming Kassenleistungen – Katalog: GKV-Hilfsmittelverzeichnis: PG 18 Kranken-/Behindertenfahrzeuge, PG 22 Mobilitätshilfen (Lifter, Rampen); Pflegehilfsmittelverzeichnis PG 50 (Pflegebetten, Treppenfahrzeuge)$t$, 8),
  ($t$Hausnotruf und Assistenzsysteme$t$, $t$KATALOG
Pflegehilfsmittelverzeichnis PG 52: Notrufsysteme und Assistenzsysteme

VORAUSSETZUNGEN
Vertrag mit den Pflegekassen, Notrufzentrale rund um die Uhr (meist Partner), Einsatzdienst in der Region.

PERSONAL
Techniker für Installation, Einsatzkräfte (Partner oder eigener Dienst).$t$, $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$, $t$Allein lebende Senioren können per Knopfdruck Hilfe rufen; Angehörige sind beruhigt. Die Pflegekasse zahlt einen monatlichen Betrag.$t$, $t$Hausnotruf-Gerät mit Notrufzentrale (eigene oder Partner), Schlüsselhinterlegung, Einsatzdienst; später Sensoren wie Sturzerkennung oder Herdabschaltung.$t$, $t$Senioren mit Pflegegrad, Angehörige, Wohnungsgesellschaften, betreutes Wohnen$t$, array[$t$Abo$t$, $t$Dienstleistung$t$]::text[], $t$Monatliche Pauschale der Pflegekasse (rund 25,50 €), Zusatzleistungen privat$t$, $t$Mit einer Notrufzentrale über eine Partnerschaft sprechen und die Aufnahme ins Verzeichnis bzw. den Vertrag mit den Pflegekassen klären.$t$, $t$Brainstorming Kassenleistungen – Katalog: Pflegehilfsmittelverzeichnis PG 52: Notrufsysteme und Assistenzsysteme$t$, 9),
  ($t$Inkontinenz- und Pflegebedarf im Abo$t$, $t$KATALOG
GKV-Hilfsmittelverzeichnis PG 15 Inkontinenzhilfen; Pflegehilfsmittelverzeichnis PG 54 Zum Verbrauch bestimmte Pflegehilfsmittel

VORAUSSETZUNGEN
Präqualifizierung, Verträge mit den Kassen, Einkauf und Versandlogistik. Markt stark umkämpft – Vorteil nur über persönliche Betreuung vor Ort.

PERSONAL
Wenig Personal: Kundenservice und Logistik.$t$, $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$, $t$Pflegebedürftige bekommen monatlich Handschuhe, Desinfektion, Bettschutz und Inkontinenzartikel nach Hause, ohne sich um Anträge kümmern zu müssen.$t$, $t$Monatliche Lieferung, Antragstellung bei der Kasse, persönliche Beratung zur passenden Größe und Saugstärke.$t$, $t$Pflegebedürftige zu Hause, pflegende Angehörige, Pflegedienste als Vermittler$t$, array[$t$Abo$t$, $t$Verkauf$t$]::text[], $t$Monatspauschale der Pflegekasse (bis 42 €) bzw. Versorgungspauschale der Krankenkasse für Inkontinenz$t$, $t$Preise und Margen der großen Online-Anbieter vergleichen und mit zwei Pflegediensten über Empfehlungen sprechen.$t$, $t$Brainstorming Kassenleistungen – Katalog: GKV-Hilfsmittelverzeichnis PG 15 Inkontinenzhilfen; Pflegehilfsmittelverzeichnis PG 54 Zum Verbrauch bestimmte Pflegehilfsmittel$t$, 10),
  ($t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$KATALOG
Wohnumfeldverbessernde Maßnahmen (§ 40 Abs. 4 SGB XI), ergänzend KfW-Förderung „Altersgerecht umbauen“

VORAUSSETZUNGEN
Meisterpflicht für Sanitär (Installateur) – angestellter Meister oder Partnerbetrieb; Fliesen und Trockenbau zulassungsfrei.

PERSONAL
Handwerker und Hilfskräfte, ein Sanitärmeister (angestellt oder Partner).$t$, $t$F - Baugewerbe - Sekundär$t$, $t$Pflegebedürftige können zu Hause bleiben, weil Bad, Eingang und Treppen passen. Die Pflegekasse zahlt bis zu 4.180 € je Maßnahme.$t$, $t$Beratung, Antrag bei der Pflegekasse, Umbau aus einer Hand: bodengleiche Dusche, Haltegriffe, Rampen, Türverbreiterung, Treppenlift-Vermittlung.$t$, $t$Pflegebedürftige und Angehörige, Pflegeberater, Hausverwaltungen$t$, array[$t$Dienstleistung$t$]::text[], $t$Festpreise je Maßnahme, finanziert über Zuschuss und Eigenanteil$t$, $t$Drei Pflegeberatungsstellen fragen, an wen sie heute für Umbauten verweisen und wie lange Kunden warten.$t$, $t$Brainstorming Kassenleistungen – Katalog: Wohnumfeldverbessernde Maßnahmen (§ 40 Abs. 4 SGB XI), ergänzend KfW-Förderung „Altersgerecht umbauen“$t$, 11),
  ($t$Therapiezentrum für Physio-, Ergo- und Sprachtherapie$t$, $t$KATALOG
Bundeseinheitliches Heilmittelpositionsnummernverzeichnis (Physiotherapie, Ergotherapie, Stimm-, Sprech-, Sprach- und Schlucktherapie); Verträge nach § 125 SGB V

VORAUSSETZUNGEN
Zulassung je Fachrichtung, fachliche Leitung mit Berufsabschluss und Berufserfahrung, Praxisräume nach Vorgaben. Engpass: Fachkräftemangel.

PERSONAL
Physiotherapeuten, Ergotherapeuten, Logopäden; Rezeption und Abrechnung.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Patienten warten oft Wochen auf einen Termin. Ein Zentrum mit mehreren Fachrichtungen und Hausbesuchen schließt die Lücke.$t$, $t$Praxis mit angestellten Therapeuten, Hausbesuche in Pflegeheimen und bei Patienten zu Hause, Präventionskurse.$t$, $t$Patienten mit Heilmittelverordnung, Pflegeheime, Ärzte als Verordner$t$, array[$t$Dienstleistung$t$]::text[], $t$Vergütung je Behandlungsposition nach Bundesvertrag, Hausbesuchspauschalen, Präventionskurse privat$t$, $t$Die Zulassungsbedingungen klären und drei Therapeuten fragen, unter welchen Bedingungen sie wechseln würden.$t$, $t$Brainstorming Kassenleistungen – Katalog: Bundeseinheitliches Heilmittelpositionsnummernverzeichnis (Physiotherapie, Ergotherapie, Stimm-, Sprech-, Sprach- und Schlucktherapie); Verträge nach § 125 SGB V$t$, 12),
  ($t$Podologie-Praxis mit Hausbesuchen$t$, $t$KATALOG
Bundeseinheitliches Heilmittelpositionsnummernverzeichnis (Podologische Therapie, v. a. diabetisches Fußsyndrom)

VORAUSSETZUNGEN
Zulassung als Heilmittelerbringer, staatlich anerkannte Podologen, Praxisausstattung (überschaubare Investition).

PERSONAL
Podologen, später Fußpflegekräfte für Privatleistungen.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Diabetiker brauchen regelmäßige medizinische Fußpflege, um Wunden und Amputationen zu vermeiden. Es gibt viel zu wenige Podologen.$t$, $t$Podologische Behandlung in der Praxis und als Hausbesuch, ergänzend kosmetische Fußpflege privat.$t$, $t$Diabetiker mit Verordnung, Pflegeheime, Senioren$t$, array[$t$Dienstleistung$t$]::text[], $t$Vergütung je Behandlung nach Kassenvertrag, Privatleistungen$t$, $t$Mit zwei Diabetologen sprechen, wie lange ihre Patienten auf einen Podologen warten.$t$, $t$Brainstorming Kassenleistungen – Katalog: Bundeseinheitliches Heilmittelpositionsnummernverzeichnis (Podologische Therapie, v. a. diabetisches Fußsyndrom)$t$, 13),
  ($t$Fahrdienst zu Arztterminen und Therapien$t$, $t$KATALOG
Krankenfahrten (§ 60 SGB V, Krankentransport-Richtlinie); Verträge mit den Krankenkassen

VORAUSSETZUNGEN
Genehmigung für Mietwagen bzw. Krankenfahrten, Personenbeförderungsschein der Fahrer, rollstuhlgerechte Fahrzeuge, Verträge mit den Kassen.

PERSONAL
Fahrer mit Personenbeförderungsschein.$t$, $t$H - Verkehr und Lagerei - Tertiär$t$, $t$Patienten ohne Auto kommen zuverlässig zu Dialyse, Bestrahlung, Therapie und Arzt. Feste Termine, vor allem tagsüber.$t$, $t$Sitzende Krankenfahrten, Fahrten im Rollstuhl, Begleitung bis in die Praxis.$t$, $t$Patienten mit Verordnung, Dialysezentren, Pflegeheime, Tagespflegen$t$, array[$t$Dienstleistung$t$]::text[], $t$Vergütung je Fahrt bzw. Kilometer nach Vertrag mit den Krankenkassen, Privatfahrten$t$, $t$Bei zwei Dialysezentren nachfragen, wie zuverlässig die heutigen Fahrdienste sind.$t$, $t$Brainstorming Kassenleistungen – Katalog: Krankenfahrten (§ 60 SGB V, Krankentransport-Richtlinie); Verträge mit den Krankenkassen$t$, 14),
  ($t$Hebammenzentrum$t$, $t$KATALOG
Hebammenhilfevertrag mit Vergütungsverzeichnis (§ 134a SGB V)

VORAUSSETZUNGEN
Hebammen bleiben meist freiberuflich und rechnen selbst ab; das Zentrum ist Dienstleister. Kursräume, Software, Datenschutz.

PERSONAL
Hebammen (freiberuflich), Verwaltungskraft.$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Schwangere finden kaum noch eine Hebamme. Ein Zentrum nimmt freiberuflichen Hebammen Räume, Verwaltung und Abrechnung ab, damit sie mehr Familien betreuen können.$t$, $t$Räume für Vorsorge und Kurse, Organisation der Termine, Abrechnungsservice, Geburtsvorbereitungs- und Rückbildungskurse.$t$, $t$Freiberufliche Hebammen, Schwangere und junge Familien$t$, array[$t$Miete$t$, $t$Dienstleistung$t$]::text[], $t$Raummiete und Servicepauschale der Hebammen; Kurse nach Vergütungsverzeichnis$t$, $t$Mit fünf Hebammen sprechen, was sie am meisten Zeit kostet und was sie für Entlastung zahlen würden.$t$, $t$Brainstorming Kassenleistungen – Katalog: Hebammenhilfevertrag mit Vergütungsverzeichnis (§ 134a SGB V)$t$, 15),
  ($t$Abrechnungs- und Praxisservice für Arzt- und Zahnarztpraxen$t$, $t$KATALOG
EBM (Einheitlicher Bewertungsmaßstab) und BEMA (zahnärztlich), ergänzend GOÄ/GOZ

VORAUSSETZUNGEN
Fundiertes Abrechnungswissen, Datenschutz und Auftragsverarbeitung, Schweigepflicht.

PERSONAL
Zahnmedizinische Verwaltungsassistentin (ZMV), Medizinische Fachangestellte mit Abrechnungserfahrung.$t$, $t$N - Freiberufliche, wissenschaftliche und technische Dienstleistungen - Tertiär$t$, $t$Praxen verlieren Geld durch unvollständige Abrechnung und finden kaum Fachpersonal. Ein externer Service rechnet vollständig ab und entlastet das Team.$t$, $t$Abrechnung nach EBM/BEMA, Prüfung auf vergessene Leistungen, Schulungen, Unterstützung bei Praxis-IT und Hygienedokumentation.$t$, $t$Haus- und Facharztpraxen, Zahnarztpraxen, MVZ$t$, array[$t$Dienstleistung$t$, $t$Abo$t$]::text[], $t$Monatspauschale oder Prozentsatz des Mehrerlöses$t$, $t$Zwei Praxen eine kostenlose Abrechnungsprüfung eines Quartals anbieten und den gefundenen Mehrerlös zeigen.$t$, $t$Brainstorming Kassenleistungen – Katalog: EBM (Einheitlicher Bewertungsmaßstab) und BEMA (zahnärztlich), ergänzend GOÄ/GOZ$t$, 16),
  ($t$Abrechnungszentrum für Pflege- und Heilmittelanbieter$t$, $t$KATALOG
Abrechnung nach § 302 SGB V und § 105 SGB XI für Heilmittel, Hilfsmittel, Häusliche Krankenpflege und Pflegesachleistungen

VORAUSSETZUNGEN
Datenaustausch mit den Kassen, Abrechnungssoftware, Datenschutz; Factoring nur mit Finanzpartner.

PERSONAL
Abrechnungsfachkräfte, IT.$t$, $t$N - Freiberufliche, wissenschaftliche und technische Dienstleistungen - Tertiär$t$, $t$Kleine Pflegedienste, Therapiepraxen und Alltagshilfen verlieren Zeit und Geld mit der Kassenabrechnung. Ein Zentrum rechnet ab und zahlt schnell aus.$t$, $t$Abrechnung mit allen Kassen, Kontrolle von Verordnungen, Mahnwesen, optional Vorfinanzierung (Factoring).$t$, $t$Pflegedienste, Alltagshilfen, Therapiepraxen, Hilfsmittel-Lieferanten$t$, array[$t$Dienstleistung$t$, $t$Provision$t$]::text[], $t$Prozentsatz vom abgerechneten Umsatz$t$, $t$Mit drei kleinen Pflegediensten sprechen, wie sie heute abrechnen und was es kostet.$t$, $t$Brainstorming Kassenleistungen – Katalog: Abrechnung nach § 302 SGB V und § 105 SGB XI für Heilmittel, Hilfsmittel, Häusliche Krankenpflege und Pflegesachleistungen$t$, 17),
  ($t$Digitale Pflege- und Gesundheitsanwendungen$t$, $t$KATALOG
Verzeichnis für Digitale Pflegeanwendungen (DiPA, § 40a SGB XI) und Digitale Gesundheitsanwendungen (DiGA, § 33a SGB V)

VORAUSSETZUNGEN
Zulassung beim BfArM mit Nachweis von Nutzen, Datenschutz und Sicherheit – aufwendig und langwierig; Medizinprodukt-Recht.

PERSONAL
Entwickler, Pflegefachkraft als fachliche Begleitung.$t$, $t$K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär$t$, $t$Pflegebedürftige und Angehörige bekommen eine App, die die Kasse bezahlt – z. B. für Sturzprävention, Gedächtnistraining oder die Organisation der Pflege.$t$, $t$Entwicklung einer zugelassenen App mit fachlichem Partner, Begleitung durch Schulung oder Pflegedienst.$t$, $t$Pflegebedürftige, Angehörige, Pflegekassen$t$, array[$t$Abo$t$]::text[], $t$Vergütung durch die Kasse nach Aufnahme ins Verzeichnis$t$, $t$Die bisher gelisteten DiPA ansehen, eine Lücke suchen und mit zwei Pflegekräften testen, ob sie sie empfehlen würden.$t$, $t$Brainstorming Kassenleistungen – Katalog: Verzeichnis für Digitale Pflegeanwendungen (DiPA, § 40a SGB XI) und Digitale Gesundheitsanwendungen (DiGA, § 33a SGB V)$t$, 18),
  ($t$Servicedienste für Kliniken und Pflegeheime$t$, $t$KATALOG
Indirekt über die Klinikfinanzierung (G-DRG, PEPP) und die Pflegesätze der Heime

VORAUSSETZUNGEN
Ausschreibungen, Hygieneschulungen, zuverlässige Personalplanung im Schichtbetrieb (abends/Wochenende möglich).

PERSONAL
Servicekräfte ohne Pflegeausbildung.$t$, $t$O - Sonstige wirtschaftliche Dienstleistungen - Tertiär$t$, $t$Kliniken und Heime entlasten ihre Pflegekräfte von Aufgaben ohne Pflegebezug und sparen Kosten.$t$, $t$Hol- und Bringdienst für Patienten im Haus, Bettenaufbereitung, Versorgungsassistenz (Material auffüllen), Botendienste.$t$, $t$Krankenhäuser, psychiatrische Kliniken, Reha-Kliniken, Pflegeheime$t$, array[$t$Dienstleistung$t$]::text[], $t$Rahmenvertrag mit Stunden- oder Leistungspauschalen$t$, $t$Bei zwei Kliniken in der Region nachfragen, welche Servicedienste sie ausschreiben oder auslagern.$t$, $t$Brainstorming Kassenleistungen – Katalog: Indirekt über die Klinikfinanzierung (G-DRG, PEPP) und die Pflegesätze der Heime$t$, 19),
  ($t$Botendienst für Apotheken und Praxen$t$, $t$KATALOG
Indirekt über die Arzneimittelversorgung (Botendienst der Apotheken, Arzneimittel-Festbeträge)

VORAUSSETZUNGEN
Vorgaben zur Arzneimittelübergabe (Botendienst unter Verantwortung der Apotheke), Kühlkette, Datenschutz.

PERSONAL
Fahrer (Minijob oder Teilzeit).$t$, $t$H - Verkehr und Lagerei - Tertiär$t$, $t$Apotheken liefern immer mehr nach Hause, haben aber kein Personal dafür. Patienten bekommen Medikamente am selben Tag.$t$, $t$Tourenplanung und Auslieferung für mehrere Apotheken, Transport von Laborproben für Praxen.$t$, $t$Apotheken, Arztpraxen, Labore$t$, array[$t$Dienstleistung$t$]::text[], $t$Pauschale je Tour oder Lieferung$t$, $t$Drei Apotheken fragen, wie viele Botenfahrten sie täglich haben und was sie dafür zahlen.$t$, $t$Brainstorming Kassenleistungen – Katalog: Indirekt über die Arzneimittelversorgung (Botendienst der Apotheken, Arzneimittel-Festbeträge)$t$, 20),
  ($t$Sanitätshaus mit angestelltem Orthopädietechnik-Meister$t$, $t$KATALOG
GKV-Hilfsmittelverzeichnis u. a. PG 05 Bandagen, PG 08 Einlagen, PG 17 Kompressionstherapie, PG 23 Orthesen

VORAUSSETZUNGEN
Meister oder gleichwertige Qualifikation für die Präqualifizierung der Fachbereiche, Ladenlokal, Werkstatt.

PERSONAL
Orthopädietechnik-Meister, Fachverkäufer für Sanitätshausbedarf.$t$, $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$, $t$Patienten bekommen Bandagen, Kompressionsstrümpfe und Orthesen mit Maßanfertigung vor Ort – viele Sanitätshäuser auf dem Land schließen mangels Nachfolger.$t$, $t$Vollsortiment-Sanitätshaus mit Werkstatt; Kompressionsversorgung auch als Hausbesuch.$t$, $t$Patienten mit Verordnung, Ärzte, Pflegeheime$t$, array[$t$Verkauf$t$, $t$Dienstleistung$t$]::text[], $t$Vertragspreise der Kassen plus private Zuzahlungen und Zusatzverkäufe$t$, $t$Prüfen, ob ein Sanitätshaus in der Region einen Nachfolger sucht (Synergie zur Unternehmensnachfolge).$t$, $t$Brainstorming Kassenleistungen – Katalog: GKV-Hilfsmittelverzeichnis u. a. PG 05 Bandagen, PG 08 Einlagen, PG 17 Kompressionstherapie, PG 23 Orthesen$t$, 21),
  ($t$Hörakustik-Fachgeschäft mit angestelltem Meister$t$, $t$KATALOG
GKV-Hilfsmittelverzeichnis PG 13 Hörhilfen

VORAUSSETZUNGEN
Hörakustiker-Meister (Meisterpflicht), Messraum, Präqualifizierung.

PERSONAL
Hörakustiker-Meister, Hörakustiker.$t$, $t$G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär$t$, $t$Schwerhörigkeit nimmt mit dem Alter zu; gute Anpassung und Hausbesuche in Heimen fehlen oft.$t$, $t$Hörtest, Anpassung und Service für Hörgeräte, Hausbesuche in Pflegeheimen.$t$, $t$Senioren, Pflegeheime, HNO-Ärzte als Verordner$t$, array[$t$Verkauf$t$, $t$Dienstleistung$t$]::text[], $t$Festbetrag der Kasse plus Eigenanteil für höherwertige Geräte, Service-Pakete$t$, $t$Die Dichte der Hörakustiker in der Region und die Gehaltsvorstellungen eines Meisters prüfen.$t$, $t$Brainstorming Kassenleistungen – Katalog: GKV-Hilfsmittelverzeichnis PG 13 Hörhilfen$t$, 22),
  ($t$Ambulante psychiatrische Pflege und Soziotherapie$t$, $t$KATALOG
Häusliche Krankenpflege – psychiatrische Pflege (HKP-Leistungsverzeichnis), Soziotherapie (§ 37a SGB V)

VORAUSSETZUNGEN
Vertrag mit den Krankenkassen, Fachkräfte mit psychiatrischer Zusatzqualifikation, meist unter einem Pflegedienst.

PERSONAL
Pflegefachkräfte mit Fachweiterbildung Psychiatrie, Sozialarbeiter (Soziotherapie).$t$, $t$R - Gesundheits- und Sozialwesen - Tertiär$t$, $t$Menschen mit psychischen Erkrankungen werden zu Hause stabilisiert, Klinikaufenthalte verkürzt oder vermieden. Großer, kaum gedeckter Bedarf.$t$, $t$Hausbesuche durch psychiatrische Fachpflege, Begleitung im Alltag, Koordination mit Ärzten und Kliniken.$t$, $t$Patienten mit Verordnung, psychiatrische Kliniken und Praxen$t$, array[$t$Dienstleistung$t$]::text[], $t$Vergütung je Einsatz nach Vertrag mit den Krankenkassen$t$, $t$Mit einer psychiatrischen Institutsambulanz sprechen, wie viele Patienten ohne Anschlussversorgung entlassen werden.$t$, $t$Brainstorming Kassenleistungen – Katalog: Häusliche Krankenpflege – psychiatrische Pflege (HKP-Leistungsverzeichnis), Soziotherapie (§ 37a SGB V)$t$, 23),
  ($t$Schulungsakademie für Alltagsbegleiter und Betreuungskräfte$t$, $t$KATALOG
Qualifizierung nach den Landesverordnungen zu § 45a SGB XI und nach der Richtlinie für Betreuungskräfte (§ 53b SGB XI)

VORAUSSETZUNGEN
Anerkennung der Lehrgänge, für Bildungsgutscheine AZAV-Zertifizierung, Dozenten aus der Pflege.

PERSONAL
Dozenten (Pflegefachkräfte, Pädagogen), Kursorganisation.$t$, $t$Q - Erziehung und Unterricht - Tertiär$t$, $t$Alltagshilfen, Pflegedienste und Heime brauchen geschultes Personal; Quereinsteiger finden einen Weg in die Branche.$t$, $t$Kurse für Alltagsbegleiter und Betreuungskräfte, Pflegehilfe-Basiskurse, Erste Hilfe und Hygiene, Inhouse-Schulungen.$t$, $t$Quereinsteiger, Arbeitsagentur und Jobcenter (Bildungsgutschein), Pflegedienste, Heime$t$, array[$t$Dienstleistung$t$]::text[], $t$Kursgebühren, Bildungsgutscheine (mit AZAV-Zulassung)$t$, $t$Prüfen, welche Kurse im Land anerkannt sind, und einen ersten Kurs für die eigene Alltagshilfe durchführen.$t$, $t$Brainstorming Kassenleistungen – Katalog: Qualifizierung nach den Landesverordnungen zu § 45a SGB XI und nach der Richtlinie für Betreuungskräfte (§ 53b SGB XI)$t$, 24)
) as v(title, description, branche, benefit, offer, customers, revenue_model, revenue_note, first_test, origin, pos)
cross join (select id from public.profiles where slug = 'igor') p
where not exists (select 1 from public.ideas i where lower(i.title) = lower(v.title));

insert into public.idea_synergies (idea_a, idea_b, note, created_by)
select least(a.id, b.id), greatest(a.id, b.id), v.note, p.id
from (values
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Verhinderungs- und Betreuungsdienst stundenweise$t$, $t$Gleiche Kunden und Mitarbeiter; beide Budgets ergänzen sich$t$),
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Ambulanter Pflegedienst$t$, $t$Alltagshilfe als Einstieg, Pflegedienst als Ausbaustufe; Kunden wachsen mit$t$),
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Hausnotruf und Assistenzsysteme$t$, $t$Gleiche Zielgruppe: allein lebende Pflegebedürftige$t$),
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Inkontinenz- und Pflegebedarf im Abo$t$, $t$Pflegebedarf-Abo als Zusatzangebot für alle Kunden der Alltagshilfe$t$),
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Schulungsakademie für Alltagsbegleiter und Betreuungskräfte$t$, $t$Eigene Mitarbeiter schulen, Akademie als zweites Standbein$t$),
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Beratungsbesuche und Pflegekurse für Angehörige$t$, $t$Beratungsbesuche bringen neue Kunden für die Alltagshilfe$t$),
  ($t$Verhinderungs- und Betreuungsdienst stundenweise$t$, $t$Tagespflege für Senioren$t$, $t$Entlastung für Angehörige: stundenweise zu Hause oder tageweise in der Tagespflege$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Ambulant betreute Senioren-Wohngemeinschaft$t$, $t$Pflegedienst versorgt die Wohngemeinschaft$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Tagespflege für Senioren$t$, $t$Gleiche Pflegedienstleitung und Kunden; Tagespflege als zweites Standbein$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Beratungsbesuche und Pflegekurse für Angehörige$t$, $t$Beratungsbesuche sind typisches Angebot eines Pflegedienstes$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Ambulante psychiatrische Pflege und Soziotherapie$t$, $t$Psychiatrische Pflege als spezialisierter Zweig des Pflegedienstes$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Hilfsmittel-Service für zu Hause$t$, $t$Pflegedienst erkennt den Bedarf, Hilfsmittel-Service liefert$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Abrechnungszentrum für Pflege- und Heilmittelanbieter$t$, $t$Eigene Abrechnung als Grundlage für den Service für andere$t$),
  ($t$Tagespflege für Senioren$t$, $t$Fahrdienst zu Arztterminen und Therapien$t$, $t$Tagespflege braucht täglich Fahrdienst$t$),
  ($t$Ambulant betreute Senioren-Wohngemeinschaft$t$, $t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$Barrierefreier Umbau der WG-Wohnung$t$),
  ($t$Ambulant betreute Senioren-Wohngemeinschaft$t$, $t$Hausnotruf und Assistenzsysteme$t$, $t$Notruf- und Assistenzsysteme in der WG$t$),
  ($t$Hilfsmittel-Service für zu Hause$t$, $t$Montage, Wartung und Aufbereitung von Hilfsmitteln$t$, $t$Gleiche Produkte: liefern, montieren, warten, aufbereiten$t$),
  ($t$Hilfsmittel-Service für zu Hause$t$, $t$Inkontinenz- und Pflegebedarf im Abo$t$, $t$Gleiche Präqualifizierung, gleiche Kunden und Lieferfahrten$t$),
  ($t$Hilfsmittel-Service für zu Hause$t$, $t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$Hilfsmittel und Umbau aus einer Hand$t$),
  ($t$Hilfsmittel-Service für zu Hause$t$, $t$Sanitätshaus mit angestelltem Orthopädietechnik-Meister$t$, $t$Hilfsmittel-Service als Einstieg, Sanitätshaus als Ausbau$t$),
  ($t$Montage, Wartung und Aufbereitung von Hilfsmitteln$t$, $t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$Gleiche Handwerker für Lifter, Rampen, Griffe und Umbau$t$),
  ($t$Hausnotruf und Assistenzsysteme$t$, $t$Digitale Pflege- und Gesundheitsanwendungen$t$, $t$Assistenzsysteme und App aus einer Hand$t$),
  ($t$Beratungsbesuche und Pflegekurse für Angehörige$t$, $t$Schulungsakademie für Alltagsbegleiter und Betreuungskräfte$t$, $t$Pflegekurse und Schulungen in denselben Räumen mit denselben Dozenten$t$),
  ($t$Haushaltshilfe nach Krankenhaus oder Schwangerschaft$t$, $t$Hebammenzentrum$t$, $t$Gleiche Familien: Haushaltshilfe in Schwangerschaft und Wochenbett$t$),
  ($t$Haushaltshilfe nach Krankenhaus oder Schwangerschaft$t$, $t$Alltagshilfe mit Kassenabrechnung$t$, $t$Gleiche Mitarbeiter, andere Kostenträger$t$),
  ($t$Therapiezentrum für Physio-, Ergo- und Sprachtherapie$t$, $t$Podologie-Praxis mit Hausbesuchen$t$, $t$Gleiche Zulassungslogik und Räume, Heilmittelzentrum$t$),
  ($t$Therapiezentrum für Physio-, Ergo- und Sprachtherapie$t$, $t$Fahrdienst zu Arztterminen und Therapien$t$, $t$Patienten zur Therapie fahren$t$),
  ($t$Fahrdienst zu Arztterminen und Therapien$t$, $t$Botendienst für Apotheken und Praxen$t$, $t$Gleiche Fahrzeuge und Fahrer, Touren kombinieren$t$),
  ($t$Abrechnungs- und Praxisservice für Arzt- und Zahnarztpraxen$t$, $t$Abrechnungszentrum für Pflege- und Heilmittelanbieter$t$, $t$Gleiches Abrechnungswissen, gleiche Software$t$),
  ($t$Abrechnungszentrum für Pflege- und Heilmittelanbieter$t$, $t$Therapiezentrum für Physio-, Ergo- und Sprachtherapie$t$, $t$Eigene Praxis als erster Kunde des Abrechnungszentrums$t$),
  ($t$Sanitätshaus mit angestelltem Orthopädietechnik-Meister$t$, $t$Hörakustik-Fachgeschäft mit angestelltem Meister$t$, $t$Gleiche Kunden und Ärzte, gemeinsames Ladenlokal möglich$t$),
  ($t$Servicedienste für Kliniken und Pflegeheime$t$, $t$Montage, Wartung und Aufbereitung von Hilfsmitteln$t$, $t$Bettenaufbereitung und Hilfsmittel-Aufbereitung mit gleichem Hygienekonzept$t$),
  ($t$Ambulante psychiatrische Pflege und Soziotherapie$t$, $t$Alltagshilfe mit Kassenabrechnung$t$, $t$Alltagsbegleitung ergänzt die psychiatrische Pflege$t$),
  ($t$Alltagshilfe mit Kassenabrechnung$t$, $t$Alltags- und Digitalhilfe für Senioren$t$, $t$Gleiche Zielgruppe; mit Anerkennung zahlt die Pflegekasse$t$),
  ($t$Hausnotruf und Assistenzsysteme$t$, $t$Alltags- und Digitalhilfe für Senioren$t$, $t$Technik für Senioren einrichten und betreuen$t$),
  ($t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Eigene Handwerker für den barrierefreien Umbau$t$),
  ($t$Montage, Wartung und Aufbereitung von Hilfsmitteln$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Monteure und Hilfskräfte aus dem Handwerksbetrieb$t$),
  ($t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$Haus-Check im Abo für Eigenheimbesitzer$t$, $t$Haus-Check erkennt Umbaubedarf bei älteren Eigentümern$t$),
  ($t$Barrierefreier Umbau mit Pflegekassen-Zuschuss$t$, $t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$Gleiche Gewerke; barrierefreie Renovierung für Vermieter$t$),
  ($t$Digitale Pflege- und Gesundheitsanwendungen$t$, $t$App-Entwicklung mit KI$t$, $t$Gleiches Entwicklungs-Know-how$t$),
  ($t$Abrechnungszentrum für Pflege- und Heilmittelanbieter$t$, $t$App-Entwicklung mit KI$t$, $t$Eigene Abrechnungssoftware als Grundlage$t$),
  ($t$Sanitätshaus mit angestelltem Orthopädietechnik-Meister$t$, $t$Unternehmensnachfolge – bestehenden Betrieb übernehmen$t$, $t$Bestehendes Sanitätshaus übernehmen statt neu gründen$t$),
  ($t$Ambulanter Pflegedienst$t$, $t$Unternehmensnachfolge – bestehenden Betrieb übernehmen$t$, $t$Bestehenden Pflegedienst übernehmen statt neu gründen$t$),
  ($t$Hilfsmittel-Service für zu Hause$t$, $t$Werkzeugverleih per Schließfach-Automat$t$, $t$Ausgabe kleiner Hilfsmittel per Schließfach$t$)
) as v(ta, tb, note)
join public.ideas a on a.title = v.ta
join public.ideas b on b.title = v.tb
cross join (select id from public.profiles where slug = 'igor') p
on conflict (idea_a, idea_b) do nothing;
