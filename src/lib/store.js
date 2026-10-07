// Zentrale Datenhaltung: lädt Daten, hält sie live aktuell, speichert offline Erfasstes
// in einer Warteschlange und gleicht sie ab, sobald wieder Netz da ist.
import { reactive } from 'vue';
import { get, set, del } from 'idb-keyval';
import { startAuthentication, startRegistration } from '@simplewebauthn/browser';
import { supabase, callAuth, sessionIdOf } from './supabase.js';
import { applyAppearance, geraeteName } from './format.js';

const CACHE_KEY = 'zwerg-cache';
const OUTBOX_KEY = 'zwerg-outbox';

export const state = reactive({
  status: 'loading', // loading | signedOut | ready
  session: null,
  sessionId: null,
  me: null,
  profiles: [],
  fields: [],
  ideas: [],
  comments: [],
  reads: {},
  devices: [],
  outbox: [],
  online: navigator.onLine,
  syncing: false,
  loadedFromServer: false,
  error: '',
  notice: '',
  toast: '',
});

let toastTimer = null;
export function toast(text) {
  state.toast = text;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => (state.toast = ''), 2600);
}

let channel = null;
let flushing = false;
let cacheTimer = null;

// ---------------------------------------------------------------------------
// Start und Anmeldung
// ---------------------------------------------------------------------------

export async function init() {
  window.addEventListener('online', () => {
    state.online = true;
    refresh();
  });
  window.addEventListener('offline', () => {
    state.online = false;
  });
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible' && state.status === 'ready') refresh();
  });

  supabase.auth.onAuthStateChange((_event, session) => {
    if (session) {
      state.session = session;
      state.sessionId = sessionIdOf(session);
    }
  });

  state.outbox = (await get(OUTBOX_KEY).catch(() => null)) ?? [];
  const cache = await get(CACHE_KEY).catch(() => null);
  const { data } = await supabase.auth.getSession().catch(() => ({ data: {} }));

  if (data?.session) {
    state.session = data.session;
    state.sessionId = sessionIdOf(data.session);
    await start(cache);
  } else if (cache && hasStoredLogin()) {
    // Offline gestartet: mit den zuletzt gespeicherten Daten weiterarbeiten.
    applyCache(cache);
    state.status = 'ready';
  } else {
    state.status = 'signedOut';
  }
}

function hasStoredLogin() {
  try {
    return !!localStorage.getItem('zwerg-auth');
  } catch {
    return false;
  }
}

async function start(cache) {
  if (cache) applyCache(cache);
  state.status = 'ready';
  subscribe();
  refresh();
  callAuth('device-seen').catch(() => {});
}

export async function finishLogin(tokenHash, kind, credentialId) {
  const { data, error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type: 'magiclink' });
  if (error || !data.session) throw new Error('Anmeldung fehlgeschlagen. Bitte erneut versuchen.');
  state.session = data.session;
  state.sessionId = sessionIdOf(data.session);
  await callAuth('device-register', { label: geraeteName(), kind, credentialId });
  await start(null);
}

function passkeyError(e) {
  if (e?.name === 'NotAllowedError' || e?.name === 'AbortError') {
    return new Error('Vorgang abgebrochen oder kein passender Passkey gefunden.');
  }
  return e instanceof Error ? e : new Error(String(e));
}

export async function loginWithPasskey() {
  const { challengeId, options } = await callAuth('login-options');
  let response;
  try {
    response = await startAuthentication({ optionsJSON: options });
  } catch (e) {
    throw passkeyError(e);
  }
  const r = await callAuth('login-verify', { challengeId, response });
  await finishLogin(r.tokenHash, 'passkey', r.credentialId);
}

export async function registerWithInvite(token) {
  const { challengeId, options } = await callAuth('register-options', { token });
  let response;
  try {
    response = await startRegistration({ optionsJSON: options });
  } catch (e) {
    if (e?.name === 'InvalidStateError') {
      throw new Error('Auf diesem Gerät ist bereits ein Passkey für Zwerg eingerichtet. Bitte normal anmelden.');
    }
    throw passkeyError(e);
  }
  const r = await callAuth('register-verify', { token, challengeId, response });
  await finishLogin(r.tokenHash, 'passkey', r.credentialId);
}

export function linkUrl(linkId, approveCode) {
  return `${location.origin}${location.pathname}#/koppeln/${linkId}/${approveCode}`;
}

