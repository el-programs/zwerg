<script setup>
import Icon from './Icon.vue';
defineEmits(['plus']);
</script>

<template>
  <nav class="bottom-nav" aria-label="Hauptmenü">
    <router-link to="/" class="item" exact-active-class="active"><Icon name="home" />Start</router-link>
    <router-link to="/ideen" class="item" active-class="active"><Icon name="list" />Ideen</router-link>
    <div class="center">
      <button class="plus" type="button" aria-label="Neue Idee" @click="$emit('plus')"><Icon name="plus" :size="26" /></button>
    </div>
    <router-link to="/phasen" class="item" active-class="active"><Icon name="phases" />Phasen</router-link>
    <router-link to="/mehr" class="item" active-class="active"><Icon name="more" />Mehr</router-link>
  </nav>
</template>

<style scoped>
.bottom-nav {
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
  max-width: 100%;
}
.item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  text-decoration: none;
  color: var(--muted);
  font-size: 11px;
  min-height: 48px;
  justify-content: center;
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
</style>
