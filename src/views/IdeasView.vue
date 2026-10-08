<script setup>
import { computed, inject, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { fieldName, partner, setFavorite, state, unparkIdea, profile, toast } from '../lib/store.js';
import {
  activeCriteria, hasSubmittedWeights, ideaResult, jointScores, jointWeightsSet, personalScores, RESULT_LABEL,
} from '../lib/score.js';
import { datum } from '../lib/format.js';
import IdeaCard from '../components/IdeaCard.vue';
import RadarChart from '../components/RadarChart.vue';
import Icon from '../components/Icon.vue';
import { kiSichtbar } from '../lib/ki.js';

const openCapture = inject('openCapture');
const route = useRoute();
const router = useRouter();
const ansicht = ref(['liste', 'ranking', 'vergleich'].includes(route.query.ansicht) ? route.query.ansicht : 'liste');
watch(ansicht, (a) => router.replace({ query: a === 'liste' ? {} : { ansicht: a } }));

const filter = ref('alle');
const suche = ref('');
const sucheOffen = ref(false);
const anderer = computed(() => partner());

const aktiv = computed(() => state.ideas.filter((i) => i.status !== 'geparkt'));
const geparkt = computed(() => state.ideas.filter((i) => i.status === 'geparkt'));
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
      const text = [i.title, i.description, fieldName(i.search_field_id), i.park_reason, ...(i.tags ?? [])].join(' ').toLowerCase();
      return text.includes(q);
    })
    .sort((a, b) => (a.created_at < b.created_at ? 1 : -1));
});

// Ranking
const ranking = computed(() => {
  const rows = aktiv.value.map((idea) => ({ idea, result: ideaResult(idea.id) }));
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
    let values = {};
    if (result.kind === 'final') {
      for (const [k, v] of Object.entries(jointScores(id))) values[k] = v.score;
    } else {
      const subs = state.profiles.map((p) => personalScores(id, p.id)).filter((m) => Object.keys(m).length);
      for (const c of activeCriteria()) {
        const vals = subs.map((m) => m[c.id]?.score).filter(Boolean);
        if (vals.length) values[c.id] = Math.round((vals.reduce((a, b) => a + b, 0) / vals.length) * 10) / 10;
      }
    }
    return { id, name: idea?.title || 'Ohne Titel', color: FARBEN[i], values, result };
  }),
);

