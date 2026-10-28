<script setup>
import { computed, inject, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  fieldName, inVorauswahl, modelName, parkIdea, partner, shortlistIdea, state, unparkIdea, profile, toast,
} from '../lib/store.js';
import {
  activeCriteria, hasSubmittedWeights, ideaResult, jointScores, jointWeightsSet, RESULT_LABEL,
} from '../lib/score.js';
import { datum } from '../lib/format.js';
import IdeaCard from '../components/IdeaCard.vue';
import SynergyButton from '../components/SynergyButton.vue';
import RadarChart from '../components/RadarChart.vue';
import Auswertung from '../components/Auswertung.vue';
import Icon from '../components/Icon.vue';
import MeLink from '../components/MeLink.vue';

const openCapture = inject('openCapture');
const route = useRoute();
const router = useRouter();
const ansicht = ref(['vorauswahl', 'liste', 'ranking', 'vergleich'].includes(route.query.ansicht) ? route.query.ansicht : 'liste');
watch(ansicht, (a) => router.replace({ query: a === 'liste' ? {} : { ansicht: a } }));

const filter = ref('alle');
const suche = ref('');
const sucheOffen = ref(false);
const anderer = computed(() => partner());

// Filter nach Geschäftsmodell gilt für Liste, Auswertung und Vergleich.
const modell = ref('');
const models = computed(() => state.models.filter((m) => !m.archived || state.ideas.some((i) => i.business_model_id === m.id)));
const passt = (i) => !modell.value || (modell.value === 'ohne' ? !i.business_model_id : i.business_model_id === modell.value);
const aktiv = computed(() => state.ideas.filter((i) => i.status !== 'geparkt' && passt(i)));
const geparkt = computed(() => state.ideas.filter((i) => i.status === 'geparkt' && passt(i)));
const filters = computed(() => [
  { id: 'alle', label: `Alle ${aktiv.value.length}` },
  { id: 'favoriten', label: 'Favoriten' },
  { id: 'meine', label: 'Meine' },
  { id: 'partner', label: `Von ${anderer.value?.name ?? 'Partner'}` },
  { id: 'parkplatz', label: `Parkplatz ${geparkt.value.length}` },
]);

const liste = computed(() => {
  const q = suche.value.trim().toLowerCase();
  const basis = filter.value === 'parkplatz' ? geparkt.value : aktiv.value;
  return basis
    .filter((i) => {
      if (filter.value === 'meine') return i.created_by === state.me?.id;
      if (filter.value === 'partner') return i.created_by !== state.me?.id;
      if (filter.value === 'favoriten') return i.is_favorite;
      return true;
    })
    .filter((i) => {
      if (!q) return true;
      const text = [i.title, i.description, i.benefit, i.offer, i.customers, fieldName(i.search_field_id), modelName(i.business_model_id), i.park_reason, ...(i.tags ?? [])].join(' ').toLowerCase();
      return text.includes(q);
    })
    .sort((a, b) => (a.created_at < b.created_at ? 1 : -1));
});

// Runde 1: Vorauswahl – gemeinsam entscheiden, ob eine Idee weiterverfolgt wird.
const vorauswahl = computed(() => aktiv.value.filter(inVorauswahl).sort((a, b) => (a.created_at < b.created_at ? -1 : 1)));
function weiter(idea) {
  shortlistIdea(idea.id);
  toast(`„${idea.title || 'Ohne Titel'}“ ist in der Bewertungsrunde`);
}
function verwerfen(idea) {
  const grund = prompt('Warum wird die Idee verworfen? (Begründung bleibt auf dem Parkplatz erhalten)');
  if (grund === null) return;
  parkIdea(idea.id, grund || 'In der Vorauswahl verworfen');
  toast('Idee auf den Parkplatz gestellt');
}

