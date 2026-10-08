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
  criteria: [],
  koCriteria: [],
  weightSubs: [],
  weights: [],
  ratingSubs: [],
  ratings: [],
  personalKo: [],
  jointRatings: [],
  evaluations: [],
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
    ...Object.fromEntries(Object.values(TABLES).map((t) => [t.key, []])),
    outbox: [],
    loadedFromServer: false,
    notice,
  });
}

// ---------------------------------------------------------------------------
// Laden, Zwischenspeicher, Live-Abgleich
// ---------------------------------------------------------------------------

// Alle Tabellen, die die App lädt und live mitverfolgt. "id" bildet den Schlüssel einer Zeile.
const byId = (r) => r.id;
const bySort = (a, b) => a.sort - b.sort;
export const TABLES = {
  profiles: { key: 'profiles', id: byId },
  search_fields: { key: 'fields', id: byId, sort: bySort },
  ideas: { key: 'ideas', id: byId, front: true },
  comments: { key: 'comments', id: byId },
  devices: { key: 'devices', id: byId },
  criteria: { key: 'criteria', id: byId, sort: bySort },
  ko_criteria: { key: 'koCriteria', id: byId, sort: bySort },
  weight_submissions: { key: 'weightSubs', id: (r) => r.profile_id },
  personal_weights: { key: 'weights', id: (r) => `${r.profile_id}|${r.criterion_id}` },
  rating_submissions: { key: 'ratingSubs', id: (r) => `${r.idea_id}|${r.profile_id}` },
  ratings: { key: 'ratings', id: (r) => `${r.idea_id}|${r.profile_id}|${r.criterion_id}` },
  personal_ko: { key: 'personalKo', id: (r) => `${r.idea_id}|${r.profile_id}|${r.ko_id}` },
  joint_ratings: { key: 'jointRatings', id: (r) => `${r.idea_id}|${r.criterion_id}` },
  idea_evaluations: { key: 'evaluations', id: (r) => r.idea_id },
};

function replayOutbox() {
  for (const op of state.outbox) {
    if (op.op === 'insert' || op.op === 'upsert') upsertLocal(op.table, op.row);
    if (op.op === 'delete' && op.match) removeLocal(op.table, op.match);
  }
}

function applyCache(c) {
  for (const t of Object.values(TABLES)) state[t.key] = c[t.key] ?? [];
  state.reads = c.reads ?? {};
  state.me = c.me ?? null;
  // Noch nicht abgeglichene Einträge wieder einblenden.
  replayOutbox();
  if (state.me) applyAppearance(state.me.theme, state.me.accent);
}

function saveCache() {
  clearTimeout(cacheTimer);
  cacheTimer = setTimeout(() => {
    const data = { me: state.me, reads: state.reads };
    for (const t of Object.values(TABLES)) data[t.key] = state[t.key];
    set(CACHE_KEY, JSON.parse(JSON.stringify(data))).catch(() => {});
  }, 300);
}

export async function refresh() {
  if (!state.online || !state.session) return;
  try {
    const names = Object.keys(TABLES);
    const results = await Promise.all([
      ...names.map((n) => supabase.from(n).select('*')),
      supabase.from('idea_reads').select('idea_id, seen_at'),
    ]);
    const failed = results.find((r) => r.error);
    if (failed) throw failed.error;

    const profiles = results[names.indexOf('profiles')].data;
    const me = profiles.find((p) => p.user_id === state.session.user.id);
    if (!me) {
      await signOut('Dieses Gerät ist nicht mehr angemeldet. Bitte erneut anmelden.');
      return;
    }
    names.forEach((n, i) => {
      const t = TABLES[n];
      const rows = results[i].data;
      if (t.sort) rows.sort(t.sort);
      if (n === 'ideas') rows.sort((a, b) => (a.created_at < b.created_at ? 1 : -1));
      if (n === 'comments') rows.sort((a, b) => (a.created_at < b.created_at ? -1 : 1));
      state[t.key] = rows;
    });
    state.me = me;
    state.reads = Object.fromEntries(results[names.length].data.map((r) => [r.idea_id, r.seen_at]));
    replayOutbox();
    state.loadedFromServer = true;
    state.error = '';
    applyAppearance(me.theme, me.accent);
    saveCache();
    flush();
  } catch (e) {
    if (!isNetworkError(e)) state.error = 'Daten konnten nicht geladen werden.';
  }
}

