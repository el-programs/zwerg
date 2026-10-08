<script setup>
// Auswahl 1–5 (bzw. 0–5 bei Gewichten) als Knopfreihe.
const props = defineProps({
  modelValue: { type: Number, default: null },
  min: { type: Number, default: 1 },
  max: { type: Number, default: 5 },
  label: { type: String, required: true },
  suggestion: { type: Number, default: null },
  disabled: { type: Boolean, default: false },
});
const emit = defineEmits(['update:modelValue']);
const values = Array.from({ length: props.max - props.min + 1 }, (_, i) => props.min + i);
</script>

<template>
  <div class="scores" role="radiogroup" :aria-label="label">
    <button
      v-for="v in values"
      :key="v"
      type="button"
      role="radio"
      :aria-checked="modelValue === v"
      :class="{ suggested: modelValue === null && suggestion === v }"
      :disabled="disabled"
      @click="emit('update:modelValue', v)"
    >{{ v }}</button>
  </div>
</template>

<style scoped>
.scores { display: flex; gap: 6px; }
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
button[aria-checked="true"] { background: var(--accent); border-color: var(--accent); color: var(--on-accent); }
button.suggested { border: 2px dashed var(--accent); }
button:disabled { cursor: default; opacity: 0.7; }
button[aria-checked="true"]:disabled { opacity: 1; }
</style>
