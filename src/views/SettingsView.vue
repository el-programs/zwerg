<script setup>
import { computed, ref } from 'vue';
import { createInvite, profile, revokeDevice, setAppearance, signOut, state, toast } from '../lib/store.js';
import ListEditor from '../components/ListEditor.vue';
import { AKZENTE, relativ } from '../lib/format.js';
import Icon from '../components/Icon.vue';

const error = ref('');
const modes = [
  { id: 'system', label: 'System' },
  { id: 'hell', label: 'Hell' },
  { id: 'dunkel', label: 'Dunkel' },
];
const dunkel = computed(() => document.documentElement.dataset.theme === 'dunkel'
  || (state.me?.theme !== 'hell' && window.matchMedia('(prefers-color-scheme: dark)').matches));

async function run(fn) {
  error.value = '';
  try {
    await fn();
  } catch (e) {
    error.value = e.message;
  }
}

function setTheme(theme) {
  run(() => setAppearance(theme, state.me.accent));
}
function setAccent(accent) {
  run(() => setAppearance(state.me.theme, accent));
}

// Geräte
const geraete = computed(() => {
  const groups = state.profiles.map((p) => ({
    person: p,
    list: state.devices.filter((d) => d.profile_id === p.id && !d.revoked_at),
  }));
  return groups.sort((a, b) => (a.person.id === state.me?.id ? -1 : b.person.id === state.me?.id ? 1 : 0));
});
function sperren(d) {
  const eigenes = d.session_id === state.sessionId;
  const text = eigenes
    ? 'Dieses Gerät abmelden und sperren?'
    : `„${d.label}“ von ${profile(d.profile_id)?.name} sperren?${d.kind === 'passkey' ? ' Der zugehörige Passkey wird ebenfalls entfernt.' : ''}`;
  if (!confirm(text)) return;
  run(async () => {
    await revokeDevice(d.id);
    toast('Gerät gesperrt');
  });
}

const einladung = ref(null);
function einladen(p) {
  run(async () => {
    einladung.value = await createInvite(p.slug);
  });
}
async function kopieren() {
  try {
    await navigator.clipboard.writeText(einladung.value.url);
    toast('Link kopiert');
  } catch {
    error.value = 'Kopieren nicht möglich – bitte den Link markieren und kopieren.';
  }
}
function teilen() {
  navigator.share?.({ title: 'Zwerg-Einladung', url: einladung.value.url }).catch(() => {});
}
const kannTeilen = typeof navigator.share === 'function';

