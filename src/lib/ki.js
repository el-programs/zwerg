// KI-Unterstützung: Aufrufe der Edge Function "ki", Verbrauch, Stufen.
import { computed } from 'vue';
import { supabase } from './supabase.js';
import { refresh, state, toast } from './store.js';

export const MODELLE = [
  { id: 'claude-opus-5-5', name: 'Claude Opus 5.5', info: 'gründlicher, etwa doppelt so teuer' },
  { id: 'claude-sonnet-5-5', name: 'Claude Sonnet 5.5', info: 'schneller und günstiger' },
];

export const STUFEN = [
  { id: 'aus', name: 'Aus', info: 'Keine KI-Funktionen für dich.' },
  { id: 'anfrage', name: 'Nur auf Anfrage', info: 'Die KI arbeitet nur, wenn du sie ausdrücklich fragst.' },
  { id: 'aktiv', name: 'Aktiv mit Hinweisen', info: 'Neue Notizen bekommen automatisch einen kurzen kritischen Check (je Notiz einmal, wenige Cent).' },
];

export async function callKi(action, body = {}) {
  const { data, error } = await supabase.functions.invoke('ki', { body: { action, ...body } });
  if (error) {
    let message = 'Die KI ist gerade nicht erreichbar. Bitte später erneut versuchen.';
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

export async function ladeStatus() {
  if (!state.online) return state.kiStatus;
  try {
    state.kiStatus = await callKi('status');
  } catch {
    /* Status bleibt unbekannt */
  }
  return state.kiStatus;
}

export const meineStufe = computed(() => state.me?.ai_level ?? 'anfrage');
// KI-Knöpfe erscheinen erst, wenn ein Schlüssel hinterlegt ist und die Person die KI nicht ausgeschaltet hat.
export const kiSichtbar = computed(() => meineStufe.value !== 'aus' && state.kiStatus?.configured === true);
export const einstellungen = computed(() => state.aiSettings[0] ?? { model: 'claude-opus-5-5', monthly_limit_eur: 10 });

export const verbrauchMonat = computed(() => {
  const d = new Date();
  const start = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1)).toISOString();
  return state.aiUsage.filter((u) => u.created_at >= start).reduce((s, u) => s + Number(u.cost_eur), 0);
});
export const limitErreicht = computed(() => verbrauchMonat.value >= Number(einstellungen.value.monthly_limit_eur));

export function euro(v) {
  return `${Number(v).toLocaleString('de-DE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} €`;
}

export function ergebnisse(ideaId, kind) {
  return state.aiResults.filter((r) => r.idea_id === ideaId && r.kind === kind);
}

export function chatVon(ideaId) {
  return state.aiChat.filter((m) => m.idea_id === ideaId);
}

export async function starte(action, body, okText) {
  const r = await callKi(action, body);
  await refresh();
  if (okText) toast(okText);
  return r;
}

export async function setStufe(level) {
  state.me = { ...state.me, ai_level: level };
  const { error } = await supabase.from('profiles').update({ ai_level: level }).eq('id', state.me.id);
  if (error) throw new Error('Speichern fehlgeschlagen.');
}

export async function setKiEinstellungen(patch) {
  const { error } = await supabase
    .from('ai_settings')
    .update({ ...patch, updated_by: state.me.id, updated_at: new Date().toISOString() })
    .eq('id', 1);
  if (error) throw new Error('Speichern fehlgeschlagen.');
  await refresh();
}

// Sehr kleiner, sicherer Markdown-Renderer (Überschriften, Listen, fett, Links).
export function markdown(text) {
  const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  const inline = (s) =>
    esc(s)
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
  const out = [];
  let list = false;
  for (const raw of String(text ?? '').split('\n')) {
    const line = raw.trimEnd();
    const item = /^\s*[-*]\s+(.*)$/.exec(line);
    if (item) {
      if (!list) out.push('<ul>');
      list = true;
      out.push(`<li>${inline(item[1])}</li>`);
      continue;
    }
    if (list) {
      out.push('</ul>');
      list = false;
    }
    const h = /^(#{1,4})\s+(.*)$/.exec(line);
    if (h) out.push(`<h3>${inline(h[2])}</h3>`);
    else if (line.trim()) out.push(`<p>${inline(line)}</p>`);
  }
  if (list) out.push('</ul>');
  return out.join('');
}
