import { createClient } from '@supabase/supabase-js';

// Öffentliche Angaben des Supabase-Projekts. Sie dürfen im Code stehen:
// Der Schutz der Daten liegt in den Zugriffsregeln (RLS) der Datenbank.
export const SUPABASE_URL = 'https://znxplygfxvghmtyqbwvb.supabase.co';
export const SUPABASE_KEY = 'sb_publishable_1TsSUvN6jXmEa7zhwAsCBw_s4XzVUWc';

export const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false, storageKey: 'zwerg-auth' },
});

// Aufruf der Anmelde-Funktion auf dem Server. Fehlermeldungen kommen auf Deutsch zurück.
export async function callAuth(action, body = {}) {
  const { data, error } = await supabase.functions.invoke('auth', { body: { action, ...body } });
  if (error) {
    let message = 'Keine Verbindung zum Server. Bitte später erneut versuchen.';
    try {
      const b = await error.context.json();
      if (b?.error) message = b.error;
    } catch {
      /* keine lesbare Antwort */
    }
    throw new Error(message);
  }
  return data;
}

// Sitzungs-ID aus dem Zugangs-Token (zur Erkennung "dieses Gerät").
export function sessionIdOf(session) {
  try {
    const part = session.access_token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(atob(part)).session_id ?? null;
  } catch {
    return null;
  }
}
