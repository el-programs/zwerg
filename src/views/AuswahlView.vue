<script setup>
// Phase 2: Auswahl. 2a – jede Idee für sich (Ampeln, Fazit, Bauchgefühl), dann Favorit und Nachrücker festlegen.
// 2b – den Favoriten prüfen: Go (Phase 3) oder No-Go (verwerfen, der nächste Nachrücker rückt nach).
import { computed, ref } from 'vue';
import {
  addDecision, checkSummary, modelName, phase2Ideas, setIdeaPhase, setSelection, state, toast,
} from '../lib/store.js';
import VoteBox from '../components/VoteBox.vue';
import Icon from '../components/Icon.vue';
import MeLink from '../components/MeLink.vue';

const titel = (i) => i.title || 'Ohne Titel';
const alle = computed(() => phase2Ideas());
const imRennen = computed(() =>
  alle.value
    .filter((i) => i.selection !== 'verworfen' && i.phase === 2)
    .sort((a, b) => ordnung(a) - ordnung(b) || titel(a).localeCompare(titel(b), 'de')),
);
const verworfen = computed(() => alle.value.filter((i) => i.selection === 'verworfen'));
const weiter = computed(() => alle.value.filter((i) => i.phase >= 3 && i.selection !== 'verworfen'));
const favorit = computed(() => imRennen.value.find((i) => i.selection === 'favorit') ?? null);
const nachruecker = computed(() => imRennen.value.filter((i) => i.selection === 'nachruecker').sort((a, b) => (a.selection_rank ?? 9) - (b.selection_rank ?? 9)));
const begruendung = ref('');

function ordnung(i) {
  if (i.selection === 'favorit') return 0;
  if (i.selection === 'nachruecker') return i.selection_rank ?? 5;
  return 10;
}
function rolleWert(i) {
  if (i.selection === 'favorit') return 'favorit';
  if (i.selection === 'nachruecker') return `n${i.selection_rank ?? 1}`;
  return '';
}
function rolleSetzen(i, wert) {
  if (wert === 'favorit') {
    if (favorit.value && favorit.value.id !== i.id) setSelection(favorit.value.id, null);
    setSelection(i.id, 'favorit');
  } else if (wert.startsWith('n')) {
    setSelection(i.id, 'nachruecker', { rank: Number(wert.slice(1)) });
  } else {
    setSelection(i.id, null);
  }
}
const ampel = (i) => checkSummary(i.id);

function festhalten() {
  if (!favorit.value) return;
  const teile = [`Favorit: ${titel(favorit.value)}`];
  if (nachruecker.value.length) teile.push(`Nachrücker: ${nachruecker.value.map((i, n) => `${n + 1}. ${titel(i)}`).join(', ')}`);
  addDecision({ title: `Auswahl Phase 2 – ${teile.join(' · ')}`, reason: begruendung.value.trim(), idea_id: favorit.value.id, phase: 2 });
  begruendung.value = '';
  toast('Auswahl im Protokoll festgehalten');
}

function go(i) {
  if (!confirm(`„${titel(i)}“ hat die Machbarkeitsprüfung bestanden und geht in Phase 3?`)) return;
  setIdeaPhase(i.id, 3);
  addDecision({ title: `Machbarkeitsprüfung bestanden: „${titel(i)}“ geht in Phase 3`, idea_id: i.id, phase: 2 });
  toast('Idee ist in Phase 3');
}

function noGo(i) {
  const grund = prompt(`Warum ist „${titel(i)}“ nicht oder nur schwer umsetzbar?`);
  if (grund === null) return;
  const reste = nachruecker.value.filter((x) => x.id !== i.id);
  const naechster = reste[0] ?? null;
  setSelection(i.id, 'verworfen', { note: grund.trim() });
  addDecision({ title: `Machbarkeitsprüfung: „${titel(i)}“ verworfen`, reason: grund.trim(), idea_id: i.id, phase: 2 });
  if (naechster && confirm(`„${titel(naechster)}“ als neuen Favoriten für die Machbarkeitsprüfung übernehmen?`)) {
    setSelection(naechster.id, 'favorit');
    reste.slice(1).forEach((x, n) => setSelection(x.id, 'nachruecker', { rank: n + 1 }));
    addDecision({ title: `Nachrücker „${titel(naechster)}“ ist neuer Favorit`, idea_id: naechster.id, phase: 2 });
  }
  toast('Idee nach der Prüfung verworfen');
}

