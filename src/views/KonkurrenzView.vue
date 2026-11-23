<script setup>
// Konkurrenz einer Idee: Anbieter als Karten (Bereich, Art, Preise, Stärken, Schwächen, Notiz),
// filterbar nach Bereich, dazu „Unsere Abgrenzung“ und „Allgemeine Notizen“.
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import { addCompetitor, competitorsOf, deleteCompetitor, profile, state, updateCompetitor, updateIdea } from '../lib/store.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const alle = computed(() => competitorsOf(id.value));

// Vorschläge für Bereich und Art; eigene Einträge sind jederzeit möglich.
const BEREICHE_KI = ['Webseiten', 'Medien und Design', 'Apps und Tools', 'Büro-Unterstützung', 'App-Vorbild'];
const ARTEN = ['Agentur', 'Freelancer', 'Baukasten / Software', 'KI-Anbieter'];
const bereiche = computed(() => {
  const eigene = alle.value.map((c) => c.area).filter(Boolean);
  const basis = idea.value?.title === 'KI-Firma' ? BEREICHE_KI : [];
  return [...new Set([...basis, ...eigene])];
});
const filter = ref('');
const liste = computed(() => (filter.value ? alle.value.filter((c) => c.area === filter.value) : alle.value));
const anzahl = (b) => alle.value.filter((c) => c.area === b).length;

