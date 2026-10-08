<script setup>
// Pilot-Feedback: Kundengespräche und Testergebnisse strukturiert erfassen.
import { computed, reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { addFeedback, deleteFeedback, heute, profile, state, toast, updateFeedback } from '../lib/store.js';
import { datum } from '../lib/format.js';
import ScoreButtons from '../components/ScoreButtons.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const ARTEN = [
  { id: 'gespraech', name: 'Kundengespräch' },
  { id: 'test', name: 'Test / Pilot' },
  { id: 'umfrage', name: 'Umfrage' },
  { id: 'sonstiges', name: 'Sonstiges' },
];
const artName = (k) => ARTEN.find((a) => a.id === k)?.name ?? k;
const leer = () => ({ kind: 'gespraech', contact: '', held_on: heute(), summary: '', problem: null, interest: null, price: '', quote: '', learnings: '' });
const neu = reactive(leer());
const formOffen = ref(false);
const offen = ref(null);

const liste = computed(() => state.feedback.filter((f) => f.idea_id === id.value).sort((a, b) => (a.held_on < b.held_on ? 1 : -1)));
function schnitt(key) {
  const v = liste.value.map((f) => f[key]).filter((x) => x);
  return v.length ? (v.reduce((a, b) => a + b, 0) / v.length).toLocaleString('de-DE', { maximumFractionDigits: 1 }) : '–';
}
const preise = computed(() => liste.value.map((f) => f.price).filter(Boolean));