function zurueckholen(i) {
  setSelection(i.id, null, { note: '' });
  toast('Idee ist wieder im Grobcheck');
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link to="/phasen" class="icon-btn" aria-label="Zum Plan"><Icon name="back" /></router-link>
      <h1 class="grow">Auswahl</h1>
      <MeLink />
    </div>
  </header>

  <main class="page">
    <div class="card intro small">
      <p><strong>2a Grobcheck:</strong> Jede Idee für sich mit ihren Kriterien einschätzen (Ampel, Notiz, Fazit). Dann Favorit und Nachrücker festlegen – nach Ampeln oder Bauchgefühl.</p>
      <p><strong>2b Machbarkeitsprüfung:</strong> Nur den Favoriten genau prüfen. Go → Phase 3. No-Go → verwerfen, der nächste Nachrücker rückt nach.</p>
    </div>

    <p v-if="!imRennen.length && !verworfen.length" class="empty">Noch keine Idee in Phase 2. In der Auswertung mit „→ Phase 2“ übernehmen.</p>

    <article v-for="i in imRennen" :key="i.id" :class="['card', 'kand', { fav: i.selection === 'favorit' }]">
      <div class="k-head">
        <div class="grow">
          <span v-if="modelName(i.business_model_id)" class="k-model">{{ modelName(i.business_model_id) }}</span>
          <router-link :to="`/idee/${i.id}`" class="k-title">{{ titel(i) }}</router-link>
        </div>
        <span v-if="i.selection === 'favorit'" class="chip fav-chip">Favorit · 2b</span>
        <span v-else-if="i.selection === 'nachruecker'" class="chip outline">Nachrücker {{ i.selection_rank }}</span>
      </div>

      <div class="ampel-bar" :title="`${ampel(i).gut} gut, ${ampel(i).schwierig} schwierig, ${ampel(i).ko} KO, ${ampel(i).offen} offen`">
        <span v-for="k in ['gut', 'schwierig', 'ko', 'offen']" :key="k" :class="['seg', k]" :style="{ flex: ampel(i)[k] }"></span>
      </div>
      <div class="k-sum small">
        <span class="s gut"><span class="dot"></span>{{ ampel(i).gut }} gut</span>
        <span class="s schwierig"><span class="dot"></span>{{ ampel(i).schwierig }} schwierig</span>
        <span class="s ko"><span class="dot"></span>{{ ampel(i).ko }} KO</span>
        <span class="s offen"><span class="dot"></span>{{ ampel(i).offen }} offen</span>
      </div>

      <p v-if="i.check_fazit" class="fazit small">{{ i.check_fazit }}</p>
      <p v-else class="small muted">Noch kein Fazit.</p>

      <div class="k-actions">
        <router-link :to="`/idee/${i.id}/grobcheck`" class="btn">Grobcheck öffnen</router-link>
        <VoteBox :idea-id="i.id" />
        <span class="grow"></span>
        <label class="field rolle">
          <span class="visually-hidden">Rolle</span>
          <select class="select" :value="rolleWert(i)" @change="rolleSetzen(i, $event.target.value)">
            <option value="">im Grobcheck</option>
            <option value="favorit">Favorit (2b prüfen)</option>
            <option value="n1">Nachrücker 1</option>
            <option value="n2">Nachrücker 2</option>
            <option value="n3">Nachrücker 3</option>
          </select>
        </label>
      </div>

      <div v-if="i.selection === 'favorit'" class="row wrap entscheid">
        <span class="small muted grow">Machbarkeitsprüfung (2b) – wie ist das Ergebnis?</span>
        <button class="btn primary" type="button" @click="go(i)">Go → Phase 3</button>
        <button class="btn danger" type="button" @click="noGo(i)">No-Go, verwerfen</button>
      </div>
    </article>

    <section v-if="favorit" class="card stack">
      <h2>Auswahl festhalten</h2>
      <p class="small muted">Favorit: <strong>{{ titel(favorit) }}</strong><template v-if="nachruecker.length"> · Nachrücker: {{ nachruecker.map((i, n) => `${n + 1}. ${titel(i)}`).join(', ') }}</template></p>
      <textarea v-model="begruendung" class="textarea" rows="3" placeholder="Warum diese Reihenfolge? Ampeln, Fazit, Bauchgefühl …"></textarea>
      <button class="btn primary" type="button" @click="festhalten">Im Protokoll festhalten</button>
    </section>

    <section v-if="weiter.length" class="stack">
      <h2>In Phase 3</h2>
      <router-link v-for="i in weiter" :key="i.id" :to="`/idee/${i.id}`" class="card done-row">{{ titel(i) }}<span class="chip outline">Phase {{ i.phase }}</span></router-link>
    </section>

    <section v-if="verworfen.length" class="stack">
      <h2>Nach der Prüfung verworfen</h2>
      <div v-for="i in verworfen" :key="i.id" class="card stack tight">
        <router-link :to="`/idee/${i.id}`" class="k-title">{{ titel(i) }}</router-link>
        <p class="small"><span class="muted">Begründung:</span> {{ i.selection_note || '–' }}</p>
        <button class="btn" type="button" @click="zurueckholen(i)">Zurück in den Grobcheck</button>
      </div>
    </section>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.tight { gap: 8px; }
.intro { display: flex; flex-direction: column; gap: 6px; }
.kand { display: flex; flex-direction: column; gap: 10px; }
.kand.fav { border-color: var(--accent); border-width: 2px; }
.k-head { display: flex; align-items: flex-start; gap: 8px; }
.k-model { display: block; font-size: 11.5px; text-transform: uppercase; letter-spacing: 0.05em; color: var(--accent); }
.k-title { font-weight: 600; font-size: 17px; color: inherit; text-decoration: none; }
.chip.fav-chip { background: var(--accent); color: var(--on-accent); font-weight: 600; }
.ampel-bar { display: flex; height: 8px; border-radius: 4px; overflow: hidden; background: var(--chip); gap: 2px; }
.seg.gut { background: var(--ok); }
.seg.schwierig { background: var(--warn); }
.seg.ko { background: var(--danger); }
.seg.offen { background: var(--line); }
.k-sum { display: flex; flex-wrap: wrap; gap: 12px; }
.s { display: inline-flex; align-items: center; gap: 5px; }
.dot { width: 10px; height: 10px; border-radius: 50%; border: 2px solid transparent; }
.s.gut .dot { background: var(--ok); }
.s.schwierig .dot { background: var(--warn); }
.s.ko .dot { background: var(--danger); }
.s.offen .dot { border-color: var(--muted); }
.fazit { white-space: pre-line; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.k-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; }
.rolle { min-width: 190px; }
.entscheid { gap: 8px; padding-top: 10px; border-top: 1px solid var(--line); }
.done-row { display: flex; align-items: center; justify-content: space-between; text-decoration: none; color: inherit; }
</style>
