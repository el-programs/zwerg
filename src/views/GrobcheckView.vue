<script setup>
// Phase 2a Grobcheck einer Idee: eigene Kriterien als Fragen, je Kriterium eine Ampel und eine Notiz,
// dazu ein Fazit. Die Idee wird für sich betrachtet, ohne Punkte und ohne Vergleich.
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { addCheck, AMPEL, checkSummary, checksOf, deleteCheck, profile, state, updateCheck, updateIdea } from '../lib/store.js';
import { relativ } from '../lib/format.js';
import VoteBox from '../components/VoteBox.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const checks = computed(() => checksOf(id.value));
const summe = computed(() => checkSummary(id.value));
const neu = ref('');
const bearbeiten = ref(null);

function hinzufuegen() {
  if (!neu.value.trim()) return;
  addCheck(id.value, neu.value);
  neu.value = '';
}
function frageSpeichern(c, text) {
  if (text.trim() && text.trim() !== c.question) updateCheck(c.id, { question: text.trim().slice(0, 500) });
  bearbeiten.value = null;
}
function entfernen(c) {
  if (!confirm(`Kriterium „${c.question}“ entfernen?`)) return;
  deleteCheck(c.id);
  bearbeiten.value = null;
}
function setStatus(c, status) {
  if (c.status !== status) updateCheck(c.id, { status });
}
function notiz(c, text) {
  if (text !== c.note) updateCheck(c.id, { note: text });
}
function fazit(text) {
  if (text !== (idea.value.check_fazit ?? '')) updateIdea(id.value, { check_fazit: text });
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link :to="idea && idea.phase >= 2 ? `/fokus/${id}` : `/idee/${id}`" class="icon-btn" aria-label="Zurück"><Icon name="back" /></router-link>
      <h1 class="grow ellipsis">Grobcheck</h1>
      <router-link to="/fokus" class="small more">Ideen-Fokus</router-link>
    </div>
  </header>

  <main v-if="!idea" class="page"><p class="empty">Diese Idee gibt es nicht (mehr).</p></main>

  <main v-else class="page">
    <div class="stack tight">
      <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>
      <p class="small muted">
        Phase 2a: Schätzt jedes Kriterium mit der Ampel ein und haltet in der Notiz fest, wie ihr darüber denkt und woher ihr es wisst.
        Die Idee wird für sich betrachtet – Kriterien könnt ihr jederzeit ergänzen, ändern oder entfernen.
      </p>
    </div>

    <div class="card summary">
      <span class="sum-chips">
        <span class="sum gut"><span class="dot"></span>{{ summe.gut }} gut</span>
        <span class="sum schwierig"><span class="dot"></span>{{ summe.schwierig }} schwierig</span>
        <span class="sum ko"><span class="dot"></span>{{ summe.ko }} KO</span>
        <span class="sum offen"><span class="dot"></span>{{ summe.offen }} offen</span>
      </span>
      <span class="sum-votes"><span class="small muted">Bauchgefühl</span><VoteBox :idea-id="idea.id" /></span>
    </div>

    <ol class="checks">
      <li v-for="(c, n) in checks" :key="c.id" :class="['card', 'check', c.status]">
        <div class="q-row">
          <span class="nr">{{ n + 1 }}</span>
          <input
            v-if="bearbeiten === c.id"
            class="input grow"
            :value="c.question"
            aria-label="Kriterium"
            @change="frageSpeichern(c, $event.target.value)"
            @keydown.enter.prevent="$event.target.blur()"
          >
          <p v-else class="question grow">{{ c.question }}</p>
          <button v-if="bearbeiten === c.id" class="icon-btn" type="button" aria-label="Kriterium entfernen" @click="entfernen(c)"><Icon name="trash" :size="18" /></button>
          <button class="link-btn small" type="button" @click="bearbeiten = bearbeiten === c.id ? null : c.id">{{ bearbeiten === c.id ? 'Fertig' : 'Ändern' }}</button>
        </div>
        <div class="ampel" role="radiogroup" :aria-label="c.question">
          <button
            v-for="a in AMPEL"
            :key="a.id"
            type="button"
            role="radio"
            :class="['amp', a.id]"
            :aria-checked="c.status === a.id"
            @click="setStatus(c, a.id)"
          ><span class="dot"></span>{{ a.label }}</button>
        </div>
        <label class="field">
          <span class="visually-hidden">Notiz</span>
          <textarea
            class="textarea"
            rows="2"
            :value="c.note"
            placeholder="Wie denken wir darüber? Woher wissen wir das?"
            @change="notiz(c, $event.target.value)"
          ></textarea>
        </label>
        <span v-if="c.updated_by" class="small muted">zuletzt {{ profile(c.updated_by)?.name }}, {{ relativ(c.updated_at) }}</span>
      </li>
    </ol>
    <p v-if="!checks.length" class="empty">Noch keine Kriterien. Legt unten das erste als Frage an.</p>

    <form class="add" @submit.prevent="hinzufuegen">
      <label class="visually-hidden" for="check-neu">Neues Kriterium</label>
      <input id="check-neu" v-model="neu" class="input" placeholder="Neues Kriterium als Frage, z. B. „Gibt es Förderung?“">
      <button class="btn" type="submit" :disabled="!neu.trim()">Hinzufügen</button>
    </form>

    <section class="stack">
      <h2>Unser Fazit</h2>
      <textarea
        class="textarea"
        rows="5"
        :value="idea.check_fazit ?? ''"
        placeholder="Was kommt auf uns zu? Wie würde die Idee aussehen? Was spricht dafür, was dagegen?"
        @change="fazit($event.target.value)"
      ></textarea>
    </section>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.more { color: var(--accent); text-decoration: none; padding: 0 8px; }
.tight { gap: 8px; }
.idea-title { font-size: 20px; }
.summary { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 10px; }
.sum-chips { display: flex; flex-wrap: wrap; gap: 12px; font-size: 14px; }
.sum { display: inline-flex; align-items: center; gap: 6px; }
.sum-votes { display: inline-flex; align-items: center; gap: 8px; }
.dot { width: 12px; height: 12px; border-radius: 50%; flex: none; border: 2px solid transparent; }
.gut .dot { background: var(--ok); }
.schwierig .dot { background: var(--warn); }
.ko .dot { background: var(--danger); }
.offen .dot { background: transparent; border-color: var(--muted); }
.checks { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.check { display: flex; flex-direction: column; gap: 10px; border-left-width: 4px; }
.check.gut { border-left-color: var(--ok); }
.check.schwierig { border-left-color: var(--warn); }
.check.ko { border-left-color: var(--danger); }
.q-row { display: flex; align-items: flex-start; gap: 8px; }
.nr { color: var(--muted); font-weight: 600; min-width: 18px; padding-top: 1px; }
.question { font-weight: 600; line-height: 1.35; }
.link-btn { border: 0; background: none; padding: 2px 0; color: var(--accent); cursor: pointer; white-space: nowrap; }
.ampel { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 6px; }
.amp { display: inline-flex; align-items: center; justify-content: center; gap: 6px; min-height: 40px; padding: 4px 6px; border: 1px solid var(--line); border-radius: 10px; background: var(--surface); color: var(--muted); font: inherit; font-size: 13px; cursor: pointer; text-align: center; }
.amp[aria-checked="true"] { color: var(--text); font-weight: 600; background: var(--chip); }
.amp.gut[aria-checked="true"] { border-color: var(--ok); }
.amp.schwierig[aria-checked="true"] { border-color: var(--warn); }
.amp.ko[aria-checked="true"] { border-color: var(--danger); }
.amp.offen[aria-checked="true"] { border-color: var(--muted); }
@media (max-width: 520px) { .ampel { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
.add { display: grid; grid-template-columns: 1fr auto; gap: 8px; }
</style>
