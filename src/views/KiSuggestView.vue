<script setup>
// KI schlägt Ideen zu einem Suchfeld vor; einzelne Vorschläge lassen sich als Idee übernehmen.
import { computed, onMounted, ref } from 'vue';
import { addIdea, fieldName, profile, state, toast, updateIdea } from '../lib/store.js';
import { relativ } from '../lib/format.js';
import { euro, kiSichtbar, ladeStatus, limitErreicht, starte } from '../lib/ki.js';
import Icon from '../components/Icon.vue';

const fieldId = ref('');
const hint = ref('');
const busy = ref(false);
const error = ref('');
const uebernommen = ref(new Set());
onMounted(ladeStatus);

const fields = computed(() => state.fields.filter((f) => !f.archived));
const laeufe = computed(() => state.aiResults.filter((r) => r.kind === 'vorschlaege'));
const aktuell = computed(() => laeufe.value[0] ?? null);
const gesperrt = computed(() => !state.online || state.kiStatus?.configured === false || limitErreicht.value || !kiSichtbar.value);

async function los() {
  error.value = '';
  busy.value = true;
  try {
    await starte('vorschlaege', { searchFieldId: fieldId.value || null, hint: hint.value }, 'Vorschläge angefordert');
  } catch (e) {
    error.value = e.message;
  } finally {
    busy.value = false;
  }
}

function uebernehmen(run, v, i) {
  const ideaId = addIdea({
    title: v.titel,
    description: `${v.beschreibung}\n\nWarum es passen könnte: ${v.warum}\nGrößter Haken: ${v.haken}\nErster Test: ${v.erster_test}`,
    searchFieldId: run.search_field_id,
  });
  updateIdea(ideaId, { tags: ['KI-Vorschlag'] });
  uebernommen.value = new Set([...uebernommen.value, `${run.id}-${i}`]);
  toast('Als Idee übernommen');
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link to="/ideen" class="icon-btn" aria-label="Zurück"><Icon name="back" /></router-link>
      <h1 class="grow">Ideen von der KI</h1>
      <span class="chip ki">KI</span>
    </div>
  </header>
  <main class="page">
    <p class="muted">Die KI schlägt sechs Ideen vor – mit Haken und einem ersten günstigen Test. Übernehmt nur, was euch wirklich anspricht.</p>
    <p v-if="!kiSichtbar" class="card small note">Du hast die KI ausgeschaltet (Mehr → KI-Unterstützung).</p>
    <p v-else-if="state.kiStatus?.configured === false" class="card small note">Die KI ist noch nicht eingerichtet (Anleitung Teil E).</p>
    <p v-else-if="limitErreicht" class="card small note">Das Monatslimit ist erreicht.</p>

    <div class="card stack">
      <label class="field">
        <span>Suchfeld</span>
        <select v-model="fieldId" class="select">
          <option value="">– beliebig –</option>
          <option v-for="f in fields" :key="f.id" :value="f.id">{{ f.name }}</option>
        </select>
      </label>
      <label class="field">
        <span>Hinweise (optional)</span>
        <input v-model="hint" class="input" placeholder="z. B. Wir können gut mit Metall arbeiten, haben eine Werkstatt">
      </label>
      <button class="btn primary" type="button" :disabled="gesperrt || busy || aktuell?.status === 'laeuft'" @click="los">Vorschläge erzeugen</button>
      <p v-if="error" class="error">{{ error }}</p>
    </div>

    <section v-for="run in laeufe.slice(0, 3)" :key="run.id" class="stack">
      <p class="small muted">
        {{ run.search_field_id ? fieldName(run.search_field_id) : 'Beliebiges Suchfeld' }} · {{ relativ(run.created_at) }} · {{ profile(run.created_by)?.name }}
        <template v-if="run.status === 'fertig'"> · ca. {{ euro(run.cost_eur) }}</template>
      </p>
      <div v-if="run.status === 'laeuft'" class="card working">Die KI überlegt … meist 20–60 Sekunden.</div>
      <div v-else-if="run.status === 'fehler'" class="card error">{{ run.error }}</div>
      <template v-else>
        <article v-for="(v, i) in run.content?.ideen ?? []" :key="i" class="card stack vorschlag">
          <div class="row"><span class="chip ki">KI-Vorschlag</span><strong class="grow">{{ v.titel }}</strong></div>
          <p>{{ v.beschreibung }}</p>
          <p class="small"><span class="muted">Warum es passen könnte:</span> {{ v.warum }}</p>
          <p class="small"><span class="muted">Größter Haken:</span> {{ v.haken }}</p>
          <p class="small"><span class="muted">Erster Test:</span> {{ v.erster_test }}</p>
          <button class="btn" type="button" :disabled="uebernommen.has(`${run.id}-${i}`)" @click="uebernehmen(run, v, i)">
            {{ uebernommen.has(`${run.id}-${i}`) ? 'Übernommen' : 'Als Idee übernehmen' }}
          </button>
        </article>
      </template>
    </section>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.chip.ki { background: transparent; border: 1px solid var(--accent); color: var(--accent); font-weight: 600; flex: none; }
.note { border-color: var(--warn); }
.working { border-style: dashed; color: var(--muted); }
.vorschlag { align-items: flex-start; }
</style>
