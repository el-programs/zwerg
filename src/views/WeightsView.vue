<script setup>
// Gewichtung: 1. jeder für sich (für den anderen verborgen), 2. Vergleich, 3. gemeinsame Gewichtung.
import { computed, watch } from 'vue';
import { partner, refresh, setJointWeight, setWeight, state, submitWeights, toast } from '../lib/store.js';
import { ABWEICHUNG, activeCriteria, hasSubmittedWeights, jointWeightsSet, personalWeight } from '../lib/score.js';
import ScoreButtons from '../components/ScoreButtons.vue';
import Icon from '../components/Icon.vue';

const me = computed(() => state.me);
const anderer = computed(() => partner());
const criteria = computed(() => activeCriteria());
const ichFertig = computed(() => me.value && hasSubmittedWeights(me.value.id));
const andererFertig = computed(() => anderer.value && hasSubmittedWeights(anderer.value.id));
const offen = computed(() => criteria.value.filter((c) => personalWeight(me.value.id, c.id) === null).length);
const schritt = computed(() => (!ichFertig.value ? 1 : !andererFertig.value ? 2 : 3));

const partnerGeladen = computed(() => criteria.value.some((c) => personalWeight(anderer.value.id, c.id) !== null));
watch(
  () => schritt.value === 3 && !partnerGeladen.value,
  (fehlt) => {
    if (fehlt) refresh();
  },
  { immediate: true },
);

function mittel(c) {
  const a = personalWeight(me.value.id, c.id);
  const b = personalWeight(anderer.value.id, c.id);
  if (a === null || b === null) return a ?? b;
  return Math.round((a + b) / 2);
}
function abweichung(c) {
  const a = personalWeight(me.value.id, c.id);
  const b = personalWeight(anderer.value.id, c.id);
  return a !== null && b !== null && Math.abs(a - b) >= ABWEICHUNG;
}
const grosseAbweichungen = computed(() => criteria.value.filter(abweichung).length);

