import { createApp } from 'vue';
import '@fontsource/ibm-plex-sans/400.css';
import '@fontsource/ibm-plex-sans/500.css';
import '@fontsource/ibm-plex-sans/600.css';
import './style.css';
import App from './App.vue';
import { router } from './router.js';
import { init } from './lib/store.js';

init().finally(() => {
  createApp(App).use(router).mount('#app');
});
