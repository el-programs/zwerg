<script setup>
// Auswertung aller weiterverfolgten Ideen: Punkte je Faktor als Farbfelder, Gesamtpunktzahl, KO-Hinweise und Synergien.
// Sortieren nach Punkten, Titel oder einzelnen Faktoren; Filter; Auswahl für Phase 2.
import { computed, onBeforeUnmount, ref } from 'vue';
import { modelName, setFavorite, setIdeaPhase, state, synergiesOf, toast } from '../lib/store.js';
import { activeCriteria, effectiveWeight, ideaResult, jointScores, RESULT_LABEL } from '../lib/score.js';
import SynergyButton from './SynergyButton.vue';

const props = defineProps({ ideas: { type: Array, required: true } });

const breit = ref(window.matchMedia('(min-width: 900px)').matches);
const mq = window.matchMedia('(min-width: 900px)');
const onMq = (e) => { breit.value = e.matches; };
mq.addEventListener('change', onMq);
onBeforeUnmount(() => mq.removeEventListener('change', onMq));

const crit = computed(() => activeCriteria());
function kurz(name) {
  const teil = name.split('/')[0].trim();
  return teil.length > 16 ? teil.split(' ')[0] : teil;
}
const koName = (id) => state.koCriteria.find((k) => k.id === id)?.name ?? '';

const rows = computed(() =>
  props.ideas.map((idea) => {
    const result = ideaResult(idea.id);
    const joint = jointScores(idea.id);
    const punkte = {};
    for (const c of crit.value) punkte[c.id] = joint[c.id]?.score ? joint[c.id].score - 1 : null;
    return { idea, result, punkte, synergien: synergiesOf(idea.id).length };
  }),
);

const FILTER = [
  { id: 'alle', label: 'Alle' },
  { id: 'ohneKo', label: 'Ohne KO' },
  { id: 'pruefen', label: 'Später prüfen' },
  { id: 'synergien', label: 'Mit Synergien' },
  { id: 'favoriten', label: 'Favoriten' },
  { id: 'phase2', label: 'Ab Phase 2' },
];
const filter = ref('alle');
const minPunkte = ref(0);
const sortierung = ref('punkte');

const gefiltert = computed(() =>
  rows.value.filter((r) => {
    if (minPunkte.value && (r.result.score ?? -1) < minPunkte.value) return false;
    switch (filter.value) {
      case 'ohneKo': return !r.result.ko;
      case 'pruefen': return r.result.checkIds.length > 0;
      case 'synergien': return r.synergien > 0;
      case 'favoriten': return r.idea.is_favorite;
      case 'phase2': return r.idea.phase >= 2;
      default: return true;
    }
  }),
);

// Reihenfolge: bewertete ohne KO, dann KO, dann unbewertete. Innerhalb nach der gewählten Spalte.
const sortiert = computed(() => {
  const gruppe = (r) => (r.result.score === null ? 2 : r.result.ko ? 1 : 0);
  const wert = (r) => {
    if (sortierung.value === 'punkte') return r.result.score ?? -1;
    if (sortierung.value === 'synergien') return r.synergien;
    return r.punkte[sortierung.value] ?? -1;
  };
  return [...gefiltert.value].sort((a, b) => {
    if (sortierung.value === 'titel') return (a.idea.title || '').localeCompare(b.idea.title || '', 'de');
    return gruppe(a) - gruppe(b) || wert(b) - wert(a) || (b.result.score ?? -1) - (a.result.score ?? -1);
  });
});
const rang = computed(() => {
  const map = {};
  let n = 0;
  for (const r of sortiert.value) if (r.result.score !== null && !r.result.ko) map[r.idea.id] = ++n;
  return map;
});
function sortiere(key) {
  sortierung.value = key;
}

