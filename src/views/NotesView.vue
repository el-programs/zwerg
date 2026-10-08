<script setup>
// Notizen: schnell festgehaltene Gedanken (für beide sichtbar) und Besprechungen.
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { deleteNote, markNotesSeen, noteToIdea, profile, state, toast, updateNote } from '../lib/store.js';
import { relativ } from '../lib/format.js';
import MeetingList from '../components/MeetingList.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const ansicht = ref(route.query.ansicht === 'meetings' ? 'meetings' : 'notizen');
watch(ansicht, (a) => router.replace({ query: a === 'notizen' ? {} : { ansicht: a } }));

// Was beim Öffnen neu war, bleibt während des Besuchs markiert.
const gesehenBis = state.notesSeen;
markNotesSeen();
onBeforeUnmount(markNotesSeen);

const suche = ref('');
const offen = ref(null);
const liste = computed(() => {
  const q = suche.value.trim().toLowerCase();
  return state.notes
    .filter((n) => !q || n.body.toLowerCase().includes(q))
    .sort((a, b) => (a.pinned !== b.pinned ? (a.pinned ? -1 : 1) : a.created_at < b.created_at ? 1 : -1));
});
const istNeu = (n) => n.created_by !== state.me?.id && n.created_at > gesehenBis;

function speichern(n, e) {
  const body = e.target.value.trim();
  if (!body) {
    e.target.value = n.body;
    return;
  }
  if (body !== n.body) updateNote(n.id, { body });
}
function zurIdee(n) {
  const id = noteToIdea(n.id);
  toast('Als Idee übernommen');
  if (id) router.push(`/idee/${id}`);
}
function loeschen(n) {
  if (!confirm('Diese Notiz löschen?')) return;
  deleteNote(n.id);
  offen.value = null;
}
function ideaTitle(id) {
  return state.ideas.find((i) => i.id === id)?.title || 'Idee';
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <h1 class="grow">Notizen</h1>
    </div>
  </header>
  <main class="page">
    <div class="tabs" role="tablist" aria-label="Ansicht">
      <button role="tab" type="button" :aria-selected="ansicht === 'notizen'" @click="ansicht = 'notizen'">Notizen</button>
      <button role="tab" type="button" :aria-selected="ansicht === 'meetings'" @click="ansicht = 'meetings'">Meetings</button>
    </div>

    <template v-if="ansicht === 'notizen'">
      <label v-if="state.notes.length > 5" class="field">
        <span class="visually-hidden">Suche</span>
        <input v-model="suche" class="input" type="search" placeholder="Notizen durchsuchen …">
      </label>
      <p v-if="!state.notes.length" class="empty">Noch keine Notizen. Tippe auf das Plus und halte einen Gedanken fest.</p>
      <p v-else-if="!liste.length" class="empty">Keine Notiz passt zur Suche.</p>

      <article v-for="n in liste" :key="n.id" class="card note" :class="{ pinned: n.pinned }">
        <template v-if="offen === n.id">
          <label class="visually-hidden" :for="`n-${n.id}`">Notiz</label>
          <textarea :id="`n-${n.id}`" class="textarea" rows="6" :value="n.body" @change="speichern(n, $event)"></textarea>
          <div class="row actions">
            <button class="btn small-btn" type="button" @click="updateNote(n.id, { pinned: !n.pinned })">{{ n.pinned ? 'Lösen' : 'Anheften' }}</button>
            <button v-if="!n.idea_id" class="btn small-btn" type="button" @click="zurIdee(n)">Zur Idee machen</button>
            <span class="grow"></span>
            <button class="icon-btn sm" type="button" aria-label="Notiz löschen" @click="loeschen(n)"><Icon name="trash" :size="18" /></button>
            <button class="btn small-btn" type="button" @click="offen = null">Fertig</button>
          </div>
        </template>
        <button v-else class="note-body" type="button" @click="offen = n.id">
          <span class="text">{{ n.body }}</span>
        </button>
        <div class="row meta">
          <span v-if="n.pinned" class="small pin">Angeheftet</span>
          <span class="small muted grow">{{ profile(n.created_by)?.name }} · {{ relativ(n.created_at) }}</span>
          <router-link v-if="n.idea_id" :to="`/idee/${n.idea_id}`" class="chip outline idea-link">Idee: {{ ideaTitle(n.idea_id) }}</router-link>
          <span v-if="istNeu(n)" class="chip new">neu</span>
        </div>
      </article>
    </template>

    <MeetingList v-else />
  </main>
</template>

<style scoped>
.grow { flex: 1; min-width: 0; }
.tabs { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 4px; padding: 4px; border-radius: 12px; background: var(--chip); max-width: 360px; }
.tabs button { height: 38px; border: 0; border-radius: 9px; background: transparent; color: var(--muted); font-weight: 500; cursor: pointer; }
.tabs button[aria-selected="true"] { background: var(--surface); color: var(--text); box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12); }
.note { display: flex; flex-direction: column; gap: 8px; }
.note.pinned { border-color: var(--accent); }
.note-body { border: 0; background: transparent; padding: 0; text-align: left; color: inherit; font: inherit; cursor: pointer; }
.text { display: -webkit-box; -webkit-line-clamp: 6; -webkit-box-orient: vertical; overflow: hidden; white-space: pre-wrap; line-height: 1.5; }
.meta { gap: 8px; flex-wrap: wrap; }
.meta .muted { flex: 1 0 auto; white-space: nowrap; }
.pin { color: var(--accent); font-weight: 600; }
.idea-link { text-decoration: none; max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.chip.new { background: var(--accent); color: var(--on-accent); font-weight: 600; }
.actions { gap: 6px; flex-wrap: wrap; }
.small-btn { min-height: 36px; padding: 0 12px; font-size: 14px; }
.sm { width: 36px; height: 36px; }
</style>
