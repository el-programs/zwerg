<script setup>
// Ideen-Fokus: Arbeitsmappe einer Idee der engeren Wahl. Bündelt Grobcheck, Business Case, Pilot-Feedback,
// Steckbrief, Aufgaben und Entscheidungen zu dieser Idee.
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { checkSummary, modelName, state } from '../lib/store.js';
import { eur, rechne } from '../lib/business.js';
import { phaseName } from '../lib/format.js';
import VoteBox from '../components/VoteBox.vue';
import TaskList from '../components/TaskList.vue';
import DecisionList from '../components/DecisionList.vue';
import SteckbriefCard from '../components/SteckbriefCard.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const grob = computed(() => checkSummary(id.value));
const rolle = computed(() => {
  const i = idea.value;
  if (i?.selection === 'favorit') return 'Favorit · Machbarkeitsprüfung (2b)';
  if (i?.selection === 'nachruecker') return `Nachrücker ${i.selection_rank ?? ''}`.trim();
  if (i?.selection === 'verworfen') return 'nach der Prüfung verworfen';
  return 'im Grobcheck (2a)';
});
const bc = computed(() => state.businessCases.find((b) => b.idea_id === id.value) ?? null);
const bcText = computed(() => {
  const r = rechne(bc.value?.scenarios?.realistisch);
  if (!r) return 'Noch nicht gerechnet';
  return `Realistisch: ${eur(r.gewinnMonat)} Ergebnis/Monat`;
});
const feedbackAnzahl = computed(() => state.feedback.filter((f) => f.idea_id === id.value).length);
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link to="/fokus" class="icon-btn back" aria-label="Zum Ideen-Fokus"><Icon name="back" /><span>Fokus</span></router-link>
      <span class="grow"></span>
      <router-link v-if="idea" :to="`/idee/${id}`" class="small more">Idee öffnen</router-link>
    </div>
  </header>

  <main v-if="!idea" class="page"><p class="empty">Diese Idee gibt es nicht (mehr).</p></main>

  <main v-else class="page">
    <div class="stack tight">
      <span v-if="modelName(idea.business_model_id)" class="model">{{ modelName(idea.business_model_id) }}</span>
      <h1 class="title">{{ idea.title || 'Ohne Titel' }}</h1>
      <div class="row wrap meta">
        <span :class="['chip', idea.selection === 'favorit' ? 'fav' : 'outline']">{{ rolle }}</span>
        <span class="small muted">Phase {{ idea.phase }} · {{ state.phases.find((p) => p.nr === idea.phase)?.name ?? phaseName(idea.phase) }}</span>
        <span class="grow"></span>
        <VoteBox :idea-id="idea.id" />
      </div>
    </div>

    <div class="tools">
      <router-link :to="`/idee/${id}/grobcheck`" class="card tool">
        <strong>Grobcheck (2a)</strong>
        <span class="small muted">{{ grob.n ? `${grob.gut} gut · ${grob.schwierig} schwierig · ${grob.ko} KO · ${grob.offen} offen` : 'Noch keine Kriterien' }}</span>
      </router-link>
      <router-link :to="`/idee/${id}/business-case`" class="card tool">
        <strong>Business Case</strong>
        <span class="small muted">{{ bcText }}</span>
      </router-link>
      <router-link :to="`/idee/${id}/feedback`" class="card tool">
        <strong>Kundengespräche und Tests</strong>
        <span class="small muted">{{ feedbackAnzahl ? `${feedbackAnzahl} Einträge` : 'Noch keine Einträge' }}</span>
      </router-link>
      <router-link :to="`/bericht/idee/${id}`" class="card tool">
        <strong>Steckbrief als PDF</strong>
        <span class="small muted">Zum Teilen oder Ausdrucken</span>
      </router-link>
    </div>

    <section class="stack">
      <h2>Unser Fazit</h2>
      <p v-if="idea.check_fazit" class="card fazit">{{ idea.check_fazit }}</p>
      <p v-else class="small muted">Noch kein Fazit – im Grobcheck unten festhalten.</p>
    </section>

    <SteckbriefCard :idea="idea" />

    <section class="stack">
      <h2>Aufgaben zu dieser Idee</h2>
      <TaskList :idea-id="idea.id" :show-filter="false" compact />
    </section>

    <section class="stack">
      <h2>Entscheidungen</h2>
      <DecisionList :idea-id="idea.id" />
    </section>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.tight { gap: 8px; }
.back { width: auto; padding: 0 10px 0 2px; gap: 2px; }
.more { color: var(--accent); text-decoration: none; padding: 0 8px; }
.model { font-size: 11.5px; text-transform: uppercase; letter-spacing: 0.05em; color: var(--accent); }
.title { font-size: 22px; margin: 0; }
.meta { gap: 10px; align-items: center; }
.chip.fav { background: var(--accent); color: var(--on-accent); font-weight: 600; }
.tools { display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); }
.tool { display: flex; flex-direction: column; gap: 4px; text-decoration: none; color: inherit; }
.fazit { white-space: pre-line; }
</style>
