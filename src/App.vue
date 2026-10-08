<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { state } from './lib/store.js';
import { ladeStatus } from './lib/ki.js';
import BottomNav from './components/BottomNav.vue';
import QuickCapture from './components/QuickCapture.vue';

const route = useRoute();
const router = useRouter();
const capture = ref(null);
// Am Computer ist die Navigation immer als Seitenleiste da; am Handy blendet sie
// sich auf Detailseiten aus (dort sitzt z. B. das Kommentarfeld unten).
const withNav = computed(() => state.status === 'ready' && !route.meta.public);
const hideNavMobile = computed(() => route.meta.nav === false);

function neuLaden() {
  window.location.reload();
}

// Abgemeldet (z. B. Gerät gesperrt): zurück zur Anmeldung. Angemeldet: KI-Status einmal abfragen.
watch(
  () => state.status,
  (s) => {
    if (s === 'signedOut' && !route.meta.public) router.replace({ name: 'anmelden' });
    if (s === 'ready') ladeStatus();
  },
  { immediate: true },
);
</script>

<template>
  <div :class="{ 'with-side': withNav }">
    <router-view />
  </div>
  <template v-if="state.status === 'ready'">
    <BottomNav v-if="withNav" :class="{ 'hide-mobile': hideNavMobile }" @plus="capture?.open()" />
    <QuickCapture ref="capture" />
  </template>
  <div v-if="state.fatal" class="fatal" role="alert">
    <strong>Da ist etwas schiefgelaufen.</strong>
    <span class="small">{{ state.fatal }}</span>
    <div class="row">
      <button class="btn primary" type="button" @click="neuLaden">Neu laden</button>
      <button class="btn" type="button" @click="state.fatal = ''">Schließen</button>
    </div>
  </div>
  <div class="toast" :class="{ 'with-side': withNav }" role="status" aria-live="polite">
    <span v-if="state.toast">{{ state.toast }}</span>
  </div>
</template>

<style>
.toast {
  position: fixed;
  left: 0;
  right: 0;
  bottom: calc(var(--nav-h) + var(--safe-b) + 14px);
  display: flex;
  justify-content: center;
  pointer-events: none;
  z-index: 50;
}
.toast span {
  background: var(--text);
  color: var(--bg);
  padding: 10px 16px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 500;
  max-width: calc(100% - 32px);
}
.fatal {
  position: fixed;
  left: 12px;
  right: 12px;
  top: calc(12px + env(safe-area-inset-top, 0px));
  z-index: 60;
  max-width: 560px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 14px 16px;
  border-radius: 12px;
  background: var(--surface);
  border: 2px solid var(--danger);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
  overflow-wrap: anywhere;
}
@media (min-width: 900px) {
  .with-side { --side: var(--side-w); padding-left: var(--side-w); }
  .toast.with-side { bottom: 28px; }
}
</style>
