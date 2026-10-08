<script setup>
// Aufgabenliste mit Schnellerfassung. Optional auf eine Idee oder Phase eingeschränkt.
import { computed, reactive, ref } from 'vue';
import { addTask, currentPhase, deleteTask, heute, profile, state, updateTask } from '../lib/store.js';
import { datum } from '../lib/format.js';
import Icon from './Icon.vue';

const props = defineProps({
  ideaId: { type: String, default: null },
  showFilter: { type: Boolean, default: true },
  compact: { type: Boolean, default: false },
});

const filter = ref('meine');
const offen = ref(null);
const neu = reactive({ title: '', assignee: '', due_date: '', idea_id: '', phase: '' });
const STATUS = [
  { id: 'offen', name: 'Offen' },
  { id: 'in_arbeit', name: 'In Arbeit' },
  { id: 'erledigt', name: 'Erledigt' },
];
const ideen = computed(() => state.ideas.filter((i) => i.status !== 'geparkt'));

const basis = computed(() => state.tasks.filter((t) => !props.ideaId || t.idea_id === props.ideaId));
const sichtbar = computed(() => {
  if (!props.showFilter) return basis.value.filter((t) => t.status !== 'erledigt');
  if (filter.value === 'erledigt') return basis.value.filter((t) => t.status === 'erledigt').sort((a, b) => (a.done_at < b.done_at ? 1 : -1));
  return basis.value.filter((t) => t.status !== 'erledigt' && (filter.value === 'alle' || t.assignee === state.me?.id));
});

function woche() {
  const d = new Date();
  d.setDate(d.getDate() + 7);
  return d.toLocaleDateString('sv-SE');
}
const gruppen = computed(() => {
  if (filter.value === 'erledigt' && props.showFilter) return [{ name: 'Erledigt', list: sichtbar.value }];
  const h = heute();
  const w = woche();
  const sort = (a, b) => ((a.due_date ?? '9') < (b.due_date ?? '9') ? -1 : 1);
  const g = [
    { name: 'Überfällig', list: sichtbar.value.filter((t) => t.due_date && t.due_date < h), warn: true },
    { name: 'Diese Woche', list: sichtbar.value.filter((t) => t.due_date && t.due_date >= h && t.due_date <= w) },
    { name: 'Später', list: sichtbar.value.filter((t) => t.due_date && t.due_date > w) },
    { name: 'Ohne Datum', list: sichtbar.value.filter((t) => !t.due_date) },
  ];
  return g.map((x) => ({ ...x, list: x.list.sort(sort) })).filter((x) => x.list.length);
});

function hinzufuegen() {
  if (!neu.title.trim()) return;
  addTask({
    title: neu.title,
    assignee: neu.assignee || state.me.id,
    due_date: neu.due_date || null,
    idea_id: props.ideaId ?? (neu.idea_id || null),
    phase: neu.phase ? Number(neu.phase) : currentPhase(),
  });
  neu.title = '';
  neu.due_date = '';
}
function abhaken(t, e) {
  updateTask(t.id, { status: e.target.checked ? 'erledigt' : 'offen' });
}
function ideaTitle(id) {
  return state.ideas.find((i) => i.id === id)?.title || 'Notiz';
}
function loeschen(t) {
  if (confirm(`Aufgabe „${t.title}“ löschen?`)) deleteTask(t.id);
}
</script>

