<script setup>
// Bewertung einer Idee: 1. jeder für sich (verborgen), 2. Vergleich, 3. gemeinsame Endbewertung.
import { computed, reactive, watch } from 'vue';
import { useRoute } from 'vue-router';
import {
  partner, refresh, setEvaluation, setJointRating, setRating, state, submitRating, toast, toggleKo,
} from '../lib/store.js';
import {
  ABWEICHUNG, activeCriteria, activeKo, evaluation, hasSubmittedRating, jointScores, personalKoIds,
  personalScores, total,
} from '../lib/score.js';
import ScoreButtons from '../components/ScoreButtons.vue';
import { ergebnisse, kiSichtbar } from '../lib/ki.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const me = computed(() => state.me);
const anderer = computed(() => partner());
const criteria = computed(() => activeCriteria());
const kos = computed(() => activeKo());

const ichFertig = computed(() => me.value && hasSubmittedRating(id.value, me.value.id));
const andererFertig = computed(() => anderer.value && hasSubmittedRating(id.value, anderer.value.id));
const schritt = computed(() => (!ichFertig.value ? 1 : !andererFertig.value ? 2 : 3));

const meine = computed(() => personalScores(id.value, me.value.id));
const seine = computed(() => (anderer.value ? personalScores(id.value, anderer.value.id) : {}));
const gemeinsam = computed(() => jointScores(id.value));
const meineKo = computed(() => personalKoIds(id.value, me.value.id));
const seineKo = computed(() => (anderer.value ? personalKoIds(id.value, anderer.value.id) : []));
const ev = computed(() => evaluation(id.value));
const offen = computed(() => criteria.value.filter((c) => !meine.value[c.id]?.score).length);
const notizOffen = reactive({});
// KI-Vorschlag erst im Vergleich zeigen, damit die eigene Bewertung unbeeinflusst bleibt.
const kiVorschlag = computed(() => {
  const e = ergebnisse(id.value, 'einschaetzung').find((r) => r.status === 'fertig');
  return kiSichtbar.value && e ? Object.fromEntries((e.content?.bewertung ?? []).map((b) => [b.faktor_id, b])) : null;
});
// Partnerwerte werden erst nach der eigenen Abgabe vom Server geliefert.
const partnerGeladen = computed(() => Object.keys(seine.value).length > 0);
watch(
  () => schritt.value === 3 && !partnerGeladen.value,
  (fehlt) => {
    if (fehlt) refresh();
  },
  { immediate: true },
);

function vorschlag(c) {
  const a = meine.value[c.id]?.score;
  const b = seine.value[c.id]?.score;
  if (!a || !b) return a ?? b ?? null;
  return Math.round((a + b) / 2);
}
function abweichung(c) {
  const a = meine.value[c.id]?.score;
  const b = seine.value[c.id]?.score;
  return !!a && !!b && Math.abs(a - b) >= ABWEICHUNG;
}
const grosseAbweichungen = computed(() => criteria.value.filter(abweichung).length);
const jointKo = computed(() => ev.value?.ko_ids ?? []);
const gemeinsamOffen = computed(() => criteria.value.filter((c) => !gemeinsam.value[c.id]?.score).length);