function abmelden() {
  const warten = state.outbox.length;
  if (warten && !confirm(`${warten} Änderung(en) sind noch nicht abgeglichen und gehen beim Abmelden verloren. Trotzdem abmelden?`)) return;
  signOut();
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner"><h1>Einstellungen</h1></div>
  </header>
  <main class="page">
    <p v-if="error" class="error">{{ error }}</p>

    <section class="stack">
      <h2 class="section-title">Darstellung</h2>
      <div class="modes" role="radiogroup" aria-label="Modus">
        <button
          v-for="m in modes"
          :key="m.id"
          type="button"
          role="radio"
          :aria-checked="(state.me?.theme ?? 'system') === m.id"
          @click="setTheme(m.id)"
        >{{ m.label }}</button>
      </div>
      <h3 class="label">Akzentfarbe</h3>
      <div class="swatches" role="radiogroup" aria-label="Akzentfarbe">
        <button
          v-for="a in AKZENTE"
          :key="a.id"
          type="button"
          role="radio"
          :aria-checked="state.me?.accent === a.id"
          class="swatch"
          @click="setAccent(a.id)"
        >
          <span class="ring"><span class="dot" :style="{ background: dunkel ? a.dunkel : a.hell }"></span></span>
          <span class="small">{{ a.name }}</span>
        </button>
      </div>
      <p class="small muted">Gilt nur für dich, auf all deinen Geräten.</p>
    </section>

    <section class="stack">
      <h2 class="section-title">Geräte</h2>
      <router-link to="/koppeln" class="btn primary block"><Icon name="qr" />Gerät hinzufügen (QR-Code scannen)</router-link>
      <div v-for="g in geraete" :key="g.person.id" class="stack">
        <h3 class="label">{{ g.person.name }}</h3>
        <p v-if="!g.list.length" class="small muted">Noch keine Geräte.</p>
        <div v-for="d in g.list" :key="d.id" class="card device">
          <Icon :name="d.kind === 'passkey' ? 'phone' : 'laptop'" />
          <div class="grow">
            <div class="row">
              <strong>{{ d.label }}</strong>
              <span v-if="d.session_id === state.sessionId" class="chip">dieses Gerät</span>
            </div>
            <div class="small muted">
              {{ d.kind === 'passkey' ? 'Passkey' : 'per QR-Code' }} · zuletzt aktiv {{ relativ(d.last_seen_at) }}
            </div>
          </div>
          <button class="btn danger" type="button" @click="sperren(d)">Sperren</button>
        </div>
      </div>
      <div class="card stack">
        <h3 class="label">Neues iPhone einrichten</h3>
        <p class="small muted">Erzeugt einen Einladungs-Link (24 Stunden gültig), mit dem auf einem neuen iPhone ein Passkey eingerichtet wird.</p>
        <div class="row wrap">
          <button v-for="p in state.profiles" :key="p.id" class="btn" type="button" @click="einladen(p)">Link für {{ p.name }}</button>
        </div>
        <div v-if="einladung" class="stack">
          <label class="field">
            <span>Einladung für {{ einladung.name }}</span>
            <input class="input" readonly :value="einladung.url" @focus="$event.target.select()">
          </label>
          <div class="row">
            <button class="btn" type="button" @click="kopieren"><Icon name="copy" :size="18" />Kopieren</button>
            <button v-if="kannTeilen" class="btn" type="button" @click="teilen"><Icon name="share" :size="18" />Teilen</button>
          </div>
        </div>
      </div>
    </section>

    <section class="stack">
      <h2 class="section-title">Suchfelder</h2>
      <p class="small muted">Gelten für euch beide. Archivierte Einträge bleiben an bestehenden Ideen erhalten.</p>
      <ListEditor table="search_fields" placeholder="Neues Suchfeld" @error="error = $event" />
    </section>

    <section class="stack">
      <h2 class="section-title">Bewertungsfaktoren</h2>
      <p class="small muted">Grundlage der Bewertungsmatrix. Neue Faktoren erscheinen in offenen Bewertungen; die Gewichtung legt ihr unter Ideen → Ranking fest.</p>
      <ListEditor table="criteria" placeholder="Neuer Faktor" with-description @error="error = $event" />
    </section>

    <section class="stack">
      <h2 class="section-title">KO-Kriterien</h2>
      <p class="small muted">Trifft eines davon zu, ist eine Idee unabhängig von der Punktzahl ausgeschlossen.</p>
      <ListEditor table="ko_criteria" placeholder="Neues KO-Kriterium" @error="error = $event" />
    </section>

    <section class="stack">
      <h2 class="section-title">Konto</h2>
      <p class="small muted">Angemeldet als {{ state.me?.name }}.</p>
      <button class="btn" type="button" @click="abmelden">Auf diesem Gerät abmelden</button>
    </section>
  </main>
</template>

<style scoped>
.label { font-size: 13px; color: var(--muted); font-weight: 500; margin-top: 4px; }
.modes { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; padding: 4px; border-radius: 12px; background: var(--chip); }
.modes button { height: 38px; border: 0; border-radius: 9px; background: transparent; color: var(--muted); font-weight: 500; cursor: pointer; }
.modes button[aria-checked="true"] { background: var(--surface); color: var(--text); box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12); }
.swatches { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px 8px; max-width: 420px; }
.swatch { border: 0; background: none; padding: 0; display: flex; flex-direction: column; align-items: center; gap: 6px; cursor: pointer; color: var(--text); }
.ring { padding: 3px; border-radius: 50%; border: 2px solid transparent; display: block; }
.swatch[aria-checked="true"] .ring { border-color: var(--text); }
.dot { width: 36px; height: 36px; border-radius: 50%; display: block; }
.device { display: flex; align-items: center; gap: 12px; padding: 10px 10px 10px 14px; }
.device .row { flex-wrap: wrap; gap: 6px; }
.device .btn { flex: none; padding: 0 12px; font-size: 14px; }
.grow { flex: 1; min-width: 0; }
.wrap { flex-wrap: wrap; }
</style>
