<script setup>
// KI-Sparring zu einer Idee: kritische Einschätzung, Marktrecherche, Chat.
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { profile, state, toast } from '../lib/store.js';
import { activeCriteria, total } from '../lib/score.js';
import { relativ } from '../lib/format.js';
import { callKi, chatVon, ergebnisse, euro, kiSichtbar, ladeStatus, limitErreicht, markdown, starte } from '../lib/ki.js';
import { supabase } from '../lib/supabase.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const tabs = [
  { id: 'einschaetzung', label: 'Einschätzung' },
  { id: 'recherche', label: 'Recherche' },
  { id: 'chat', label: 'Chat' },
];
const tab = ref(tabs.some((t) => t.id === route.query.tab) ? route.query.tab : 'einschaetzung');
const error = ref('');
const busy = ref(false);
const frage = ref('');
const nachricht = ref('');

onMounted(ladeStatus);
const eingerichtet = computed(() => state.kiStatus?.configured !== false);
const gesperrt = computed(() => !state.online || !eingerichtet.value || limitErreicht.value || !kiSichtbar.value);
const sperrGrund = computed(() => {
  if (!kiSichtbar.value) return 'Du hast die KI ausgeschaltet (Einstellungen → KI-Unterstützung).';
  if (!eingerichtet.value) return 'Die KI ist noch nicht eingerichtet (Anleitung Teil E).';
  if (limitErreicht.value) return 'Das Monatslimit ist erreicht (Einstellungen → KI-Unterstützung).';
  if (!state.online) return 'Für die KI wird eine Internetverbindung benötigt.';
  return '';
});

const einschaetzungen = computed(() => ergebnisse(id.value, 'einschaetzung'));
const einschaetzung = computed(() => einschaetzungen.value[0] ?? null);
const recherchen = computed(() => ergebnisse(id.value, 'recherche'));
const recherche = computed(() => recherchen.value[0] ?? null);
const chat = computed(() => chatVon(id.value));

const kiBewertung = computed(() => {
  const c = einschaetzung.value?.content;
  if (!c?.bewertung) return [];
  const byId = Object.fromEntries(c.bewertung.map((b) => [b.faktor_id, b]));
  return activeCriteria().map((k) => ({ faktor: k, vorschlag: byId[k.id] ?? null }));
});
const kiPunkte = computed(() => {
  const map = {};
  for (const r of kiBewertung.value) if (r.vorschlag) map[r.faktor.id] = { score: r.vorschlag.punkte };
  return total(map);
});