function inPhase2(r) {
  if (!confirm(`„${r.idea.title || 'Ohne Titel'}“ in Phase 2 (Machbarkeitsprüfung) übernehmen?`)) return;
  setIdeaPhase(r.idea.id, 2);
  toast('Idee ist in Phase 2');
}
const hinweis = (r) => r.result.checkIds.map(koName).filter(Boolean).join('\n');
</script>

<template>
  <div class="stack aw">
    <div class="segmented wrap" role="group" aria-label="Filter">
      <button v-for="f in FILTER" :key="f.id" type="button" :aria-pressed="filter === f.id" @click="filter = f.id">{{ f.label }}</button>
    </div>
    <div class="row wrap controls">
      <label class="field inline">
        <span>Sortieren nach</span>
        <select v-model="sortierung" class="select">
          <option value="punkte">Gesamtpunkte</option>
          <option value="titel">Titel</option>
          <option value="synergien">Anzahl Synergien</option>
          <optgroup label="Faktor">
            <option v-for="c in crit" :key="c.id" :value="c.id">{{ c.name }}</option>
          </optgroup>
        </select>
      </label>
      <label class="field inline">
        <span>Mindestens</span>
        <select v-model.number="minPunkte" class="select">
          <option :value="0">alle Punkte</option>
          <option v-for="p in [40, 50, 60, 70, 80]" :key="p" :value="p">{{ p }} Punkte</option>
        </select>
      </label>
    </div>
    <div class="legend small muted" aria-hidden="true">
      <span>Punkte je Faktor:</span>
      <span v-for="p in 5" :key="p" class="leg"><span :class="['cell', `h${p - 1}`]">{{ p - 1 }}</span></span>
      <span class="leg"><span class="cell leer">–</span> offen</span>
    </div>

    <p v-if="!sortiert.length" class="empty">Keine Idee passt zu diesem Filter.</p>

    <!-- Großer Bildschirm: Tabelle -->
    <div v-else-if="breit" class="table-wrap">
      <table class="tbl">
        <thead>
          <tr>
            <th class="c-rang">#</th>
            <th class="c-idee"><button type="button" class="th-btn" :aria-pressed="sortierung === 'titel'" @click="sortiere('titel')">Idee</button></th>
            <th class="c-pkt"><button type="button" class="th-btn" :aria-pressed="sortierung === 'punkte'" @click="sortiere('punkte')">Punkte</button></th>
            <th v-for="c in crit" :key="c.id" class="c-fak" :title="`${c.name} · Gewicht ${Math.round(effectiveWeight(c) * 10) / 10}`">
              <button type="button" class="th-btn vert" :aria-pressed="sortierung === c.id" @click="sortiere(c.id)">{{ kurz(c.name) }}</button>
            </th>
            <th class="c-hin">Hinweise</th>
            <th class="c-akt"><span class="visually-hidden">Aktionen</span></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in sortiert" :key="r.idea.id" :class="{ ko: r.result.ko, offen: r.result.score === null }">
            <td class="c-rang">{{ rang[r.idea.id] ?? '' }}</td>
            <td class="c-idee">
              <router-link :to="`/idee/${r.idea.id}`" class="t-title">{{ r.idea.title || 'Ohne Titel' }}</router-link>
              <span class="t-model">{{ modelName(r.idea.business_model_id) }}</span>
            </td>
            <td class="c-pkt">
              <router-link :to="`/idee/${r.idea.id}/bewertung`" class="pkt" :title="RESULT_LABEL[r.result.kind]">
                <strong>{{ r.result.score ?? '–' }}</strong>
                <span class="bar" aria-hidden="true"><span :style="{ width: `${r.result.score ?? 0}%` }"></span></span>
              </router-link>
            </td>
            <td v-for="c in crit" :key="c.id" class="c-fak">
              <span :class="['cell', r.punkte[c.id] === null ? 'leer' : `h${r.punkte[c.id]}`]" :title="`${c.name}: ${r.punkte[c.id] ?? 'offen'}`">{{ r.punkte[c.id] ?? '' }}</span>
            </td>
            <td class="c-hin">
              <span v-if="r.result.ko" class="chip ko-chip">KO</span>
              <span v-if="r.result.checkIds.length" class="chip pruef-chip" :title="hinweis(r)">{{ r.result.checkIds.length }} prüfen</span>
              <span v-if="r.result.score !== null && r.result.kind !== 'final'" class="chip outline">vorläufig</span>
              <span v-if="r.result.score === null" class="small muted">{{ r.result.rated ? `${r.result.rated}/${r.result.of}` : 'nicht bewertet' }}</span>
            </td>
            <td class="c-akt">
              <span class="akt">
                <SynergyButton :idea-id="r.idea.id" :size="18" />
                <span v-if="r.idea.phase >= 2" class="chip outline">Phase {{ r.idea.phase }}</span>
                <button v-else-if="!r.result.ko && r.result.score !== null" class="btn small-btn" type="button" @click="inPhase2(r)">→ Phase 2</button>
                <button class="icon-btn star" type="button" :aria-pressed="r.idea.is_favorite" :aria-label="r.idea.is_favorite ? 'Favorit entfernen' : 'Als Favorit markieren'" @click="setFavorite(r.idea.id, !r.idea.is_favorite)">{{ r.idea.is_favorite ? '★' : '☆' }}</button>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- iPhone: kompakte Zeilen mit Farbstreifen -->
    <ol v-else class="mlist">
      <li v-for="r in sortiert" :key="r.idea.id" :class="['card', 'mrow', { ko: r.result.ko, offen: r.result.score === null }]">
        <div class="mtop">
          <span class="mrang">{{ rang[r.idea.id] ?? '' }}</span>
          <router-link :to="`/idee/${r.idea.id}`" class="t-title grow">{{ r.idea.title || 'Ohne Titel' }}</router-link>
          <router-link :to="`/idee/${r.idea.id}/bewertung`" class="mscore">{{ r.result.score ?? '–' }}</router-link>
        </div>
        <div class="strip" aria-hidden="true">
          <span v-for="c in crit" :key="c.id" :class="['scell', r.punkte[c.id] === null ? 'leer' : `h${r.punkte[c.id]}`, { aktiv: sortierung === c.id }]"></span>
        </div>
        <div class="mbottom">
          <span v-if="r.result.ko" class="chip ko-chip">KO</span>
          <span v-if="r.result.checkIds.length" class="chip pruef-chip" :title="hinweis(r)">{{ r.result.checkIds.length }} prüfen</span>
          <span v-if="r.result.score === null" class="small muted">{{ r.result.rated ? `in Arbeit ${r.result.rated}/${r.result.of}` : 'nicht bewertet' }}</span>
          <span v-else-if="sortierung !== 'punkte' && sortierung !== 'titel' && sortierung !== 'synergien'" class="small muted">{{ kurz(crit.find((c) => c.id === sortierung)?.name ?? '') }}: {{ r.punkte[sortierung] ?? '–' }}</span>
          <span class="grow"></span>
          <span v-if="r.idea.phase >= 2" class="chip outline">Phase {{ r.idea.phase }}</span>
          <button v-else-if="!r.result.ko && r.result.score !== null" class="btn small-btn" type="button" @click="inPhase2(r)">→ Phase 2</button>
          <SynergyButton :idea-id="r.idea.id" :size="18" />
          <button class="icon-btn star" type="button" :aria-pressed="r.idea.is_favorite" :aria-label="r.idea.is_favorite ? 'Favorit entfernen' : 'Als Favorit markieren'" @click="setFavorite(r.idea.id, !r.idea.is_favorite)">{{ r.idea.is_favorite ? '★' : '☆' }}</button>
        </div>
      </li>
    </ol>
  </div>
