<script setup>
// Handy: Leiste unten mit Plus in der Mitte. Computer: Seitenleiste links.
import Icon from './Icon.vue';
import ZLogo from './ZLogo.vue';
defineEmits(['plus']);
</script>

<template>
  <nav class="nav" aria-label="Hauptmenü">
    <div class="brand side-only">
      <ZLogo :size="34" :echoes="1" />
      <span>Zwerg</span>
    </div>
    <button class="new side-only" type="button" @click="$emit('plus')"><Icon name="plus" :size="20" />Neue Notiz</button>
    <router-link to="/" class="item" exact-active-class="active"><Icon name="home" /><span>Start</span></router-link>
    <router-link to="/ideen" class="item" active-class="active"><Icon name="list" /><span class="side-label">Gedanken &amp; Ideen</span><span class="mobile-label">Ideen</span></router-link>
    <div class="center mobile-only">
      <button class="plus" type="button" aria-label="Neue Notiz" @click="$emit('plus')"><Icon name="plus" :size="26" /></button>
    </div>
    <router-link to="/notizen" class="item" active-class="active"><Icon name="note" /><span>Notizen</span></router-link>
    <router-link to="/phasen" class="item" active-class="active"><Icon name="phases" /><span>Plan</span></router-link>
    <router-link to="/mehr" class="item side-only" active-class="active"><Icon name="settings" /><span>Einstellungen</span></router-link>
  </nav>
</template>

<style scoped>
.nav {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 20;
  height: calc(var(--nav-h) + var(--safe-b));
  padding-bottom: var(--safe-b);
  background: var(--surface);
  border-top: 1px solid var(--line);
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  align-items: center;
}
.side-only, .item.side-only { display: none; }
.side-label { display: none; }
.item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 3px;
  min-height: 48px;
  text-decoration: none;
  color: var(--muted);
  font-size: 11px;
}
.item.active { color: var(--accent); font-weight: 600; }
.center { display: flex; justify-content: center; }
.plus {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  border: 0;
  background: var(--accent);
  color: var(--on-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

@media (max-width: 899px) {
  .nav.hide-mobile { display: none; }
}

@media (min-width: 900px) {
  .nav {
    top: 0;
    right: auto;
    width: var(--side-w);
    height: auto;
    padding: 20px 14px;
    border-top: 0;
    border-right: 1px solid var(--line);
    display: flex;
    flex-direction: column;
    align-items: stretch;
    gap: 4px;
  }
  .mobile-only { display: none; }
  .side-only, .item.side-only { display: flex; }
  .side-label { display: inline; }
  .mobile-label { display: none; }
  .brand {
    align-items: center;
    gap: 10px;
    padding: 4px 10px 22px;
    font-size: 20px;
    font-weight: 600;
    letter-spacing: 0.02em;
  }
  .new {
    align-items: center;
    justify-content: center;
    gap: 8px;
    height: 44px;
    margin-bottom: 18px;
    border: 0;
    border-radius: 10px;
    background: var(--accent);
    color: var(--on-accent);
    font-weight: 600;
    cursor: pointer;
  }
  .item {
    flex-direction: row;
    justify-content: flex-start;
    gap: 12px;
    min-height: 42px;
    padding: 0 12px;
    border-radius: 10px;
    font-size: 15px;
    color: var(--text);
  }
  .item:hover { background: var(--chip); }
  .item.active { background: var(--chip); color: var(--accent); }
}
</style>
