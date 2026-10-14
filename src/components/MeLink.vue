<script setup>
// Eigenes Kürzel oben rechts: führt am Handy von jeder Hauptseite in die Einstellungen.
import { state } from '../lib/store.js';
</script>

<template>
  <router-link v-if="state.me" to="/mehr" class="avatar me mobile-only" :aria-label="`Einstellungen von ${state.me.name}`">{{ state.me.kuerzel }}</router-link>
</template>

<style scoped>
.me { width: 36px; height: 36px; flex: none; text-decoration: none; color: var(--text); font-size: 13px; margin-left: 4px; }
</style>
