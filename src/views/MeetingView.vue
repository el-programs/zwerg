<script setup>
// Eine Besprechung: Kopfdaten, Tagesordnungspunkte mit Notiz und Ergebnis, daraus Aufgaben und Entscheidungen.
import { computed, reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  addDecision, addMeetingItem, addTask, carryOverOpenItems, currentPhase, deleteMeeting, deleteMeetingItem, itemsOf,
  moveMeetingItem, openItemsFromPrevious, previousMeeting, profile, state, toast, updateMeeting, updateMeetingItem, updateTask,
} from '../lib/store.js';
import { datum } from '../lib/format.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const id = computed(() => route.params.id);
const meeting = computed(() => state.meetings.find((m) => m.id === id.value));
const items = computed(() => itemsOf(id.value));
const vorige = computed(() => previousMeeting(id.value));
const offeneVorher = computed(() => openItemsFromPrevious(id.value));
const aufgaben = computed(() => state.tasks.filter((t) => t.meeting_id === id.value));
const entscheidungen = computed(() => state.decisions.filter((d) => d.meeting_id === id.value));
const verknuepft = computed(() => (meeting.value?.idea_ids ?? []).map((i) => state.ideas.find((x) => x.id === i)).filter(Boolean));
const waehlbar = computed(() => state.ideas.filter((i) => !(meeting.value?.idea_ids ?? []).includes(i.id)));

const neuerPunkt = ref('');
const aufgabeFuer = ref(null);
const aufgabe = reactive({ title: '', assignee: '', due_date: '' });