const neu = ref('');
const auf = reactive({});
function hinzu() {
  if (!neu.value.trim()) return;
  const cid = addCompetitor(id.value, neu.value);
  if (filter.value) updateCompetitor(cid, { area: filter.value });
  auf[cid] = true;
  neu.value = '';
}
function feld(c, key, wert) {
  const v = key === 'name' ? wert.trim() : wert;
  if (key === 'name' && !v) return;
  if (v !== c[key]) updateCompetitor(c.id, { [key]: v });
}
function weg(c) {
  if (confirm(`„${c.name}“ entfernen?`)) deleteCompetitor(c.id);
}
const link = (u) => (/^https?:\/\//i.test(u) ? u : `https://${u}`);
const host = (u) => u.replace(/^https?:\/\//i, '').replace(/\/$/, '');
function text(key, wert) {
  if (wert !== (idea.value[key] ?? '')) updateIdea(id.value, { [key]: wert });
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link :to="`/fokus/${id}`" class="icon-btn" aria-label="Zur Arbeitsmappe"><Icon name="back" /></router-link>
      <h1 class="grow ellipsis">Konkurrenz</h1>
      <router-link to="/fokus" class="small more">Ideen-Fokus</router-link>
    </div>
  </header>

  <main v-if="!idea" class="page"><p class="empty">Diese Idee gibt es nicht (mehr).</p></main>

  <main v-else class="page">
    <div class="stack tight">
      <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>
      <p class="small muted">Wer bietet Ähnliches an, zu welchen Preisen, was machen sie gut oder schlecht? Grundlage für Preis-Check, Preiskalkulation und eure Abgrenzung.</p>
    </div>

    <label class="field">
      <span>Unsere Abgrenzung</span>
      <textarea class="textarea" rows="3" :value="idea.competition_edge ?? ''" placeholder="Was machen wir anders oder besser – Tempo, Preis, Rundum-Paket, persönlich vor Ort …?" @change="text('competition_edge', $event.target.value)"></textarea>
    </label>

    <section class="stack">
      <div class="row wrap">
        <h2 class="grow">Anbieter ({{ alle.length }})</h2>
      </div>
      <div v-if="bereiche.length" class="segmented wrap" role="group" aria-label="Bereich">
        <button type="button" :aria-pressed="filter === ''" @click="filter = ''">Alle</button>
        <button v-for="b in bereiche" :key="b" type="button" :aria-pressed="filter === b" @click="filter = b">{{ b }}<span v-if="anzahl(b)" class="cnt">{{ anzahl(b) }}</span></button>
      </div>

      <article v-for="c in liste" :key="c.id" class="card comp">
        <button v-if="!auf[c.id]" class="kurz" type="button" @click="auf[c.id] = true">
          <span class="grow">
            <span class="c-name">{{ c.name }}</span>
            <span class="c-tags">
              <span v-if="c.area" class="chip outline">{{ c.area }}</span>
              <span v-if="c.kind" class="chip">{{ c.kind }}</span>
            </span>
            <span v-if="c.prices" class="small"><span class="muted">Preise:</span> {{ c.prices }}</span>
            <span v-if="c.strengths" class="small plus">+ {{ c.strengths }}</span>
            <span v-if="c.weaknesses" class="small minus">– {{ c.weaknesses }}</span>
          </span>
          <Icon name="down" :size="18" />
        </button>

        <template v-else>
          <div class="row">
            <input class="input grow name" :value="c.name" aria-label="Name" @change="feld(c, 'name', $event.target.value)">
            <button class="icon-btn" type="button" aria-label="Zuklappen" @click="auf[c.id] = false"><Icon name="up" :size="18" /></button>
          </div>
          <div class="grid">
            <label class="field">
              <span>Link</span>
              <input class="input" inputmode="url" :value="c.url" placeholder="www.beispiel.de" @change="feld(c, 'url', $event.target.value.trim())">
            </label>
            <label class="field">
              <span>Bereich</span>
              <input class="input" :list="`bereiche-${c.id}`" :value="c.area" placeholder="z. B. Webseiten" @change="feld(c, 'area', $event.target.value.trim())">
              <datalist :id="`bereiche-${c.id}`"><option v-for="b in bereiche" :key="b" :value="b" /></datalist>
            </label>
            <label class="field">
              <span>Art</span>
              <input class="input" :list="`arten-${c.id}`" :value="c.kind" placeholder="z. B. Agentur" @change="feld(c, 'kind', $event.target.value.trim())">
              <datalist :id="`arten-${c.id}`"><option v-for="a in ARTEN" :key="a" :value="a" /></datalist>
            </label>
            <label class="field">
              <span>Preise</span>
              <input class="input" :value="c.prices" placeholder="z. B. Website ab 990 €, App 29 €/Monat" @change="feld(c, 'prices', $event.target.value)">
            </label>
          </div>
          <label class="field">
            <span>Stärken</span>
            <textarea class="textarea" rows="2" :value="c.strengths" @change="feld(c, 'strengths', $event.target.value)"></textarea>
          </label>
          <label class="field">
            <span>Schwächen</span>
            <textarea class="textarea" rows="2" :value="c.weaknesses" placeholder="z. B. aus Kundenbewertungen" @change="feld(c, 'weaknesses', $event.target.value)"></textarea>
          </label>
          <label class="field">
            <span>Notiz</span>
            <textarea class="textarea" rows="2" :value="c.note" @change="feld(c, 'note', $event.target.value)"></textarea>
          </label>
          <div class="row wrap foot">
            <a v-if="c.url" :href="link(c.url)" target="_blank" rel="noopener noreferrer" class="small">{{ host(c.url) }}</a>
            <span class="grow small muted">angelegt von {{ profile(c.created_by)?.name }}</span>
            <button class="btn danger" type="button" @click="weg(c)">Entfernen</button>
          </div>
        </template>
      </article>
      <p v-if="!liste.length" class="empty">{{ alle.length ? 'Kein Anbieter in diesem Bereich.' : 'Noch keine Anbieter erfasst.' }}</p>

      <form class="add" @submit.prevent="hinzu">
        <label class="visually-hidden" for="comp-neu">Neuer Anbieter</label>
        <input id="comp-neu" v-model="neu" class="input" :placeholder="filter ? `Neuer Anbieter im Bereich ${filter}` : 'Neuer Anbieter, z. B. Name der Agentur'">
        <button class="btn" type="submit" :disabled="!neu.trim()">Hinzufügen</button>
      </form>
    </section>

    <label class="field">
      <span>Allgemeine Notizen</span>
      <textarea class="textarea" rows="5" :value="idea.competition_notes ?? ''" placeholder="Marktbeobachtungen, Trends, Links …" @change="text('competition_notes', $event.target.value)"></textarea>
    </label>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.more { color: var(--accent); text-decoration: none; padding: 0 8px; }
.tight { gap: 8px; }
.idea-title { font-size: 20px; }
.segmented.wrap { flex-wrap: wrap; }
.cnt { margin-left: 6px; font-size: 12px; opacity: 0.7; }
.comp { display: flex; flex-direction: column; gap: 10px; }
.kurz { display: flex; align-items: flex-start; gap: 10px; border: 0; background: none; color: inherit; font: inherit; text-align: left; padding: 0; cursor: pointer; width: 100%; }
.kurz .grow { display: flex; flex-direction: column; gap: 4px; }
.c-name { font-weight: 600; font-size: 16px; }
.c-tags { display: flex; flex-wrap: wrap; gap: 6px; }
.plus { color: var(--ok); }
.minus { color: var(--danger); }
.name { font-weight: 600; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 8px; }
.foot { gap: 10px; align-items: center; }
.foot a { color: var(--accent); }
.add { display: grid; grid-template-columns: 1fr auto; gap: 8px; }
</style>
