<script setup>
// Bauchgefühl je Person: eigene Daumen zum Antippen, dazu die Stimme des Partners.
import { computed } from 'vue';
import { partner, setVote, state, voteOf } from '../lib/store.js';
import Icon from './Icon.vue';

const props = defineProps({ ideaId: { type: String, required: true } });
const DAUMEN = [
  { v: 1, cls: 'hoch', label: 'Daumen hoch' },
  { v: 0, cls: 'seite', label: 'Daumen zur Seite' },
  { v: -1, cls: 'runter', label: 'Daumen runter' },
];
const meins = computed(() => voteOf(props.ideaId, state.me?.id));
const anderer = computed(() => partner());
const seins = computed(() => (anderer.value ? voteOf(props.ideaId, anderer.value.id) : null));
const art = (v) => DAUMEN.find((d) => d.v === v);
</script>

<template>
  <span class="votes">
    <span class="mine" role="group" :aria-label="`Dein Gefühl (${state.me?.kuerzel})`">
      <button
        v-for="d in DAUMEN"
        :key="d.v"
        type="button"
        :class="['vbtn', d.cls, { an: meins === d.v }]"
        :aria-pressed="meins === d.v"
        :aria-label="d.label"
        :title="`${d.label} (${state.me?.kuerzel})`"
        @click.stop.prevent="setVote(ideaId, d.v)"
      ><Icon name="thumb" :size="16" /></button>
    </span>
    <span v-if="anderer" :class="['other', seins !== null ? art(seins).cls : 'leer']" :title="`${anderer.name}: ${seins !== null ? art(seins).label : 'noch keine Angabe'}`">
      <span class="kz">{{ anderer.kuerzel }}</span>
      <Icon v-if="seins !== null" name="thumb" :size="15" class="ico" />
      <span v-else class="dash">–</span>
    </span>
  </span>
</template>

<style scoped>
.votes { display: inline-flex; align-items: center; gap: 6px; flex: none; }
.mine { display: inline-flex; gap: 2px; padding: 2px; border-radius: 9px; background: var(--chip); }
.vbtn { width: 28px; height: 28px; display: inline-flex; align-items: center; justify-content: center; border: 0; border-radius: 7px; background: transparent; color: var(--muted); cursor: pointer; }
.vbtn.an { color: var(--on-accent); }
.vbtn.hoch.an { background: var(--ok); }
.vbtn.seite.an { background: var(--warn); }
.vbtn.runter.an { background: var(--danger); }
.seite :deep(svg) { transform: rotate(90deg); }
.runter :deep(svg) { transform: rotate(180deg); }
.other { display: inline-flex; align-items: center; gap: 3px; min-width: 40px; height: 28px; padding: 0 6px; border-radius: 8px; border: 1px solid var(--line); font-size: 11px; font-weight: 700; color: var(--muted); }
.other.hoch .ico { color: var(--ok); }
.other.seite .ico { color: var(--warn); }
.other.runter .ico { color: var(--danger); }
.dash { padding: 0 3px; }
</style>
