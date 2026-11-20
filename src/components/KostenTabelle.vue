<script setup>
// Kostentabelle einer Idee: Positionen einmalig oder monatlich mit Betrag und Notiz, Summen darunter.
import { computed, reactive } from 'vue';
import { addCost, costTotals, costsOf, deleteCost, updateCost } from '../lib/store.js';
import { eur } from '../lib/business.js';
import Icon from './Icon.vue';

const props = defineProps({ ideaId: { type: String, required: true } });
const ARTEN = [
  { id: 'einmalig', name: 'Einmalig bis zur Gründung' },
  { id: 'monatlich', name: 'Monatlich nach der Gründung' },
];
const posten = computed(() => costsOf(props.ideaId));
const summe = computed(() => costTotals(props.ideaId));
const neu = reactive({ einmalig: '', monatlich: '' });

function betrag(c, wert) {
  const text = String(wert).trim().replace(/\./g, '').replace(',', '.');
  const zahl = text === '' ? null : Number(text);
  if (text !== '' && !Number.isFinite(zahl)) return;
  if (zahl !== (c.amount === null ? null : Number(c.amount))) updateCost(c.id, { amount: zahl });
}
const zeigen = (v) => (v === null || v === undefined ? '' : Number(v).toLocaleString('de-DE', { maximumFractionDigits: 2 }));
function hinzu(kind) {
  if (!neu[kind].trim()) return;
  addCost(props.ideaId, kind, neu[kind]);
  neu[kind] = '';
}
function weg(c) {
  if (confirm(`Position „${c.label}“ entfernen?`)) deleteCost(c.id);
}
</script>

<template>
  <div class="kosten">
    <section v-for="a in ARTEN" :key="a.id" class="block">
      <h3>{{ a.name }}</h3>
      <div v-for="c in posten.filter((x) => x.kind === a.id)" :key="c.id" class="zeile">
        <input class="input label" :value="c.label" aria-label="Position" @change="$event.target.value.trim() && updateCost(c.id, { label: $event.target.value.trim() })">
        <label class="betrag">
          <span class="visually-hidden">Betrag</span>
          <input class="input" inputmode="decimal" :value="zeigen(c.amount)" placeholder="–" @change="betrag(c, $event.target.value)">
          <span class="eur">€</span>
        </label>
        <input class="input note" :value="c.note" placeholder="Notiz" aria-label="Notiz" @change="updateCost(c.id, { note: $event.target.value })">
        <button class="icon-btn" type="button" aria-label="Position entfernen" @click="weg(c)"><Icon name="trash" :size="18" /></button>
      </div>
      <form class="add" @submit.prevent="hinzu(a.id)">
        <input v-model="neu[a.id]" class="input" :placeholder="a.id === 'einmalig' ? 'Neue Position, z. B. Fotoausrüstung' : 'Neue Position, z. B. Buchhaltungssoftware'">
        <button class="btn" type="submit" :disabled="!neu[a.id].trim()">Hinzufügen</button>
      </form>
    </section>

    <div class="card summen">
      <div><span class="small muted">Budget bis zur Gründung</span><strong>{{ eur(summe.einmalig) }}</strong></div>
      <div><span class="small muted">Laufend pro Monat</span><strong>{{ eur(summe.monatlich) }}</strong></div>
      <div><span class="small muted">Laufend im ersten Jahr</span><strong>{{ eur(summe.monatlich * 12) }}</strong></div>
      <div><span class="small muted">Gesamt erstes Jahr</span><strong>{{ eur(summe.einmalig + summe.monatlich * 12) }}</strong></div>
      <p v-if="summe.offen" class="small muted full">{{ summe.offen }} Position{{ summe.offen === 1 ? '' : 'en' }} noch ohne Betrag.</p>
    </div>
  </div>
</template>

<style scoped>
.kosten { display: flex; flex-direction: column; gap: 14px; }
.block { display: flex; flex-direction: column; gap: 6px; }
h3 { margin: 0; font-size: 14px; color: var(--muted); font-weight: 600; }
.zeile { display: grid; grid-template-columns: minmax(0, 2fr) 120px minmax(0, 1.4fr) auto; gap: 6px; align-items: center; }
.betrag { position: relative; display: block; }
.betrag .input { width: 100%; text-align: right; padding-right: 26px; }
.eur { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); color: var(--muted); font-size: 14px; }
.add { display: grid; grid-template-columns: 1fr auto; gap: 6px; }
.summen { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; }
.summen div { display: flex; flex-direction: column; gap: 2px; }
.summen strong { font-size: 18px; }
.full { grid-column: 1 / -1; margin: 0; }
@media (max-width: 640px) {
  .zeile { grid-template-columns: minmax(0, 1fr) 110px auto; }
  .zeile .note { grid-column: 1 / 3; grid-row: 2; }
}
</style>