function speichern() {
  if (!neu.summary.trim() && !neu.contact.trim()) return;
  addFeedback({ ...neu, idea_id: id.value });
  Object.assign(neu, leer());
  formOffen.value = false;
  toast('Feedback gespeichert');
}
function loeschen(f) {
  if (confirm('Diesen Eintrag löschen?')) deleteFeedback(f.id);
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <button class="icon-btn" type="button" aria-label="Zurück" @click="router.push(`/idee/${id}`)"><Icon name="back" /></button>
      <h1 class="grow">Pilot-Feedback</h1>
    </div>
  </header>
  <main v-if="!idea" class="page"><p class="empty">Diese Idee gibt es nicht (mehr).</p></main>
  <main v-else class="page">
    <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>

    <section class="stats">
      <div class="card"><span class="small muted">Einträge</span><strong class="big">{{ liste.length }}</strong></div>
      <div class="card"><span class="small muted">Ø Problem spürbar</span><strong class="big">{{ schnitt('problem') }}</strong></div>
      <div class="card"><span class="small muted">Ø Kaufinteresse</span><strong class="big">{{ schnitt('interest') }}</strong></div>
    </section>
    <p v-if="preise.length" class="small"><span class="muted">Genannte Zahlungsbereitschaft:</span> {{ preise.join(' · ') }}</p>

    <button v-if="!formOffen" class="btn primary" type="button" @click="formOffen = true">Gespräch oder Test erfassen</button>
    <form v-else class="card stack" @submit.prevent="speichern">
      <div class="two">
        <label class="field">
          <span>Art</span>
          <select v-model="neu.kind" class="select"><option v-for="a in ARTEN" :key="a.id" :value="a.id">{{ a.name }}</option></select>
        </label>
        <label class="field"><span>Datum</span><input v-model="neu.held_on" class="input" type="date"></label>
      </div>
      <label class="field">
        <span>Mit wem? (Firma/Rolle – keine sensiblen Personendaten)</span>
        <input v-model="neu.contact" class="input" placeholder="z. B. Schreinerei, Inhaber">
      </label>
      <label class="field"><span>Zusammenfassung</span><textarea v-model="neu.summary" class="textarea" rows="4"></textarea></label>
      <div class="field"><span>Wie stark spürt die Person das Problem? (1 = gar nicht, 5 = sehr)</span>
        <ScoreButtons v-model="neu.problem" label="Problem spürbar" />
      </div>
      <div class="field"><span>Kaufinteresse (1 = keins, 5 = würde sofort kaufen)</span>
        <ScoreButtons v-model="neu.interest" label="Kaufinteresse" />
      </div>
      <label class="field"><span>Zahlungsbereitschaft</span><input v-model="neu.price" class="input" placeholder="z. B. bis 40 € im Monat"></label>
      <label class="field"><span>Zitat (wörtlich)</span><input v-model="neu.quote" class="input"></label>
      <label class="field"><span>Erkenntnisse für uns</span><textarea v-model="neu.learnings" class="textarea" rows="3"></textarea></label>
      <div class="row">
        <button class="btn primary" type="submit" :disabled="!neu.summary.trim() && !neu.contact.trim()">Speichern</button>
        <button class="btn" type="button" @click="formOffen = false">Abbrechen</button>
      </div>
    </form>

    <div class="stack">
      <article v-for="f in liste" :key="f.id" class="card entry">
        <button class="head" type="button" :aria-expanded="offen === f.id" @click="offen = offen === f.id ? null : f.id">
          <span class="grow">
            <strong>{{ f.contact || artName(f.kind) }}</strong>
            <span class="small muted block">{{ artName(f.kind) }} · {{ datum(f.held_on) }} · {{ profile(f.created_by)?.name }}</span>
          </span>
          <span class="small scores">
            <span v-if="f.problem" title="Problem spürbar">P {{ f.problem }}</span>
            <span v-if="f.interest" title="Kaufinteresse">K {{ f.interest }}</span>
          </span>
        </button>
        <p v-if="f.quote" class="quote">„{{ f.quote }}“</p>
        <template v-if="offen === f.id">
          <label class="field"><span>Mit wem?</span><input class="input" :value="f.contact" @change="updateFeedback(f.id, { contact: $event.target.value })"></label>
          <label class="field"><span>Zusammenfassung</span><textarea class="textarea" rows="4" :value="f.summary" @change="updateFeedback(f.id, { summary: $event.target.value })"></textarea></label>
          <div class="field"><span>Problem spürbar</span><ScoreButtons :model-value="f.problem" label="Problem spürbar" @update:model-value="updateFeedback(f.id, { problem: $event })" /></div>
          <div class="field"><span>Kaufinteresse</span><ScoreButtons :model-value="f.interest" label="Kaufinteresse" @update:model-value="updateFeedback(f.id, { interest: $event })" /></div>
          <label class="field"><span>Zahlungsbereitschaft</span><input class="input" :value="f.price" @change="updateFeedback(f.id, { price: $event.target.value })"></label>
          <label class="field"><span>Zitat</span><input class="input" :value="f.quote" @change="updateFeedback(f.id, { quote: $event.target.value })"></label>
          <label class="field"><span>Erkenntnisse</span><textarea class="textarea" rows="3" :value="f.learnings" @change="updateFeedback(f.id, { learnings: $event.target.value })"></textarea></label>
          <button class="btn danger" type="button" @click="loeschen(f)"><Icon name="trash" :size="18" />Löschen</button>
        </template>
        <template v-else>
          <p v-if="f.summary" class="pre clamp">{{ f.summary }}</p>
          <p v-if="f.learnings" class="small pre"><span class="muted">Erkenntnis:</span> {{ f.learnings }}</p>
        </template>
      </article>
      <p v-if="!liste.length" class="empty">Noch kein Feedback. Sprecht mit möglichen Kunden, bevor ihr Geld ausgebt.</p>
    </div>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.block { display: block; }
.idea-title { font-size: 20px; }
.stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px; }
.stats .card { display: flex; flex-direction: column; gap: 2px; padding: 10px 12px; }
.big { font-size: 22px; }
.two { display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); }
.entry { display: flex; flex-direction: column; gap: 8px; }
.head { display: flex; align-items: center; gap: 10px; border: 0; background: none; padding: 0; text-align: left; cursor: pointer; color: var(--text); }
.scores { display: flex; gap: 8px; font-weight: 600; }
.quote { font-style: italic; }
.pre { white-space: pre-wrap; }
.clamp { display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
</style>