<template>
  <div class="tasks">
    <form class="card add" @submit.prevent="hinzufuegen">
      <label class="visually-hidden" :for="`task-neu-${ideaId ?? 'alle'}`">Neue Aufgabe</label>
      <input :id="`task-neu-${ideaId ?? 'alle'}`" v-model="neu.title" class="input" placeholder="Neue Aufgabe …">
      <div class="add-row">
        <label class="field">
          <span>Wer</span>
          <select v-model="neu.assignee" class="select">
            <option value="">{{ state.me?.name }} (ich)</option>
            <option v-for="p in state.profiles.filter((x) => x.id !== state.me?.id)" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>
        </label>
        <label class="field">
          <span>Fällig</span>
          <input v-model="neu.due_date" class="input" type="date">
        </label>
        <label v-if="!ideaId && !compact" class="field">
          <span>Notiz</span>
          <select v-model="neu.idea_id" class="select">
            <option value="">– keine –</option>
            <option v-for="i in ideen" :key="i.id" :value="i.id">{{ i.title || 'Ohne Titel' }}</option>
          </select>
        </label>
        <button class="btn primary" type="submit" :disabled="!neu.title.trim()">Hinzufügen</button>
      </div>
    </form>

    <div v-if="showFilter" class="segmented" role="group" aria-label="Filter">
      <button type="button" :aria-pressed="filter === 'meine'" @click="filter = 'meine'">Meine</button>
      <button type="button" :aria-pressed="filter === 'alle'" @click="filter = 'alle'">Alle offenen</button>
      <button type="button" :aria-pressed="filter === 'erledigt'" @click="filter = 'erledigt'">Erledigt</button>
    </div>

    <section v-for="g in gruppen" :key="g.name" class="stack">
      <h3 class="group" :class="{ warn: g.warn }">{{ g.name }} ({{ g.list.length }})</h3>
      <div v-for="t in g.list" :key="t.id" class="card task" :class="{ done: t.status === 'erledigt' }">
        <div class="row top">
          <input class="check" type="checkbox" :checked="t.status === 'erledigt'" :aria-label="`${t.title} erledigt`" @change="abhaken(t, $event)">
          <button class="title-btn grow" type="button" :aria-expanded="offen === t.id" @click="offen = offen === t.id ? null : t.id">
            <span class="t-title">{{ t.title }}</span>
            <span class="meta small muted">
              <span class="avatar">{{ profile(t.assignee)?.kuerzel ?? '–' }}</span>
              <span v-if="t.due_date" :class="{ late: t.due_date < heute() && t.status !== 'erledigt' }">{{ datum(t.due_date) }}</span>
              <span v-if="t.status === 'in_arbeit'" class="chip">in Arbeit</span>
              <span v-if="t.phase" class="chip outline">Phase {{ t.phase }}</span>
              <span v-if="t.idea_id && !ideaId" class="ellipsis">· {{ ideaTitle(t.idea_id) }}</span>
            </span>
          </button>
        </div>
        <div v-if="offen === t.id" class="edit">
          <label class="field">
            <span>Titel</span>
            <input class="input" :value="t.title" @change="$event.target.value.trim() && updateTask(t.id, { title: $event.target.value.trim() })">
          </label>
          <label class="field">
            <span>Notizen</span>
            <textarea class="textarea" rows="3" :value="t.notes" @change="updateTask(t.id, { notes: $event.target.value })"></textarea>
          </label>
          <div class="add-row">
            <label class="field">
              <span>Wer</span>
              <select class="select" :value="t.assignee ?? ''" @change="updateTask(t.id, { assignee: $event.target.value || null })">
                <option value="">– niemand –</option>
                <option v-for="p in state.profiles" :key="p.id" :value="p.id">{{ p.name }}</option>
              </select>
            </label>
            <label class="field">
              <span>Fällig</span>
              <input class="input" type="date" :value="t.due_date ?? ''" @change="updateTask(t.id, { due_date: $event.target.value || null })">
            </label>
            <label class="field">
              <span>Status</span>
              <select class="select" :value="t.status" @change="updateTask(t.id, { status: $event.target.value })">
                <option v-for="s in STATUS" :key="s.id" :value="s.id">{{ s.name }}</option>
              </select>
            </label>
            <label class="field">
              <span>Phase</span>
              <select class="select" :value="t.phase ?? ''" @change="updateTask(t.id, { phase: $event.target.value ? Number($event.target.value) : null })">
                <option value="">–</option>
                <option v-for="n in [1, 2, 3, 4]" :key="n" :value="n">Phase {{ n }}</option>
              </select>
            </label>
            <label v-if="!ideaId" class="field">
              <span>Notiz</span>
              <select class="select" :value="t.idea_id ?? ''" @change="updateTask(t.id, { idea_id: $event.target.value || null })">
                <option value="">– keine –</option>
                <option v-for="i in ideen" :key="i.id" :value="i.id">{{ i.title || 'Ohne Titel' }}</option>
              </select>
            </label>
          </div>
          <div class="row">
            <router-link v-if="t.idea_id && !ideaId" :to="`/idee/${t.idea_id}`" class="btn">Zur Notiz</router-link>
            <button class="btn danger" type="button" @click="loeschen(t)"><Icon name="trash" :size="18" />Löschen</button>
          </div>
        </div>
      </div>
    </section>
    <p v-if="!gruppen.length" class="empty">{{ filter === 'erledigt' ? 'Noch nichts erledigt.' : 'Keine offenen Aufgaben.' }}</p>
  </div>
</template>

<style scoped>
.tasks { display: flex; flex-direction: column; gap: 14px; }
.add { display: flex; flex-direction: column; gap: 10px; }
.add-row { display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); align-items: end; }
.group { font-size: 13px; font-weight: 600; color: var(--muted); }
.group.warn { color: var(--danger); }
.task { padding: 10px 12px; display: flex; flex-direction: column; gap: 10px; }
.task.done .t-title { text-decoration: line-through; color: var(--muted); }
.top { align-items: flex-start; }
.check { width: 22px; height: 22px; margin-top: 2px; accent-color: var(--accent); flex: none; cursor: pointer; }
.title-btn { border: 0; background: none; padding: 0; text-align: left; display: flex; flex-direction: column; gap: 4px; cursor: pointer; color: var(--text); min-width: 0; }
.t-title { font-weight: 500; }
.meta { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.meta .avatar { width: 22px; height: 22px; font-size: 9px; color: var(--text); }
.late { color: var(--danger); font-weight: 600; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 200px; }
.edit { display: flex; flex-direction: column; gap: 10px; border-top: 1px solid var(--line); padding-top: 10px; }
.grow { flex: 1; }
</style>
