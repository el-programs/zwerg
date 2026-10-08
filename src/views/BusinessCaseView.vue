<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { profile, saveBusinessCase, state } from '../lib/store.js';
import { relativ } from '../lib/format.js';
import { eur, FELDER, prozent, rechne, SZENARIEN } from '../lib/business.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const bc = computed(() => state.businessCases.find((b) => b.idea_id === id.value) ?? null);
const aktiv = ref('realistisch');

// Lokale Entwürfe, damit das Tippen nicht von eingehenden Aktualisierungen unterbrochen wird.
const entwurf = reactive({ vorsichtig: {}, realistisch: {}, optimistisch: {} });
const notizen = ref('');
const einheit = ref('Stück');
let editing = false;
watch(
  bc,
  (b) => {
    if (editing) return;
    for (const s of SZENARIEN) entwurf[s.id] = { ...(b?.scenarios?.[s.id] ?? {}) };
    notizen.value = b?.notes ?? '';
    einheit.value = b?.unit ?? 'Stück';
  },
  { immediate: true },
);

let timer = null;
function geaendert() {
  editing = true;
  clearTimeout(timer);
  timer = setTimeout(() => {
    saveBusinessCase(id.value, { scenarios: JSON.parse(JSON.stringify(entwurf)), notes: notizen.value, unit: einheit.value || 'Stück' });
    editing = false;
  }, 600);
}
function vorlageUebernehmen() {
  // Leere Szenarien aus „realistisch“ ableiten: vorsichtig 70 % Absatz, optimistisch 130 %.
  const r = entwurf.realistisch;
  for (const [sid, f] of [['vorsichtig', 0.7], ['optimistisch', 1.3]]) {
    if (Object.values(entwurf[sid]).some((v) => v !== '' && v !== null && v !== undefined)) continue;
    entwurf[sid] = { ...r, absatz: r.absatz ? String(Math.round(Number(String(r.absatz).replace(',', '.')) * f)) : '' };
  }
  geaendert();
}

