<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { state } from '../lib/store.js';
import {
  einstellungen, euro, ladeStatus, limitErreicht, meineStufe, MODELLE, setKiEinstellungen, setStufe, STUFEN, verbrauchMonat,
} from '../lib/ki.js';

const emit = defineEmits(['error']);
const limit = ref('');
watch(einstellungen, (e) => (limit.value = String(Number(e.monthly_limit_eur))), { immediate: true });
const anteil = computed(() => Math.min(100, (verbrauchMonat.value / Math.max(0.01, Number(einstellungen.value.monthly_limit_eur))) * 100));
const monat = new Date().toLocaleDateString('de-DE', { month: 'long' });
onMounted(ladeStatus);

async function run(fn) {
  try {
    await fn();
  } catch (e) {
    emit('error', e.message);
  }
}
function limitSpeichern() {
  const v = Math.round(Number(String(limit.value).replace(',', '.')) * 100) / 100;
  if (!Number.isFinite(v) || v < 0 || v > 500) return emit('error', 'Bitte einen Betrag zwischen 0 und 500 € eingeben.');
  if (v === Number(einstellungen.value.monthly_limit_eur)) return;
  run(() => setKiEinstellungen({ monthly_limit_eur: v }));
}
</script>

<template>
  <section class="stack">
    <h2 class="section-title">KI-Unterstützung</h2>

    <div v-if="state.kiStatus && !state.kiStatus.configured" class="card stack note">
      <strong>Noch nicht eingerichtet</strong>
      <p class="small">
        Die KI-Funktionen sind eingebaut, aber ausgeschaltet, bis ihr einen Claude-API-Schlüssel hinterlegt.
        Die Anleitung steht in <code>ANLEITUNG.md</code>, Teil E.
      </p>
    </div>

    <h3 class="label">Meine Stufe (gilt nur für {{ state.me?.name }})</h3>
    <div class="options" role="radiogroup" aria-label="KI-Stufe">
      <button
        v-for="s in STUFEN"
        :key="s.id"
        type="button"
        role="radio"
        :aria-checked="meineStufe === s.id"
        class="option"
        @click="run(() => setStufe(s.id))"
      >
        <strong>{{ s.name }}</strong>
        <span class="small muted">{{ s.info }}</span>
      </button>
    </div>

    <h3 class="label">Modell (für euch beide)</h3>
    <div class="options two" role="radiogroup" aria-label="KI-Modell">
      <button
        v-for="m in MODELLE"
        :key="m.id"
        type="button"
        role="radio"
        :aria-checked="einstellungen.model === m.id"
        class="option"
        @click="run(() => setKiEinstellungen({ model: m.id }))"
      >
        <strong>{{ m.name }}</strong>
        <span class="small muted">{{ m.info }}</span>
      </button>
    </div>

    <h3 class="label">Kostenbremse</h3>
    <div class="card stack">
      <div class="row between">
        <span>Verbrauch im {{ monat }}</span>
        <strong>ca. {{ euro(verbrauchMonat) }} von {{ euro(einstellungen.monthly_limit_eur) }}</strong>
      </div>
      <span class="bar" :class="{ full: limitErreicht }" aria-hidden="true"><span :style="{ width: `${anteil}%` }"></span></span>
      <p v-if="limitErreicht" class="small warn">Limit erreicht – die KI ist bis Monatsende gesperrt, außer ihr hebt das Limit an.</p>
      <label class="field">
        <span>Monatslimit in Euro (für euch beide zusammen)</span>
        <input v-model="limit" class="input" inputmode="decimal" @blur="limitSpeichern" @keydown.enter.prevent="$event.target.blur()">
      </label>
      <p class="small muted">Kosten sind Näherungswerte aus den Preisen der Claude API (umgerechnet in Euro).</p>
    </div>

    <p class="small muted">
      Datenschutz: Nur wenn ihr eine KI-Funktion nutzt, wird die betroffene Notiz (Titel, Beschreibung, Kommentare) an Anthropic
      übermittelt. Anthropic nutzt API-Daten nicht zum Training. KI-Bewertungen sind immer als Vorschlag gekennzeichnet und fließen nie
      automatisch in eure Wertung ein.
    </p>
  </section>
</template>

<style scoped>
p { margin: 0; }
.label { font-size: 13px; color: var(--muted); font-weight: 500; margin-top: 4px; }
.options { display: grid; gap: 8px; }
.options.two { grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }
.option {
  display: flex; flex-direction: column; gap: 2px; align-items: flex-start; text-align: left;
  padding: 12px 14px; border-radius: var(--radius); border: 1px solid var(--line); background: var(--surface); cursor: pointer;
}
.option[aria-checked="true"] { border: 2px solid var(--accent); padding: 11px 13px; }
.between { justify-content: space-between; flex-wrap: wrap; }
.bar { display: block; height: 8px; border-radius: 4px; background: var(--chip); overflow: hidden; }
.bar span { display: block; height: 100%; background: var(--accent); }
.bar.full span { background: var(--danger); }
.warn { color: var(--danger); }
.note { border-color: var(--warn); }
code { font-size: 13px; }
</style>