export async function startLink() {
  return callAuth('link-start');
}

export async function pollLink(linkId, pollSecret) {
  const r = await callAuth('link-poll', { linkId, pollSecret });
  if (r.status === 'approved') await finishLogin(r.tokenHash, 'qr');
  return r.status;
}

export async function approveLink(linkId, approveCode) {
  const { challengeId, options } = await callAuth('login-options');
  let response;
  try {
    response = await startAuthentication({ optionsJSON: options });
  } catch (e) {
    throw passkeyError(e);
  }
  await callAuth('link-approve', { linkId, approveCode, challengeId, response });
}

export async function signOut(notice = '') {
  if (channel) {
    supabase.removeChannel(channel);
    channel = null;
  }
  await supabase.auth.signOut({ scope: 'local' }).catch(() => {});
  await del(CACHE_KEY).catch(() => {});
  await del(OUTBOX_KEY).catch(() => {});
  Object.assign(state, {
    status: 'signedOut',
    session: null,
    sessionId: null,
    me: null,
    profiles: [],
    fields: [],
    ideas: [],
    comments: [],
    reads: {},
    devices: [],
    outbox: [],
    loadedFromServer: false,
    notice,
  });
}

// ---------------------------------------------------------------------------
// Laden, Zwischenspeicher, Live-Abgleich
// ---------------------------------------------------------------------------

function applyCache(c) {
  state.profiles = c.profiles ?? [];
  state.fields = c.fields ?? [];
  state.ideas = c.ideas ?? [];
  state.comments = c.comments ?? [];
  state.reads = c.reads ?? {};
  state.devices = c.devices ?? [];
  state.me = c.me ?? null;
  // Noch nicht abgeglichene Einträge wieder einblenden.
  for (const op of state.outbox) if (op.op === 'insert') upsertLocal(op.table, op.row);
  if (state.me) applyAppearance(state.me.theme, state.me.accent);
}

function saveCache() {
  clearTimeout(cacheTimer);
  cacheTimer = setTimeout(() => {
    const plain = JSON.parse(
      JSON.stringify({
        me: state.me,
        profiles: state.profiles,
        fields: state.fields,
        ideas: state.ideas,
        comments: state.comments,
        reads: state.reads,
        devices: state.devices,
      }),
    );
    set(CACHE_KEY, plain).catch(() => {});
  }, 300);
}

export async function refresh() {
  if (!state.online || !state.session) return;
  try {
    const [profiles, fields, ideas, comments, reads, devices] = await Promise.all([
      supabase.from('profiles').select('*').order('name'),
      supabase.from('search_fields').select('*').order('sort'),
      supabase.from('ideas').select('*').order('created_at', { ascending: false }),
      supabase.from('comments').select('*').order('created_at'),
      supabase.from('idea_reads').select('idea_id, seen_at'),
      supabase.from('devices').select('*').order('created_at'),
    ]);
    const failed = [profiles, fields, ideas, comments, reads, devices].find((r) => r.error);
    if (failed) throw failed.error;

    const me = profiles.data.find((p) => p.user_id === state.session.user.id);
    if (!me) {
      await signOut('Dieses Gerät ist nicht mehr angemeldet. Bitte erneut anmelden.');
      return;
    }
    state.me = me;
    state.profiles = profiles.data;
    state.fields = fields.data;
    state.ideas = ideas.data;
    state.comments = comments.data;
    state.reads = Object.fromEntries(reads.data.map((r) => [r.idea_id, r.seen_at]));
    state.devices = devices.data;
    for (const op of state.outbox) if (op.op === 'insert') upsertLocal(op.table, op.row);
    state.loadedFromServer = true;
    state.error = '';
    applyAppearance(me.theme, me.accent);
    saveCache();
    flush();
  } catch (e) {
    if (!isNetworkError(e)) state.error = 'Daten konnten nicht geladen werden.';
  }
}

const TABLE_KEYS = { ideas: 'ideas', comments: 'comments', search_fields: 'fields', profiles: 'profiles', devices: 'devices' };

function subscribe() {
  if (channel) return;
  channel = supabase.channel('zwerg-db');
  for (const table of Object.keys(TABLE_KEYS)) {
    channel.on('postgres_changes', { event: '*', schema: 'public', table }, (p) => onChange(table, p));
  }
  channel.subscribe();
}

