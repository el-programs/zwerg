-- Zwerg · Freies Notizfeld je Besprechung (zusätzlich zu den Tagesordnungspunkten)
alter table public.meetings add column notes text not null default '' check (length(notes) <= 50000);
