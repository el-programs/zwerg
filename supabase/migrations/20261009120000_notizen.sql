-- Zwerg · Schnellnotizen: Gedanken festhalten, für beide sichtbar, später ggf. zur Idee machen

create table public.notes (
  id         uuid primary key default gen_random_uuid(),
  body       text not null check (length(body) between 1 and 20000),
  pinned     boolean not null default false,
  idea_id    uuid references public.ideas (id) on delete set null, -- Idee, die daraus entstanden ist
  created_by uuid not null default public.current_profile_id() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id),
  updated_at timestamptz not null default now()
);
create index notes_created_idx on public.notes (created_at desc);

alter table public.notes enable row level security;
create policy "Mitglieder lesen Notizen" on public.notes for select to authenticated using (public.is_member());
create policy "Mitglieder schreiben Notizen" on public.notes for insert to authenticated
  with check (public.is_member() and created_by = public.current_profile_id());
create policy "Mitglieder ändern Notizen" on public.notes for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "Mitglieder löschen Notizen" on public.notes for delete to authenticated using (public.is_member());

grant select, insert, update, delete on public.notes to authenticated;
grant all on public.notes to service_role;

alter publication supabase_realtime add table public.notes;
