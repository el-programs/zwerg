<script setup>
// Bearbeitbare Liste für Suchfelder, Bewertungsfaktoren und KO-Kriterien.
import { computed, reactive, ref } from 'vue';
import { addListItem, moveListItem, state, TABLES, updateListItem } from '../lib/store.js';
import Icon from './Icon.vue';

const props = defineProps({
  table: { type: String, required: true },
  placeholder: { type: String, default: 'Neuer Eintrag' },
  withDescription: { type: Boolean, default: false },
});
const emit = defineEmits(['error']);
const items = computed(() => [...state[TABLES[props.table].key]].sort((a, b) => a.sort - b.sort));
const neu = ref('');
const drafts = reactive({});

async function run(fn) {
  try {
    await fn();
  } catch (e) {
    emit('error', e.message);
  }
}
function value(item, key) {
  return drafts[`${item.id}.${key}`] ?? item[key] ?? '';
}
function commit(item, key) {
  const k = `${item.id}.${key}`;
  if (!(k in drafts)) return;
  const v = drafts[k].trim();
  delete drafts[k];
  if ((key === 'name' && !v) || v === (item[key] ?? '')) return;
  run(() => updateListItem(props.table, item.id, { [key]: v }));
}
function add() {
  if (!neu.value.trim()) return;
  run(async () => {
    await addListItem(props.table, neu.value);
    neu.value = '';
  });
}
</script>

<template>
  <div class="list">
    <div v-for="(item, i) in items" :key="item.id" class="entry" :class="{ archived: item.archived }">
      <div class="row">
        <label class="visually-hidden" :for="`${table}-${item.id}`">Name</label>
        <input
          :id="`${table}-${item.id}`"
          class="input"
          :value="value(item, 'name')"
          @input="drafts[`${item.id}.name`] = $event.target.value"
          @blur="commit(item, 'name')"
          @keydown.enter.prevent="$event.target.blur()"
        >
        <button class="icon-btn" type="button" aria-label="Nach oben" :disabled="i === 0" @click="run(() => moveListItem(table, item.id, -1))"><Icon name="up" :size="18" /></button>
        <button class="icon-btn" type="button" aria-label="Nach unten" :disabled="i === items.length - 1" @click="run(() => moveListItem(table, item.id, 1))"><Icon name="down" :size="18" /></button>
        <button class="btn small-btn" type="button" @click="run(() => updateListItem(table, item.id, { archived: !item.archived }))">
          {{ item.archived ? 'Aktivieren' : 'Archivieren' }}
        </button>
      </div>
      <input
        v-if="withDescription"
        class="input desc"
        :value="value(item, 'description')"
        placeholder="Kurze Erklärung (optional)"
        :aria-label="`Erklärung zu ${item.name}`"
        @input="drafts[`${item.id}.description`] = $event.target.value"
        @blur="commit(item, 'description')"
        @keydown.enter.prevent="$event.target.blur()"
      >
    </div>
    <form class="row" @submit.prevent="add">
      <label class="visually-hidden" :for="`${table}-neu`">{{ placeholder }}</label>
      <input :id="`${table}-neu`" v-model="neu" class="input" :placeholder="placeholder">
      <button class="btn" type="submit" :disabled="!neu.trim()">Hinzufügen</button>
    </form>
  </div>
</template>

<style scoped>
.list { display: flex; flex-direction: column; gap: 10px; }
.entry { display: flex; flex-direction: column; gap: 4px; }
.row { display: flex; align-items: center; gap: 4px; }
.row .input { flex: 1; min-width: 0; }
.desc { font-size: 14px; min-height: 38px; padding: 6px 12px; color: var(--muted); }
.archived .input { color: var(--muted); text-decoration: line-through; }
.small-btn { padding: 0 10px; font-size: 13px; }
</style>
