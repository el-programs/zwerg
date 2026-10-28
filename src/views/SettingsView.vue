<script setup>
// Einstellungen: Übersicht mit Gruppen; jeder Eintrag öffnet einen eigenen Bereich (/mehr/<bereich>).
// Am Handy entweder Übersicht oder Bereich, am Computer beides nebeneinander.
import { computed, onBeforeUnmount, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { createInvite, profile, revokeDevice, setAppearance, signOut, state, toast } from '../lib/store.js';
import ListEditor from '../components/ListEditor.vue';
import { AKZENTE, relativ } from '../lib/format.js';
import Icon from '../components/Icon.vue';
import { excelExport } from '../lib/export.js';

const route = useRoute();
const router = useRouter();
const error = ref('');

const mq = window.matchMedia('(min-width: 900px)');
const istBreit = ref(mq.matches);
const aufBreite = (e) => { istBreit.value = e.matches; };
mq.addEventListener('change', aufBreite);
onBeforeUnmount(() => mq.removeEventListener('change', aufBreite));

const aktiv = (list) => list.filter((x) => !x.archived).length;
const GRUPPEN = computed(() => [
  { name: 'Ich', items: [
    { id: 'darstellung', titel: 'Darstellung', info: `${modes.find((m) => m.id === (state.me?.theme ?? 'system'))?.label} · ${AKZENTE.find((a) => a.id === state.me?.accent)?.name ?? 'Petrol'}` },
    { id: 'konto', titel: 'Konto', info: state.me?.name ?? '' },
  ] },
  { name: 'Ideen und Bewertung', items: [
    { id: 'geschaeftsmodelle', titel: 'Geschäftsmodelle', info: `${aktiv(state.models)} aktiv` },
    { id: 'branchen', titel: 'Branchen', info: `${aktiv(state.fields)} aktiv` },
    { id: 'faktoren', titel: 'Bewertungsfaktoren', info: `${aktiv(state.criteria)} aktiv` },
    { id: 'ko', titel: 'KO-Kriterien', info: `${aktiv(state.koCriteria)} aktiv` },
  ] },
  { name: 'Zusammenarbeit', items: [
    { id: 'geraete', titel: 'Geräte', info: `${state.devices.filter((d) => !d.revoked_at).length} Geräte` },
    { id: 'hinzufuegen', titel: 'Gerät hinzufügen oder einladen', info: '' },
  ] },
  { name: 'Daten', items: [
    { id: 'export', titel: 'Export und Berichte', info: 'Excel, PDF' },
  ] },
]);
const alle = computed(() => GRUPPEN.value.flatMap((g) => g.items));
const gewaehlt = computed(() => route.params.bereich || null);
// Am Computer ist immer ein Bereich offen (Standard: Darstellung).
const bereich = computed(() => gewaehlt.value || (istBreit.value ? 'darstellung' : null));
const titel = computed(() => alle.value.find((b) => b.id === bereich.value)?.titel ?? 'Einstellungen');
function oeffnen(id) {
  router.push(`/mehr/${id}`);
}
function zurueck() {
  router.push('/mehr');
}
// eslint-disable-next-line no-undef
const version = __ZWERG_VERSION__;
const exportLaeuft = ref(false);
async function exportieren() {
  exportLaeuft.value = true;
  try {
    await excelExport();
  } catch (e) {
    error.value = `Export fehlgeschlagen: ${e.message}`;
  } finally {
    exportLaeuft.value = false;
  }
}
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
    <div class="topbar-inner">
      <button v-if="gewaehlt && !istBreit" class="icon-btn" type="button" aria-label="Zurück zu den Einstellungen" @click="zurueck"><Icon name="back" /></button>
      <h1 class="grow">{{ istBreit ? 'Einstellungen' : titel }}</h1>
    </div>
  </header>
  <main class="page settings" :class="{ breit: istBreit }">
    <p v-if="error" class="error">{{ error }}</p>
    <div class="layout">
      <nav v-if="istBreit || !bereich" class="overview" aria-label="Bereiche">
        <section v-for="g in GRUPPEN" :key="g.name" class="group">
          <h2 class="group-title">{{ g.name }}</h2>
          <div class="card list">
            <button
              v-for="b in g.items"
              :key="b.id"
              type="button"
              class="entry"
              :aria-current="bereich === b.id ? 'page' : undefined"
              @click="oeffnen(b.id)"
            >
              <span class="grow">{{ b.titel }}</span>
              <span class="small muted">{{ b.info }}</span>
              <span class="chev" aria-hidden="true">›</span>
            </button>
          </div>
        </section>
        <p class="small muted version">Version vom {{ version }} (UTC)</p>
      </nav>
      <div v-if="bereich" class="content">
      <div v-if="bereich === 'darstellung'" class="bereich">
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
      </div>
      <div v-if="bereich === 'konto'" class="bereich">
      <section class="stack">
        <h2 class="section-title">Konto</h2>
        <p class="small muted">Angemeldet als {{ state.me?.name }}. Version vom {{ version }} (UTC).</p>
        <button class="btn" type="button" @click="abmelden">Auf diesem Gerät abmelden</button>
      </section>
      </div>
      <div v-if="bereich === 'geschaeftsmodelle'" class="bereich">
      <section class="stack">
        <h2 class="section-title">Geschäftsmodelle</h2>
        <p class="small muted">Überbegriff für eure Ideen: Wie verdient ihr Geld? Gelten für euch beide; neue Gruppen unten hinzufügen. Archivierte bleiben an bestehenden Ideen erhalten.</p>
        <ListEditor table="business_models" placeholder="Neues Geschäftsmodell" @error="error = $event" />
      </section>
      </div>
      <div v-if="bereich === 'branchen'" class="bereich">
      <section class="stack">
        <h2 class="section-title">Branchen</h2>
        <p class="small muted">Abschnitte nach NACE mit Sektor. Gelten für euch beide. Archivierte Einträge bleiben an bestehenden Ideen erhalten.</p>
        <ListEditor table="search_fields" placeholder="Neue Branche, z. B. W - … - Tertiär" @error="error = $event" />
      </section>
      </div>
      <div v-if="bereich === 'faktoren'" class="bereich">
      <section class="stack">
        <h2 class="section-title">Bewertungsfaktoren</h2>
        <p class="small muted">Je Faktor eine Frage und die passende Antwortskala – die rechte Antwort ist immer die beste für euch. Neue Faktoren erscheinen in offenen Bewertungen; die Gewichtung legt ihr unter Geschäftsideen → Auswertung fest.</p>
        <ListEditor table="criteria" placeholder="Neuer Faktor" with-description with-scale description-placeholder="Frage für die Bewertung, z. B. Wie gut …?" @error="error = $event" />
      </section>
      </div>
      <div v-if="bereich === 'ko'" class="bereich">
      <section class="stack">
        <h2 class="section-title">KO-Kriterien</h2>
        <p class="small muted">Trifft eines davon zu, ist eine Idee unabhängig von der Punktzahl ausgeschlossen.</p>
        <ListEditor table="ko_criteria" placeholder="Neues KO-Kriterium" @error="error = $event" />
      </section>
      </div>
      <div v-if="bereich === 'geraete'" class="bereich">
      <section class="stack">
        <h2 class="section-title">Geräte</h2>
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
        <router-link to="/mehr/hinzufuegen" class="small more-link">Gerät hinzufügen oder einladen ›</router-link>
      </section>
      </div>
      <div v-if="bereich === 'hinzufuegen'" class="bereich">
      <section class="stack">
        <h2 class="section-title">Gerät hinzufügen oder einladen</h2>
        <p class="small muted">Laptop oder weiteres Gerät: am neuen Gerät „Mit iPhone anmelden“ wählen und den QR-Code hier scannen.</p>
        <router-link to="/koppeln" class="btn primary block"><Icon name="qr" />Gerät hinzufügen (QR-Code scannen)</router-link>
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
      </div>
      <div v-if="bereich === 'export'" class="bereich">
      <section class="stack">
        <h2 class="section-title">Export &amp; Berichte</h2>
        <p class="small muted">Alles als Excel-Datei (Ideen, Bewertungen, Business Cases, Aufgaben, Entscheidungen, Pilot-Feedback, Notizen, Meetings) oder als PDF-Bericht, z. B. für Bank oder Steuerberater. Den Steckbrief einer Idee findet ihr in der Idee ganz unten.</p>
        <div class="row wrap">
          <button class="btn" type="button" :disabled="exportLaeuft" @click="exportieren">{{ exportLaeuft ? 'Wird erstellt …' : 'Excel-Export' }}</button>
          <router-link to="/bericht" class="btn">Projektbericht (PDF)</router-link>
        </div>
      </section>
      </div>
      </div>
    </div>
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
.layout { display: flex; flex-direction: column; gap: 18px; }
.group { display: flex; flex-direction: column; gap: 6px; }
.group-title { font-size: 12px; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); font-weight: 600; margin: 8px 4px 0; }
.list { padding: 0; overflow: hidden; display: flex; flex-direction: column; }
.entry { display: flex; align-items: center; gap: 10px; min-height: 50px; padding: 0 14px; border: 0; border-top: 1px solid var(--line); background: transparent; color: var(--text); font: inherit; text-align: left; cursor: pointer; }
.entry:first-child { border-top: 0; }
.entry[aria-current="page"] { background: var(--chip); }
.entry[aria-current="page"] .grow { color: var(--accent); font-weight: 600; }
.chev { color: var(--muted); font-size: 18px; }
.version { margin: 6px 4px 0; }
.bereich { display: flex; flex-direction: column; gap: 14px; }
.more-link { color: var(--accent); text-decoration: none; }
/* Am Handy steht der Bereichsname schon oben in der Leiste. */
.settings:not(.breit) .content :deep(.section-title) { display: none; }
@media (min-width: 900px) {
  .settings.breit { max-width: 1100px; }
  .layout { display: grid; grid-template-columns: 300px minmax(0, 1fr); align-items: start; gap: 28px; }
  .overview { position: sticky; top: 12px; }
}
</style>
