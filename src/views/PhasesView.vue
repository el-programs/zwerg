<script setup>
// Plan: Phasen mit Zielen und Abschlusskriterien, Aufgaben und Entscheidungsprotokoll.
import { computed, reactive, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { currentPhase, profile, setCurrentPhase, state, toast, toggleCriterion, updatePhase } from '../lib/store.js';
import TaskList from '../components/TaskList.vue';
import DecisionList from '../components/DecisionList.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const TABS = [
  { id: 'phasen', label: 'Phasen' },
  { id: 'aufgaben', label: 'Aufgaben' },
  { id: 'entscheidungen', label: 'Entscheidungen' },
];
const tab = ref(TABS.some((t) => t.id === route.query.tab) ? route.query.tab : 'phasen');
watch(tab, (t) => router.replace({ query: t === 'phasen' ? {} : { tab: t } }));
watch(() => route.query.tab, (t) => { if (t && t !== tab.value) tab.value = t; });

const aktuell = computed(() => currentPhase());
const offen = ref(aktuell.value);
const bearbeiten = ref(null);
const entwurf = reactive({ name: '', goal: '', result: '', hints: '' });
const neuesKriterium = ref('');

function fortschritt(p) {
  const n = p.criteria?.length ?? 0;
  return { done: (p.criteria ?? []).filter((c) => c.done).length, n };
}
function ideenIn(nr) {
  return state.ideas.filter((i) => i.phase === nr && i.status !== 'geparkt');
}
function aufgabenIn(nr) {
  return state.tasks.filter((t) => t.phase === nr && t.status !== 'erledigt').length;
}
function startBearbeiten(p) {
  Object.assign(entwurf, { name: p.name, goal: p.goal, result: p.result, hints: p.hints });
  bearbeiten.value = p.nr;
}
function speichern(p) {
  updatePhase(p.nr, { name: entwurf.name.trim() || p.name, goal: entwurf.goal, result: entwurf.result, hints: entwurf.hints });
  bearbeiten.value = null;
  toast('Phase gespeichert');
}
function kriteriumHinzu(p) {
  const text = neuesKriterium.value.trim();
  if (!text) return;
  updatePhase(p.nr, { criteria: [...(p.criteria ?? []), { id: crypto.randomUUID().slice(0, 8), text, done: false }] });
  neuesKriterium.value = '';
}
function kriteriumWeg(p, c) {
  if (!confirm(`Kriterium „${c.text}“ entfernen?`)) return;
  updatePhase(p.nr, { criteria: p.criteria.filter((x) => x.id !== c.id) });
}
function kriteriumText(p, c, text) {
  if (!text.trim()) return;
  updatePhase(p.nr, { criteria: p.criteria.map((x) => (x.id === c.id ? { ...x, text: text.trim() } : x)) });
}
function wechseln(p) {
  const { done, n } = fortschritt(state.phases.find((x) => x.nr === aktuell.value) ?? { criteria: [] });
  const hinweis = p.nr > aktuell.value && done < n ? `\n\nHinweis: In Phase ${aktuell.value} sind erst ${done} von ${n} Abschlusskriterien erfüllt.` : '';
  const grund = prompt(`In Phase ${p.nr} (${p.name}) wechseln? Kurze Begründung fürs Protokoll:${hinweis}`);
  if (grund === null) return;
  setCurrentPhase(p.nr, grund);
  offen.value = p.nr;
  toast(`Aktuelle Phase: ${p.name}`);
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner"><h1>Plan</h1></div>
  </header>
  <main class="page">
    <div class="tabs" role="tablist" aria-label="Bereich">
      <button v-for="t in TABS" :key="t.id" role="tab" type="button" :aria-selected="tab === t.id" @click="tab = t.id">{{ t.label }}</button>
    </div>

    <template v-if="tab === 'phasen'">
      <p class="small muted">Die App führt durch die Phasen, erzwingt aber nichts. Ziele, Ergebnisse, Hinweise und Abschlusskriterien sind bearbeitbar.</p>
      <ol class="phasen">
        <li v-for="p in state.phases" :key="p.nr" class="card phase" :class="{ current: p.nr === aktuell }">
          <button class="phase-head" type="button" :aria-expanded="offen === p.nr" @click="offen = offen === p.nr ? null : p.nr">
            <span class="nr">{{ p.nr }}</span>
            <span class="grow">
              <strong>{{ p.name }}</strong>
              <span class="small muted block">
                {{ fortschritt(p).done }}/{{ fortschritt(p).n }} Kriterien · {{ ideenIn(p.nr).length }} Ideen · {{ aufgabenIn(p.nr) }} offene Aufgaben
              </span>
            </span>
            <span v-if="p.nr === aktuell" class="badge-new">aktuell</span>
          </button>
          <span class="progress" aria-hidden="true"><span :style="{ width: `${fortschritt(p).n ? (fortschritt(p).done / fortschritt(p).n) * 100 : 0}%` }"></span></span>

          <div v-if="offen === p.nr" class="body">
            <template v-if="bearbeiten === p.nr">
              <label class="field"><span>Name</span><input v-model="entwurf.name" class="input"></label>
              <label class="field"><span>Ziel</span><textarea v-model="entwurf.goal" class="textarea" rows="2"></textarea></label>
              <label class="field"><span>Ergebnis</span><textarea v-model="entwurf.result" class="textarea" rows="2"></textarea></label>
              <label class="field"><span>Hinweise</span><textarea v-model="entwurf.hints" class="textarea" rows="3"></textarea></label>
              <div class="row"><button class="btn primary" type="button" @click="speichern(p)">Speichern</button><button class="btn" type="button" @click="bearbeiten = null">Abbrechen</button></div>
            </template>
            <template v-else>
              <p><span class="muted">Ziel:</span> {{ p.goal }}</p>
              <p><span class="muted">Ergebnis:</span> {{ p.result }}</p>
              <p v-if="p.hints" class="hint">{{ p.hints }}</p>
            </template>

            <h3>Abschlusskriterien</h3>
            <ul class="criteria">
              <li v-for="c in p.criteria" :key="c.id">
                <label class="check">
                  <input type="checkbox" :checked="c.done" @change="toggleCriterion(p.nr, c.id, $event.target.checked)">
                  <span v-if="bearbeiten !== p.nr" :class="{ done: c.done }">{{ c.text }}</span>
                </label>
                <input v-if="bearbeiten === p.nr" class="input crit-input" :value="c.text" @change="kriteriumText(p, c, $event.target.value)">
                <span v-if="c.done && bearbeiten !== p.nr" class="small muted">{{ profile(c.done_by)?.kuerzel }}</span>
                <button v-if="bearbeiten === p.nr" class="icon-btn" type="button" aria-label="Kriterium entfernen" @click="kriteriumWeg(p, c)"><Icon name="close" :size="18" /></button>
              </li>
            </ul>
            <form v-if="bearbeiten === p.nr" class="row" @submit.prevent="kriteriumHinzu(p)">
              <input v-model="neuesKriterium" class="input" placeholder="Neues Kriterium">
              <button class="btn" type="submit" :disabled="!neuesKriterium.trim()">Hinzufügen</button>
            </form>

            <template v-if="ideenIn(p.nr).length">
              <h3>Ideen in dieser Phase</h3>
              <div class="row wrap">
                <router-link v-for="i in ideenIn(p.nr)" :key="i.id" :to="`/idee/${i.id}`" class="chip outline idea-chip">{{ i.is_favorite ? '★ ' : '' }}{{ i.title || 'Ohne Titel' }}</router-link>
              </div>
            </template>

            <div class="row wrap actions">
              <button v-if="bearbeiten !== p.nr" class="btn" type="button" @click="startBearbeiten(p)">Bearbeiten</button>
              <button v-if="p.nr !== aktuell" class="btn primary" type="button" @click="wechseln(p)">{{ p.nr < aktuell ? `Zurück zu Phase ${p.nr}` : `In Phase ${p.nr} wechseln` }}</button>
            </div>
          </div>
        </li>
      </ol>
    </template>

    <TaskList v-else-if="tab === 'aufgaben'" />
    <DecisionList v-else />
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.block { display: block; }
.wrap { flex-wrap: wrap; }
.tabs { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 4px; padding: 4px; border-radius: 12px; background: var(--chip); max-width: 520px; }
.tabs button { height: 38px; border: 0; border-radius: 9px; background: transparent; color: var(--muted); font-weight: 500; cursor: pointer; font-size: 14px; }
.tabs button[aria-selected="true"] { background: var(--surface); color: var(--text); box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12); }
.phasen { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.phase { display: flex; flex-direction: column; gap: 10px; }
.phase.current { border-color: var(--accent); }
.phase-head { display: flex; align-items: center; gap: 12px; border: 0; background: none; padding: 0; text-align: left; cursor: pointer; color: var(--text); }
.nr { width: 30px; height: 30px; border-radius: 50%; flex: none; display: inline-flex; align-items: center; justify-content: center; background: var(--chip); font-weight: 600; }
.current .nr { background: var(--accent); color: var(--on-accent); }
.progress { display: block; height: 4px; border-radius: 2px; background: var(--chip); overflow: hidden; }
.progress span { display: block; height: 100%; background: var(--accent); }
.body { display: flex; flex-direction: column; gap: 10px; border-top: 1px solid var(--line); padding-top: 12px; }
.hint { background: var(--chip); padding: 10px 12px; border-radius: 10px; font-size: 14px; }
h3 { font-size: 14px; font-weight: 600; margin: 4px 0 0; }
.criteria { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 6px; }
.criteria li { display: flex; align-items: center; gap: 8px; }
.check { display: flex; gap: 10px; align-items: flex-start; cursor: pointer; flex: 1; }
.check input { width: 20px; height: 20px; margin-top: 2px; accent-color: var(--accent); flex: none; }
.done { text-decoration: line-through; color: var(--muted); }
.crit-input { flex: 1; min-height: 38px; padding: 6px 10px; }
.idea-chip { text-decoration: none; font-size: 13px; padding: 4px 10px; }
.actions { margin-top: 4px; }
</style>
