<script setup>
// Steckbrief einer Idee: Leitfragen mit Fortschritt; jedes Feld lässt sich direkt bearbeiten.
import { computed, nextTick, ref } from 'vue';
import { updateIdea } from '../lib/store.js';
import { ausgefuellt, ERLOESMODELLE, erloesText, FELDER, fortschritt } from '../lib/steckbrief.js';

const props = defineProps({ idea: { type: Object, required: true } });
const offen = ref(null);
const entwurf = ref('');
const stand = computed(() => fortschritt(props.idea));

function bearbeiten(f) {
  offen.value = f.key;
  entwurf.value = f.erloes ? props.idea.revenue_note ?? '' : props.idea[f.key] ?? '';
  nextTick(() => document.getElementById(`sb-${f.key}`)?.focus());
}
function speichern(f) {
  const v = entwurf.value.trim();
  const key = f.erloes ? 'revenue_note' : f.key;
  if (v !== (props.idea[key] ?? '')) updateIdea(props.idea.id, { [key]: v });
  offen.value = null;
}
function toggleErloes(m) {
  const list = new Set(props.idea.revenue_model ?? []);
  if (list.has(m)) list.delete(m);
  else list.add(m);
  updateIdea(props.idea.id, { revenue_model: ERLOESMODELLE.filter((x) => list.has(x)) });
}
</script>

<template>
  <section class="card stack sb">
    <div class="row head">
      <strong class="grow">Steckbrief</strong>
      <span class="small muted">{{ stand.done }} von {{ stand.of }} ausgefüllt</span>
    </div>
    <span class="prog" aria-hidden="true"><span :style="{ width: `${(stand.done / stand.of) * 100}%` }"></span></span>
    <div v-for="f in FELDER" :key="f.key" class="item">
      <span class="lbl">{{ f.name }} <span v-if="f.optional" class="opt">optional</span></span>
      <template v-if="offen === f.key">
        <span class="frage">{{ f.frage }}</span>
        <div v-if="f.erloes" class="chips" role="group" :aria-label="f.name">
          <button v-for="m in ERLOESMODELLE" :key="m" type="button" class="pill" :aria-pressed="(idea.revenue_model ?? []).includes(m)" @click="toggleErloes(m)">{{ m }}</button>
        </div>
        <textarea
          :id="`sb-${f.key}`"
          v-model="entwurf"
          class="textarea"
          :rows="f.erloes ? 1 : 3"
          :placeholder="f.erloes ? 'Ergänzung, z. B. Tagespreis + Kaution' : f.beispiel ?? ''"
          @blur="speichern(f)"
          @keydown.esc="offen = null"
        ></textarea>
      </template>
      <button v-else-if="ausgefuellt(idea, f)" type="button" class="value" @click="bearbeiten(f)">{{ f.erloes ? erloesText(idea) : idea[f.key] }}</button>
      <button v-else type="button" class="add" :title="f.frage" @click="bearbeiten(f)">+ ergänzen</button>
    </div>
  </section>
</template>

<style scoped>
.sb { gap: 8px; }
.head { align-items: baseline; }
.grow { flex: 1; min-width: 0; }
.prog { display: block; height: 6px; border-radius: 3px; background: var(--chip); overflow: hidden; }
.prog span { display: block; height: 100%; background: var(--accent); border-radius: 3px; transition: width 0.2s; }
.item { display: flex; flex-direction: column; gap: 4px; padding: 9px 0 2px; border-top: 1px solid var(--line); }
.item:first-of-type { border-top: 0; }
.lbl { font-size: 13px; color: var(--muted); }
.opt { font-size: 12px; }
.frage { font-size: 12.5px; color: var(--muted); }
.value, .add { border: 0; background: none; padding: 0; font: inherit; text-align: left; cursor: pointer; }
.value { color: var(--text); white-space: pre-wrap; line-height: 1.45; }
.add { color: var(--accent); }
.chips { display: flex; gap: 6px; flex-wrap: wrap; }
.pill { border: 1px solid var(--line); border-radius: 999px; padding: 6px 12px; font: inherit; font-size: 13.5px; color: var(--text); background: transparent; cursor: pointer; }
.pill[aria-pressed="true"] { background: var(--text); color: var(--bg); border-color: var(--text); }
</style>
