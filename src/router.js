import { createRouter, createWebHashHistory } from 'vue-router';
import { state } from './lib/store.js';

// Hash-Adressen (#/ideen …), damit die App auf GitHub Pages ohne Server-Regeln läuft.
export const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'start', component: () => import('./views/StartView.vue') },
    { path: '/ideen', name: 'ideen', component: () => import('./views/IdeasView.vue') },
    { path: '/idee/:id/bewertung', name: 'bewertung', component: () => import('./views/RatingView.vue') },
    { path: '/gewichtung', name: 'gewichtung', component: () => import('./views/WeightsView.vue') },
    { path: '/idee/:id', name: 'idee', component: () => import('./views/IdeaView.vue'), meta: { nav: false } },
    { path: '/phasen', name: 'phasen', component: () => import('./views/PhasesView.vue') },
    { path: '/mehr', name: 'mehr', component: () => import('./views/SettingsView.vue') },
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
