<script setup>
const phasen = [
  { nr: 1, name: 'Ideenfindung', ziel: 'Breit sammeln ohne Bewertung, danach filtern und bewerten.', ergebnis: '2–3 Favoriten' },
  { nr: 2, name: 'Machbarkeitsprüfung und Auswahl', ziel: 'Markt, Wettbewerb und Business Case prüfen.', ergebnis: 'Eine Idee als Gründungskandidat – oder zurück zu Phase 1' },
  { nr: 3, name: 'Pilot- und Vorbereitungsphase', ziel: 'Mit echten Kunden bei geringem Risiko testen; parallel Businessplan, Finanzierung und Rechtsform vorbereiten.', ergebnis: 'Gründungsentscheidung' },
  { nr: 4, name: 'Gründung', ziel: 'Formale Gründung und Aufbau.', ergebnis: 'Die neue Firma' },
];
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner"><h1>Phasen</h1></div>
  </header>
  <main class="page">
    <ol class="phasen">
      <li v-for="p in phasen" :key="p.nr" class="card" :class="{ current: p.nr === 1 }">
        <div class="row">
          <span class="nr">{{ p.nr }}</span>
          <h2 class="grow">{{ p.name }}</h2>
          <span v-if="p.nr === 1" class="badge-new">aktuell</span>
        </div>
        <p>{{ p.ziel }}</p>
        <p class="small muted">Ergebnis: {{ p.ergebnis }}</p>
      </li>
    </ol>
    <p class="small muted">
      Ziele, Abschlusskriterien und Hinweise je Phase werden in Etappe 4 bearbeitbar.
    </p>
  </main>
</template>

<style scoped>
.phasen { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.phasen p { margin: 6px 0 0; }
.current { border-color: var(--accent); }
.nr {
  width: 28px; height: 28px; border-radius: 50%; flex: none;
  display: inline-flex; align-items: center; justify-content: center;
  background: var(--chip); font-weight: 600; font-size: 14px;
}
.current .nr { background: var(--accent); color: var(--on-accent); }
.grow { flex: 1; }
</style>
