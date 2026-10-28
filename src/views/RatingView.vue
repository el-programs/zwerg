<script setup>
// Bewertung einer Idee: gemeinsam in einem Durchgang. Je Faktor eine Frage mit fünf Antworten,
// dazu die KO-Kriterien. Zum Schluss wird die Bewertung abgeschlossen (Endbewertung).
import { computed, reactive } from 'vue';
import { useRoute } from 'vue-router';
import { profile, setEvaluation, setJointNote, setJointRating, shortlistIdea, state, toast } from '../lib/store.js';
import { activeCriteria, activeKo, antwort, evaluation, ideaResult, jointScores, SKALEN, total } from '../lib/score.js';
import ScoreButtons from '../components/ScoreButtons.vue';
import { relativ } from '../lib/format.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const criteria = computed(() => activeCriteria());
const kos = computed(() => activeKo());

const gemeinsam = computed(() => jointScores(id.value));
const ev = computed(() => evaluation(id.value));
const jointKo = computed(() => ev.value?.ko_ids ?? []);
const pruefen = computed(() => ev.value?.ko_check_ids ?? []);
const beantwortet = computed(() => criteria.value.filter((c) => gemeinsam.value[c.id]?.score).length);
const offen = computed(() => criteria.value.length - beantwortet.value);
const abgeschlossen = computed(() => !!ev.value?.finalized_at);
const ergebnis = computed(() => ideaResult(id.value));
const notizOffen = reactive({});
const zuletzt = computed(() => {
  const rows = state.jointRatings.filter((r) => r.idea_id === id.value).sort((a, b) => (a.updated_at < b.updated_at ? 1 : -1));
  return rows[0] ?? null;
});
function antworten(c, score) {
  if (abgeschlossen.value) return;
  setJointRating(id.value, c.id, score);
}
// Je KO-Kriterium: nicht relevant · später prüfen · trifft zu (schließt die Idee aus).
const KO_STUFEN = [
  { id: 'nein', label: 'Nicht relevant' },
  { id: 'pruefen', label: 'Später prüfen' },
  { id: 'trifft', label: 'Trifft zu' },
];
function koStufe(koId) {
  if (jointKo.value.includes(koId)) return 'trifft';
  if (pruefen.value.includes(koId)) return 'pruefen';
  return 'nein';
}
function setKo(koId, stufe) {
  if (abgeschlossen.value) return;
  const ko = jointKo.value.filter((k) => k !== koId);
  const check = pruefen.value.filter((k) => k !== koId);
  if (stufe === 'trifft') ko.push(koId);
  if (stufe === 'pruefen') check.push(koId);
  setEvaluation(id.value, { ko_ids: ko, ko_check_ids: check });
}
function abschliessen() {
  setEvaluation(id.value, { finalized_at: new Date().toISOString(), finalized_by: state.me.id });
  toast('Bewertung abgeschlossen');
}
function wiederOeffnen() {
  setEvaluation(id.value, { finalized_at: null, finalized_by: null });
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link :to="`/idee/${id}`" class="icon-btn" aria-label="Zurück zur Idee"><Icon name="back" /></router-link>
      <h1 class="grow ellipsis">Bewertung</h1>
      <span class="small muted">{{ beantwortet }} von {{ criteria.length }}</span>
    </div>
  </header>

  <main v-if="!idea" class="page"><p class="empty">Diese Idee gibt es nicht (mehr).</p></main>

  <main v-else class="page">
    <div class="stack tight">
      <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>
      <p class="small muted">
        Ihr bewertet gemeinsam. Die rechte Antwort ist immer die beste für euch (4 Punkte), die linke zählt 0 Punkte.
        Jede Antwort wird sofort gespeichert und erscheint beim anderen.
        <template v-if="zuletzt"> Zuletzt geändert von {{ profile(zuletzt.updated_by)?.name }}, {{ relativ(zuletzt.updated_at) }}.</template>
      </p>
    </div>

    <div v-if="(idea.shortlist ?? 'offen') === 'offen' && idea.status !== 'geparkt'" class="card stack small">
      <strong>Diese Idee ist noch in der Vorauswahl.</strong>
      <span class="muted">Bewertet werden nur Ideen, die ihr weiterverfolgen wollt.</span>
      <button class="btn primary" type="button" @click="shortlistIdea(idea.id); toast('Idee ist in der Bewertungsrunde')">Weiterverfolgen und bewerten</button>
    </div>

    <p v-if="abgeschlossen" class="card small ok-card"><Icon name="check" :size="16" /> Bewertung abgeschlossen{{ ergebnis.ko ? ' – wegen KO ausgeschlossen' : '' }}. Zum Ändern unten „Wieder öffnen“.</p>

    <div class="stack">
      <div v-for="c in criteria" :key="c.id" class="card crit">
        <div>
          <span class="fac">{{ c.name }}</span>
          <p class="question">{{ c.description || c.name }}</p>
        </div>
        <ScoreButtons
          :model-value="gemeinsam[c.id]?.score ?? null"
          :labels="SKALEN[c.scale] ?? SKALEN.qualitaet"
          :disabled="abgeschlossen"
          :label="c.description || c.name"
          @update:model-value="antworten(c, $event)"
        />
        <button
          v-if="!notizOffen[c.id] && !gemeinsam[c.id]?.note"
          class="link-btn small"
          type="button"
          :disabled="!gemeinsam[c.id]?.score || abgeschlossen"
          @click="notizOffen[c.id] = true"
        >+ Begründung</button>
        <label v-else class="field">
          <span>Begründung</span>
          <input
            class="input"
            :value="gemeinsam[c.id]?.note ?? ''"
            placeholder="Warum diese Antwort?"
            :disabled="abgeschlossen"
            @change="setJointNote(id, c.id, $event.target.value)"
          >
        </label>
      </div>
    </div>

    <section v-if="kos.length" class="card stack">
      <h2>KO-Kriterien</h2>
      <p class="small muted">
        <strong>Später prüfen</strong>: wichtig für diese Idee, noch offen – die Idee bleibt in der Auswertung.
        <strong>Trifft zu</strong>: das KO ist eingetreten – die Idee ist unabhängig von der Punktzahl ausgeschlossen.
      </p>
      <div v-for="k in kos" :key="k.id" class="ko-item">
        <span class="ko-name">{{ k.name }}</span>
        <div class="ko-stufen" role="radiogroup" :aria-label="k.name">
          <button
            v-for="st in KO_STUFEN"
            :key="st.id"
            type="button"
            role="radio"
            :class="['ko-btn', st.id]"
            :aria-checked="koStufe(k.id) === st.id"
            :disabled="abgeschlossen"
            @click="setKo(k.id, st.id)"
          >{{ st.label }}</button>
        </div>
      </div>
    </section>

    <div class="sticky-action">
      <span class="small muted">Punktzahl: <strong>{{ offen ? '–' : total(gemeinsam) }}</strong> / 100<template v-if="offen"> · noch {{ offen }} offen</template></span>
      <button v-if="!abgeschlossen" class="btn primary" type="button" :disabled="offen > 0" @click="abschliessen">Abschließen</button>
      <button v-else class="btn" type="button" @click="wiederOeffnen">Wieder öffnen</button>
    </div>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.tight { gap: 8px; }
.idea-title { font-size: 20px; }
.crit { display: flex; flex-direction: column; gap: 10px; }
.fac { font-size: 12px; color: var(--muted); text-transform: uppercase; letter-spacing: 0.04em; }
.question { font-weight: 600; font-size: 16px; line-height: 1.35; margin-top: 2px; }
.link-btn { align-self: flex-start; border: 0; background: none; padding: 0; color: var(--accent); cursor: pointer; }
.link-btn:disabled { color: var(--muted); cursor: default; }
.ko-item { display: flex; flex-direction: column; gap: 6px; padding-top: 10px; border-top: 1px solid var(--line); }
.ko-name { font-weight: 600; }
.ko-stufen { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }
.ko-btn { min-height: 40px; padding: 4px 6px; border: 1px solid var(--line); border-radius: 10px; background: var(--surface); color: var(--muted); font: inherit; font-size: 14px; cursor: pointer; }
.ko-btn[aria-checked="true"] { color: var(--text); font-weight: 600; border-color: var(--accent); background: var(--chip); }
.ko-btn.pruefen[aria-checked="true"] { border-color: var(--warn); color: var(--warn); }
.ko-btn.trifft[aria-checked="true"] { border-color: var(--danger); color: var(--on-accent); background: var(--danger); }
.ko-btn:disabled { cursor: default; }
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
.ok-card { display: flex; align-items: center; gap: 8px; color: var(--ok); border-color: var(--ok); }
@media (min-width: 900px) { .sticky-action { bottom: 12px; } }
</style>