const ergebnisse = computed(() => Object.fromEntries(SZENARIEN.map((s) => [s.id, rechne(entwurf[s.id])])));
const ZEILEN = [
  { id: 'umsatzMonat', name: 'Umsatz pro Monat', f: (v) => eur(v) },
  { id: 'umsatzJahr', name: 'Umsatz pro Jahr', f: (v) => eur(v) },
  { id: 'dbEinheit', name: 'Deckungsbeitrag je Einheit', f: (v) => eur(v, 2) },
  { id: 'marge', name: 'Marge (DB / Preis)', f: prozent },
  { id: 'gewinnMonat', name: 'Ergebnis pro Monat', f: (v) => eur(v), farbe: true },
  { id: 'gewinnJahr', name: 'Ergebnis pro Jahr', f: (v) => eur(v), farbe: true },
  { id: 'breakEven', name: 'Break-even (Einheiten pro Monat)', f: (v) => (v === null ? 'nicht erreichbar' : v.toLocaleString('de-DE')) },
  { id: 'amortisation', name: 'Investition zurück nach', f: (v) => (v === null ? 'nicht absehbar' : `${v} Monat${v === 1 ? '' : 'en'}`) },
];
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <button class="icon-btn" type="button" aria-label="Zurück" @click="router.push(`/idee/${id}`)"><Icon name="back" /></button>
      <h1 class="grow">Business Case</h1>
    </div>
  </header>
  <main v-if="!idea" class="page"><p class="empty">Diese Notiz gibt es nicht (mehr).</p></main>
  <main v-else class="page wide">
    <div class="stack tight">
      <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>
      <p class="small muted">
        Alle Beträge netto. Drei Szenarien für Investition, Kosten, Preis und Absatz – Zwerg rechnet Umsatz, Marge und Break-even.
        <template v-if="bc?.updated_at"> Zuletzt geändert {{ relativ(bc.updated_at) }} von {{ profile(bc.updated_by)?.name }}.</template>
      </p>
    </div>

    <div class="segmented mobile-only" role="group" aria-label="Szenario">
      <button v-for="s in SZENARIEN" :key="s.id" type="button" :aria-pressed="aktiv === s.id" @click="aktiv = s.id">{{ s.name }}</button>
    </div>

    <section class="grid">
      <div v-for="s in SZENARIEN" :key="s.id" class="card col" :class="{ hidden: aktiv !== s.id, main: s.id === 'realistisch' }">
        <h3>{{ s.name }}</h3>
        <label v-for="f in FELDER" :key="f.id" class="field">
          <span>{{ f.name }}<template v-if="f.id === 'absatz'"> ({{ einheit }})</template></span>
          <span class="inp">
            <input v-model="entwurf[s.id][f.id]" class="input" inputmode="decimal" placeholder="0" @input="geaendert">
            <span class="unit">{{ f.id === 'absatz' ? '' : f.einheit }}</span>
          </span>
        </label>
      </div>
    </section>
    <button class="btn" type="button" @click="vorlageUebernehmen">Leere Szenarien aus „Realistisch“ ableiten (Absatz −30 % / +30 %)</button>

    <section class="table-wrap">
      <table class="res">
        <thead>
          <tr><th scope="col">Ergebnis</th><th v-for="s in SZENARIEN" :key="s.id" scope="col">{{ s.name }}</th></tr>
        </thead>
        <tbody>
          <tr v-for="z in ZEILEN" :key="z.id">
            <th scope="row">{{ z.name }}</th>
            <td
              v-for="s in SZENARIEN"
              :key="s.id"
              :class="z.farbe && ergebnisse[s.id] ? (ergebnisse[s.id][z.id] >= 0 ? 'pos' : 'neg') : ''"
            >
              {{ ergebnisse[s.id] ? z.f(ergebnisse[s.id][z.id]) : '–' }}
            </td>
          </tr>
        </tbody>
      </table>
    </section>
    <p class="small muted">Ein „–“ heißt: Preis oder Absatz fehlen noch. Ergebnis = Deckungsbeitrag × Absatz − Fixkosten (vor Steuern).</p>

    <div class="two">
      <label class="field">
        <span>Bezeichnung der Einheit</span>
        <input v-model="einheit" class="input" placeholder="z. B. Stück, Stunde, Abo" @input="geaendert">
      </label>
    </div>
    <label class="field">
      <span>Annahmen und Quellen</span>
      <textarea v-model="notizen" class="textarea" rows="5" placeholder="Woher stammen die Zahlen? Was ist geschätzt, was belegt?" @input="geaendert"></textarea>
    </label>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; }
.tight { gap: 6px; }
.idea-title { font-size: 20px; }
.grid { display: grid; gap: 12px; grid-template-columns: repeat(3, minmax(0, 1fr)); }
.col { display: flex; flex-direction: column; gap: 10px; }
.col.main { border-color: var(--accent); }
.col h3 { font-size: 16px; margin: 0; }
.inp { display: flex; align-items: center; gap: 6px; }
.inp .input { text-align: right; font-variant-numeric: tabular-nums; }
.unit { width: 14px; color: var(--muted); }
.table-wrap { overflow-x: auto; border: 1px solid var(--line); border-radius: var(--radius); background: var(--surface); }
.res { width: 100%; border-collapse: collapse; font-size: 14px; }
.res th, .res td { padding: 9px 12px; border-bottom: 1px solid var(--line); text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; }
.res th[scope="row"], .res thead th:first-child { text-align: left; font-weight: 400; white-space: normal; }
.res thead th { font-size: 13px; color: var(--muted); font-weight: 500; }
.res tr:last-child th, .res tr:last-child td { border-bottom: 0; }
.pos { color: var(--ok); font-weight: 600; }
.neg { color: var(--danger); font-weight: 600; }
.two { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; }
@media (max-width: 899px) {
  .grid { grid-template-columns: 1fr; }
  .col.hidden { display: none; }
}
</style>
