<script setup>
import { computed } from 'vue';
import { commentsOf, fieldName, isNewIdea, isPending, modelName, newComments, profile } from '../lib/store.js';
import { ideaResult } from '../lib/score.js';
import SynergyButton from './SynergyButton.vue';

const props = defineProps({ idea: { type: Object, required: true } });
const neu = computed(() => isNewIdea(props.idea) || newComments(props.idea).length > 0);
const anzahl = computed(() => commentsOf(props.idea.id).length);
const von = computed(() => profile(props.idea.created_by));
// Auf der Karte ohne Sektor, z. B. „C - Verarbeitendes Gewerbe“.
const feld = computed(() => fieldName(props.idea.search_field_id).replace(/ - (Primär|Sekundär|Tertiär)$/, ''));
const ergebnis = computed(() => ideaResult(props.idea.id));
const modell = computed(() => modelName(props.idea.business_model_id));
</script>

<template>
  <div class="card idea">
    <span v-if="modell" class="modell">{{ modell }}</span>
    <span class="top">
      <span v-if="idea.is_favorite" class="star" aria-label="Favorit">★</span>
      <router-link :to="`/idee/${idea.id}`" class="title">{{ idea.title || 'Ohne Titel' }}</router-link>
      <span v-if="ergebnis.score !== null" class="score" :title="ergebnis.kind === 'final' ? 'Endbewertung' : 'vorläufig'">{{ ergebnis.ko ? 'KO' : ergebnis.score }}</span>
      <span v-if="neu" class="badge-new">neu</span>
      <SynergyButton :idea-id="idea.id" class="syn" />
    </span>
    <span v-if="idea.description" class="desc small muted">{{ idea.description }}</span>
    <span class="meta small muted">
      <span v-if="feld" class="chip branche" :title="feld">{{ feld }}</span>
      <span v-if="idea.status !== 'geparkt' && (idea.shortlist ?? 'offen') === 'offen'" class="chip outline">Vorauswahl</span>
      <span v-if="isPending(idea.id)" class="chip outline">wartet auf Abgleich</span>
      <span class="grow"></span>
      <span>{{ anzahl === 1 ? '1 Kommentar' : `${anzahl} Kommentare` }}</span>
      <span v-if="von" class="avatar" :title="von.name">{{ von.kuerzel }}</span>
    </span>
  </div>
</template>

<style scoped>
.idea { position: relative; display: flex; flex-direction: column; gap: 6px; color: inherit; cursor: pointer; }
/* Die ganze Karte öffnet die Idee; das Synergie-Symbol liegt darüber. */
.title::after { content: ''; position: absolute; inset: 0; border-radius: inherit; }
.syn { position: relative; z-index: 1; margin: -12px -10px -12px 0; }
.modell { font-size: 11.5px; text-transform: uppercase; letter-spacing: 0.05em; color: var(--accent); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.branche { display: inline-block; min-width: 0; max-width: 48%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 24px; }
.top { display: flex; align-items: flex-start; gap: 8px; }
.title { color: inherit; text-decoration: none; flex: 1; font-weight: 600; font-size: 16px; line-height: 1.3; }
.star { color: var(--warn); }
.score { flex: none; font-size: 13px; font-weight: 600; padding: 1px 8px; border-radius: 6px; border: 1px solid var(--line); }
.desc { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.meta { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.grow { flex: 1; }
.avatar { width: 24px; height: 24px; font-size: 10px; color: var(--text); }
</style>
