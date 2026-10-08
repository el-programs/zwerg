import { createRouter, createWebHashHistory } from 'vue-router';
import { state } from './lib/store.js';
// Die Hauptbereiche werden direkt mitgeladen, damit ein Menüklick nie auf Nachladen warten muss.
import StartView from './views/StartView.vue';
import IdeasView from './views/IdeasView.vue';
import IdeaView from './views/IdeaView.vue';
import RatingView from './views/RatingView.vue';
import WeightsView from './views/WeightsView.vue';
import PhasesView from './views/PhasesView.vue';
import SettingsView from './views/SettingsView.vue';
import KiView from './views/KiView.vue';
import KiSuggestView from './views/KiSuggestView.vue';

// Hash-Adressen (#/ideen …), damit die App auf GitHub Pages ohne Server-Regeln läuft.
export const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'start', component: StartView },
    { path: '/ideen', name: 'ideen', component: IdeasView },
    { path: '/idee/:id/bewertung', name: 'bewertung', component: RatingView },
    { path: '/idee/:id/ki', name: 'ki', component: KiView },
    { path: '/ki/vorschlaege', name: 'ki-vorschlaege', component: KiSuggestView },
    { path: '/gewichtung', name: 'gewichtung', component: WeightsView },
    { path: '/idee/:id', name: 'idee', component: IdeaView, meta: { nav: false } },
    { path: '/phasen', name: 'phasen', component: PhasesView },
    { path: '/mehr', name: 'mehr', component: SettingsView },
    { path: '/koppeln/:linkId?/:code?', name: 'koppeln', component: () => import('./views/LinkApproveView.vue'), meta: { nav: false } },
    { path: '/anmelden', name: 'anmelden', component: () => import('./views/LoginView.vue'), meta: { public: true, nav: false } },
    { path: '/einladung/:token', name: 'einladung', component: () => import('./views/InviteView.vue'), meta: { public: true, nav: false } },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
  scrollBehavior: () => ({ top: 0 }),
});

router.beforeEach((to) => {
  const signedIn = state.status === 'ready';
  if (to.meta.public) {
    if (signedIn && to.name === 'anmelden') return typeof to.query.weiter === 'string' ? to.query.weiter : '/';
    return true;
  }
  if (!signedIn) {
    return { name: 'anmelden', query: to.fullPath !== '/' ? { weiter: to.fullPath } : {} };
  }
  return true;
});