function stern(idea) {
  setFavorite(idea.id, !idea.is_favorite);
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <h1 class="grow">Gedanken &amp; Ideen</h1>
      <button class="icon-btn" type="button" aria-label="Neue Idee" title="Neue Idee" @click="openCapture('idee')"><Icon name="plus" /></button>
      <router-link v-if="kiSichtbar && ansicht === 'liste'" to="/ki/vorschlaege" class="btn ki-btn">KI-Vorschläge</router-link>
      <button v-if="ansicht === 'liste'" class="icon-btn" type="button" :aria-pressed="sucheOffen" aria-label="Suchen" @click="sucheOffen = !sucheOffen"><Icon name="search" /></button>
    </div>
  </header>
  <main class="page">
    <div class="tabs" role="tablist" aria-label="Ansicht">
      <button role="tab" type="button" :aria-selected="ansicht === 'liste'" @click="ansicht = 'liste'">Liste</button>
      <button role="tab" type="button" :aria-selected="ansicht === 'ranking'" @click="ansicht = 'ranking'">Ranking</button>
      <button role="tab" type="button" :aria-selected="ansicht === 'vergleich'" @click="ansicht = 'vergleich'">Vergleich</button>
    </div>

    <!-- Liste -->
    <template v-if="ansicht === 'liste'">
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
          {{ filter === 'parkplatz' ? 'Der Parkplatz ist leer.' : state.ideas.length ? 'Keine Idee passt zu diesem Filter.' : 'Noch keine Ideen. Tippe auf das Plus, um die erste zu notieren.' }}
        </p>
      </div>
    </template>

    <!-- Ranking -->
    <template v-else-if="ansicht === 'ranking'">
      <router-link to="/gewichtung" class="card status" :class="{ done: gewichtungStatus.done }">
        <span class="grow">
          <strong>Gewichtung</strong>
          <span class="small muted block">{{ gewichtungStatus.text }}</span>
        </span>
        <Icon name="send" :size="18" />
      </router-link>
      <p class="small muted">
        Sortiert nach Gesamtpunktzahl (0–100). Ziel der Phase 1: 2–3 Favoriten – mit dem Stern markieren
        <template v-if="favoriten"> (aktuell {{ favoriten }})</template>.
      </p>

      <ol class="rank">
        <li v-for="(r, n) in ranking.bewertet" :key="r.idea.id" class="card rank-row">
          <span class="pos">{{ n + 1 }}</span>
          <router-link :to="`/idee/${r.idea.id}/bewertung`" class="grow rank-main">
            <span class="rank-title">{{ r.idea.title || 'Ohne Titel' }}</span>
            <span class="bar" aria-hidden="true"><span :style="{ width: `${r.result.score}%` }"></span></span>
            <span class="small muted">{{ RESULT_LABEL[r.result.kind] }}</span>
          </router-link>
          <strong class="score">{{ r.result.score }}</strong>
          <button class="icon-btn star" type="button" :aria-pressed="r.idea.is_favorite" :aria-label="r.idea.is_favorite ? 'Favorit entfernen' : 'Als Favorit markieren'" @click="stern(r.idea)">
            {{ r.idea.is_favorite ? '★' : '☆' }}
          </button>
        </li>
      </ol>
      <p v-if="!ranking.bewertet.length" class="empty">Noch keine bewerteten Ideen. Öffne eine Idee und tippe auf „Bewerten“.</p>

      <section v-if="ranking.ko.length" class="stack">
        <h2>Ausgeschlossen (KO)</h2>
        <router-link v-for="r in ranking.ko" :key="r.idea.id" :to="`/idee/${r.idea.id}/bewertung`" class="card ko-row">
          <span class="grow">{{ r.idea.title || 'Ohne Titel' }}</span>
          <span class="chip outline">{{ r.result.kind === 'final' ? 'KO' : 'KO-Hinweis' }}</span>
        </router-link>
      </section>

      <section v-if="ranking.offen.length" class="stack">
        <h2>Noch nicht bewertet</h2>
        <router-link v-for="r in ranking.offen" :key="r.idea.id" :to="`/idee/${r.idea.id}/bewertung`" class="card ko-row">
          <span class="grow">{{ r.idea.title || 'Ohne Titel' }}</span>
          <span class="small muted">{{ r.result.submitted?.length ? 'wartet auf Abgabe' : 'Bewerten' }}</span>
        </router-link>
      </section>
    </template>

    <!-- Vergleich -->
    <template v-else-if="ansicht === 'vergleich'">
      <p class="small muted">Bis zu drei bewertete Ideen auswählen. Gezeigt wird die Endbewertung, sonst der Mittelwert eurer Einzelbewertungen.</p>
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
                <td v-for="s in serien" :key="s.id">{{ s.values[a.id] ?? '–' }}</td>
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
.ki-btn { min-height: 36px; padding: 0 12px; font-size: 14px; border-color: var(--accent); color: var(--accent); }
.block { display: block; }
p { margin: 0; }
.tabs { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 4px; padding: 4px; border-radius: 12px; background: var(--chip); max-width: 480px; }
.tabs button { height: 38px; border: 0; border-radius: 9px; background: transparent; color: var(--muted); font-weight: 500; cursor: pointer; }
.tabs button[aria-selected="true"] { background: var(--surface); color: var(--text); box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12); }
.segmented.wrap { flex-wrap: wrap; }
.parked { display: flex; flex-direction: column; gap: 6px; align-items: flex-start; }
.parked-title { font-weight: 600; color: var(--text); text-decoration: none; }
.status { display: flex; align-items: center; gap: 12px; text-decoration: none; color: inherit; border-color: var(--warn); }
.status.done { border-color: var(--line); }
.rank { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
.rank-row { display: flex; align-items: center; gap: 12px; padding: 10px 6px 10px 14px; }
.pos { width: 24px; text-align: center; font-weight: 600; color: var(--muted); }
.rank-main { display: flex; flex-direction: column; gap: 4px; text-decoration: none; color: inherit; }
.rank-title { font-weight: 600; }
.bar { display: block; height: 6px; border-radius: 3px; background: var(--chip); overflow: hidden; }
.bar span { display: block; height: 100%; background: var(--accent); border-radius: 3px; }
.score { font-size: 20px; min-width: 34px; text-align: right; }
.star { font-size: 22px; color: var(--warn); }
.ko-row { display: flex; align-items: center; gap: 10px; text-decoration: none; color: inherit; }
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