async function los(action, body, text) {
  error.value = '';
  busy.value = true;
  try {
    await starte(action, { ideaId: id.value, ...body }, text);
  } catch (e) {
    error.value = e.message;
  } finally {
    busy.value = false;
  }
}
function senden() {
  const t = nachricht.value.trim();
  if (!t) return;
  nachricht.value = '';
  los('chat', { nachricht: t });
}
async function loeschen(r) {
  if (!confirm('Dieses KI-Ergebnis löschen?')) return;
  await supabase.from('ai_results').delete().eq('id', r.id);
  state.aiResults = state.aiResults.filter((x) => x.id !== r.id);
  toast('Gelöscht');
}
function wer(m) {
  return m.role === 'assistant' ? 'KI' : profile(m.profile_id)?.name ?? '';
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <button class="icon-btn" type="button" aria-label="Zurück" @click="router.push(`/idee/${id}`)"><Icon name="back" /></button>
      <h1 class="grow ellipsis">KI-Sparring</h1>
      <span class="chip ki">KI</span>
    </div>
  </header>

  <main v-if="!idea" class="page"><p class="empty">Diese Notiz gibt es nicht (mehr).</p></main>

  <main v-else class="page">
    <h2 class="idea-title">{{ idea.title || 'Ohne Titel' }}</h2>
    <div class="tabs" role="tablist" aria-label="KI-Funktion">
      <button v-for="t in tabs" :key="t.id" role="tab" type="button" :aria-selected="tab === t.id" @click="tab = t.id">{{ t.label }}</button>
    </div>
    <p v-if="sperrGrund" class="card small note">{{ sperrGrund }}</p>
    <p v-if="error" class="error">{{ error }}</p>

    <!-- Einschätzung -->
    <template v-if="tab === 'einschaetzung'">
      <p class="small muted">Die KI prüft die Notiz kritisch: Stärken, Schwächen, Risiken – getrennt nach Fakten, Schätzungen und Annahmen – und schlägt je Faktor eine Bewertung vor.</p>
      <button class="btn primary" type="button" :disabled="gesperrt || busy || einschaetzung?.status === 'laeuft'" @click="los('einschaetzung', {}, 'Einschätzung angefordert')">
        {{ einschaetzung ? 'Neu einschätzen lassen' : 'Kritisch einschätzen' }}
      </button>

      <div v-if="einschaetzung?.status === 'laeuft'" class="card working">Die KI denkt nach … das dauert meist 20–60 Sekunden. Du kannst die Seite verlassen.</div>
      <div v-else-if="einschaetzung?.status === 'fehler'" class="card error">{{ einschaetzung.error }}</div>
      <article v-else-if="einschaetzung?.content" class="card stack result">
        <div class="row head">
          <span class="chip ki">KI-Vorschlag</span>
          <span class="small muted grow">{{ relativ(einschaetzung.created_at) }} · {{ profile(einschaetzung.created_by)?.name }} · ca. {{ euro(einschaetzung.cost_eur) }}</span>
          <button class="icon-btn" type="button" aria-label="Löschen" @click="loeschen(einschaetzung)"><Icon name="trash" :size="18" /></button>
        </div>
        <p class="fazit">{{ einschaetzung.content.fazit }}</p>
        <div class="cols">
          <div><h3>Stärken</h3><ul><li v-for="(x, i) in einschaetzung.content.staerken" :key="i">{{ x }}</li></ul></div>
          <div><h3>Schwächen</h3><ul><li v-for="(x, i) in einschaetzung.content.schwaechen" :key="i">{{ x }}</li></ul></div>
          <div><h3>Risiken</h3><ul><li v-for="(x, i) in einschaetzung.content.risiken" :key="i">{{ x }}</li></ul></div>
        </div>
        <div class="cols">
          <div><h3>Fakten</h3><ul><li v-for="(x, i) in einschaetzung.content.fakten" :key="i">{{ x }}</li></ul></div>
          <div><h3>Schätzungen</h3><ul><li v-for="(x, i) in einschaetzung.content.schaetzungen" :key="i">{{ x }}</li></ul></div>
          <div><h3>Annahmen</h3><ul><li v-for="(x, i) in einschaetzung.content.annahmen" :key="i">{{ x }}</li></ul></div>
        </div>
        <div v-if="einschaetzung.content.offene_fragen?.length"><h3>Offene Fragen</h3><ul><li v-for="(x, i) in einschaetzung.content.offene_fragen" :key="i">{{ x }}</li></ul></div>
        <div>
          <h3>Bewertungsvorschlag der KI <span class="muted small">– fließt nicht in eure Wertung ein</span></h3>
          <p class="small muted">Gesamt nach eurer Gewichtung: <strong>{{ kiPunkte ?? '–' }}</strong> / 100</p>
          <div class="table">
            <div v-for="r in kiBewertung" :key="r.faktor.id" class="trow">
              <span class="name">{{ r.faktor.name }}</span>
              <strong class="pts">{{ r.vorschlag?.punkte ?? '–' }}</strong>
              <span class="small muted why">{{ r.vorschlag?.begruendung }}</span>
            </div>
          </div>
        </div>
      </article>
      <p v-if="einschaetzungen.length > 1" class="small muted">{{ einschaetzungen.length - 1 }} frühere Einschätzung(en) gespeichert.</p>
    </template>

    <!-- Recherche -->
    <template v-else-if="tab === 'recherche'">
      <p class="small muted">Marktrecherche mit aktuellen Webquellen: Marktgröße, Wettbewerber, Preise, rechtliche Hürden – mit Quellenangabe. Kostet etwas mehr (Websuche), meist 10–40 Cent.</p>
      <label class="field">
        <span>Besondere Frage (optional)</span>
        <input v-model="frage" class="input" placeholder="z. B. Gibt es das schon im Raum Augsburg?">
      </label>
      <button class="btn primary" type="button" :disabled="gesperrt || busy || recherche?.status === 'laeuft'" @click="los('recherche', { frage }, 'Recherche gestartet')">
        Recherche starten
      </button>
      <div v-if="recherche?.status === 'laeuft'" class="card working">Die KI recherchiert im Web … das dauert meist 1–2 Minuten. Du kannst die Seite verlassen.</div>
      <div v-else-if="recherche?.status === 'fehler'" class="card error">{{ recherche.error }}</div>
      <article v-else-if="recherche?.content" class="card stack result">
        <div class="row head">
          <span class="chip ki">KI-Recherche</span>
          <span class="small muted grow">{{ relativ(recherche.created_at) }} · {{ profile(recherche.created_by)?.name }} · ca. {{ euro(recherche.cost_eur) }}</span>
          <button class="icon-btn" type="button" aria-label="Löschen" @click="loeschen(recherche)"><Icon name="trash" :size="18" /></button>
        </div>
        <p v-if="recherche.prompt" class="small muted">Frage: {{ recherche.prompt }}</p>
        <div class="md" v-html="markdown(recherche.content.text)"></div>
        <div v-if="recherche.content.quellen?.length">
          <h3>Quellen</h3>
          <ol class="quellen">
            <li v-for="q in recherche.content.quellen" :key="q.url"><a :href="q.url" target="_blank" rel="noopener noreferrer">{{ q.title }}</a></li>
          </ol>
        </div>
      </article>
    </template>

    <!-- Chat -->
    <template v-else>
      <p class="small muted">Sparring zur Notiz. Der Verlauf ist für euch beide sichtbar.</p>
      <div class="chat">
        <div v-for="m in chat" :key="m.id" class="msg" :class="m.role">
          <span class="who small">{{ wer(m) }}</span>
          <div v-if="m.status === 'laeuft'" class="bubble muted">… denkt nach</div>
          <div v-else-if="m.role === 'assistant'" class="bubble md" :class="{ error: m.status === 'fehler' }" v-html="markdown(m.content)"></div>
          <div v-else class="bubble">{{ m.content }}</div>
        </div>
        <p v-if="!chat.length" class="empty">Noch keine Nachrichten. Frag die KI zum Beispiel: „Was ist der größte Denkfehler bei dieser Notiz?“</p>
      </div>
      <form class="composer" @submit.prevent="senden">
        <label class="visually-hidden" for="ki-msg">Nachricht an die KI</label>
        <textarea id="ki-msg" v-model="nachricht" rows="2" class="textarea" placeholder="Frage an die KI …" :disabled="gesperrt" @keydown.enter.meta.prevent="senden" @keydown.enter.ctrl.prevent="senden"></textarea>
        <button class="btn primary" type="submit" :disabled="gesperrt || busy || !nachricht.trim()">Senden</button>
      </form>
    </template>
  </main>
</template>

<style scoped>
p { margin: 0; }
.grow { flex: 1; min-width: 0; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.idea-title { font-size: 20px; }
.chip.ki { background: transparent; border: 1px solid var(--accent); color: var(--accent); font-weight: 600; }
.tabs { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 4px; padding: 4px; border-radius: 12px; background: var(--chip); max-width: 480px; }
.tabs button { height: 38px; border: 0; border-radius: 9px; background: transparent; color: var(--muted); font-weight: 500; cursor: pointer; }
.tabs button[aria-selected="true"] { background: var(--surface); color: var(--text); box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12); }
.note { border-color: var(--warn); }
.working { border-style: dashed; color: var(--muted); }
.result { border-color: var(--accent); }
.head { align-items: center; }
.fazit { font-size: 16px; font-weight: 500; }
.cols { display: grid; gap: 12px; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); }
h3 { font-size: 14px; font-weight: 600; margin: 0 0 4px; }
ul { margin: 0; padding-left: 18px; }
li { margin: 2px 0; }
.table { display: flex; flex-direction: column; border: 1px solid var(--line); border-radius: 10px; }
.trow { display: grid; grid-template-columns: minmax(0, 1fr) 28px; gap: 2px 10px; padding: 8px 12px; border-bottom: 1px solid var(--line); }
.trow:last-child { border-bottom: 0; }
.trow .why { grid-column: 1 / -1; }
.pts { text-align: right; }
.md :deep(h3) { font-size: 15px; margin: 14px 0 4px; }
.md :deep(p) { margin: 4px 0; }
.md :deep(ul) { margin: 4px 0; padding-left: 18px; }
.quellen { margin: 0; padding-left: 20px; font-size: 14px; overflow-wrap: anywhere; }
.chat { display: flex; flex-direction: column; gap: 12px; }
.msg { display: flex; flex-direction: column; gap: 2px; max-width: 92%; }
.msg.user { align-self: flex-end; align-items: flex-end; }
.who { color: var(--muted); }
.bubble { padding: 10px 14px; border-radius: 14px; background: var(--surface); border: 1px solid var(--line); white-space: pre-wrap; overflow-wrap: anywhere; }
.msg.user .bubble { background: var(--chip); }
.bubble.md { white-space: normal; }
.composer { display: flex; gap: 8px; align-items: flex-end; }
.composer .textarea { flex: 1; }
</style>
