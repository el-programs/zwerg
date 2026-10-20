<script setup>
// Bewertung einer Idee: gemeinsam in einem Durchgang. Je Faktor eine Frage mit fünf Antworten,
// dazu die KO-Kriterien. Zum Schluss wird die Bewertung abgeschlossen (Endbewertung).
import { computed, reactive } from 'vue';
import { useRoute } from 'vue-router';
import { profile, setEvaluation, setJointNote, setJointRating, shortlistIdea, state, toast } from '../lib/store.js';
import { activeCriteria, activeKo, antwort, evaluation, jointScores, SKALEN, total } from '../lib/score.js';
import ScoreButtons from '../components/ScoreButtons.vue';
import { ergebnisse, kiSichtbar } from '../lib/ki.js';
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
const beantwortet = computed(() => criteria.value.filter((c) => gemeinsam.value[c.id]?.score).length);
const offen = computed(() => criteria.value.length - beantwortet.value);
const abgeschlossen = computed(() => !!ev.value?.finalized_at);
const notizOffen = reactive({});
const zuletzt = computed(() => {
  const rows = state.jointRatings.filter((r) => r.idea_id === id.value).sort((a, b) => (a.updated_at < b.updated_at ? 1 : -1));
  return rows[0] ?? null;
});
// Eine vorhandene KI-Einschätzung wird je Faktor als Hinweis gezeigt.
const kiVorschlag = computed(() => {
  const e = ergebnisse(id.value, 'einschaetzung').find((r) => r.status === 'fertig');
  return kiSichtbar.value && e ? Object.fromEntries((e.content?.bewertung ?? []).map((b) => [b.faktor_id, b])) : null;
});

function antworten(c, score) {
  if (abgeschlossen.value) return;
  setJointRating(id.value, c.id, score);
}
function toggleJointKo(koId, on) {
  const list = new Set(jointKo.value);
  if (on) list.add(koId);
  else list.delete(koId);
  setEvaluation(id.value, { ko_ids: [...list] });
}
function abschliessen() {
  setEvaluation(id.value, { ko_ids: jointKo.value, finalized_at: new Date().toISOString(), finalized_by: state.me.id });
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

    <p v-if="abgeschlossen" class="card small ok-card"><Icon name="check" :size="16" /> Bewertung abgeschlossen{{ jointKo.length ? ' – wegen KO ausgeschlossen' : '' }}. Zum Ändern unten „Wieder öffnen“.</p>

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
        <p v-if="kiVorschlag?.[c.id]" class="small ki-hint">
          <span class="ki-tag">KI-Vorschlag</span> <strong>{{ antwort(c, kiVorschlag[c.id].punkte) }}</strong>
          <span class="muted"> – {{ kiVorschlag[c.id].begruendung }}</span>
        </p>
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
      <p class="small muted">Trifft eines zu, ist die Idee unabhängig von der Punktzahl ausgeschlossen.</p>
      <label v-for="k in kos" :key="k.id" class="check">
        <input type="checkbox" :checked="jointKo.includes(k.id)" :disabled="abgeschlossen" @change="toggleJointKo(k.id, $event.target.checked)">
        <span>{{ k.name }}</span>
      </label>
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
.ki-tag { font-size: 11px; font-weight: 600; padding: 1px 6px; border-radius: 6px; border: 1px solid var(--accent); color: var(--accent); }
.ok-card { display: flex; align-items: center; gap: 8px; color: var(--ok); border-color: var(--ok); }
@media (min-width: 900px) { .sticky-action { bottom: 12px; } }
</style>