function abgeben() {
  if (offen.value) return;
  if (!confirm('Bewertung abgeben? Danach siehst du die Bewertung deines Partners.')) return;
  submitRating(id.value);
  toast('Bewertung abgegeben');
}
function vorschlaegeUebernehmen() {
  for (const c of criteria.value) if (!gemeinsam.value[c.id]?.score && vorschlag(c)) setJointRating(id.value, c.id, vorschlag(c));
  if (!ev.value) setEvaluation(id.value, { ko_ids: [...new Set([...meineKo.value, ...seineKo.value])] });
}
function toggleJointKo(koId, on) {
  const list = new Set(jointKo.value);
  if (on) list.add(koId);
  else list.delete(koId);
  setEvaluation(id.value, { ko_ids: [...list] });
}
function festlegen() {
  setEvaluation(id.value, { ko_ids: jointKo.value, finalized_at: new Date().toISOString(), finalized_by: me.value.id });
  toast('Endbewertung festgelegt');
}
function wiederOeffnen() {
  setEvaluation(id.value, { finalized_at: null, finalized_by: null });
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link :to="`/idee/${id}`" class="icon-btn" aria-label="Zurück zur Notiz"><Icon name="back" /></router-link>
      <h1 class="grow ellipsis">Bewertung</h1>
    </div>
  </header>

  <main v-if="!idea || !me || !anderer" class="page"><p class="empty">Diese Notiz gibt es nicht (mehr).</p></main>

  <main v-else class="page">
    <div class="stack tight">
      <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>
      <ol class="steps">
        <li :class="{ on: schritt === 1, done: schritt > 1 }">1 · Jeder für sich</li>
        <li :class="{ on: schritt === 2, done: schritt > 2 }">2 · Vergleich</li>
        <li :class="{ on: schritt === 3 }">3 · Gemeinsam</li>
      </ol>
    </div>

    <!-- Schritt 1: eigene Bewertung -->
    <template v-if="schritt === 1">
      <p class="muted">
        Bewerte jeden Faktor von <strong>1</strong> (schlecht für uns) bis <strong>5</strong> (sehr gut für uns) –
        auch bei Risiko, Wettbewerb oder Aufwand gilt: 5 = günstig für uns.
      </p>
      <p class="small muted">{{ anderer.name }}: {{ andererFertig ? 'hat schon abgegeben' : 'noch offen' }}. Seine Werte siehst du erst nach deiner Abgabe.</p>
      <div class="stack">
        <div v-for="c in criteria" :key="c.id" class="card crit">
          <div>
            <strong>{{ c.name }}</strong>
            <p v-if="c.description" class="small muted">{{ c.description }}</p>
          </div>
          <ScoreButtons
            :model-value="meine[c.id]?.score ?? null"
            :label="`Punkte für ${c.name}`"
            @update:model-value="setRating(id, c.id, { score: $event })"
          />
          <button v-if="!notizOffen[c.id] && !meine[c.id]?.note" class="link-btn small" type="button" :disabled="!meine[c.id]?.score" @click="notizOffen[c.id] = true">+ Begründung</button>
          <label v-else class="field">
            <span>Begründung</span>
            <input
              class="input"
              :value="meine[c.id]?.note ?? ''"
              placeholder="Warum diese Punktzahl?"
              @change="setRating(id, c.id, { note: $event.target.value })"
            >
          </label>
        </div>
      </div>

      <section v-if="kos.length" class="card stack">
        <h2>KO-Kriterien</h2>
        <p class="small muted">Trifft eines zu, ist die Notiz unabhängig von der Punktzahl ausgeschlossen.</p>
        <label v-for="k in kos" :key="k.id" class="check">
          <input type="checkbox" :checked="meineKo.includes(k.id)" @change="toggleKo(id, k.id, $event.target.checked)">
          <span>{{ k.name }}</span>
        </label>
      </section>

      <div class="sticky-action">
        <span class="small muted">Deine Punktzahl: <strong>{{ total(meine) ?? '–' }}</strong> / 100</span>
        <button class="btn primary" type="button" :disabled="offen > 0" @click="abgeben">
          {{ offen ? `Noch ${offen} offen` : 'Bewertung abgeben' }}
        </button>
      </div>
    </template>

    <!-- Schritt 2: warten -->
    <template v-else-if="schritt === 2">
      <section class="card stack">
        <h2>Abgegeben – warte auf {{ anderer.name }}</h2>
        <p>Deine Punktzahl: <strong>{{ total(meine) ?? '–' }}</strong> von 100</p>
        <p class="small muted">Sobald {{ anderer.name }} abgegeben hat, erscheinen hier beide Bewertungen im Vergleich.</p>
      </section>
    </template>

    <template v-else-if="!partnerGeladen">
      <section class="card stack">
        <h2>Bewertung von {{ anderer.name }} wird geladen …</h2>
        <p class="small muted">Einen Moment – ohne Internet erscheint sie, sobald wieder Verbindung besteht.</p>
      </section>
    </template>

    <!-- Schritt 3: Vergleich und gemeinsame Bewertung -->
    <template v-else>
      <section class="totals">
        <div class="card">
          <span class="small muted">{{ me.name }}</span>
          <strong class="big">{{ total(meine) ?? '–' }}</strong>
        </div>
        <div class="card">
          <span class="small muted">{{ anderer.name }}</span>
          <strong class="big">{{ total(seine) ?? '–' }}</strong>
        </div>
        <div class="card" :class="{ final: ev?.finalized_at }">
          <span class="small muted">Gemeinsam</span>
          <strong class="big">{{ total(gemeinsam) ?? '–' }}</strong>
        </div>
      </section>

      <p class="small" :class="grosseAbweichungen ? 'warn' : 'muted'">
        {{ grosseAbweichungen ? `${grosseAbweichungen} Faktor(en) mit großer Abweichung (ab ${ABWEICHUNG} Punkten) – besprecht diese zuerst.` : 'Ihr liegt überall nah beieinander.' }}
      </p>

      <div class="stack">
        <div v-for="c in criteria" :key="c.id" class="card crit" :class="{ diff: abweichung(c) }">
          <div class="row top">
            <strong class="grow">{{ c.name }}</strong>
            <span v-if="abweichung(c)" class="chip warn-chip">große Abweichung</span>
          </div>
          <div class="pair small">
            <div><span class="avatar">{{ me.kuerzel }}</span> <strong>{{ meine[c.id]?.score ?? '–' }}</strong> <span v-if="meine[c.id]?.note" class="muted">– {{ meine[c.id].note }}</span></div>
            <div><span class="avatar">{{ anderer.kuerzel }}</span> <strong>{{ seine[c.id]?.score ?? '–' }}</strong> <span v-if="seine[c.id]?.note" class="muted">– {{ seine[c.id].note }}</span></div>
            <div v-if="kiVorschlag?.[c.id]" class="ki-hint" :title="kiVorschlag[c.id].begruendung"><span class="ki-tag">KI-Vorschlag</span> <strong>{{ kiVorschlag[c.id].punkte }}</strong> <span class="muted">– {{ kiVorschlag[c.id].begruendung }}</span></div>
          </div>
          <ScoreButtons
            :model-value="gemeinsam[c.id]?.score ?? null"
            :suggestion="vorschlag(c)"
            :label="`Gemeinsame Punkte für ${c.name}`"
            @update:model-value="setJointRating(id, c.id, $event)"
          />
        </div>
      </div>

      <section v-if="kos.length" class="card stack">
        <h2>KO-Kriterien (gemeinsam)</h2>
        <p v-if="meineKo.length || seineKo.length" class="small muted">
          Einzeln markiert:
          <template v-for="k in kos" :key="k.id">
            <span v-if="meineKo.includes(k.id) || seineKo.includes(k.id)" class="chip outline">
              {{ k.name }} ({{ [meineKo.includes(k.id) ? me.kuerzel : '', seineKo.includes(k.id) ? anderer.kuerzel : ''].filter(Boolean).join(', ') }})
            </span>
          </template>
        </p>
        <label v-for="k in kos" :key="k.id" class="check">
          <input type="checkbox" :checked="jointKo.includes(k.id)" @change="toggleJointKo(k.id, $event.target.checked)">
          <span>{{ k.name }}</span>
        </label>
      </section>

      <div class="row wrap actions">
        <button v-if="gemeinsamOffen" class="btn" type="button" @click="vorschlaegeUebernehmen">Vorschläge (Mittelwert) für offene Faktoren übernehmen</button>
        <button v-if="!ev?.finalized_at" class="btn primary" type="button" :disabled="gemeinsamOffen > 0" @click="festlegen">
          {{ gemeinsamOffen ? `Noch ${gemeinsamOffen} gemeinsam offen` : 'Endbewertung festlegen' }}
        </button>
        <template v-else>
          <p class="small ok"><Icon name="check" :size="16" /> Endbewertung festgelegt{{ jointKo.length ? ' – wegen KO ausgeschlossen' : '' }}.</p>
          <button class="btn" type="button" @click="wiederOeffnen">Wieder öffnen</button>
        </template>
      </div>
    </template>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tight { gap: 8px; }
.idea-title { font-size: 20px; }
.steps { list-style: none; margin: 0; padding: 0; display: flex; gap: 6px; flex-wrap: wrap; font-size: 13px; }
.steps li { padding: 4px 10px; border-radius: 999px; background: var(--chip); color: var(--muted); }
.steps li.on { background: var(--accent); color: var(--on-accent); font-weight: 600; }
.steps li.done { color: var(--text); }
.crit { display: flex; flex-direction: column; gap: 10px; }
.crit.diff { border-color: var(--warn); }
.top { align-items: flex-start; }
.wrap { flex-wrap: wrap; }
.link-btn { align-self: flex-start; border: 0; background: none; padding: 0; color: var(--accent); cursor: pointer; }
.link-btn:disabled { color: var(--muted); cursor: default; }
.check { display: flex; gap: 10px; align-items: flex-start; min-height: 32px; cursor: pointer; }
.check input { width: 20px; height: 20px; margin-top: 2px; accent-color: var(--accent); }
.sticky-action {
  position: sticky;
  bottom: calc(var(--nav-h) + var(--safe-b) + 8px);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 12px 10px 16px;
  border-radius: var(--radius);
  background: var(--surface);
  border: 1px solid var(--line);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}
.totals { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px; }
.totals .card { display: flex; flex-direction: column; gap: 2px; padding: 10px 12px; }
.totals .final { border-color: var(--accent); }
.big { font-size: 22px; }
.ki-hint { flex-basis: 100%; }
.ki-tag { font-size: 11px; font-weight: 600; padding: 1px 6px; border-radius: 6px; border: 1px solid var(--accent); color: var(--accent); }
.pair { display: flex; flex-wrap: wrap; gap: 6px 18px; }
.pair .avatar { width: 24px; height: 24px; font-size: 10px; display: inline-flex; vertical-align: middle; }
.warn { color: var(--warn); font-weight: 500; }
.warn-chip { background: transparent; border: 1px solid var(--warn); color: var(--warn); }
.ok { color: var(--ok); display: flex; align-items: center; gap: 6px; }
.actions { align-items: center; }
</style>