function abgeben() {
  if (offen.value) return;
  if (!confirm('Gewichtung abgeben? Danach siehst du die Gewichtung deines Partners.')) return;
  submitWeights();
  toast('Gewichtung abgegeben');
}
function mittelwerteUebernehmen() {
  for (const c of criteria.value) if (c.joint_weight === null) setJointWeight(c.id, mittel(c));
  toast('Vorschläge übernommen');
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link to="/ideen?ansicht=ranking" class="icon-btn" aria-label="Zurück"><Icon name="back" /></router-link>
      <h1 class="grow">Gewichtung</h1>
    </div>
  </header>

  <main v-if="me && anderer" class="page">
    <ol class="steps">
      <li :class="{ on: schritt === 1, done: schritt > 1 }">1 · Jeder für sich</li>
      <li :class="{ on: schritt === 2, done: schritt > 2 }">2 · Vergleich</li>
      <li :class="{ on: schritt === 3 }">3 · Gemeinsam</li>
    </ol>

    <p class="muted intro">
      Wie wichtig ist euch jeder Faktor? <strong>0</strong> = spielt keine Rolle, <strong>5</strong> = sehr wichtig.
      Die Gewichtung gilt für alle Notizen.
    </p>

    <template v-if="schritt === 1">
      <p class="small muted">
        {{ anderer.name }}: {{ andererFertig ? 'hat schon abgegeben' : 'noch offen' }}. Seine Werte siehst du erst nach deiner Abgabe.
      </p>
      <div class="stack">
        <div v-for="c in criteria" :key="c.id" class="card crit">
          <div>
            <strong>{{ c.name }}</strong>
            <p v-if="c.description" class="small muted">{{ c.description }}</p>
          </div>
          <ScoreButtons
            :model-value="personalWeight(me.id, c.id)"
            :min="0"
            :label="`Gewicht für ${c.name}`"
            @update:model-value="setWeight(c.id, $event)"
          />
        </div>
      </div>
      <button class="btn primary block" type="button" :disabled="offen > 0" @click="abgeben">
        {{ offen ? `Noch ${offen} Faktor${offen > 1 ? 'en' : ''} offen` : 'Gewichtung abgeben' }}
      </button>
    </template>

    <template v-else-if="schritt === 2">
      <section class="card stack">
        <h2>Abgegeben – warte auf {{ anderer.name }}</h2>
        <p class="small muted">Sobald {{ anderer.name }} abgegeben hat, seht ihr hier beide Gewichtungen nebeneinander.</p>
      </section>
      <div class="table">
        <div v-for="c in criteria" :key="c.id" class="trow">
          <span class="grow">{{ c.name }}</span>
          <span class="val">{{ personalWeight(me.id, c.id) }}</span>
        </div>
      </div>
    </template>

    <template v-else-if="!partnerGeladen">
      <section class="card"><h2>Gewichtung von {{ anderer.name }} wird geladen …</h2></section>
    </template>

    <template v-else>
      <p class="small" :class="grosseAbweichungen ? 'warn' : 'muted'">
        {{ grosseAbweichungen ? `${grosseAbweichungen} Faktor(en) mit großer Abweichung – hier lohnt sich das Gespräch.` : 'Ihr liegt überall nah beieinander.' }}
      </p>
      <div class="stack">
        <div v-for="c in criteria" :key="c.id" class="card crit" :class="{ diff: abweichung(c) }">
          <div class="row top">
            <strong class="grow">{{ c.name }}</strong>
            <span v-if="abweichung(c)" class="chip warn-chip">große Abweichung</span>
          </div>
          <div class="row small">
            <span>{{ me.kuerzel }}: <strong>{{ personalWeight(me.id, c.id) }}</strong></span>
            <span>{{ anderer.kuerzel }}: <strong>{{ personalWeight(anderer.id, c.id) }}</strong></span>
            <span class="muted">Gemeinsam:</span>
          </div>
          <ScoreButtons
            :model-value="c.joint_weight"
            :min="0"
            :suggestion="mittel(c)"
            :label="`Gemeinsames Gewicht für ${c.name}`"
            @update:model-value="setJointWeight(c.id, $event)"
          />
        </div>
      </div>
      <div class="row wrap">
        <button v-if="!jointWeightsSet()" class="btn" type="button" @click="mittelwerteUebernehmen">Restliche Vorschläge (Mittelwert) übernehmen</button>
        <p v-else class="small ok"><Icon name="check" :size="16" /> Gemeinsame Gewichtung steht. Sie gilt ab sofort für das Ranking.</p>
      </div>
    </template>
  </main>
</template>

<style scoped>
.grow { flex: 1; min-width: 0; }
p { margin: 0; }
.intro { font-size: 15px; }
.steps { list-style: none; margin: 0; padding: 0; display: flex; gap: 6px; flex-wrap: wrap; font-size: 13px; }
.steps li { padding: 4px 10px; border-radius: 999px; background: var(--chip); color: var(--muted); }
.steps li.on { background: var(--accent); color: var(--on-accent); font-weight: 600; }
.steps li.done { color: var(--text); }
.crit { display: flex; flex-direction: column; gap: 10px; }
.crit.diff { border-color: var(--warn); }
.top { align-items: flex-start; }
.wrap { flex-wrap: wrap; }
.warn { color: var(--warn); font-weight: 500; }
.warn-chip { background: transparent; border: 1px solid var(--warn); color: var(--warn); }
.ok { color: var(--ok); display: flex; align-items: center; gap: 6px; }
.table { display: flex; flex-direction: column; border: 1px solid var(--line); border-radius: var(--radius); background: var(--surface); }
.trow { display: flex; padding: 10px 14px; border-bottom: 1px solid var(--line); }
.trow:last-child { border-bottom: 0; }
.val { font-weight: 600; }
</style>
