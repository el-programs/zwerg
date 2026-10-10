<script setup>
// Schnellerfassung: das Plus legt immer eine Notiz an; aus „Gedanken & Ideen“ heraus eine Idee. Das Textfeld ist immer vorhanden und wird direkt
// beim Antippen fokussiert – nur so öffnet das iPhone sofort die Tastatur (mit Diktat-Mikrofon).
import { computed, ref } from 'vue';
import { addIdea, addNote, state, toast } from '../lib/store.js';
import Icon from './Icon.vue';

const isOpen = ref(false);
const mode = ref('notiz');
const text = ref('');
const fieldId = ref('');
const sheet = ref(null);
const area = ref(null);
const fields = computed(() => state.fields.filter((f) => !f.archived));
const isWindows = /Windows/.test(navigator.userAgent);

let hideTimer = null;

// Am iPhone schiebt sich die Tastatur über die Seite. Der sichtbare Bereich (visualViewport)
// bestimmt deshalb Lage und Höhe des Fensters, damit der Text immer zu sehen ist.
function fitViewport() {
  const vv = window.visualViewport;
  if (!vv || !sheet.value) return;
  sheet.value.style.setProperty('--vv-top', `${vv.offsetTop}px`);
  sheet.value.style.setProperty('--vv-h', `${vv.height}px`);
}
function watchViewport(on) {
  const vv = window.visualViewport;
  if (!vv) return;
  const fn = on ? 'addEventListener' : 'removeEventListener';
  vv[fn]('resize', fitViewport);
  vv[fn]('scroll', fitViewport);
  if (on) fitViewport();
}

function open(m = 'notiz') {
  mode.value = m === 'idee' ? 'idee' : 'notiz';
  clearTimeout(hideTimer);
  sheet.value.style.visibility = 'visible';
  sheet.value.inert = false;
  area.value.focus();
  isOpen.value = true;
  watchViewport(true);
}

function close() {
  isOpen.value = false;
  watchViewport(false);
  area.value.blur();
  sheet.value.inert = true;
  hideTimer = setTimeout(() => {
    if (!isOpen.value) sheet.value.style.visibility = 'hidden';
  }, 250);
}

function save() {
  if (!text.value.trim()) return close();
  if (mode.value === 'idee') addIdea({ text: text.value, searchFieldId: fieldId.value });
  else addNote(text.value);
  text.value = '';
  close();
  const was = mode.value === 'idee' ? 'Idee' : 'Notiz';
  toast(state.online ? `${was} gespeichert` : 'Offline gespeichert – wird später abgeglichen');
}

function onKey(e) {
  if (e.key === 'Escape') close();
  if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) save();
}

defineExpose({ open });
</script>

<template>
  <div class="backdrop" :class="{ open: isOpen }" @click="close"></div>
  <section ref="sheet" class="sheet" :class="{ open: isOpen }" inert style="visibility: hidden" aria-label="Schnellerfassung" @keydown="onKey">
    <div class="head">
      <h2 class="grow">{{ mode === 'idee' ? 'Neue Idee' : 'Neue Notiz' }}</h2>
      <button class="btn primary save" type="button" :disabled="!text.trim()" @click="save">Speichern</button>
      <button class="icon-btn" type="button" aria-label="Schließen" @click="close"><Icon name="close" /></button>
    </div>
    <label v-if="mode === 'idee'" class="field">
      <span>Suchfeld</span>
      <select v-model="fieldId" class="select">
        <option value="">– ohne –</option>
        <option v-for="f in fields" :key="f.id" :value="f.id">{{ f.name }}</option>
      </select>
    </label>
    <label class="visually-hidden" for="qc-text">{{ mode === 'idee' ? 'Idee' : 'Notiz' }}</label>
    <textarea
      id="qc-text"
      ref="area"
      v-model="text"
      class="textarea"
      rows="5"
      :placeholder="mode === 'idee' ? 'Idee kurz beschreiben … Die erste Zeile wird zum Titel.' : 'Gedanken festhalten …'"
    ></textarea>
    <p class="hint small muted">
      <Icon name="mic" :size="16" />
      <span v-if="isWindows">Diktieren: Windows-Taste + H</span>
      <span v-else>Diktieren: Mikrofon auf der Tastatur</span>
    </p>
  </section>
</template>

<style scoped>
.backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s;
  z-index: 30;
}
.backdrop.open { opacity: 1; pointer-events: auto; }
.sheet {
  position: fixed;
  left: 8px;
  right: 8px;
  top: calc(var(--vv-top, 0px) + env(safe-area-inset-top, 0px) + 8px);
  z-index: 31;
  max-width: 640px;
  margin: 0 auto;
  background: var(--surface);
  border-radius: 18px;
  padding: 10px 16px 14px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  opacity: 0;
  transform: translateY(-24px);
  pointer-events: none;
  transition: opacity 0.18s, transform 0.18s;
}
.sheet.open { opacity: 1; transform: none; pointer-events: auto; }
.head { display: flex; align-items: center; gap: 8px; }
.head h2 { margin: 0; }
/* Textfeld füllt den Platz über der Tastatur, bleibt aber immer ganz sichtbar. */
.sheet .textarea { min-height: 96px; max-height: calc(var(--vv-h, 100vh) - env(safe-area-inset-top, 0px) - 150px); }
.hint { display: flex; align-items: center; gap: 6px; margin: 0; }
.grow { flex: 1; min-width: 0; }
.save { min-height: 38px; padding: 0 14px; font-size: 15px; }
@media (min-width: 700px) {
  .sheet { top: 12vh; padding-bottom: 16px; }
}
</style>
