<script setup>
import { computed } from 'vue';
import { state } from '../lib/store.js';

const status = computed(() => {
  const n = state.outbox.length;
  if (!state.online) {
    return { color: 'var(--warn)', text: n ? `Offline – ${n} Änderung${n > 1 ? 'en' : ''} warten auf Abgleich` : 'Offline – Erfassen geht trotzdem' };
  }
  if (n || state.syncing) return { color: 'var(--warn)', text: 'Wird abgeglichen …' };
  if (state.error) return { color: 'var(--danger)', text: state.error };
  return { color: 'var(--ok)', text: 'Alles synchronisiert' };
});
</script>

<template>
  <p class="sync small muted" role="status">
    <span class="dot" :style="{ background: status.color }"></span>{{ status.text }}
  </p>
</template>

<style scoped>
.sync { display: flex; align-items: center; gap: 8px; margin: 0; }
.dot { width: 8px; height: 8px; border-radius: 50%; flex: none; }
</style>
