<script setup>
// Druckfertige Berichte: Projektbericht oder Steckbrief einer Idee. „Als PDF speichern“ öffnet den Druckdialog.
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { currentPhase, fieldName, profile, state } from '../lib/store.js';
import {
  activeCriteria, effectiveWeight, ideaResult, jointScores, personalScores, rankedIdeas, RESULT_LABEL,
} from '../lib/score.js';
import { eur, prozent, rechne, SZENARIEN } from '../lib/business.js';
import { datum, phaseName as standardPhase } from '../lib/format.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const ideaId = computed(() => route.params.id ?? null);
const idea = computed(() => state.ideas.find((i) => i.id === ideaId.value));
const stand = new Date().toLocaleDateString('de-DE', { day: 'numeric', month: 'long', year: 'numeric' });
const namen = computed(() => state.profiles.map((p) => p.name).join(' & '));
const phaseName = (nr) => state.phases.find((p) => p.nr === nr)?.name ?? standardPhase(nr);
const ideaTitle = (id) => state.ideas.find((i) => i.id === id)?.title || 'Ohne Titel';
const kriterien = computed(() => activeCriteria());
const gewicht = (c) => (Math.round(effectiveWeight(c) * 10) / 10).toLocaleString('de-DE');

// Projektbericht
const phasen = computed(() => [...state.phases].sort((a, b) => a.nr - b.nr));
const ranking = computed(() => rankedIdeas());
const offeneAufgaben = computed(() =>
  state.tasks.filter((t) => t.status !== 'erledigt').sort((a, b) => ((a.due_date ?? '9') < (b.due_date ?? '9') ? -1 : 1)),
);
const entscheidungen = computed(() =>
  state.decisions.filter((d) => !ideaId.value || d.idea_id === ideaId.value).sort((a, b) => (a.decided_on < b.decided_on ? 1 : -1)),
);
const geparkt = computed(() => state.ideas.filter((i) => i.status === 'geparkt'));

// Steckbrief
const ergebnis = computed(() => (idea.value ? ideaResult(idea.value.id) : null));
const bewertung = computed(() => {
  if (!idea.value) return [];
  const joint = jointScores(idea.value.id);
  const pers = state.profiles.map((p) => personalScores(idea.value.id, p.id));
  return kriterien.value.map((c) => ({ c, pers: pers.map((m) => m[c.id]?.score ?? '–'), joint: joint[c.id]?.score ?? '–' }));
});
const bc = computed(() => state.businessCases.find((b) => b.idea_id === ideaId.value));
const szenarien = computed(() => SZENARIEN.map((s) => ({ ...s, r: rechne(bc.value?.scenarios?.[s.id]) })));
const feedback = computed(() => state.feedback.filter((f) => f.idea_id === ideaId.value).sort((a, b) => (a.held_on < b.held_on ? 1 : -1)));
function schnitt(key) {
  const v = feedback.value.map((f) => f[key]).filter(Boolean);
  return v.length ? (v.reduce((a, b) => a + b, 0) / v.length).toLocaleString('de-DE', { maximumFractionDigits: 1 }) : '–';
}
const ideeAufgaben = computed(() => state.tasks.filter((t) => t.idea_id === ideaId.value));

function zurueck() {
  if (window.history.length > 1) router.back();
  else router.push(ideaId.value ? `/idee/${ideaId.value}` : '/mehr');
}
function drucken() {
  window.print();
}
</script>

