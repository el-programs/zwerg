<script setup>
// Synergie-Symbol (zwei Ringe): öffnet die verbundene Idee, bei mehreren eine Auswahl.
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { synergiesOf } from '../lib/store.js';
import Icon from './Icon.vue';

const props = defineProps({ ideaId: { type: String, required: true }, size: { type: Number, default: 20 } });
const router = useRouter();
const links = computed(() => synergiesOf(props.ideaId));
const offen = ref(false);
const root = ref(null);

function tippen() {
  if (links.value.length === 1) router.push(`/idee/${links.value[0].idea.id}`);
  else offen.value = !offen.value;
}
function oeffnen(id) {
  offen.value = false;
  router.push(`/idee/${id}`);
}
function draussen(e) {
  if (root.value && !root.value.contains(e.target)) offen.value = false;
}
function taste(e) {
  if (e.key === 'Escape') offen.value = false;
}
watch(offen, (o) => {
  if (o) {
    document.addEventListener('pointerdown', draussen);
    document.addEventListener('keydown', taste);
  } else {
    document.removeEventListener('pointerdown', draussen);
    document.removeEventListener('keydown', taste);
  }
});
onBeforeUnmount(() => { offen.value = false; });
</script>

<template>
  <span v-if="links.length" ref="root" class="synergy" :style="offen ? { zIndex: 30 } : null">
    <button
      class="icon-btn syn-btn"
      type="button"
      :aria-expanded="links.length > 1 ? offen : undefined"
      :aria-label="links.length === 1 ? `Synergie mit ${links[0].idea.title}` : `${links.length} Synergien anzeigen`"
      :title="links.length === 1 ? `Synergie: ${links[0].idea.title}` : `${links.length} Synergien`"
      @click.stop.prevent="tippen"
    >
      <Icon name="synergy" :size="size" />
      <span v-if="links.length > 1" class="count">{{ links.length }}</span>
    </button>
    <span v-if="offen" class="menu card" role="menu" @click.stop.prevent>
      <span class="menu-head small muted">Lässt sich kombinieren mit</span>
      <button v-for="s in links" :key="s.id" class="menu-item" type="button" role="menuitem" @click.stop.prevent="oeffnen(s.idea.id)">
        <span class="menu-title">{{ s.idea.title || 'Ohne Titel' }}</span>
        <span v-if="s.note" class="small muted">{{ s.note }}</span>
      </button>
    </span>
  </span>
</template>

<style scoped>
.synergy { position: relative; display: inline-flex; flex: none; }
.syn-btn { color: var(--accent); position: relative; }
.count {
  position: absolute;
  top: 6px;
  right: 3px;
  min-width: 16px;
  height: 16px;
  padding: 0 4px;
  border-radius: 8px;
  background: var(--accent);
  color: var(--on-accent);
  font-size: 10.5px;
  font-weight: 700;
  line-height: 16px;
  text-align: center;
}
.menu {
  position: absolute;
  top: 100%;
  right: 0;
  z-index: 20;
  width: min(320px, calc(100vw - 32px));
  max-height: 60vh;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 8px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.16);
}
.menu-head { padding: 4px 8px 6px; }
.menu-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
  text-align: left;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  padding: 8px;
  border-radius: 8px;
  cursor: pointer;
}
.menu-item:hover, .menu-item:focus-visible { background: var(--chip); }
.menu-title { font-weight: 600; }
</style>
