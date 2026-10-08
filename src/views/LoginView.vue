<script setup>
import { onBeforeUnmount, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import QRCode from 'qrcode';
import { linkUrl, loginWithPasskey, pollLink, startLink, state } from '../lib/store.js';
import ZLogo from '../components/ZLogo.vue';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const busy = ref(false);
const error = ref('');
const qr = ref('');
const qrStatus = ref('');
let timer = null;
let stopAt = 0;

function weiter() {
  router.replace(typeof route.query.weiter === 'string' ? route.query.weiter : '/');
}

async function passkey() {
  error.value = '';
  busy.value = true;
  try {
    await loginWithPasskey();
    weiter();
  } catch (e) {
    error.value = e.message;
  } finally {
    busy.value = false;
  }
}

async function showQr() {
  error.value = '';
  stop();
  try {
    const link = await startLink();
    qr.value = await QRCode.toDataURL(linkUrl(link.linkId, link.approveCode), { margin: 1, width: 560 });
    qrStatus.value = 'Warte auf Bestätigung vom iPhone …';
    stopAt = Date.now() + 5 * 60 * 1000;
    timer = setInterval(async () => {
      if (Date.now() > stopAt) {
        stop();
        qrStatus.value = 'Der Code ist abgelaufen.';
        return;
      }
      try {
        const status = await pollLink(link.linkId, link.pollSecret);
        if (status === 'approved') {
          stop();
          weiter();
        } else if (status === 'expired') {
          stop();
          qrStatus.value = 'Der Code ist abgelaufen.';
        }
      } catch {
        /* kurz kein Netz – weiter versuchen */
      }
    }, 2000);
  } catch (e) {
    error.value = e.message;
  }
}

function stop() {
  clearInterval(timer);
  timer = null;
}

onBeforeUnmount(stop);
</script>

<template>
  <main class="login">
    <ZLogo :size="150" animate label="Zwerg-Logo" />
    <h1 class="name">Zwerg</h1>
    <p v-if="state.notice" class="notice">{{ state.notice }}</p>

    <div v-if="!qr" class="actions">
      <button class="btn primary block" type="button" :disabled="busy" @click="passkey">
        <Icon name="key" />{{ busy ? 'Einen Moment …' : 'Mit Passkey anmelden' }}
      </button>
      <button class="btn block" type="button" @click="showQr"><Icon name="qr" />Mit dem iPhone verbinden</button>
      <p class="small muted center">
        Am iPhone: Passkey mit Face ID. Am Laptop: „Mit dem iPhone verbinden“ zeigt einen QR-Code, den du in Zwerg auf dem iPhone scannst.
      </p>
    </div>

    <div v-else class="qr-box">
      <img :src="qr" alt="QR-Code zum Verbinden" width="280" height="280">
      <ol class="small">
        <li>Öffne Zwerg auf deinem iPhone.</li>
        <li>Tippe auf <strong>Einstellungen → Gerät hinzufügen</strong>.</li>
        <li>Scanne diesen Code und bestätige mit Face ID.</li>
      </ol>
      <p class="small muted" role="status">{{ qrStatus }}</p>
      <div class="row">
        <button class="btn" type="button" @click="showQr">Neuen Code</button>
        <button class="btn" type="button" @click="stop(); qr = ''">Zurück</button>
      </div>
    </div>

    <p v-if="error" class="error center">{{ error }}</p>
  </main>
</template>

<style scoped>
.login {
  min-height: 100dvh;
  max-width: 420px;
  margin: 0 auto;
  padding: 48px 20px calc(32px + var(--safe-b));
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 18px;
}
.name { font-size: 34px; letter-spacing: 0.02em; margin-bottom: 12px; }
.actions { width: 100%; display: flex; flex-direction: column; gap: 10px; }
.center { text-align: center; }
.notice { background: var(--chip); padding: 10px 14px; border-radius: 10px; font-size: 14px; text-align: center; }
.qr-box { display: flex; flex-direction: column; align-items: center; gap: 12px; }
.qr-box img { border-radius: 12px; background: #fff; padding: 10px; width: 280px; height: 280px; }
.qr-box ol { margin: 0; padding-left: 20px; }
</style>
