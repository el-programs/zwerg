-- Zwerg · KO-Kriterien mit drei Stufen je Idee: nicht relevant · später prüfen · trifft zu (= ausgeschlossen).
-- ko_ids bleibt „trifft zu“, neu ist ko_check_ids für „später prüfen“.
-- Bisherige Haken waren als „später prüfen“ gemeint und werden dorthin verschoben.

alter table public.idea_evaluations add column ko_check_ids uuid[] not null default '{}';

update public.idea_evaluations
set ko_check_ids = ko_ids, ko_ids = '{}', updated_at = now()
where cardinality(ko_ids) > 0;