function feld(key, value) {
  if ((meeting.value[key] ?? '') === value) return;
  updateMeeting(id.value, { [key]: value });
}
function teilnehmer(pid) {
  const list = meeting.value.attendees ?? [];
  updateMeeting(id.value, { attendees: list.includes(pid) ? list.filter((x) => x !== pid) : [...list, pid] });
}
function punkt(item, key, value) {
  if (item[key] === value) return;
  updateMeetingItem(item.id, { [key]: value });
}
function punktHinzufuegen() {
  if (!neuerPunkt.value.trim()) return;
  addMeetingItem(id.value, { title: neuerPunkt.value.trim() });
  neuerPunkt.value = '';
}
function uebernehmen() {
  const n = carryOverOpenItems(id.value);
  toast(`${n} offene${n === 1 ? 'r' : ''} Punkt${n === 1 ? '' : 'e'} übernommen`);
}
function herkunft(item) {
  const alt = state.meetingItems.find((x) => x.id === item.carried_from);
  const m = alt && state.meetings.find((x) => x.id === alt.meeting_id);
  return m ? `aus der Besprechung vom ${datum(m.held_on)}` : 'aus einer früheren Besprechung';
}
function punktLoeschen(item) {
  if (confirm(`Punkt „${item.title || 'ohne Titel'}“ löschen?`)) deleteMeetingItem(item.id);
}
function aufgabeOeffnen(item) {
  aufgabeFuer.value = item.id;
  Object.assign(aufgabe, { title: '', assignee: state.me.id, due_date: '' });
}
function aufgabeSpeichern() {
  if (!aufgabe.title.trim()) return;
  addTask({ ...aufgabe, meeting_id: id.value, phase: currentPhase() });
  aufgabeFuer.value = null;
  toast('Aufgabe angelegt – steht auch unter Plan → Aufgaben');
}
function alsEntscheidung(item) {
  addDecision({
    title: item.title || 'Entscheidung aus Besprechung',
    decision: item.result,
    reason: item.notes,
    decided_on: meeting.value.held_on,
    meeting_id: id.value,
  });
  toast('Ins Entscheidungsprotokoll übernommen');
}
function verknuepfen(e) {
  const v = e.target.value;
  e.target.value = '';
  if (v) updateMeeting(id.value, { idea_ids: [...(meeting.value.idea_ids ?? []), v] });
}
function loesen(ideaId) {
  updateMeeting(id.value, { idea_ids: meeting.value.idea_ids.filter((x) => x !== ideaId) });
}
function besprechungLoeschen() {
  if (!confirm('Diese Besprechung mit allen Punkten löschen? Aufgaben und Entscheidungen daraus bleiben erhalten.')) return;
  deleteMeeting(id.value);
  toast('Besprechung gelöscht');
  router.replace('/notizen?ansicht=meetings');
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link to="/notizen?ansicht=meetings" class="icon-btn back"><Icon name="back" /><span>Meetings</span></router-link>
      <span class="grow"></span>
      <button v-if="meeting" class="icon-btn" type="button" aria-label="Besprechung löschen" @click="besprechungLoeschen"><Icon name="trash" /></button>
    </div>
  </header>
  <main v-if="!meeting" class="page"><p class="empty">Diese Besprechung gibt es nicht (mehr).</p></main>
  <main v-else class="page">
    <label class="visually-hidden" for="m-title">Titel</label>
    <input id="m-title" class="title-input" :value="meeting.title" placeholder="Titel, z. B. Wochenrunde" maxlength="200" @change="feld('title', $event.target.value.trim())" @keydown.enter.prevent="$event.target.blur()">

    <section class="card stack">
      <div class="three">
        <label class="field"><span>Datum</span><input class="input" type="date" :value="meeting.held_on" @change="$event.target.value && feld('held_on', $event.target.value)"></label>
        <label class="field"><span>Uhrzeit</span><input class="input" type="time" :value="meeting.start_time?.slice(0, 5) ?? ''" @change="feld('start_time', $event.target.value || null)"></label>
        <label class="field"><span>Ort</span><input class="input" :value="meeting.place" placeholder="z. B. Büro, Telefon" @change="feld('place', $event.target.value.trim())"></label>
      </div>
      <div class="field">
        <span>Dabei</span>
        <div class="segmented" role="group" aria-label="Teilnehmer">
          <button v-for="p in state.profiles" :key="p.id" type="button" :aria-pressed="meeting.attendees.includes(p.id)" @click="teilnehmer(p.id)">{{ p.name }}</button>
        </div>
      </div>
      <label class="field"><span>Gäste (optional)</span><input class="input" :value="meeting.guests" placeholder="z. B. Steuerberater Herr Maier" @change="feld('guests', $event.target.value.trim())"></label>
    </section>

    <section class="stack">
      <h2><label for="m-notes">Notizen</label></h2>
      <textarea
        id="m-notes"
        class="textarea meeting-notes"
        rows="8"
        :value="meeting.notes ?? ''"
        placeholder="Alles, was ihr während des Meetings festhalten wollt …"
        @change="feld('notes', $event.target.value)"
      ></textarea>
    </section>

    <div v-if="offeneVorher.length" class="card carry">
      <span class="grow small">{{ offeneVorher.length }} Punkt{{ offeneVorher.length === 1 ? '' : 'e' }} ohne Ergebnis aus der Besprechung vom {{ datum(vorige.held_on) }}</span>
      <button class="btn" type="button" @click="uebernehmen">Offene Punkte übernehmen</button>
    </div>

    <section class="stack">
      <h2>Tagesordnung</h2>
      <p v-if="!items.length" class="small muted">Noch keine Punkte. Füge unten den ersten Tagesordnungspunkt hinzu.</p>
      <ol class="agenda">
        <li v-for="(item, n) in items" :key="item.id" class="card stack item" :class="{ done: item.result.trim() }">
          <div class="row">
            <span class="nr">{{ n + 1 }}</span>
            <label class="visually-hidden" :for="`t-${item.id}`">Punkt</label>
            <input :id="`t-${item.id}`" class="input item-title" :value="item.title" placeholder="Punkt" @change="punkt(item, 'title', $event.target.value.trim())" @keydown.enter.prevent="$event.target.blur()">
            <button class="icon-btn sm" type="button" aria-label="Punkt löschen" @click="punktLoeschen(item)"><Icon name="trash" :size="18" /></button>
          </div>
          <span v-if="item.carried_from" class="chip outline carried">{{ herkunft(item) }}</span>
          <label class="field"><span>Notiz</span><textarea class="textarea" rows="3" :value="item.notes" placeholder="Was wurde besprochen?" @change="punkt(item, 'notes', $event.target.value)"></textarea></label>
          <label class="field"><span>Ergebnis</span><textarea class="textarea" rows="2" :value="item.result" placeholder="Was kam dabei heraus? Leer = noch offen" @change="punkt(item, 'result', $event.target.value)"></textarea></label>

          <form v-if="aufgabeFuer === item.id" class="sub stack" @submit.prevent="aufgabeSpeichern">
            <label class="field"><span>Aufgabe</span><input v-model="aufgabe.title" class="input" placeholder="Was ist zu tun?" autofocus></label>
            <div class="two">
              <label class="field"><span>Wer</span>
                <select v-model="aufgabe.assignee" class="select">
                  <option v-for="p in state.profiles" :key="p.id" :value="p.id">{{ p.name }}</option>
                </select>
              </label>
              <label class="field"><span>Bis</span><input v-model="aufgabe.due_date" class="input" type="date"></label>
            </div>
            <div class="row">
              <button class="btn primary" type="submit" :disabled="!aufgabe.title.trim()">Aufgabe anlegen</button>
              <button class="btn" type="button" @click="aufgabeFuer = null">Abbrechen</button>
            </div>
          </form>

          <div class="row actions">
            <button class="btn small-btn" type="button" @click="aufgabeOeffnen(item)">+ Aufgabe</button>
            <button class="btn small-btn" type="button" :disabled="!item.result.trim()" title="Erst ein Ergebnis eintragen" @click="alsEntscheidung(item)">+ Entscheidung</button>
            <span class="grow"></span>
            <button class="icon-btn sm" type="button" aria-label="Nach oben" :disabled="n === 0" @click="moveMeetingItem(item.id, -1)"><Icon name="up" :size="18" /></button>
            <button class="icon-btn sm" type="button" aria-label="Nach unten" :disabled="n === items.length - 1" @click="moveMeetingItem(item.id, 1)"><Icon name="down" :size="18" /></button>
          </div>
        </li>
      </ol>
      <form class="add" @submit.prevent="punktHinzufuegen">
        <label class="visually-hidden" for="m-neu">Neuer Punkt</label>
        <input id="m-neu" v-model="neuerPunkt" class="input" placeholder="Neuer Tagesordnungspunkt …" maxlength="300">
        <button class="btn primary" type="submit" :disabled="!neuerPunkt.trim()">Hinzufügen</button>
      </form>
    </section>

    <section class="stack">
      <h2>Besprochene Ideen</h2>
      <div v-if="verknuepft.length" class="chips">
        <span v-for="i in verknuepft" :key="i.id" class="chip linked">
          <router-link :to="`/idee/${i.id}`">{{ i.title || 'Ohne Titel' }}</router-link>
          <button type="button" :aria-label="`${i.title} entfernen`" @click="loesen(i.id)"><Icon name="close" :size="14" /></button>
        </span>
      </div>
      <label class="field">
        <span class="visually-hidden">Idee verknüpfen</span>
        <select class="select" @change="verknuepfen">
          <option value="">+ Idee verknüpfen …</option>
          <option v-for="i in waehlbar" :key="i.id" :value="i.id">{{ i.title || 'Ohne Titel' }}</option>
        </select>
      </label>
    </section>

    <section v-if="aufgaben.length" class="stack">
      <h2>Aufgaben aus dieser Besprechung</h2>
      <label v-for="t in aufgaben" :key="t.id" class="card row task">
        <input type="checkbox" :checked="t.status === 'erledigt'" @change="updateTask(t.id, { status: $event.target.checked ? 'erledigt' : 'offen' })">
        <span class="grow" :class="{ strike: t.status === 'erledigt' }">{{ t.title }}</span>
        <span class="small muted">{{ profile(t.assignee)?.kuerzel }}<template v-if="t.due_date"> · {{ datum(t.due_date) }}</template></span>
      </label>
    </section>

    <section v-if="entscheidungen.length" class="stack">
      <h2>Entscheidungen aus dieser Besprechung</h2>
      <div v-for="d in entscheidungen" :key="d.id" class="card stack">
        <strong>{{ d.title }}</strong>
        <p v-if="d.decision" class="small pre">{{ d.decision }}</p>
      </div>
    </section>
  </main>
</template>

<style scoped>
p { margin: 0; }
h2 { margin: 8px 0 0; font-size: 17px; }
.grow { flex: 1; min-width: 0; }
.back { width: auto; gap: 4px; padding-right: 10px; text-decoration: none; }
.title-input { width: 100%; border: 0; background: transparent; font: inherit; font-size: 22px; font-weight: 600; color: var(--text); padding: 4px 0; }
.title-input:focus { outline: none; border-bottom: 2px solid var(--accent); }
.three { display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); }
.two { display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); }
.meeting-notes { min-height: 180px; }
.carry { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; border-color: var(--warn); }
.agenda { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.item { border-left: 3px solid var(--warn); }
.item.done { border-left-color: var(--accent); }
.nr { width: 26px; height: 26px; border-radius: 50%; background: var(--chip); display: inline-flex; align-items: center; justify-content: center; font-weight: 600; font-size: 14px; flex: none; }
.item-title { font-weight: 600; }
.carried { align-self: flex-start; }
.actions { gap: 6px; }
.sm { width: 36px; height: 36px; flex: none; }
.small-btn { min-height: 36px; padding: 0 12px; font-size: 14px; }
.sub { padding: 12px; border-radius: 10px; background: var(--chip); }
.add { display: flex; gap: 8px; }
.add .input { flex: 1; min-width: 0; }
.chips { display: flex; flex-wrap: wrap; gap: 6px; }
.linked { display: inline-flex; align-items: center; gap: 4px; }
.linked a { color: inherit; text-decoration: none; }
.linked button { border: 0; background: transparent; color: var(--muted); padding: 0; display: inline-flex; cursor: pointer; }
.task { gap: 12px; cursor: pointer; }
.strike { text-decoration: line-through; color: var(--muted); }
.pre { white-space: pre-wrap; }
</style>
