<script setup>
// Auswahl als Knopfreihe: Zahlen (z. B. Gewichte 0–5) oder Antworten in Worten (Bewertung).
const props = defineProps({
  modelValue: { type: Number, default: null },
  min: { type: Number, default: 1 },
  max: { type: Number, default: 5 },
  label: { type: String, required: true },
  suggestion: { type: Number, default: null },
  disabled: { type: Boolean, default: false },
  // Beschriftungen in Wertereihenfolge; dann zeigt eine zweite Zeile die Punkte (Wert − 1).
  labels: { type: Array, default: null },
});
const emit = defineEmits(['update:modelValue']);
const values = Array.from({ length: props.max - props.min + 1 }, (_, i) => props.min + i);
</script>

<template>
  <div>
    <div class="scores" :class="{ worded: labels }" role="radiogroup" :aria-label="label">
      <button
        v-for="(v, i) in values"
        :key="v"
        type="button"
        role="radio"
        :aria-checked="modelValue === v"
        :class="{ suggested: modelValue === null && suggestion === v }"
        :disabled="disabled"
        @click="emit('update:modelValue', v)"
      >{{ labels ? labels[i] : v }}</button>
    </div>
    <div v-if="labels" class="points" aria-hidden="true">
      <span v-for="v in values" :key="v">{{ v - 1 }}</span>
    </div>
  </div>
</template>

<style scoped>
.scores { display: flex; gap: 6px; }
.scores.worded { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 5px; }
button {
  flex: 1;
  min-width: 40px;
  height: 40px;
  border-radius: 9px;
  border: 1px solid var(--line);
  background: var(--surface);
  color: var(--text);
  font-weight: 600;
  cursor: pointer;
}
.worded button { min-width: 0; height: 46px; padding: 0 2px; font-size: 12.5px; line-height: 1.15; }
button[aria-checked="true"] { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
button.suggested { border: 2px dashed var(--accent); }
button:disabled { cursor: default; opacity: 0.7; }
button[aria-checked="true"]:disabled { opacity: 1; }
.points { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); text-align: center; font-size: 11px; color: var(--muted); margin-top: 3px; }
@media (min-width: 700px) { .worded button { font-size: 13.5px; } }
</style>
