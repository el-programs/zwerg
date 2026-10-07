<script setup>
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import {
  addComment, commentsOf, deleteComment, deleteIdea, markSeen, newComments, profile, state, toast, updateIdea,
} from '../lib/store.js';
import { datum, phaseName, relativ } from '../lib/format.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const id = computed(() => route.params.id);
const idea = computed(() => state.ideas.find((i) => i.id === id.value));
const comments = computed(() => commentsOf(id.value));
const fields = computed(() => state.fields.filter((f) => !f.archived || f.id === idea.value?.search_field_id));

// Entwürfe der Felder; werden von außen nur aktualisiert, solange man nicht selbst darin schreibt.
const draft = reactive({ title: '', description: '', search_field_id: '', tags: '' });
const editing = ref('');
const neuerLink = reactive({ url: '', label: '' });
const kommentar = ref('');
const neuSeit = ref('');

function fromIdea() {
  if (!idea.value) return;
  for (const key of ['title', 'description', 'search_field_id']) {
    if (editing.value !== key) draft[key] = idea.value[key] ?? '';
  }
  if (editing.value !== 'tags') draft.tags = (idea.value.tags ?? []).join(', ');
}
watch(idea, fromIdea, { immediate: true, deep: true });

function commit(key) {
  editing.value = '';
  if (!idea.value) return;
  let value = draft[key];
  if (key === 'tags') {
    value = [...new Set(draft.tags.split(',').map((t) => t.trim().replace(/^#/, '')).filter(Boolean))];
    if (value.join(',') === (idea.value.tags ?? []).join(',')) return;
  } else {
    if (key === 'title') value = value.trim();
    if (key === 'search_field_id') value = value || null;
    if ((idea.value[key] ?? '') === (value ?? '')) return;
  }
  updateIdea(idea.value.id, { [key]: value });
}

function addLink() {
  let url = neuerLink.url.trim();
  if (!url) return;
  if (!/^https?:\/\//i.test(url)) url = `https://${url}`;
  const links = [...(idea.value.links ?? []), { url, label: neuerLink.label.trim() }];
  updateIdea(idea.value.id, { links });
  neuerLink.url = '';
  neuerLink.label = '';
}

function removeLink(index) {
  const links = (idea.value.links ?? []).filter((_, i) => i !== index);
  updateIdea(idea.value.id, { links });
}

function sendComment() {
  if (!kommentar.value.trim()) return;
  addComment(id.value, kommentar.value);
  kommentar.value = '';
}

function removeComment(c) {
  if (confirm('Diesen Kommentar löschen?')) deleteComment(c.id);
}

function removeIdea() {
  if (!confirm('Diese Idee mit allen Kommentaren endgültig löschen?')) return;
  deleteIdea(idea.value.id);
  toast('Idee gelöscht');
  router.replace('/ideen');
}

function host(url) {
  try {
    return new URL(url).host;
  } catch {
    return url;
  }
}

onMounted(() => {
  if (!idea.value) return;
  const ungelesen = newComments(idea.value);
  neuSeit.value = ungelesen.length ? ungelesen[0].created_at : '';
  markSeen(id.value);
});

// Kommen neue Kommentare herein, während die Idee offen ist, gelten sie als gelesen.
watch(
  () => comments.value.length,
  async () => {
    if (idea.value) markSeen(id.value);
    await nextTick();
  },
);
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link to="/ideen" class="icon-btn back"><Icon name="back" /><span>Ideen</span></router-link>
      <span class="grow"></span>
    </div>
  </header>

  <main v-if="!idea" class="page">
    <p class="empty">Diese Idee gibt es nicht (mehr).</p>
  </main>

  <main v-else class="page detail">
    <section class="stack">
      <label class="visually-hidden" for="idee-titel">Titel</label>
      <input
        id="idee-titel"
        v-model="draft.title"
        class="title-input"
        placeholder="Titel"
        @focus="editing = 'title'"
        @blur="commit('title')"
        @keydown.enter.prevent="$event.target.blur()"
      >
      <p class="small muted">
        von {{ profile(idea.created_by)?.name }} · {{ datum(idea.created_at) }}
        <template v-if="idea.updated_by && idea.updated_at !== idea.created_at">
          · zuletzt geändert von {{ profile(idea.updated_by)?.name }}, {{ relativ(idea.updated_at) }}
        </template>
      </p>
      <div class="row wrap">
        <span class="chip">Phase {{ idea.phase }} · {{ phaseName(idea.phase) }}</span>
      </div>
    </section>

    <label class="field">
      <span>Kurzbeschreibung</span>
      <textarea
        v-model="draft.description"
        class="textarea"
        rows="5"
        placeholder="Worum geht es? Für wen? Warum könnte das funktionieren?"
        @focus="editing = 'description'"
        @blur="commit('description')"
      ></textarea>
    </label>

    <div class="two">
      <label class="field">
        <span>Suchfeld</span>
        <select v-model="draft.search_field_id" class="select" @change="commit('search_field_id')">
          <option value="">– ohne –</option>
          <option v-for="f in fields" :key="f.id" :value="f.id">{{ f.name }}</option>
        </select>
      </label>
      <label class="field">
        <span>Schlagworte (mit Komma trennen)</span>
        <input
          v-model="draft.tags"
          class="input"
          placeholder="z. B. Service, B2B"
          @focus="editing = 'tags'"
          @blur="commit('tags')"
          @keydown.enter.prevent="$event.target.blur()"
        >
      </label>
    </div>

    <section class="stack">
      <h2>Links</h2>
      <div v-for="(l, i) in idea.links ?? []" :key="l.url + i" class="card link">
        <Icon name="link" :size="18" />
        <a :href="l.url" target="_blank" rel="noopener noreferrer" class="grow ellipsis">{{ l.label || host(l.url) }}</a>
        <button class="icon-btn" type="button" aria-label="Link entfernen" @click="removeLink(i)"><Icon name="close" :size="18" /></button>
      </div>
      <form class="link-form" @submit.prevent="addLink">
        <label class="visually-hidden" for="link-url">Adresse</label>
        <input id="link-url" v-model="neuerLink.url" class="input" inputmode="url" placeholder="Adresse, z. B. www.beispiel.de">
        <label class="visually-hidden" for="link-label">Bezeichnung</label>
        <input id="link-label" v-model="neuerLink.label" class="input" placeholder="Bezeichnung (optional)">
        <button class="btn" type="submit" :disabled="!neuerLink.url.trim()">Hinzufügen</button>
      </form>
    </section>

    <section class="stack">
      <h2>Kommentare ({{ comments.length }})</h2>
      <p v-if="!comments.length" class="small muted">Noch keine Kommentare.</p>
      <div v-for="c in comments" :key="c.id" class="comment">
        <span class="avatar">{{ profile(c.author_id)?.kuerzel }}</span>
        <div class="grow">
          <div class="row small">
            <strong>{{ profile(c.author_id)?.name }}</strong>
            <span class="muted">{{ relativ(c.created_at) }}</span>
            <span v-if="neuSeit && c.created_at >= neuSeit && c.author_id !== state.me?.id" class="badge-new">neu</span>
            <button v-if="c.author_id === state.me?.id" class="link-btn small muted" type="button" @click="removeComment(c)">löschen</button>
          </div>
          <p class="body">{{ c.body }}</p>
        </div>
      </div>
    </section>

    <section class="danger-zone">
      <button class="btn danger" type="button" @click="removeIdea"><Icon name="trash" :size="18" />Idee löschen</button>
    </section>
  </main>

  <form v-if="idea" class="composer" @submit.prevent="sendComment">
    <label class="visually-hidden" for="kommentar">Kommentar</label>
    <textarea
      id="kommentar"
      v-model="kommentar"
      rows="1"
      class="input grow"
      placeholder="Kommentar schreiben …"
      @keydown.enter.meta.prevent="sendComment"
      @keydown.enter.ctrl.prevent="sendComment"
    ></textarea>
    <button class="send" type="submit" aria-label="Senden" :disabled="!kommentar.trim()"><Icon name="send" :size="20" /></button>
  </form>
</template>

<style scoped>
.back { width: auto; padding: 0 10px 0 4px; gap: 2px; }
.detail { padding-bottom: 120px; }
.title-input {
  width: 100%;
  border: 0;
  background: transparent;
  font-size: 23px;
  font-weight: 600;
  line-height: 1.25;
  padding: 4px 0;
  color: var(--text);
}
.title-input:focus { outline: none; box-shadow: inset 0 -2px 0 var(--accent); }
.wrap { flex-wrap: wrap; }
p { margin: 0; }
.two { display: grid; gap: 12px; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); }
.link { display: flex; align-items: center; gap: 10px; padding: 4px 4px 4px 12px; }
.ellipsis { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.grow { flex: 1; min-width: 0; }
.link-form { display: grid; gap: 8px; grid-template-columns: 1fr; }
@media (min-width: 640px) { .link-form { grid-template-columns: 2fr 1.4fr auto; } }
.comment { display: flex; gap: 10px; }
.comment .avatar { width: 30px; height: 30px; }
.body { white-space: pre-wrap; overflow-wrap: anywhere; }
.link-btn { border: 0; background: none; padding: 0; margin-left: auto; cursor: pointer; text-decoration: underline; }
.danger-zone { border-top: 1px solid var(--line); padding-top: 18px; }
.composer {
  position: fixed;
  left: var(--side, 0px);
  right: 0;
  bottom: 0;
  z-index: 20;
  background: var(--surface);
  border-top: 1px solid var(--line);
  padding: 10px 12px calc(10px + var(--safe-b));
  display: flex;
  gap: 10px;
  align-items: flex-end;
}
.composer .input { border-radius: 22px; resize: none; max-height: 140px; field-sizing: content; }
@media (min-width: 900px) {
  .composer {
    --pad: max(24px, calc((100vw - var(--side, 0px) - var(--content-w)) / 2 + 32px));
    padding-left: var(--pad);
    padding-right: var(--pad);
  }
}
.send {
  width: 44px;
  height: 44px;
  flex: none;
  border-radius: 50%;
  border: 0;
  background: var(--accent);
  color: var(--on-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.send:disabled { opacity: 0.45; }
</style>