function onChange(table, payload) {
  const key = TABLE_KEYS[table];
  if (payload.eventType === 'DELETE') {
    state[key] = state[key].filter((r) => r.id !== payload.old.id);
  } else {
    upsertLocal(key === 'fields' ? 'search_fields' : table, payload.new);
  }
  if (table === 'profiles' && state.me && payload.new?.id === state.me.id) {
    state.me = payload.new;
    applyAppearance(state.me.theme, state.me.accent);
  }
  if (table === 'search_fields') state.fields.sort((a, b) => a.sort - b.sort);
  if (table === 'devices' && payload.new?.session_id === state.sessionId && payload.new?.revoked_at) {
    signOut('Dieses Gerät wurde in den Einstellungen gesperrt.');
    return;
  }
  saveCache();
}

function upsertLocal(table, row) {
  const key = TABLE_KEYS[table];
  const list = state[key];
  const i = list.findIndex((r) => r.id === row.id);
  if (i >= 0) list[i] = { ...list[i], ...row };
  else if (table === 'ideas') list.unshift(row);
  else list.push(row);
}

// ---------------------------------------------------------------------------
// Warteschlange für Änderungen (funktioniert auch offline)
// ---------------------------------------------------------------------------

function isNetworkError(e) {
  const msg = String(e?.message ?? e ?? '');
  return !e?.code && /fetch|network|load failed|offline/i.test(msg);
}

async function enqueue(op) {
  state.outbox.push(op);
  await set(OUTBOX_KEY, JSON.parse(JSON.stringify(state.outbox))).catch(() => {});
  flush();
}

async function runOp(op) {
  const q = supabase.from(op.table);
  if (op.op === 'insert') return q.upsert(op.row, { onConflict: 'id', ignoreDuplicates: true });
  if (op.op === 'update') return q.update(op.patch).eq('id', op.id);
  if (op.op === 'delete') return q.delete().eq('id', op.id);
  return { error: null };
}

export async function flush() {
  if (flushing || !state.online || !state.session || !state.outbox.length) return;
  flushing = true;
  state.syncing = true;
  try {
    while (state.outbox.length) {
      const op = state.outbox[0];
      let error;
      try {
        ({ error } = await runOp(op));
      } catch (e) {
        error = e;
      }
      if (error && isNetworkError(error)) break;
      if (error) state.error = `Eine Änderung konnte nicht gespeichert werden (${error.message}).`;
      state.outbox.shift();
      await set(OUTBOX_KEY, JSON.parse(JSON.stringify(state.outbox))).catch(() => {});
    }
  } finally {
    flushing = false;
    state.syncing = false;
  }
}

export function isPending(id) {
  return state.outbox.some((op) => op.row?.id === id || op.id === id);
}

// ---------------------------------------------------------------------------
// Ideen und Kommentare
// ---------------------------------------------------------------------------

export function addIdea({ text = '', title = '', description = '', searchFieldId = null }) {
  if (text) {
    const lines = text.trim().split('\n');
    title = lines[0].trim().slice(0, 200);
    description = lines.slice(1).join('\n').trim();
  }
  const now = new Date().toISOString();
  const row = {
    id: crypto.randomUUID(),
    title,
    description,
    search_field_id: searchFieldId || null,
    tags: [],
    links: [],
    created_by: state.me.id,
    created_at: now,
  };
  upsertLocal('ideas', { ...row, phase: 1, status: 'aktiv', park_reason: null, updated_by: state.me.id, updated_at: now });
  state.reads[row.id] = now;
  saveCache();
  enqueue({ op: 'insert', table: 'ideas', row });
  return row.id;
}

export function updateIdea(id, patch) {
  upsertLocal('ideas', { id, ...patch, updated_by: state.me.id, updated_at: new Date().toISOString() });
  saveCache();
  // Wartet die Idee selbst noch auf den Abgleich, die Änderung direkt dort einarbeiten.
  const pending = state.outbox.find((op) => op.op === 'insert' && op.table === 'ideas' && op.row.id === id);
  if (pending) {
    Object.assign(pending.row, patch);
    set(OUTBOX_KEY, JSON.parse(JSON.stringify(state.outbox))).catch(() => {});
    flush();
    return;
  }
  enqueue({ op: 'update', table: 'ideas', id, patch });
}

