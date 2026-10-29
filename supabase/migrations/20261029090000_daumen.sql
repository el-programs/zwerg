-- Zwerg · Bauchgefühl je Person und Idee: Daumen hoch (1), zur Seite (0), runter (-1). Für beide sichtbar.

create table public.idea_votes (
  idea_id    uuid not null references public.ideas (id) on delete cascade,
  profile_id uuid not null default public.current_profile_id() references public.profiles (id) on delete cascade,
  vote       smallint check (vote in (-1, 0, 1)),   -- null = keine Angabe (zurückgenommen)
  updated_at timestamptz not null default now(),
  primary key (idea_id, profile_id)
);

alter table public.idea_votes enable row level security;
create policy "Mitglieder lesen Daumen" on public.idea_votes for select to authenticated using (public.is_member());
create policy "Eigenen Daumen setzen" on public.idea_votes for insert to authenticated
  with check (public.is_member() and profile_id = public.current_profile_id());
create policy "Eigenen Daumen ändern" on public.idea_votes for update to authenticated
  using (public.is_member() and profile_id = public.current_profile_id())
  with check (profile_id = public.current_profile_id());
grant select, insert, update on public.idea_votes to authenticated;
grant all on public.idea_votes to service_role;
alter publication supabase_realtime add table public.idea_votes;
