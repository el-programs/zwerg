<script setup>
// Phase 2b Gründungscheck einer Idee: Gründungsplan, Budget und Kalkulation (mit Kostentabelle),
// Klärungspunkte und Go/No-Go. Je Prüfpunkt Status, Ergebnis, Verantwortlicher und Termin.
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import { ABSCHNITTE, addStep, costTotals, deleteStep, profile, state, stepSummary, stepsOf, updateStep } from '../lib/store.js';
import { eur } from '../lib/business.js';
import { datum } from '../lib/format.js';
import KostenTabelle from '../components/KostenTabelle.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const summe = computed(() => stepSummary(id.value));
const neu = reactive({ plan: '', budget: '', klaerung: '', gonogo: '' });
const bearbeiten = ref(null);
const offen = reactive({});

const STATUS = [
  { id: 'offen', label: 'offen' },
  { id: 'in_arbeit', label: 'in Arbeit' },
  { id: 'erledigt', label: 'erledigt' },
];
const GO = [
  { id: 'offen', label: 'offen' },
  { id: 'ja', label: 'erfüllt' },
  { id: 'nein', label: 'nicht erfüllt' },
];
const stand = (sec) => {
  const l = stepsOf(id.value, sec);
  return sec === 'gonogo' ? `${l.filter((x) => x.status === 'ja').length} von ${l.length} erfüllt` : `${l.filter((x) => x.status === 'erledigt').length} von ${l.length} erledigt`;
};
function hinzu(sec) {
  if (!neu[sec].trim()) return;
  addStep(id.value, sec, neu[sec]);
  neu[sec] = '';
}
function titel(s, text) {
  if (text.trim() && text.trim() !== s.title) updateStep(s.id, { title: text.trim().slice(0, 500) });
  bearbeiten.value = null;
}
function weg(s) {
  if (!confirm(`Prüfpunkt „${s.title}“ entfernen?`)) return;
  deleteStep(s.id);
  bearbeiten.value = null;
}
const istOffen = (sec) => offen[sec] ?? sec !== 'gonogo';
// Prüfpunkte kompakt: Titel und Status; Ergebnis, Verantwortlicher und Termin auf Antippen.
const auf = reactive({});
const kostenAuf = ref(false);
const kosten = computed(() => costTotals(id.value));
const statusText = (sec, st) => (sec === 'gonogo' ? GO : STATUS).find((x) => x.id === st)?.label ?? st;
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link :to="`/fokus/${id}`" class="icon-btn" aria-label="Zur Arbeitsmappe"><Icon name="back" /></router-link>
      <h1 class="grow ellipsis">Gründungscheck</h1>
      <router-link to="/fokus" class="small more">Ideen-Fokus</router-link>
    </div>
  </header>

  <main v-if="!idea" class="page"><p class="empty">Diese Idee gibt es nicht (mehr).</p></main>

  <main v-else class="page">
    <div class="stack tight">
      <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>
      <p class="small muted">Phase 2b: Was brauchen wir bis zur Gründung, was kostet es, wie lange dauert es? Prüfpunkte könnt ihr ergänzen, ändern oder entfernen.</p>
    </div>

    <div class="card summary small">
      <span><strong>{{ summe.erledigt }}</strong> von {{ summe.n }} Prüfpunkten erledigt<template v-if="summe.inArbeit"> · {{ summe.inArbeit }} in Arbeit</template></span>
      <span>Go/No-Go: <strong>{{ summe.goJa }}</strong> von {{ summe.goN }} erfüllt<template v-if="summe.goNein"> · <span class="nein">{{ summe.goNein }} nicht erfüllt</span></template></span>
    </div>

    <section v-for="a in ABSCHNITTE" :key="a.id" class="card abschnitt">
      <button class="kopf" type="button" :aria-expanded="istOffen(a.id)" @click="offen[a.id] = !istOffen(a.id)">
        <span class="grow">
          <strong>{{ a.name }}</strong>
          <span class="small muted block">{{ a.hint }} · {{ stand(a.id) }}</span>
        </span>
        <Icon :name="istOffen(a.id) ? 'up' : 'down'" :size="18" />
      </button>

      <div v-if="istOffen(a.id)" class="body">
        <article v-for="(s, n) in stepsOf(id, a.id)" :key="s.id" :class="['step', s.status]">
          <button v-if="!auf[s.id]" class="s-kurz" type="button" @click="auf[s.id] = true">
            <span class="nr">{{ n + 1 }}</span>
            <span class="grow">
              <span class="s-title">{{ s.title }}</span>
              <span v-if="s.result" class="s-res small muted">{{ s.result }}</span>
            </span>
            <span class="s-tags">
              <span :class="['pill', s.status]">{{ statusText(a.id, s.status) }}</span>
              <span v-if="s.assignee" class="small muted">{{ profile(s.assignee)?.kuerzel }}</span>
              <span v-if="s.due_date && s.status !== 'erledigt'" class="small muted">{{ datum(s.due_date) }}</span>
            </span>
          </button>
          <template v-else>
          <div class="s-head">
            <span class="nr">{{ n + 1 }}</span>
            <input v-if="bearbeiten === s.id" class="input grow" :value="s.title" aria-label="Prüfpunkt" @change="titel(s, $event.target.value)" @keydown.enter.prevent="$event.target.blur()">
            <p v-else class="s-title grow">{{ s.title }}</p>
            <button v-if="bearbeiten === s.id" class="icon-btn" type="button" aria-label="Prüfpunkt entfernen" @click="weg(s)"><Icon name="trash" :size="18" /></button>
            <button class="link-btn small" type="button" @click="bearbeiten = bearbeiten === s.id ? null : s.id">{{ bearbeiten === s.id ? 'Fertig' : 'Ändern' }}</button>
            <button class="icon-btn zu" type="button" aria-label="Zuklappen" @click="auf[s.id] = false; bearbeiten = null"><Icon name="up" :size="18" /></button>
          </div>
          <div class="seg" role="radiogroup" :aria-label="s.title">
            <button
              v-for="st in a.id === 'gonogo' ? GO : STATUS"
              :key="st.id"
              type="button"
              role="radio"
              :class="['seg-btn', st.id]"
              :aria-checked="s.status === st.id"
              @click="s.status !== st.id && updateStep(s.id, { status: st.id })"
            >{{ st.label }}</button>
          </div>
          <textarea
            class="textarea"
            rows="2"
            :value="s.result"
            :placeholder="a.id === 'gonogo' ? 'Begründung' : 'Ergebnis, Quelle, Notizen …'"
            aria-label="Ergebnis"
            @change="$event.target.value !== s.result && updateStep(s.id, { result: $event.target.value })"
          ></textarea>
          <div v-if="a.id !== 'gonogo'" class="s-meta">
            <label class="field">
              <span>Wer kümmert sich?</span>
              <select class="select" :value="s.assignee ?? ''" @change="updateStep(s.id, { assignee: $event.target.value || null })">
                <option value="">– niemand –</option>
                <option v-for="p in state.profiles" :key="p.id" :value="p.id">{{ p.name }}</option>
              </select>
            </label>
            <label class="field">
              <span>Bis wann?</span>
              <input class="input" type="date" :value="s.due_date ?? ''" @change="updateStep(s.id, { due_date: $event.target.value || null })">
            </label>
            <span v-if="s.updated_by" class="small muted upd">zuletzt {{ profile(s.updated_by)?.name }}<template v-if="s.due_date && s.status !== 'erledigt'"> · fällig {{ datum(s.due_date) }}</template></span>
          </div>
          </template>
        </article>

        <form class="add" @submit.prevent="hinzu(a.id)">
          <input v-model="neu[a.id]" class="input" :placeholder="a.id === 'gonogo' ? 'Neues Kriterium' : 'Neuer Prüfpunkt'">
          <button class="btn" type="submit" :disabled="!neu[a.id].trim()">Hinzufügen</button>
        </form>

        <div v-if="a.id === 'budget'" class="kosten">
          <button class="kopf" type="button" :aria-expanded="kostenAuf" @click="kostenAuf = !kostenAuf">
            <span class="grow">
              <strong>Kostentabelle</strong>
              <span class="small muted block">Bis zur Gründung {{ eur(kosten.einmalig) }} · monatlich {{ eur(kosten.monatlich) }}<template v-if="kosten.offen"> · {{ kosten.offen }} ohne Betrag</template></span>
            </span>
            <Icon :name="kostenAuf ? 'up' : 'down'" :size="18" />
          </button>
          <KostenTabelle v-if="kostenAuf" :idea-id="id" />
        </div>
      </div>
    </section>

    <p class="small muted">Die Entscheidung Go (→ Phase 3) oder No-Go trefft ihr im <router-link to="/fokus">Ideen-Fokus</router-link> beim Favoriten.</p>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.block { display: block; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.more { color: var(--accent); text-decoration: none; padding: 0 8px; }
.tight { gap: 8px; }
.idea-title { font-size: 20px; }
.summary { display: flex; flex-wrap: wrap; gap: 6px 18px; }
.nein { color: var(--danger); }
.abschnitt { display: flex; flex-direction: column; gap: 12px; }
.kopf { display: flex; align-items: center; gap: 10px; border: 0; background: none; color: inherit; font: inherit; text-align: left; padding: 0; cursor: pointer; }
.body { display: flex; flex-direction: column; gap: 10px; }
.step { display: flex; flex-direction: column; gap: 8px; padding: 12px 0 0; border-top: 1px solid var(--line); }
.s-kurz { display: flex; align-items: flex-start; gap: 8px; border: 0; background: none; color: inherit; font: inherit; text-align: left; padding: 0; cursor: pointer; width: 100%; }
.s-kurz .s-title { display: block; }
.s-res { display: block; margin-top: 2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.s-tags { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; flex: none; }
.pill { font-size: 12px; padding: 1px 8px; border-radius: 9px; border: 1px solid var(--line); color: var(--muted); white-space: nowrap; }
.pill.in_arbeit { border-color: var(--warn); color: var(--warn); }
.pill.erledigt, .pill.ja { border-color: var(--ok); color: var(--ok); }
.pill.nein { border-color: var(--danger); color: var(--danger); }
.zu { width: 32px; height: 32px; }
.s-head { display: flex; align-items: flex-start; gap: 8px; }
.nr { color: var(--muted); font-weight: 600; min-width: 18px; }
.s-title { font-weight: 600; line-height: 1.35; }
.step.erledigt .s-title, .step.ja .s-title { color: var(--muted); }
.link-btn { border: 0; background: none; padding: 2px 0; color: var(--accent); cursor: pointer; white-space: nowrap; }
.seg { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }
.seg-btn { min-height: 36px; border: 1px solid var(--line); border-radius: 9px; background: var(--surface); color: var(--muted); font: inherit; font-size: 13px; cursor: pointer; }
.seg-btn[aria-checked="true"] { color: var(--text); font-weight: 600; background: var(--chip); border-color: var(--muted); }
.seg-btn.in_arbeit[aria-checked="true"] { border-color: var(--warn); }
.seg-btn.erledigt[aria-checked="true"], .seg-btn.ja[aria-checked="true"] { border-color: var(--ok); color: var(--ok); }
.seg-btn.nein[aria-checked="true"] { border-color: var(--danger); color: var(--danger); }
.s-meta { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 8px; align-items: end; }
.upd { grid-column: 1 / -1; }
.add { display: grid; grid-template-columns: 1fr auto; gap: 8px; }
.kosten { display: flex; flex-direction: column; gap: 10px; padding-top: 12px; border-top: 1px solid var(--line); }
.kosten h3 { margin: 0; font-size: 16px; }
</style>
