<script setup>
import { onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { callAuth } from '../lib/supabase.js';
import { registerWithInvite, state } from '../lib/store.js';
import ZLogo from '../components/ZLogo.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const name = ref('');
const error = ref('');
const busy = ref(false);
const loading = ref(true);
const canPasskey = typeof window.PublicKeyCredential !== 'undefined';

onMounted(async () => {
  try {
    const r = await callAuth('invite-info', { token: route.params.token });
    name.value = r.name;
  } catch (e) {
    error.value = e.message;
  } finally {
    loading.value = false;
  }
});

async function einrichten() {
  error.value = '';
  busy.value = true;
  try {
    await registerWithInvite(route.params.token);
    router.replace('/');
  } catch (e) {
    error.value = e.message;
  } finally {
    busy.value = false;
  }
}
</script>

<template>
  <main class="invite">
    <ZLogo :size="120" animate label="Zwerg-Logo" />
    <h1 class="name">Zwerg</h1>
    <p v-if="loading" class="muted">Einladung wird geprüft …</p>
    <template v-else-if="name">
      <h2>Willkommen, {{ name }}!</h2>
      <p class="center">
        Richte jetzt auf diesem Gerät einen Passkey ein. Du bestätigst ihn mit Face ID oder Fingerabdruck –
        ein Passwort gibt es nicht.
      </p>
      <p v-if="state.status === 'ready'" class="small muted center">
        Hinweis: Auf diesem Gerät ist bereits {{ state.me?.name }} angemeldet. Der Passkey wird für {{ name }} eingerichtet.
      </p>
      <button class="btn primary block" type="button" :disabled="busy || !canPasskey" @click="einrichten">
        <Icon name="key" />{{ busy ? 'Einen Moment …' : 'Passkey einrichten' }}
      </button>
      <p v-if="!canPasskey" class="error center">Dieser Browser unterstützt keine Passkeys. Bitte Safari auf dem iPhone verwenden.</p>
    </template>
    <p v-if="error" class="error center">{{ error }}</p>
    <router-link v-if="error" to="/anmelden" class="btn">Zur Anmeldung</router-link>
  </main>
</template>

<style scoped>
.invite {
  min-height: 100dvh;
  max-width: 420px;
  margin: 0 auto;
  padding: 48px 20px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
}
.name { font-size: 30px; letter-spacing: 0.02em; }
.center { text-align: center; margin: 0; }
</style>