<template>
  <header class="topbar no-print">
    <div class="topbar-inner">
      <button class="icon-btn" type="button" aria-label="Zurück" @click="zurueck"><Icon name="back" /></button>
      <h1 class="grow">{{ ideaId ? 'Steckbrief' : 'Projektbericht' }}</h1>
      <button class="btn primary print-btn" type="button" @click="drucken">Als PDF speichern</button>
    </div>
  </header>
  <main class="page">
    <p class="small muted no-print">Im Druckfenster „Als PDF speichern“ wählen. Am iPhone: Teilen-Symbol im Druckfenster → „In Dateien sichern“.</p>

    <p v-if="ideaId && !idea" class="empty">Diese Idee gibt es nicht (mehr).</p>

    <!-- Steckbrief einer Idee -->
    <article v-else-if="idea" class="report">
      <header class="r-head">
        <span class="r-brand">Zwerg · Steckbrief</span>
        <span>Stand {{ stand }} · {{ namen }}</span>
      </header>
      <h1>{{ idea.title || 'Ohne Titel' }}</h1>
      <p class="r-meta">
        Phase {{ idea.phase }} · {{ phaseName(idea.phase) }}
        <template v-if="idea.search_field_id"> · Suchfeld: {{ fieldName(idea.search_field_id) }}</template>
        <template v-if="idea.status === 'geparkt'"> · geparkt</template>
        <template v-if="idea.is_favorite"> · Favorit</template>
        · angelegt von {{ profile(idea.created_by)?.name }} am {{ datum(idea.created_at) }}
      </p>
      <p v-if="idea.description" class="r-text">{{ idea.description }}</p>
      <p v-if="idea.tags?.length" class="r-meta">Schlagworte: {{ idea.tags.join(', ') }}</p>
      <p v-if="idea.status === 'geparkt' && idea.park_reason" class="r-text"><strong>Parkgrund:</strong> {{ idea.park_reason }}</p>

      <h2>Bewertung</h2>
      <p class="r-score">
        <strong>{{ ergebnis.score ?? '–' }}</strong> / 100 · {{ RESULT_LABEL[ergebnis.kind] }}<template v-if="ergebnis.ko"> · <span class="r-ko">KO-Kriterium zutreffend</span></template>
      </p>
      <table v-if="bewertung.length">
        <thead><tr><th>Faktor</th><th class="num">Gewicht</th><th v-for="p in state.profiles" :key="p.id" class="num">{{ p.kuerzel }}</th><th class="num">Gemeinsam</th></tr></thead>
        <tbody>
          <tr v-for="row in bewertung" :key="row.c.id">
            <td>{{ row.c.name }}</td><td class="num">{{ gewicht(row.c) }}</td>
            <td v-for="(v, n) in row.pers" :key="n" class="num">{{ v }}</td><td class="num">{{ row.joint }}</td>
          </tr>
        </tbody>
      </table>
      <p class="r-note">Punkte je Faktor 1–5 (5 = gut für uns), Gewicht 0–5. Gesamtwert = gewichteter Durchschnitt, umgerechnet auf 0–100.</p>

      <template v-if="bc">
        <h2>Business Case</h2>
        <table>
          <thead><tr><th></th><th v-for="s in szenarien" :key="s.id" class="num">{{ s.name }}</th></tr></thead>
          <tbody>
            <tr><td>Umsatz pro Monat</td><td v-for="s in szenarien" :key="s.id" class="num">{{ eur(s.r?.umsatzMonat) }}</td></tr>
            <tr><td>Deckungsbeitrag je {{ bc.unit || 'Einheit' }}</td><td v-for="s in szenarien" :key="s.id" class="num">{{ eur(s.r?.dbEinheit, 2) }}</td></tr>
            <tr><td>Marge</td><td v-for="s in szenarien" :key="s.id" class="num">{{ prozent(s.r?.marge) }}</td></tr>
            <tr><td>Ergebnis pro Monat</td><td v-for="s in szenarien" :key="s.id" class="num">{{ eur(s.r?.gewinnMonat) }}</td></tr>
            <tr><td>Ergebnis pro Jahr</td><td v-for="s in szenarien" :key="s.id" class="num">{{ eur(s.r?.gewinnJahr) }}</td></tr>
            <tr><td>Break-even ({{ bc.unit || 'Einheiten' }}/Monat)</td><td v-for="s in szenarien" :key="s.id" class="num">{{ s.r?.breakEven ?? '–' }}</td></tr>
            <tr><td>Amortisation (Monate)</td><td v-for="s in szenarien" :key="s.id" class="num">{{ s.r?.amortisation ?? '–' }}</td></tr>
          </tbody>
        </table>
        <p v-if="bc.notes" class="r-text">{{ bc.notes }}</p>
      </template>

      <template v-if="feedback.length">
        <h2>Pilot-Feedback</h2>
        <p class="r-meta">{{ feedback.length }} Einträge · Ø Problem spürbar {{ schnitt('problem') }} · Ø Kaufinteresse {{ schnitt('interest') }}</p>
        <div v-for="f in feedback" :key="f.id" class="r-entry">
          <strong>{{ datum(f.held_on) }}<template v-if="f.contact"> · {{ f.contact }}</template></strong>
          <p v-if="f.summary" class="r-text">{{ f.summary }}</p>
          <p v-if="f.quote" class="r-quote">„{{ f.quote }}“</p>
          <p v-if="f.learnings" class="r-text"><em>Erkenntnis:</em> {{ f.learnings }}</p>
        </div>
      </template>

      <template v-if="entscheidungen.length">
        <h2>Entscheidungen</h2>
        <div v-for="d in entscheidungen" :key="d.id" class="r-entry">
          <strong>{{ datum(d.decided_on) }} · {{ d.title }}</strong>
          <p v-if="d.reason" class="r-text">Begründung: {{ d.reason }}</p>
        </div>
      </template>

      <template v-if="ideeAufgaben.length">
        <h2>Aufgaben</h2>
        <table>
          <thead><tr><th>Aufgabe</th><th>Wer</th><th>Fällig</th><th>Status</th></tr></thead>
          <tbody>
            <tr v-for="t in ideeAufgaben" :key="t.id"><td>{{ t.title }}</td><td>{{ profile(t.assignee)?.kuerzel }}</td><td>{{ t.due_date ? datum(t.due_date) : '–' }}</td><td>{{ t.status === 'erledigt' ? 'erledigt' : t.status === 'in_arbeit' ? 'in Arbeit' : 'offen' }}</td></tr>
          </tbody>
        </table>
      </template>
    </article>

    <!-- Projektbericht -->
    <article v-else class="report">
      <header class="r-head">
        <span class="r-brand">Zwerg · Projektbericht</span>
        <span>Stand {{ stand }} · {{ namen }}</span>
      </header>
      <h1>Unser Weg zur Gründung</h1>
      <p class="r-meta">Aktuell in Phase {{ currentPhase() }} · {{ phaseName(currentPhase()) }} · {{ ranking.bewertet.length + ranking.ko.length + ranking.offen.length }} aktive Ideen, {{ geparkt.length }} geparkt</p>

      <h2>Phasen</h2>
      <div v-for="p in phasen" :key="p.nr" class="r-entry">
        <strong>{{ p.nr }} · {{ p.name }}<template v-if="p.nr === currentPhase()"> (aktuell)</template></strong>
        <p class="r-text">Ziel: {{ p.goal }} – Ergebnis: {{ p.result }}</p>
        <ul class="r-list">
          <li v-for="c in p.criteria" :key="c.id">{{ c.done ? '☑' : '☐' }} {{ c.text }}</li>
        </ul>
      </div>

      <h2>Ranking</h2>
      <table v-if="ranking.bewertet.length || ranking.ko.length">
        <thead><tr><th class="num">#</th><th>Idee</th><th class="num">Punkte</th><th>Stand</th><th>Phase</th></tr></thead>
        <tbody>
          <tr v-for="(r, n) in ranking.bewertet" :key="r.idea.id">
            <td class="num">{{ n + 1 }}</td><td>{{ r.idea.title || 'Ohne Titel' }}<template v-if="r.idea.is_favorite"> ★</template></td>
            <td class="num">{{ r.result.score }}</td><td>{{ RESULT_LABEL[r.result.kind] }}</td><td>{{ r.idea.phase }}</td>
          </tr>
          <tr v-for="r in ranking.ko" :key="r.idea.id" class="r-dim">
            <td class="num">KO</td><td>{{ r.idea.title || 'Ohne Titel' }}</td><td class="num">{{ r.result.score ?? '–' }}</td><td>KO-Kriterium</td><td>{{ r.idea.phase }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else class="r-text">Noch keine bewerteten Ideen.</p>
      <p v-if="ranking.offen.length" class="r-meta">Noch nicht bewertet: {{ ranking.offen.map((r) => r.idea.title || 'Ohne Titel').join(', ') }}</p>

      <h2>Bewertungsfaktoren und Gewichtung</h2>
      <table>
        <thead><tr><th>Faktor</th><th class="num">Gewicht (0–5)</th></tr></thead>
        <tbody><tr v-for="c in kriterien" :key="c.id"><td>{{ c.name }}</td><td class="num">{{ gewicht(c) }}</td></tr></tbody>
      </table>

      <template v-if="entscheidungen.length">
        <h2>Entscheidungen</h2>
        <div v-for="d in entscheidungen" :key="d.id" class="r-entry">
          <strong>{{ datum(d.decided_on) }} · {{ d.title }}</strong>
          <span class="r-meta"> – {{ profile(d.created_by)?.name }}<template v-if="d.idea_id"> · {{ ideaTitle(d.idea_id) }}</template></span>
          <p v-if="d.reason" class="r-text">Begründung: {{ d.reason }}</p>
        </div>
      </template>

      <template v-if="offeneAufgaben.length">
        <h2>Offene Aufgaben</h2>
        <table>
          <thead><tr><th>Aufgabe</th><th>Wer</th><th>Fällig</th><th>Idee</th></tr></thead>
          <tbody>
            <tr v-for="t in offeneAufgaben" :key="t.id"><td>{{ t.title }}</td><td>{{ profile(t.assignee)?.kuerzel }}</td><td>{{ t.due_date ? datum(t.due_date) : '–' }}</td><td>{{ t.idea_id ? ideaTitle(t.idea_id) : '' }}</td></tr>
          </tbody>
        </table>
      </template>

      <template v-if="geparkt.length">
        <h2>Parkplatz</h2>
        <div v-for="i in geparkt" :key="i.id" class="r-entry">
          <strong>{{ i.title || 'Ohne Titel' }}</strong>
          <p v-if="i.park_reason" class="r-text">{{ i.park_reason }}</p>
        </div>
      </template>
    </article>
  </main>
</template>

<style scoped>
.grow { flex: 1; min-width: 0; }
.print-btn { min-height: 38px; padding: 0 14px; font-size: 14px; }
/* Der Bericht sieht auch am Bildschirm wie Papier aus – unabhängig vom dunklen Modus. */
.report {
  background: #fff;
  color: #1c1d1f;
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 28px 30px;
  font-size: 13.5px;
  line-height: 1.5;
}
.report h1 { font-size: 24px; margin: 6px 0 4px; }
.report h2 { font-size: 16px; margin: 22px 0 8px; padding-bottom: 4px; border-bottom: 1.5px solid #c96f3b; break-after: avoid; }
.r-head { display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; font-size: 11.5px; color: #66686d; }
.r-brand { font-weight: 600; color: #c96f3b; letter-spacing: 0.02em; }
.r-meta { color: #55575c; margin: 4px 0; font-size: 12.5px; }
.r-text { margin: 4px 0; white-space: pre-wrap; }
.r-note { color: #6b6d72; font-size: 11.5px; margin: 6px 0 0; }
.r-score { font-size: 15px; margin: 0 0 8px; }
.r-score strong { font-size: 22px; }
.r-ko { color: #b3261e; font-weight: 600; }
.r-entry { margin: 8px 0 10px; break-inside: avoid; }
.r-quote { margin: 4px 0; font-style: italic; color: #3d3f44; }
.r-list { margin: 4px 0 0; padding-left: 4px; list-style: none; }
.r-dim td { color: #77797e; }
table { width: 100%; border-collapse: collapse; font-size: 12.5px; break-inside: auto; }
th, td { text-align: left; padding: 5px 8px; border-bottom: 1px solid #e3e3e0; vertical-align: top; }
th { font-weight: 600; color: #4a4c51; background: #f5f5f2; }
tr { break-inside: avoid; }
.num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
@media (max-width: 560px) {
  .report { padding: 18px 14px; }
  table { font-size: 11.5px; }
  th, td { padding: 4px 5px; }
}
</style>

<style>
/* Druck: nur der Bericht, ohne Navigation, auf weißem A4. */
@media print {
  @page { size: A4; margin: 16mm 14mm; }
  html, body { background: #fff !important; }
  .nav, .toast, .fatal, .no-print, .backdrop, .sheet { display: none !important; }
  .with-side { padding-left: 0 !important; }
  .page { padding: 0 !important; max-width: none !important; }
  .report { border: 0 !important; padding: 0 !important; border-radius: 0 !important; }
}
</style>
