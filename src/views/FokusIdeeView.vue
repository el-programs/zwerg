<script setup>
// Ideen-Fokus: Arbeitsmappe einer Idee der engeren Wahl. Bündelt Grobcheck (2a), Gründungscheck (2b),
// Steckbrief, weitere Gedanken, Aufgaben und Entscheidungen zu dieser Idee.
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { checkSummary, competitorsOf, costTotals, modelName, state, stepSummary } from '../lib/store.js';
import { eur } from '../lib/business.js';
import { phaseName } from '../lib/format.js';
import VoteBox from '../components/VoteBox.vue';
import TaskList from '../components/TaskList.vue';
import DecisionList from '../components/DecisionList.vue';
import SteckbriefCard from '../components/SteckbriefCard.vue';
import GliederText from '../components/GliederText.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const grob = computed(() => checkSummary(id.value));
const rolle = computed(() => {
  const i = idea.value;
  if (i?.selection === 'favorit') return 'Favorit · 2b';
  if (i?.selection === 'nachruecker') return `Nachrücker ${i.selection_rank ?? ''}`.trim();
  if (i?.selection === 'verworfen') return 'nach der Prüfung verworfen';
  return 'im Grobcheck (2a)';
});
const gc = computed(() => stepSummary(id.value));
const konkurrenz = computed(() => competitorsOf(id.value));
const kosten = computed(() => costTotals(id.value));
const gcText = computed(() => {
  if (!gc.value.n) return 'Noch keine Prüfpunkte';
  const teile = [`${gc.value.erledigt} von ${gc.value.n} erledigt`];
  if (kosten.value.einmalig) teile.push(`Budget ${eur(kosten.value.einmalig)}`);
  return teile.join(' · ');
});
// Pilot-Feedback erst ab Phase 3 (oder wenn schon Einträge da sind)
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
      <router-link :to="`/idee/${id}/gruendungscheck`" class="card tool">
        <strong>Gründungscheck (2b)</strong>
        <span class="small muted">{{ gcText }}</span>
      </router-link>
      <router-link :to="`/idee/${id}/konkurrenz`" class="card tool">
        <strong>Konkurrenz</strong>
        <span class="small muted">{{ konkurrenz.length ? `${konkurrenz.length} Anbieter erfasst` : 'Noch keine Anbieter erfasst' }}</span>
      </router-link>
      <router-link v-if="idea.phase >= 3 || feedbackAnzahl" :to="`/idee/${id}/feedback`" class="card tool">
        <strong>Pilot-Feedback</strong>
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

    <section v-if="idea.description" class="stack">
      <div class="row"><h2 class="grow">Weitere Gedanken</h2><router-link :to="`/idee/${id}`" class="small more">bearbeiten</router-link></div>
      <GliederText :text="idea.description" />
    </section>

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