</template>

<style scoped>
.grow { flex: 1; min-width: 0; }
.aw { gap: 12px; }
.segmented.wrap { flex-wrap: wrap; }
.controls { gap: 12px; align-items: flex-end; }
.inline { min-width: 140px; flex: 1; max-width: 300px; }
.legend { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.leg { display: inline-flex; align-items: center; gap: 4px; }
.cell { display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; border-radius: 5px; font-size: 12px; font-weight: 600; color: var(--heat-text); font-variant-numeric: tabular-nums; }
.h0 { background: var(--h0); } .h1 { background: var(--h1); } .h2 { background: var(--h2); } .h3 { background: var(--h3); } .h4 { background: var(--h4); }
.leer { background: var(--chip); color: var(--muted); }
.chip.ko-chip { background: var(--danger); color: var(--on-accent); font-weight: 600; }
.chip.pruef-chip { background: transparent; border: 1px solid var(--warn); color: var(--warn); }
.star { font-size: 20px; color: var(--warn); width: 36px; height: 36px; }
.small-btn { min-height: 32px; padding: 0 10px; font-size: 13px; white-space: nowrap; }
.t-title { font-weight: 600; color: inherit; text-decoration: none; }
.bar { display: block; height: 5px; border-radius: 3px; background: var(--chip); overflow: hidden; }
.bar span { display: block; height: 100%; background: var(--accent); border-radius: 3px; }

/* Tabelle */
.table-wrap { overflow-x: auto; border: 1px solid var(--line); border-radius: var(--radius); background: var(--surface); }
.tbl { width: 100%; border-collapse: collapse; font-size: 14px; }
.tbl th, .tbl td { padding: 6px 4px; border-bottom: 1px solid var(--line); vertical-align: middle; }
.tbl tbody tr:last-child td { border-bottom: 0; }
.tbl thead th { font-size: 12px; color: var(--muted); font-weight: 500; text-align: left; vertical-align: bottom; }
.th-btn { border: 0; background: none; color: inherit; font: inherit; padding: 2px; cursor: pointer; text-align: left; }
.th-btn[aria-pressed="true"] { color: var(--accent); font-weight: 700; }
.th-btn.vert { writing-mode: vertical-rl; transform: rotate(180deg); white-space: nowrap; max-height: 120px; }
.c-rang { width: 28px; text-align: center; color: var(--muted); font-weight: 600; padding-left: 10px !important; }
.c-idee { min-width: 180px; max-width: 260px; }
.c-idee .t-title { display: block; line-height: 1.3; }
.t-model { display: block; font-size: 11.5px; color: var(--muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 240px; }
.c-pkt { width: 72px; }
.pkt { display: flex; flex-direction: column; gap: 3px; color: inherit; text-decoration: none; }
.pkt strong { font-size: 16px; }
.c-fak { width: 28px; text-align: center; padding: 6px 1px !important; }
.c-hin { white-space: nowrap; }
.c-hin .chip { margin-right: 4px; }
.akt { display: flex; align-items: center; justify-content: flex-end; gap: 2px; }
tr.ko td:not(.c-hin):not(.c-akt) { opacity: 0.5; }
tr.ko .pkt strong { text-decoration: line-through; }

/* iPhone */
.mlist { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
.mrow { display: flex; flex-direction: column; gap: 8px; padding: 12px 8px 6px 12px; }
.mtop { display: flex; align-items: baseline; gap: 8px; padding-right: 6px; }
.mrang { width: 18px; color: var(--muted); font-weight: 600; flex: none; }
.mscore { font-size: 20px; font-weight: 700; color: inherit; text-decoration: none; }
.strip { display: grid; grid-auto-flow: column; grid-auto-columns: 1fr; gap: 2px; margin-right: 6px; }
.scell { height: 12px; border-radius: 2px; }
.scell.aktiv { outline: 2px solid var(--text); outline-offset: 1px; }
.mbottom { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; min-height: 36px; }
.mrow.ko .mtop, .mrow.ko .strip { opacity: 0.5; }
.mrow.ko .mscore { text-decoration: line-through; }
</style>
