<script setup>
// Entscheidungsprotokoll: wer hat wann was entschieden und warum.
import { computed, reactive, ref } from 'vue';
import { addDecision, deleteDecision, heute, profile, state, toast, updateDecision } from '../lib/store.js';
import { datum } from '../lib/format.js';

const props = defineProps({ ideaId: { type: String, default: null } });
const formOffen = ref(false);
const neu = reactive({ title: '', decision: '', reason: '', decided_on: heute(), idea_id: '' });
const bearbeiten = ref(null);
const ideen = computed(() => state.ideas);
const liste = computed(() =>
  state.decisions
    .filter((d) => !props.ideaId || d.idea_id === props.ideaId)
    .sort((a, b) => (a.decided_on === b.decided_on ? (a.created_at < b.created_at ? 1 : -1) : a.decided_on < b.decided_on ? 1 : -1)),
);

function speichern() {
  if (!neu.title.trim()) return;
  addDecision({ ...neu, idea_id: props.ideaId ?? (neu.idea_id || null) });
  Object.assign(neu, { title: '', decision: '', reason: '', decided_on: heute(), idea_id: '' });
  formOffen.value = false;
  toast('Entscheidung protokolliert');
}
function ideaTitle(id) {
  return state.ideas.find((i) => i.id === id)?.title || 'Notiz';
}
function loeschen(d) {
  if (confirm('Diesen Protokolleintrag löschen?')) deleteDecision(d.id);
}
</script>

<template>
  <div class="decisions">
    <button v-if="!formOffen" class="btn primary" type="button" @click="formOffen = true">Entscheidung protokollieren</button>
    <form v-else class="card stack" @submit.prevent="speichern">
      <label class="field"><span>Was wurde entschieden? (kurz)</span><input v-model="neu.title" class="input" placeholder="z. B. Werkzeugverleih wird Gründungskandidat"></label>
      <label class="field"><span>Entscheidung im Detail</span><textarea v-model="neu.decision" class="textarea" rows="3"></textarea></label>
      <label class="field"><span>Begründung – warum?</span><textarea v-model="neu.reason" class="textarea" rows="3"></textarea></label>
      <div class="two">
        <label class="field"><span>Datum</span><input v-model="neu.decided_on" class="input" type="date"></label>
        <label v-if="!ideaId" class="field">
          <span>Zu Notiz (optional)</span>
          <select v-model="neu.idea_id" class="select">
            <option value="">– keine –</option>
            <option v-for="i in ideen" :key="i.id" :value="i.id">{{ i.title || 'Ohne Titel' }}</option>
          </select>
        </label>
      </div>
      <div class="row">
        <button class="btn primary" type="submit" :disabled="!neu.title.trim()">Speichern</button>
        <button class="btn" type="button" @click="formOffen = false">Abbrechen</button>
      </div>
    </form>

    <ol class="timeline">
      <li v-for="d in liste" :key="d.id" class="card entry">
        <div class="row head">
          <span class="small muted">{{ datum(d.decided_on) }} · {{ profile(d.created_by)?.name }}</span>
          <span v-if="d.automatic" class="chip outline">automatisch</span>
        </div>
        <template v-if="bearbeiten === d.id">
          <input class="input" :value="d.title" @change="$event.target.value.trim() && updateDecision(d.id, { title: $event.target.value.trim() })">
          <textarea class="textarea" rows="3" :value="d.decision" placeholder="Entscheidung" @change="updateDecision(d.id, { decision: $event.target.value })"></textarea>
          <textarea class="textarea" rows="3" :value="d.reason" placeholder="Begründung" @change="updateDecision(d.id, { reason: $event.target.value })"></textarea>
          <div class="row"><button class="btn" type="button" @click="bearbeiten = null">Fertig</button><button class="btn danger" type="button" @click="loeschen(d)">Löschen</button></div>
        </template>
        <template v-else>
          <strong>{{ d.title }}</strong>
          <p v-if="d.decision" class="pre">{{ d.decision }}</p>
          <p v-if="d.reason" class="pre"><span class="muted">Warum:</span> {{ d.reason }}</p>
          <div class="row small">
            <router-link v-if="d.idea_id && !ideaId" :to="`/idee/${d.idea_id}`">{{ ideaTitle(d.idea_id) }}</router-link>
            <span v-if="d.phase" class="muted">Phase {{ d.phase }}</span>
            <button v-if="d.created_by === state.me?.id" class="link-btn" type="button" @click="bearbeiten = d.id">bearbeiten</button>
          </div>
        </template>
      </li>
    </ol>
    <p v-if="!liste.length" class="empty">Noch keine Entscheidungen protokolliert.</p>
  </div>
</template>

<style scoped>
.decisions { display: flex; flex-direction: column; gap: 14px; }
.decisions > .btn { align-self: flex-start; }
.two { display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); }
.timeline { list-style: none; margin: 0; padding: 0 0 0 14px; border-left: 2px solid var(--line); display: flex; flex-direction: column; gap: 10px; }
.entry { display: flex; flex-direction: column; gap: 6px; position: relative; }
.entry::before { content: ''; position: absolute; left: -22px; top: 18px; width: 10px; height: 10px; border-radius: 50%; background: var(--accent); }
.head { justify-content: space-between; }
p { margin: 0; }
.pre { white-space: pre-wrap; }
.link-btn { border: 0; background: none; padding: 0; color: var(--accent); cursor: pointer; margin-left: auto; }
</style>
