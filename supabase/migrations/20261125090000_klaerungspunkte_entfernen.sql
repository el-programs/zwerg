-- Zwerg · Gründungscheck der KI-Firma: die Klärungspunkte „Jetzige Firma …“ und „Rechtsform …“ entfernen.

delete from public.idea_steps s
using public.ideas i
where s.idea_id = i.id
  and i.title = $t$KI-Firma$t$
  and s.section = 'klaerung'
  and (s.title like $t$Jetzige Firma:%$t$ or s.title like $t$Rechtsform %$t$);

-- Übrige Klärungspunkte lückenlos neu nummerieren
update public.idea_steps s
set sort = n.rn
from (
  select s2.id, row_number() over (partition by s2.idea_id order by s2.sort, s2.created_at) as rn
  from public.idea_steps s2
  join public.ideas i on i.id = s2.idea_id
  where i.title = $t$KI-Firma$t$ and s2.section = 'klaerung'
) n
where s.id = n.id and s.sort <> n.rn;