function subscribe() {
  if (channel) return;
  channel = supabase.channel('zwerg-db');
  for (const table of Object.keys(TABLES)) {
    channel.on('postgres_changes', { event: '*', schema: 'public', table }, (p) => onChange(table, p));
  }
  channel.subscribe();
}

function onChange(table, payload) {
  if (payload.eventType === 'DELETE') removeLocal(table, payload.old);
  else upsertLocal(table, payload.new);
  if (table === 'profiles' && state.me && payload.new?.id === state.me.id) {
    state.me = payload.new;
    applyAppearance(state.me.theme, state.me.accent);
  }
  if (table === 'devices' && payload.new?.session_id === state.sessionId && payload.new?.revoked_at) {
    signOut('Dieses Gerät wurde in den Einstellungen gesperrt.');
    return;
  }
  // Hat der Partner gerade abgegeben, nachdem ich schon abgegeben hatte? Dann seine Werte nachladen.
  if ((table === 'rating_submissions' || table === 'weight_submissions') && payload.new?.profile_id !== state.me?.id) {
    refresh();
  }
  saveCache();
}

function upsertLocal(table, row) {
  const t = TABLES[table];
  if (!t) return;
  const list = state[t.key];
  const k = t.id(row);
  const i = list.findIndex((r) => t.id(r) === k);
  if (i >= 0) list[i] = { ...list[i], ...row };
  else if (t.front) list.unshift(row);
  else list.push(row);
  if (t.sort) list.sort(t.sort);
}

