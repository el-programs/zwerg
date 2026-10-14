-- Zwerg · Branchen nach NACE-Abschnitten statt freier Suchfelder
-- Die Tabelle search_fields bleibt technisch bestehen und heißt in der App jetzt „Branche“.
-- Die bisherigen Suchfelder werden archiviert (an bestehenden Ideen bleiben sie sichtbar).

alter table public.search_fields drop constraint if exists search_fields_name_check;
alter table public.search_fields add constraint search_fields_name_check check (length(name) between 1 and 150);

update public.search_fields set archived = true where archived = false;

insert into public.search_fields (name, sort) values
  ('A - Land- und Forstwirtschaft, Fischerei - Primär', 10),
  ('B - Bergbau und Gewinnung von Steinen und Erden - Primär', 20),
  ('C - Verarbeitendes Gewerbe - Sekundär', 30),
  ('D - Energieversorgung - Sekundär', 40),
  ('E - Wasserversorgung, Abwasser- und Abfallentsorgung - Sekundär', 50),
  ('F - Baugewerbe - Sekundär', 60),
  ('G - Handel; Instandhaltung und Reparatur von Kfz - Tertiär', 70),
  ('H - Verkehr und Lagerei - Tertiär', 80),
  ('I - Gastgewerbe (Beherbergung & Gastronomie) - Tertiär', 90),
  ('J - Verlagswesen, Rundfunk, Medieninhalte - Tertiär', 100),
  ('K - Telekommunikation, Softwareentwicklung, IT-Dienstleistungen - Tertiär', 110),
  ('L - Finanz- und Versicherungsdienstleistungen - Tertiär', 120),
  ('M - Grundstücks- und Wohnungswesen - Tertiär', 130),
  ('N - Freiberufliche, wissenschaftliche und technische Dienstleistungen - Tertiär', 140),
  ('O - Sonstige wirtschaftliche Dienstleistungen - Tertiär', 150),
  ('P - Öffentliche Verwaltung, Verteidigung, Sozialversicherung - Tertiär', 160),
  ('Q - Erziehung und Unterricht - Tertiär', 170),
  ('R - Gesundheits- und Sozialwesen - Tertiär', 180),
  ('S - Kunst, Sport und Erholung - Tertiär', 190),
  ('T - Sonstige Dienstleistungen - Tertiär', 200),
  ('U - Private Haushalte mit Hauspersonal - Tertiär', 210),
  ('V - Exterritoriale Organisationen - Tertiär', 220);
