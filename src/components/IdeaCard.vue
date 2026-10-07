<script setup>
import { computed } from 'vue';
import { commentsOf, fieldName, isNewIdea, isPending, newComments, profile } from '../lib/store.js';

const props = defineProps({ idea: { type: Object, required: true } });
const neu = computed(() => isNewIdea(props.idea) || newComments(props.idea).length > 0);
const anzahl = computed(() => commentsOf(props.idea.id).length);
const von = computed(() => profile(props.idea.created_by));
const feld = computed(() => fieldName(props.idea.search_field_id));
</script>

<template>
  <router-link :to="`/idee/${idea.id}`" class="card idea">
    <span class="top">
      <span class="title">{{ idea.title || 'Ohne Titel' }}</span>
      <span v-if="neu" class="badge-new">neu</span>
    </span>
    <span v-if="idea.description" class="desc small muted">{{ idea.description }}</span>
    <span class="meta small muted">
      <span v-if="feld" class="chip">{{ feld }}</span>
      <span v-if="isPending(idea.id)" class="chip outline">wartet auf Abgleich</span>
      <span class="grow"></span>
      <span>{{ anzahl === 1 ? '1 Kommentar' : `${anzahl} Kommentare` }}</span>
      <span v-if="von" class="avatar" :title="von.name">{{ von.kuerzel }}</span>
    </span>
  </router-link>
</template>

<style scoped>
.idea { display: flex; flex-direction: column; gap: 6px; text-decoration: none; color: inherit; }
.top { display: flex; align-items: flex-start; gap: 8px; }
.title { flex: 1; font-weight: 600; font-size: 16px; line-height: 1.3; }
.desc { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.meta { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.grow { flex: 1; }
.avatar { width: 24px; height: 24px; font-size: 10px; color: var(--text); }
</style>
