<script setup>
// Übersicht der Besprechungen, die neueste oben.
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { addMeeting, itemsOf, profile, state } from '../lib/store.js';
import { datum } from '../lib/format.js';
import Icon from './Icon.vue';

const router = useRouter();
const liste = computed(() =>
  [...state.meetings].sort((a, b) => (a.held_on === b.held_on ? (a.created_at < b.created_at ? 1 : -1) : a.held_on < b.held_on ? 1 : -1)),
);
function info(m) {
  const items = itemsOf(m.id);
  const offen = items.filter((i) => !i.result.trim()).length;
  const teile = [`${items.length} Punkt${items.length === 1 ? '' : 'e'}`];
  if (offen) teile.push(`${offen} ohne Ergebnis`);
  return teile.join(' · ');
}
function neu() {
  const id = addMeeting();
  router.push(`/notizen/besprechung/${id}`);
}
</script>

<template>
  <div class="stack">
    <button class="btn primary new" type="button" @click="neu"><Icon name="plus" :size="20" />Neue Besprechung</button>
    <p v-if="!liste.length" class="empty">Noch keine Besprechungen. Legt die erste an und sammelt die Tagesordnungspunkte.</p>
    <router-link v-for="m in liste" :key="m.id" :to="`/notizen/besprechung/${m.id}`" class="card meeting">
      <span class="small muted">{{ datum(m.held_on) }}<template v-if="m.start_time"> · {{ m.start_time.slice(0, 5) }} Uhr</template></span>
      <strong>{{ m.title || 'Besprechung' }}</strong>
      <span class="row foot">
        <span class="small muted grow">{{ info(m) }}</span>
        <span v-for="a in m.attendees" :key="a" class="chip outline">{{ profile(a)?.kuerzel }}</span>
      </span>
    </router-link>
  </div>
</template>

<style scoped>
.new { align-self: flex-start; gap: 8px; }
.meeting { display: flex; flex-direction: column; gap: 4px; text-decoration: none; color: inherit; }
.foot { margin-top: 4px; gap: 6px; }
.grow { flex: 1; min-width: 0; }
</style>
