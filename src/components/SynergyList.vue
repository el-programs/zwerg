<script setup>
// Synergien einer Idee: verbundene Ideen mit kurzer Begründung, hinzufügen und entfernen.
import { computed, reactive } from 'vue';
import { addSynergy, deleteSynergy, state, synergiesOf, toast, updateSynergy } from '../lib/store.js';
import Icon from './Icon.vue';

const props = defineProps({ ideaId: { type: String, required: true } });
const links = computed(() => synergiesOf(props.ideaId));
const neu = reactive({ other: '', note: '' });
const auswahl = computed(() => {
  const vergeben = new Set(links.value.map((s) => s.idea.id));
  return state.ideas
    .filter((i) => i.id !== props.ideaId && !vergeben.has(i.id))
    .sort((a, b) => (a.title || '').localeCompare(b.title || '', 'de'));
});

function hinzufuegen() {
  if (!neu.other) return;
  addSynergy(props.ideaId, neu.other, neu.note);
  neu.other = '';
  neu.note = '';
  toast('Synergie gespeichert');
}
function entfernen(s) {
  if (!confirm(`Synergie mit „${s.idea.title || 'Ohne Titel'}“ entfernen?`)) return;
  deleteSynergy(s.id);
}
</script>

<template>
  <section class="stack">
    <h2>Synergien ({{ links.length }})</h2>
    <p class="small muted">Ideen, die sich mit dieser kombinieren lassen, z. B. gleiche Kunden, Leute oder Technik. Sie erscheinen auf der Karte als Ringe.</p>
    <div v-for="s in links" :key="s.id" class="card syn">
      <Icon name="synergy" :size="20" class="rings" />
      <div class="grow stack tight">
        <router-link :to="`/idee/${s.idea.id}`" class="syn-title">{{ s.idea.title || 'Ohne Titel' }}</router-link>
        <label class="visually-hidden" :for="`syn-${s.id}`">Begründung</label>
        <input
          :id="`syn-${s.id}`"
          class="input small"
          :value="s.note"
          placeholder="Warum passt das zusammen?"
          @change="updateSynergy(s.id, $event.target.value)"
        >
      </div>
      <button class="icon-btn" type="button" aria-label="Synergie entfernen" @click="entfernen(s)"><Icon name="close" :size="18" /></button>
    </div>
    <form class="syn-form" @submit.prevent="hinzufuegen">
      <label class="visually-hidden" for="syn-neu">Idee</label>
      <select id="syn-neu" v-model="neu.other" class="select">
        <option value="">Idee wählen …</option>
        <option v-for="i in auswahl" :key="i.id" :value="i.id">{{ i.title || 'Ohne Titel' }}</option>
      </select>
      <label class="visually-hidden" for="syn-notiz">Begründung</label>
      <input id="syn-notiz" v-model="neu.note" class="input" placeholder="Begründung (optional)">
      <button class="btn" type="submit" :disabled="!neu.other">Verbinden</button>
    </form>
  </section>
</template>

<style scoped>
p { margin: 0; }
.syn { display: flex; align-items: flex-start; gap: 10px; padding: 10px 6px 10px 14px; }
.rings { color: var(--accent); flex: none; margin-top: 2px; }
.grow { flex: 1; min-width: 0; }
.tight { gap: 6px; }
.syn-title { font-weight: 600; color: inherit; }
.syn-form { display: grid; grid-template-columns: 1fr; gap: 8px; }
@media (min-width: 640px) { .syn-form { grid-template-columns: 1.2fr 1fr auto; } }
</style>
