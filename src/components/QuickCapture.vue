<script setup>
// Schnellnotiz hinter dem Plus-Knopf. Das Textfeld ist immer vorhanden und wird direkt
// beim Antippen fokussiert – nur so öffnet das iPhone sofort die Tastatur (mit Diktat-Mikrofon).
import { computed, ref } from 'vue';
import { addIdea, state, toast } from '../lib/store.js';
import Icon from './Icon.vue';

const isOpen = ref(false);
const text = ref('');
const fieldId = ref('');
const sheet = ref(null);
const area = ref(null);
const fields = computed(() => state.fields.filter((f) => !f.archived));
const isWindows = /Windows/.test(navigator.userAgent);

let hideTimer = null;

function open() {
  clearTimeout(hideTimer);
  sheet.value.style.visibility = 'visible';
  sheet.value.inert = false;
  area.value.focus();
  isOpen.value = true;
}

function close() {
  isOpen.value = false;
  area.value.blur();
  sheet.value.inert = true;
  hideTimer = setTimeout(() => {
    if (!isOpen.value) sheet.value.style.visibility = 'hidden';
  }, 250);
}

function save() {
  if (!text.value.trim()) return close();
  addIdea({ text: text.value, searchFieldId: fieldId.value });
  text.value = '';
  close();
  toast(state.online ? 'Idee gespeichert' : 'Offline gespeichert – wird später abgeglichen');
}

function onKey(e) {
  if (e.key === 'Escape') close();
  if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) save();
}

defineExpose({ open });
</script>

<template>
  <div class="backdrop" :class="{ open: isOpen }" @click="close"></div>
  <section ref="sheet" class="sheet" :class="{ open: isOpen }" inert style="visibility: hidden" aria-label="Neue Idee" @keydown="onKey">
    <div class="head">
      <h2>Neue Idee</h2>
      <button class="icon-btn" type="button" aria-label="Schließen" @click="close"><Icon name="close" /></button>
    </div>
    <label class="visually-hidden" for="qc-text">Idee</label>
    <textarea
      id="qc-text"
      ref="area"
      v-model="text"
      class="textarea"
      rows="5"
      placeholder="Idee kurz notieren … Die erste Zeile wird zum Titel."
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
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 31;
  max-width: 640px;
  margin: 0 auto;
  background: var(--surface);
  border-radius: 18px 18px 0 0;
  padding: 10px 16px calc(16px + var(--safe-b));
  display: flex;
  flex-direction: column;
  gap: 10px;
  opacity: 0;
  transform: translateY(24px);
  pointer-events: none;
  transition: opacity 0.18s, transform 0.18s;
}
.sheet.open { opacity: 1; transform: none; pointer-events: auto; }
.head { display: flex; align-items: center; justify-content: space-between; }
.hint { display: flex; align-items: center; gap: 6px; margin: 0; }
.grow { flex: 1; min-width: 0; }
.save { align-self: flex-end; }
@media (min-width: 700px) {
  .sheet { bottom: auto; top: 12vh; border-radius: 18px; padding-bottom: 16px; }
}
</style>