// Ranking (Runde 2: nur weiterverfolgte Ideen)
const ranking = computed(() => {
  const rows = aktiv.value.filter((i) => i.shortlist === 'weiter').map((idea) => ({ idea, result: ideaResult(idea.id) }));
  const bewertet = rows.filter((r) => r.result.score !== null && !r.result.ko).sort((a, b) => b.result.score - a.result.score);
  const ko = rows.filter((r) => r.result.ko);
  const offen = rows.filter((r) => r.result.score === null && !r.result.ko);
  return { bewertet, ko, offen };
});
const favoriten = computed(() => aktiv.value.filter((i) => i.is_favorite).length);
const gewichtungStatus = computed(() => {
  if (jointWeightsSet()) return { text: 'Gemeinsame Gewichtung steht.', done: true };
  const ich = state.me && hasSubmittedWeights(state.me.id);
  const er = anderer.value && hasSubmittedWeights(anderer.value.id);
  if (!ich) return { text: 'Lege zuerst deine Gewichtung fest.', done: false };
  if (!er) return { text: `Warte auf die Gewichtung von ${anderer.value?.name}.`, done: false };
  return { text: 'Beide haben gewichtet – jetzt gemeinsam festlegen.', done: false };
});

// Vergleich
const vergleichbar = computed(() => ranking.value.bewertet.concat(ranking.value.ko).map((r) => r.idea));
const auswahl = ref([]);
watch(
  vergleichbar,
  (list) => {
    auswahl.value = auswahl.value.filter((id) => list.some((i) => i.id === id));
    if (!auswahl.value.length) auswahl.value = list.slice(0, 2).map((i) => i.id);
  },
  { immediate: true },
);
function toggleAuswahl(id) {
  if (auswahl.value.includes(id)) auswahl.value = auswahl.value.filter((x) => x !== id);
  else if (auswahl.value.length < 3) auswahl.value = [...auswahl.value, id];
  else toast('Höchstens drei Ideen gleichzeitig');
}
function kurz(name) {
  const teil = name.split('/')[0].trim();
  return teil.length > 18 ? teil.split(' ')[0] : teil;
}
const achsen = computed(() => activeCriteria().map((c) => ({ id: c.id, label: kurz(c.name), name: c.name })));
const FARBEN = ['var(--s1)', 'var(--s2)', 'var(--s3)'];
const serien = computed(() =>
  auswahl.value.map((id, i) => {
    const idea = state.ideas.find((x) => x.id === id);
    const result = ideaResult(id);
    const values = {};
    for (const [k, v] of Object.entries(jointScores(id))) values[k] = v.score;
    return { id, name: idea?.title || 'Ohne Titel', color: FARBEN[i], values, result };
  }),
);