export function deleteIdea(id) {
  state.ideas = state.ideas.filter((i) => i.id !== id);
  state.comments = state.comments.filter((c) => c.idea_id !== id);
  saveCache();
  enqueue({ op: 'delete', table: 'ideas', id });
}

export function addComment(ideaId, body) {
  const row = {
    id: crypto.randomUUID(),
    idea_id: ideaId,
    author_id: state.me.id,
    body: body.trim(),
    created_at: new Date().toISOString(),
  };
  upsertLocal('comments', row);
  state.reads[ideaId] = row.created_at;
  saveCache();
  enqueue({ op: 'insert', table: 'comments', row });
}

export function deleteComment(id) {
  state.comments = state.comments.filter((c) => c.id !== id);
  saveCache();
  enqueue({ op: 'delete', table: 'comments', id });
}

export function markSeen(ideaId) {
  const now = new Date().toISOString();
  state.reads[ideaId] = now;
  saveCache();
  if (!state.online || isPending(ideaId) || !state.me) return;
  supabase
    .from('idea_reads')
    .upsert({ profile_id: state.me.id, idea_id: ideaId, seen_at: now }, { onConflict: 'profile_id,idea_id' })
    .then(() => {});
}

// ---------------------------------------------------------------------------
// Auswertungen für die Anzeige
// ---------------------------------------------------------------------------

export function profile(id) {
  return state.profiles.find((p) => p.id === id) ?? null;
}

export function partner() {
  return state.profiles.find((p) => p.id !== state.me?.id) ?? null;
}

export function fieldName(id) {
  return state.fields.find((f) => f.id === id)?.name ?? '';
}

export function commentsOf(ideaId) {
  return state.comments.filter((c) => c.idea_id === ideaId);
}

export function isNewIdea(idea) {
  return !!state.me && idea.created_by !== state.me.id && !state.reads[idea.id];
}

export function newComments(idea) {
  const seen = state.reads[idea.id] ?? '';
  return state.comments.filter((c) => c.idea_id === idea.id && c.author_id !== state.me?.id && c.created_at > seen);
}

// Neues vom anderen: neue Ideen und neue Kommentare, das Neueste zuerst.
export function neuigkeiten() {
  const items = [];
  for (const idea of state.ideas) {
    if (isNewIdea(idea)) items.push({ idea, kind: 'idee', at: idea.created_at });
    const nc = newComments(idea);
    if (nc.length) items.push({ idea, kind: 'kommentar', count: nc.length, at: nc[nc.length - 1].created_at });
  }
  return items.sort((a, b) => (a.at < b.at ? 1 : -1));
}

// ---------------------------------------------------------------------------
// Einstellungen
// ---------------------------------------------------------------------------

function requireOnline() {
  if (!state.online) throw new Error('Dafür wird eine Internetverbindung benötigt.');
}

async function must(res) {
  const { error } = await res;
  if (error) throw new Error(isNetworkError(error) ? 'Keine Verbindung.' : error.message);
}

export async function setAppearance(theme, accent) {
  applyAppearance(theme, accent);
  state.me = { ...state.me, theme, accent };
  saveCache();
  if (state.online) await must(supabase.from('profiles').update({ theme, accent }).eq('id', state.me.id));
}

export async function addField(name) {
  requireOnline();
  const sort = Math.max(0, ...state.fields.map((f) => f.sort)) + 10;
  await must(supabase.from('search_fields').insert({ name: name.trim(), sort }));
  await refresh();
}

export async function updateField(id, patch) {
  requireOnline();
  await must(supabase.from('search_fields').update(patch).eq('id', id));
  await refresh();
}

export async function moveField(id, dir) {
  requireOnline();
  const list = [...state.fields].sort((a, b) => a.sort - b.sort);
  const i = list.findIndex((f) => f.id === id);
  const j = i + dir;
  if (j < 0 || j >= list.length) return;
  await must(supabase.from('search_fields').update({ sort: list[j].sort }).eq('id', list[i].id));
  await must(supabase.from('search_fields').update({ sort: list[i].sort }).eq('id', list[j].id));
  await refresh();
}

export async function createInvite(slug) {
  requireOnline();
  return callAuth('invite-create', { slug });
}

export async function revokeDevice(deviceId) {
  requireOnline();
  await callAuth('device-revoke', { deviceId });
  await refresh();
}
