-- Zwerg · Grobcheck: Kriterium zum realistischen Einkommen für die vier Ideen der engeren Wahl ergänzen.

insert into public.idea_checks (idea_id, sort, question, created_by)
select i.id,
       coalesce((select max(c.sort) from public.idea_checks c where c.idea_id = i.id), 0) + 1,
       $t$Kann die Idee nach 2–3 Jahren ein Gehalt (oder zwei) tragen?$t$,
       p.id
from public.ideas i
cross join (select id from public.profiles where slug = 'igor') p
where lower(i.title) in (lower($t$Gesundheits-Logistik$t$), lower($t$24/7-Minimarkt ohne Personal$t$),
                         lower($t$App-Entwicklung mit KI$t$), lower($t$Eigenmarke mit White-Label-Produkten$t$))
  and not exists (select 1 from public.idea_checks c where c.idea_id = i.id and c.question like $t$Kann die Idee nach 2–3 Jahren ein Gehalt%$t$);
