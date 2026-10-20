-- Zwerg: KI-Unterstützung entfernt. Die zugehörigen Tabellen und die Stufe je Person werden gelöscht.

alter publication supabase_realtime drop table
  public.ai_settings, public.ai_usage, public.ai_results, public.ai_chat;

drop table if exists public.ai_chat, public.ai_results, public.ai_usage, public.ai_settings;

alter table public.profiles drop column if exists ai_level;
