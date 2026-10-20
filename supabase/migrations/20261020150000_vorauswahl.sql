-- Zwerg · Zwei Runden: erst Vorauswahl (weiterverfolgen oder verwerfen), dann Bewertung
alter table public.ideas
  add column shortlist      text not null default 'offen' check (shortlist in ('offen', 'weiter')),
  add column shortlisted_at timestamptz,
  add column shortlisted_by uuid references public.profiles (id);

-- Ideen, die schon (teilweise) bewertet sind, gelten als weiterverfolgt.
update public.ideas i set shortlist = 'weiter', shortlisted_at = now()
where exists (select 1 from public.joint_ratings r where r.idea_id = i.id)
   or exists (select 1 from public.idea_evaluations e where e.idea_id = i.id);
