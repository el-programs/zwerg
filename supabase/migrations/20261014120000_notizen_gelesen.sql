-- Zwerg · „Neu“ bei Notizen gilt pro Person statt pro Gerät
alter table public.profiles add column notes_seen_at timestamptz;
grant update (notes_seen_at) on public.profiles to authenticated;
