import { createApp } from 'vue';
import '@fontsource/ibm-plex-sans/400.css';
import '@fontsource/ibm-plex-sans/500.css';
import '@fontsource/ibm-plex-sans/600.css';
import './style.css';
import App from './App.vue';
import { router } from './router.js';
import { init } from './lib/store.js';
import { registerSW } from 'virtual:pwa-register';

// Neue Version: sofort aktivieren und die Seite neu laden, damit nie alte und neue Teile gemischt werden.
registerSW({ immediate: true });

// Fehlt nach einem Update ein Programmteil der alten Version, einmal neu laden statt stehen zu bleiben.
function reloadOnce() {
  const key = 'zwerg-reload';
  const last = Number(sessionStorage.getItem(key) || 0);
  if (Date.now() - last < 10000) return;
  sessionStorage.setItem(key, String(Date.now()));
  window.location.reload();
}
window.addEventListener('vite:preloadError', (e) => {
  e.preventDefault();
  reloadOnce();
});
router.onError((err, to) => {
  if (/dynamically imported module|Importing a module script failed|Failed to fetch/i.test(String(err?.message))) {
    if (to?.fullPath) window.location.hash = to.fullPath;
    reloadOnce();
  }
});

init().finally(() => {
  createApp(App).use(router).mount('#app');
});
