-- Zwerg · Synergien: Verbindungen zwischen Ideen, die sich kombinieren lassen (ungerichtet, je Paar eine Zeile)

create table public.idea_synergies (
  id         uuid primary key default gen_random_uuid(),
  idea_a     uuid not null references public.ideas (id) on delete cascade,
  idea_b     uuid not null references public.ideas (id) on delete cascade,
  note       text not null default '' check (length(note) <= 500),
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  created_at timestamptz not null default now(),
  check (idea_a < idea_b),
  unique (idea_a, idea_b)
);
create index idea_synergies_b_idx on public.idea_synergies (idea_b);

alter table public.idea_synergies enable row level security;
create policy "Mitglieder lesen Synergien" on public.idea_synergies for select to authenticated using (public.is_member());
create policy "Mitglieder legen Synergien an" on public.idea_synergies for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Synergien" on public.idea_synergies for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Synergien" on public.idea_synergies for delete to authenticated using (public.is_member());
grant select, insert, update, delete on public.idea_synergies to authenticated;
grant all on public.idea_synergies to service_role;
alter publication supabase_realtime add table public.idea_synergies;

-- Vorschläge für die vorhandenen Ideen, angelegt von Igor
insert into public.idea_synergies (idea_a, idea_b, note, created_by)
select least(a.id, b.id), greatest(a.id, b.id), v.note, p.id
from (values
  ($t$Digitalisierungs-Service für Handwerksbetriebe$t$, $t$Konfigurator-Websites für Handwerker$t$, $t$Gleiche Kunden: Digitalisierung und Website als Paket für Handwerksbetriebe$t$),
  ($t$Digitalisierungs-Service für Handwerksbetriebe$t$, $t$Digitale Wartungsprotokolle per QR-Code$t$, $t$Wartungsprotokolle als Baustein beim Digitalisieren eines Betriebs$t$),
  ($t$Digitalisierungs-Service für Handwerksbetriebe$t$, $t$App-Entwicklung mit KI$t$, $t$Aus der Beratung entstehen Kunden und Ideen für eigene Branchen-Apps$t$),
  ($t$Konfigurator-Websites für Handwerker$t$, $t$Regionales Portal für freie Handwerkertermine$t$, $t$Anfragen aus Konfiguratoren können ins Portal laufen; gleiche Kunden$t$),
  ($t$Digitale Wartungsprotokolle per QR-Code$t$, $t$Digitales Ersatzteillager für Firmen$t$, $t$Gleiche Technik: Anlagen und Ersatzteile per QR-Code digital erfassen$t$),
  ($t$Digitale Wartungsprotokolle per QR-Code$t$, $t$Haus-Check im Abo für Eigenheimbesitzer$t$, $t$Beim Haus-Check werden Anlagen per QR-Code dokumentiert$t$),
  ($t$3D-Druck- und Ersatzteil-Service$t$, $t$Montagehilfen und Vorrichtungen für Handwerker$t$, $t$Gleiche Fertigung: Konstruktion im CAD, 3D-Druck$t$),
  ($t$3D-Druck- und Ersatzteil-Service$t$, $t$Digitales Ersatzteillager für Firmen$t$, $t$Digital gelagerte Ersatzteile werden bei Bedarf gedruckt$t$),
  ($t$Montagehilfen und Vorrichtungen für Handwerker$t$, $t$Maßgefertigte Einlagen und Ordnungssysteme$t$, $t$Gleiche Konstruktion und Fertigung, gleiche Kunden (Handwerker)$t$),
  ($t$Maßgefertigte Einlagen und Ordnungssysteme$t$, $t$Materialboxen für Handwerker$t$, $t$Passende Einlagen für die Materialboxen$t$),
  ($t$Werkzeugverleih per Schließfach-Automat$t$, $t$Materialboxen für Handwerker$t$, $t$Gleiche Kunden und Ausgabe per Schließfach$t$),
  ($t$Werkzeugverleih per Schließfach-Automat$t$, $t$Mietwerkstatt per App (Selbstbedienung)$t$, $t$Gleiche Selbstbedienungstechnik (App, Zugang, Buchung)$t$),
  ($t$Mietservice für Baby- und Kinderausstattung$t$, $t$Fitnessgeräte im Miet-Abo für zu Hause$t$, $t$Gleiches Miet-Abo-Modell mit Lieferung und Abholung$t$),
  ($t$24/7-Mikro-Fitnessstudio ohne Personal$t$, $t$Fitnessgeräte im Miet-Abo für zu Hause$t$, $t$Gleiche Zielgruppe, Geräte und Einkauf$t$),
  ($t$Haushaltsauflösung mit Online-Wiederverkauf$t$, $t$Retouren- und Restpostenhandel$t$, $t$Gleicher Online-Verkaufskanal und Lager$t$),
  ($t$Haushaltsauflösung mit Online-Wiederverkauf$t$, $t$Kommissionsverkauf für Privatleute$t$, $t$Waren aus Haushaltsauflösungen über den Kommissionsverkauf anbieten$t$),
  ($t$Haushaltsauflösung mit Online-Wiederverkauf$t$, $t$Gebrauchte Küchen: Ankauf, Abbau und Wiedereinbau$t$, $t$Küchen aus Haushaltsauflösungen ankaufen und wieder einbauen$t$),
  ($t$Haushaltsauflösung mit Online-Wiederverkauf$t$, $t$Rückbau und Entkernung$t$, $t$Gleiche Leute, Fahrzeuge und Entsorgung beim Räumen$t$),
  ($t$Retouren- und Restpostenhandel$t$, $t$Kommissionsverkauf für Privatleute$t$, $t$Gleicher Verkaufskanal, mehr Ware im Angebot$t$),
  ($t$Gebrauchte Küchen: Ankauf, Abbau und Wiedereinbau$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Abbau und Einbau der Küchen durch die eigenen Hilfskräfte$t$),
  ($t$Gebrauchte Küchen: Ankauf, Abbau und Wiedereinbau$t$, $t$Rückbau und Entkernung$t$, $t$Beim Rückbau ausgebaute Küchen weiterverkaufen$t$),
  ($t$Alltags- und Digitalhilfe für Senioren$t$, $t$Haus-Check im Abo für Eigenheimbesitzer$t$, $t$Gleiche Zielgruppe: ältere Eigenheimbesitzer$t$),
  ($t$Kfz-Zulassungsdienst für Autohäuser und Flotten$t$, $t$Fahrzeugpflege vor Ort beim Arbeitgeber$t$, $t$Gleiche Kunden: Autohäuser und Firmenflotten$t$),
  ($t$Eigenmarke mit White-Label-Produkten$t$, $t$Eigenmarke mit Private-Label-Produkten$t$, $t$Beides Eigenmarke: gleicher Vertrieb, Shop und Marketing$t$),
  ($t$Aufmaß und digitale Bestandspläne$t$, $t$Rückbau und Entkernung$t$, $t$Bestandspläne vor dem Rückbau erstellen$t$),
  ($t$Aufmaß und digitale Bestandspläne$t$, $t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$Aufmaß als Grundlage für Renovierungsangebote$t$),
  ($t$Digitale Wartungsprotokolle per QR-Code$t$, $t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$Gleiche Kunden: Hausverwaltungen$t$),
  ($t$Handwerksbetrieb mit Hilfskräften$t$, $t$Baustellenservice$t$, $t$Baustellenservice als Einstieg für die Hilfskräfte$t$),
  ($t$Handwerksbetrieb mit Hilfskräften$t$, $t$Rückbau und Entkernung$t$, $t$Rückbau als typische Arbeit der Hilfskräfte$t$),
  ($t$Handwerksbetrieb mit Hilfskräften$t$, $t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$Renovierungen als regelmäßige Aufträge für den Betrieb$t$),
  ($t$Baustellenservice$t$, $t$Rückbau und Entkernung$t$, $t$Gleiche Baustellen, Fahrzeuge und Entsorgung$t$),
  ($t$Rückbau und Entkernung$t$, $t$Wohnungsrenovierung bei Mieterwechsel$t$, $t$Erst zurückbauen, dann renovieren: Auftrag aus einer Hand$t$),
  ($t$Unternehmensnachfolge – bestehenden Betrieb übernehmen$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Einen bestehenden Handwerksbetrieb übernehmen statt neu gründen$t$),
  ($t$App-Entwicklung mit KI$t$, $t$Handwerksbetrieb mit Hilfskräften$t$, $t$Eigene App für Aufträge, Fotos und Freigabe durch den Bauleiter$t$)
) as v(ta, tb, note)
join public.ideas a on a.title = v.ta
join public.ideas b on b.title = v.tb
cross join (select id from public.profiles where slug = 'igor') p
on conflict (idea_a, idea_b) do nothing;