</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <h1 class="grow">Geschäftsideen</h1>
      <button class="icon-btn" type="button" aria-label="Neue Idee" title="Neue Idee" @click="openCapture('idee')"><Icon name="plus" /></button>
      <button v-if="ansicht === 'liste'" class="icon-btn" type="button" :aria-pressed="sucheOffen" aria-label="Suchen" @click="sucheOffen = !sucheOffen"><Icon name="search" /></button>
      <MeLink />
    </div>
  </header>
  <main :class="['page', { wide: ansicht === 'ranking' }]">
    <div class="tabs" role="tablist" aria-label="Ansicht">
      <button role="tab" type="button" :aria-selected="ansicht === 'vorauswahl'" @click="ansicht = 'vorauswahl'">Vorauswahl<span v-if="vorauswahl.length" class="tab-count">{{ vorauswahl.length }}</span></button>
      <button role="tab" type="button" :aria-selected="ansicht === 'liste'" @click="ansicht = 'liste'">Liste</button>
      <button role="tab" type="button" :aria-selected="ansicht === 'ranking'" @click="ansicht = 'ranking'">Auswertung</button>
      <button role="tab" type="button" :aria-selected="ansicht === 'vergleich'" @click="ansicht = 'vergleich'">Vergleich</button>
    </div>
    <label class="field model-filter">
      <span class="visually-hidden">Geschäftsmodell</span>
      <select v-model="modell" class="select">
        <option value="">Alle Geschäftsmodelle</option>
        <option v-for="m in models" :key="m.id" :value="m.id">{{ m.name }} ({{ state.ideas.filter((i) => i.business_model_id === m.id && i.status !== 'geparkt').length }})</option>
        <option value="ohne">Ohne Geschäftsmodell</option>
      </select>
    </label>

    <!-- Runde 1: Vorauswahl -->
    <template v-if="ansicht === 'vorauswahl'">
      <p class="small muted">Runde 1: Entscheidet gemeinsam, ob ihr eine Idee weiterverfolgt. Weiterverfolgte Ideen kommen in die Bewertung (Runde 2), verworfene mit Begründung auf den Parkplatz.</p>
      <p v-if="!vorauswahl.length" class="empty">Alle Ideen sind entschieden. Neue Ideen erscheinen hier automatisch.</p>
      <article v-for="i in vorauswahl" :key="i.id" class="card stack pick">
        <span v-if="modelName(i.business_model_id)" class="pick-model">{{ modelName(i.business_model_id) }}</span>
        <div class="pick-head">
          <router-link :to="`/idee/${i.id}`" class="pick-title">{{ i.title || 'Ohne Titel' }}</router-link>
          <SynergyButton :idea-id="i.id" class="pick-syn" />
        </div>
        <p v-if="i.benefit" class="small"><span class="muted">Nutzen:</span> {{ i.benefit }}</p>
        <p v-if="i.offer" class="small"><span class="muted">Angebot:</span> {{ i.offer }}</p>
        <div class="row pick-actions">
          <button class="btn primary" type="button" @click="weiter(i)">Weiterverfolgen</button>
          <button class="btn" type="button" @click="verwerfen(i)">Verwerfen</button>
          <span class="grow"></span>
          <router-link :to="`/idee/${i.id}`" class="small more-link">Steckbrief</router-link>
        </div>
      </article>
    </template>

    <!-- Liste -->
    <template v-else-if="ansicht === 'liste'">
      <label v-if="sucheOffen" class="field">
        <span class="visually-hidden">Suche</span>
        <input v-model="suche" class="input" type="search" placeholder="Titel, Beschreibung, Schlagwort …" autofocus>
      </label>
      <div class="segmented" role="group" aria-label="Filter">
        <button v-for="f in filters" :key="f.id" type="button" :aria-pressed="filter === f.id" @click="filter = f.id">{{ f.label }}</button>
      </div>
      <p v-if="filter === 'parkplatz'" class="small muted">Verworfene Ideen mit Begründung. Sie lassen sich jederzeit reaktivieren.</p>
      <div class="stack">
        <template v-if="filter === 'parkplatz'">
          <div v-for="i in liste" :key="i.id" class="card parked">
            <router-link :to="`/idee/${i.id}`" class="parked-title">{{ i.title || 'Ohne Titel' }}</router-link>
            <p class="small"><span class="muted">Begründung:</span> {{ i.park_reason || '–' }}</p>
            <p class="small muted">geparkt von {{ profile(i.parked_by)?.name ?? '–' }}{{ i.parked_at ? `, ${datum(i.parked_at)}` : '' }}</p>
            <button class="btn" type="button" @click="unparkIdea(i.id); toast('Idee reaktiviert')">Reaktivieren</button>
          </div>
        </template>
        <template v-else>
          <IdeaCard v-for="i in liste" :key="i.id" :idea="i" />
        </template>
        <p v-if="!liste.length" class="empty">
          {{ filter === 'parkplatz' ? 'Der Parkplatz ist leer.' : state.ideas.length ? 'Keine Idee passt zu diesem Filter.' : 'Noch keine Geschäftsideen. Tippe oben rechts auf das +, um die erste anzulegen.' }}
        </p>
      </div>
    </template>

    <!-- Auswertung (früher Ranking) -->
    <template v-else-if="ansicht === 'ranking'">
      <router-link to="/gewichtung" class="card status" :class="{ done: gewichtungStatus.done }">
        <span class="grow">
          <strong>Gewichtung</strong>
          <span class="small muted block">{{ gewichtungStatus.text }}</span>
        </span>
        <Icon name="send" :size="18" />
      </router-link>
      <p class="small muted">
        Alle weiterverfolgten Ideen mit ihren Punkten je Faktor (0–4) und der Gesamtpunktzahl (0–100). Ziel der Phase 1: 2–3 Favoriten
        mit dem Stern markieren<template v-if="favoriten"> (aktuell {{ favoriten }})</template> und mit „→ Phase 2“ in die Machbarkeitsprüfung übernehmen.
      </p>

      <Auswertung :ideas="aktiv.filter((i) => i.shortlist === 'weiter')" />
    </template>

    <!-- Vergleich -->
    <template v-else-if="ansicht === 'vergleich'">
      <p class="small muted">Bis zu drei bewertete Ideen auswählen. Gezeigt werden eure gemeinsamen Antworten als Punkte 0–4.</p>
      <div class="segmented wrap" role="group" aria-label="Ideen auswählen">
        <button v-for="i in vergleichbar" :key="i.id" type="button" :aria-pressed="auswahl.includes(i.id)" @click="toggleAuswahl(i.id)">{{ i.title || 'Ohne Titel' }}</button>
      </div>
      <p v-if="!vergleichbar.length" class="empty">Noch keine bewerteten Ideen zum Vergleichen.</p>
      <template v-else-if="serien.length">
        <ul class="legend">
          <li v-for="s in serien" :key="s.id">
            <span class="swatch" :style="{ background: s.color }"></span>
            <span class="grow">{{ s.name }}</span>
            <strong>{{ s.result.score ?? '–' }}</strong>
            <span class="small muted">{{ RESULT_LABEL[s.result.kind] }}{{ s.result.ko ? ' · KO' : '' }}</span>
          </li>
        </ul>
        <div class="card chart"><RadarChart :axes="achsen" :series="serien" /></div>
        <div class="table-wrap">
          <table class="cmp">
            <thead>
              <tr>
                <th scope="col">Faktor</th>
                <th v-for="s in serien" :key="s.id" scope="col"><span class="swatch" :style="{ background: s.color }"></span>{{ s.name }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="a in achsen" :key="a.id">
                <th scope="row">{{ a.name }}</th>
                <td v-for="s in serien" :key="s.id">{{ s.values[a.id] ? s.values[a.id] - 1 : '–' }}</td>
              </tr>
              <tr class="sum">
                <th scope="row">Gesamt (0–100)</th>
                <td v-for="s in serien" :key="s.id">{{ s.result.score ?? '–' }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
    </template>
  </main>
</template>

<style scoped>
.grow { flex: 1; min-width: 0; }
.block { display: block; }
p { margin: 0; }
.tabs { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 4px; padding: 4px; border-radius: 12px; background: var(--chip); max-width: 560px; }
.tabs button { font-size: 14px; padding: 0 2px; position: relative; }
.tab-count { position: absolute; top: -6px; right: -2px; min-width: 18px; padding: 0 5px; border-radius: 9px; background: var(--accent); color: var(--on-accent); font-size: 11px; line-height: 18px; font-weight: 600; }
.pick { gap: 8px; }
.pick-model { font-size: 11.5px; text-transform: uppercase; letter-spacing: 0.05em; color: var(--accent); }
.pick-title { font-weight: 600; font-size: 16px; color: inherit; text-decoration: none; }
.pick-actions { flex-wrap: wrap; gap: 8px; margin-top: 4px; }
.more-link { color: var(--accent); text-decoration: none; }
.tabs button { height: 38px; border: 0; border-radius: 9px; background: transparent; color: var(--muted); font-weight: 500; cursor: pointer; }
.tabs button[aria-selected="true"] { background: var(--surface); color: var(--text); box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12); }
.segmented.wrap { flex-wrap: wrap; }
.model-filter { max-width: 480px; }
.parked { display: flex; flex-direction: column; gap: 6px; align-items: flex-start; }
.parked-title { font-weight: 600; color: var(--text); text-decoration: none; }
.status { display: flex; align-items: center; gap: 12px; text-decoration: none; color: inherit; border-color: var(--warn); }
.status.done { border-color: var(--line); }
.pick-head { display: flex; align-items: flex-start; gap: 8px; }
.pick-head .pick-title { flex: 1; min-width: 0; }
.pick-syn { margin: -10px -8px -10px 0; }
.legend { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; }
.legend li { display: flex; align-items: center; gap: 10px; }
.swatch { display: inline-block; width: 12px; height: 12px; border-radius: 3px; margin-right: 6px; flex: none; }
.chart { padding: 8px; }
.table-wrap { overflow-x: auto; border: 1px solid var(--line); border-radius: var(--radius); background: var(--surface); }
.cmp { width: 100%; border-collapse: collapse; font-size: 14px; }
.cmp th, .cmp td { padding: 8px 12px; border-bottom: 1px solid var(--line); text-align: left; }
.cmp td { text-align: center; font-variant-numeric: tabular-nums; }
.cmp thead th { font-size: 13px; color: var(--muted); font-weight: 500; white-space: nowrap; }
.cmp th[scope="row"] { font-weight: 400; }
.cmp .sum th, .cmp .sum td { font-weight: 600; border-bottom: 0; }
</style>