function removeLocal(table, row) {
  const t = TABLES[table];
  if (!t) return;
  const k = t.id(row);
  state[t.key] = state[t.key].filter((r) => t.id(r) !== k);
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
  if (op.op === 'insert') return q.upsert(op.row, { onConflict: op.onConflict ?? 'id', ignoreDuplicates: true });
  if (op.op === 'upsert') return q.upsert(op.row, { onConflict: op.onConflict });
  if (op.op === 'update') return op.match ? q.update(op.patch).match(op.match) : q.update(op.patch).eq('id', op.id);
  if (op.op === 'delete') return op.match ? q.delete().match(op.match) : q.delete().eq('id', op.id);
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
    const andererAbgegeben = state.ratingSubs.some((r) => r.idea_id === idea.id && r.profile_id !== state.me?.id);
    const ichAbgegeben = state.ratingSubs.some((r) => r.idea_id === idea.id && r.profile_id === state.me?.id);
    if (andererAbgegeben && !ichAbgegeben && idea.status !== 'geparkt') {
      const sub = state.ratingSubs.find((r) => r.idea_id === idea.id && r.profile_id !== state.me?.id);
      items.push({ idea, kind: 'bewertung', at: sub.submitted_at });
    }
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

// Bearbeitbare Listen (Suchfelder, Bewertungsfaktoren, KO-Kriterien)
export const addField = (name) => addListItem('search_fields', name);
export const updateField = (id, patch) => updateListItem('search_fields', id, patch);
export const moveField = (id, dir) => moveListItem('search_fields', id, dir);

export async function addListItem(table, name) {
  requireOnline();
  const list = state[TABLES[table].key];
  const sort = Math.max(0, ...list.map((f) => f.sort)) + 10;
  await must(supabase.from(table).insert({ name: name.trim(), sort }));
  await refresh();
}

export async function updateListItem(table, id, patch) {
  requireOnline();
  await must(supabase.from(table).update(patch).eq('id', id));
  await refresh();
}

export async function moveListItem(table, id, dir) {
  requireOnline();
  const list = [...state[TABLES[table].key]].sort((a, b) => a.sort - b.sort);
  const i = list.findIndex((f) => f.id === id);
  const j = i + dir;
  if (j < 0 || j >= list.length) return;
  await must(supabase.from(table).update({ sort: list[j].sort }).eq('id', list[i].id));
  await must(supabase.from(table).update({ sort: list[i].sort }).eq('id', list[j].id));
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

// ---------------------------------------------------------------------------
// Etappe 2: Gewichtung, Bewertung, KO, Parkplatz, Favoriten
// ---------------------------------------------------------------------------

function now() {
  return new Date().toISOString();
}

function queueUpsert(table, row, onConflict) {
  upsertLocal(table, row);
  saveCache();
  enqueue({ op: 'upsert', table, row, onConflict });
}

export function setWeight(criterionId, weight) {
  queueUpsert('personal_weights', { profile_id: state.me.id, criterion_id: criterionId, weight, updated_at: now() }, 'profile_id,criterion_id');
}

export function submitWeights() {
  const row = { profile_id: state.me.id, submitted_at: now() };
  upsertLocal('weight_submissions', row);
  saveCache();
  enqueue({ op: 'insert', table: 'weight_submissions', row, onConflict: 'profile_id' });
  afterSync(refresh);
}

export function setJointWeight(criterionId, weight) {
  upsertLocal('criteria', { id: criterionId, joint_weight: weight });
  saveCache();
  enqueue({ op: 'update', table: 'criteria', id: criterionId, patch: { joint_weight: weight } });
}

export function setRating(ideaId, criterionId, patch) {
  const existing = state.ratings.find((r) => r.idea_id === ideaId && r.profile_id === state.me.id && r.criterion_id === criterionId);
  const row = { note: '', ...existing, idea_id: ideaId, profile_id: state.me.id, criterion_id: criterionId, ...patch, updated_at: now() };
  if (!row.score) {
    // Nur eine Notiz ohne Punktzahl: lokal merken, gespeichert wird mit der Punktzahl.
    upsertLocal('ratings', row);
    return;
  }
  queueUpsert('ratings', row, 'idea_id,profile_id,criterion_id');
}

export function toggleKo(ideaId, koId, on) {
  const row = { idea_id: ideaId, profile_id: state.me.id, ko_id: koId };
  if (on) {
    upsertLocal('personal_ko', row);
    saveCache();
    enqueue({ op: 'insert', table: 'personal_ko', row, onConflict: 'idea_id,profile_id,ko_id' });
  } else {
    removeLocal('personal_ko', row);
    saveCache();
    enqueue({ op: 'delete', table: 'personal_ko', match: row });
  }
}

export function submitRating(ideaId) {
  const row = { idea_id: ideaId, profile_id: state.me.id, submitted_at: now() };
  upsertLocal('rating_submissions', row);
  saveCache();
  enqueue({ op: 'insert', table: 'rating_submissions', row, onConflict: 'idea_id,profile_id' });
  afterSync(refresh);
}

export function setJointRating(ideaId, criterionId, score) {
  queueUpsert('joint_ratings', { idea_id: ideaId, criterion_id: criterionId, score, updated_by: state.me.id, updated_at: now() }, 'idea_id,criterion_id');
}

export function setEvaluation(ideaId, patch) {
  const existing = state.evaluations.find((e) => e.idea_id === ideaId) ?? { ko_ids: [], ko_note: '', finalized_at: null, finalized_by: null };
  queueUpsert('idea_evaluations', { ...existing, idea_id: ideaId, ...patch, updated_at: now() }, 'idea_id');
}

export function parkIdea(id, reason) {
  updateIdea(id, { status: 'geparkt', park_reason: reason.trim(), parked_at: now(), parked_by: state.me.id, is_favorite: false });
}

export function unparkIdea(id) {
  updateIdea(id, { status: 'aktiv', park_reason: null, parked_at: null, parked_by: null });
}

export function setFavorite(id, value) {
  updateIdea(id, { is_favorite: value });
}

// Führt fn aus, sobald die Warteschlange abgearbeitet ist (z. B. Partnerwerte nachladen).
async function afterSync(fn) {
  for (let i = 0; i < 40 && (state.outbox.length || flushing); i++) {
    await new Promise((r) => setTimeout(r, 250));
  }
  if (!state.outbox.length) fn();
}
