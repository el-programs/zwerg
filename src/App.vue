<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { state } from './lib/store.js';
import BottomNav from './components/BottomNav.vue';
import QuickCapture from './components/QuickCapture.vue';

const route = useRoute();
const router = useRouter();
const capture = ref(null);
// Am Computer ist die Navigation immer als Seitenleiste da; am Handy blendet sie
// sich auf Detailseiten aus (dort sitzt z. B. das Kommentarfeld unten).
const withNav = computed(() => state.status === 'ready' && !route.meta.public);
const hideNavMobile = computed(() => route.meta.nav === false);

// Abgemeldet (z. B. Gerät gesperrt): zurück zur Anmeldung.
watch(
  () => state.status,
  (s) => {
    if (s === 'signedOut' && !route.meta.public) router.replace({ name: 'anmelden' });
  },
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
@media (min-width: 900px) {
  .with-side { --side: var(--side-w); padding-left: var(--side-w); }
  .toast.with-side { bottom: 28px; }
}
</style>
