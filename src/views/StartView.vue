<script setup>
import { computed, onMounted, ref } from 'vue';
import { addIdea, currentPhase, heute, neuigkeiten, partner, state, toast } from '../lib/store.js';
import { relativ } from '../lib/format.js';
import ZLogo from '../components/ZLogo.vue';
import Icon from '../components/Icon.vue';
import SyncStatus from '../components/SyncStatus.vue';

const text = ref('');
const fieldId = ref('');
const area = ref(null);
const fields = computed(() => state.fields.filter((f) => !f.archived));
const neu = computed(() => neuigkeiten());
const aktive = computed(() => state.ideas.filter((i) => i.status !== 'geparkt').length);
const phase = computed(() => state.phases.find((p) => p.nr === currentPhase()));
const meineAufgaben = computed(() => state.tasks.filter((t) => t.status !== 'erledigt' && t.assignee === state.me?.id));
const ueberfaellig = computed(() => meineAufgaben.value.filter((t) => t.due_date && t.due_date < heute()).length);
const favoriten = computed(() => state.ideas.filter((i) => i.is_favorite && i.status !== 'geparkt').length);
const anderer = computed(() => partner());
const isWindows = /Windows/.test(navigator.userAgent);
const stunde = new Date().getHours();
const gruss = stunde < 11 ? 'Guten Morgen' : stunde < 18 ? 'Guten Tag' : 'Guten Abend';

onMounted(() => {
  // Am Computer direkt lostippen können; auf dem Handy öffnet erst ein Antippen die Tastatur.
  if (window.matchMedia('(pointer: fine)').matches) area.value?.focus();
});

function save() {
  if (!text.value.trim()) return;
  addIdea({ text: text.value, searchFieldId: fieldId.value });
  text.value = '';
  toast(state.online ? 'Idee gespeichert' : 'Offline gespeichert – wird später abgeglichen');
}
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <ZLogo class="mobile-only" :size="30" :echoes="1" />
      <span class="brand grow mobile-only">Zwerg</span>
      <h1 class="grow desktop-only">{{ gruss }}, {{ state.me?.name }}</h1>
      <router-link v-if="state.me" to="/mehr" class="avatar me" :aria-label="`Einstellungen von ${state.me.name}`">{{ state.me.kuerzel }}</router-link>
    </div>
  </header>

  <main class="page start">
    <section class="card stack capture">
      <label for="start-text" class="title">Was ist dir eingefallen?</label>
      <textarea
        id="start-text"
        ref="area"
        v-model="text"
        class="textarea"
        rows="4"
        placeholder="Idee kurz notieren … Die erste Zeile wird zum Titel."
        @keydown.enter.meta.prevent="save"
        @keydown.enter.ctrl.prevent="save"
      ></textarea>
      <p class="hint small muted">
        <Icon name="mic" :size="16" />
        <span v-if="isWindows">Diktieren: Windows-Taste + H</span>
        <span v-else>Diktieren: Mikrofon auf der Tastatur</span>
      </p>
      <div class="row">
        <label class="field grow">
          <span>Suchfeld</span>
          <select v-model="fieldId" class="select">
            <option value="">– ohne –</option>
            <option v-for="f in fields" :key="f.id" :value="f.id">{{ f.name }}</option>
          </select>
        </label>
        <button class="btn primary save" type="button" :disabled="!text.trim()" @click="save">Speichern</button>
      </div>
    </section>

    <div class="side">
    <section class="stack">
      <div class="row between">
        <h2>Neu von {{ anderer?.name ?? 'deinem Partner' }}</h2>
        <span v-if="neu.length" class="small muted">{{ neu.length }} neu</span>
      </div>
      <p v-if="!neu.length" class="small muted">Nichts Neues – du bist auf dem aktuellen Stand.</p>
      <router-link v-for="n in neu.slice(0, 6)" :key="n.kind + n.idea.id" :to="n.kind === 'bewertung' ? `/idee/${n.idea.id}/bewertung` : `/idee/${n.idea.id}`" class="card news">
        <span class="dot"></span>
        <span class="grow">
          <span class="news-title">
            <template v-if="n.kind === 'idee'">Neue Idee: „{{ n.idea.title || 'Ohne Titel' }}“</template>
            <template v-else-if="n.kind === 'bewertung'">„{{ n.idea.title || 'Ohne Titel' }}“ wurde bewertet – du bist dran</template>
            <template v-else>{{ n.count === 1 ? 'Neuer Kommentar' : `${n.count} neue Kommentare` }} zu „{{ n.idea.title || 'Ohne Titel' }}“</template>
          </span>
          <span class="small muted">{{ relativ(n.at) }}</span>
        </span>
      </router-link>
    </section>

    <section class="tiles">
      <router-link to="/ideen" class="card tile">
        <span class="small muted">Gedanken &amp; Notizen</span>
        <span class="big">{{ aktive }}</span>
        <span v-if="favoriten" class="small muted">davon {{ favoriten }} Favorit{{ favoriten > 1 ? 'en' : '' }}</span>
      </router-link>
      <router-link to="/phasen" class="card tile">
        <span class="small muted">Aktuelle Phase</span>
        <span class="mid">{{ currentPhase() }} · {{ phase?.name ?? 'Ideenfindung' }}</span>
      </router-link>
      <router-link to="/phasen?tab=aufgaben" class="card tile">
        <span class="small muted">Meine Aufgaben</span>
        <span class="big">{{ meineAufgaben.length }}</span>
        <span v-if="ueberfaellig" class="small late">{{ ueberfaellig }} überfällig</span>
      </router-link>
    </section>

    <SyncStatus />
    </div>
  </main>
</template>

<style scoped>
.side { display: flex; flex-direction: column; gap: 22px; }
@media (min-width: 900px) {
  .start { display: grid; grid-template-columns: minmax(0, 1.1fr) minmax(0, 1fr); align-items: start; gap: 28px; }
  .capture .textarea { min-height: 190px; }
}
.brand { font-size: 19px; font-weight: 600; letter-spacing: 0.02em; margin-left: 4px; }
.me { width: 36px; height: 36px; text-decoration: none; color: var(--text); font-size: 13px; }
.title { font-weight: 600; font-size: 16px; }
.hint { display: flex; align-items: center; gap: 6px; margin: 0; }
.grow { flex: 1; min-width: 0; }
.save { align-self: flex-end; }
.between { justify-content: space-between; }
.news { display: flex; align-items: center; gap: 12px; text-decoration: none; color: inherit; padding: 12px 14px; }
.news .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--accent); flex: none; }
.news-title { display: block; font-weight: 500; }
.tiles { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px; }
.tile { display: flex; flex-direction: column; gap: 2px; text-decoration: none; color: inherit; }
.big { font-size: 24px; font-weight: 600; }
.late { color: var(--danger); font-weight: 600; }
.mid { font-size: 16px; font-weight: 600; }
</style>
