<script setup>
import { computed, ref } from 'vue';
import { fieldName, partner, state } from '../lib/store.js';
import IdeaCard from '../components/IdeaCard.vue';
import Icon from '../components/Icon.vue';

const filter = ref('alle');
const suche = ref('');
const sucheOffen = ref(false);
const anderer = computed(() => partner());

const aktiv = computed(() => state.ideas.filter((i) => i.status !== 'geparkt'));
const filters = computed(() => [
  { id: 'alle', label: `Alle ${aktiv.value.length}` },
  { id: 'meine', label: 'Meine' },
  { id: 'partner', label: `Von ${anderer.value?.name ?? 'Partner'}` },
]);

const liste = computed(() => {
  const q = suche.value.trim().toLowerCase();
  return aktiv.value
    .filter((i) => filter.value === 'alle' || (filter.value === 'meine' ? i.created_by === state.me?.id : i.created_by !== state.me?.id))
    .filter((i) => {
      if (!q) return true;
      const text = [i.title, i.description, fieldName(i.search_field_id), ...(i.tags ?? [])].join(' ').toLowerCase();
      return text.includes(q);
    })
    .sort((a, b) => (a.created_at < b.created_at ? 1 : -1));
});
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <h1 class="grow">Ideen</h1>
      <button class="icon-btn" type="button" :aria-pressed="sucheOffen" aria-label="Suchen" @click="sucheOffen = !sucheOffen"><Icon name="search" /></button>
    </div>
  </header>
  <main class="page">
    <label v-if="sucheOffen" class="field">
      <span class="visually-hidden">Suche</span>
      <input v-model="suche" class="input" type="search" placeholder="Titel, Beschreibung, Schlagwort …" autofocus>
    </label>
    <div class="segmented" role="group" aria-label="Filter">
      <button v-for="f in filters" :key="f.id" type="button" :aria-pressed="filter === f.id" @click="filter = f.id">{{ f.label }}</button>
    </div>
    <div class="stack">
      <IdeaCard v-for="i in liste" :key="i.id" :idea="i" />
      <p v-if="!liste.length" class="empty">
        {{ state.ideas.length ? 'Keine Idee passt zu diesem Filter.' : 'Noch keine Ideen. Tippe unten auf das Plus, um die erste zu notieren.' }}
      </p>
    </div>
  </main>
</template>
