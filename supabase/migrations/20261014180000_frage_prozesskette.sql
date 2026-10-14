-- Zwerg · Frage für den umbenannten Faktor „Einfachheit der Prozesskette“ nachtragen
update public.criteria
set description = 'Wie einfach sind Einkauf, Herstellung und Vertrieb?', scale = 'qualitaet'
where name = 'Einfachheit der Prozesskette';
