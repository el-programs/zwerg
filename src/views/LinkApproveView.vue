<script setup>
// iPhone: QR-Code vom Laptop scannen und die Anmeldung mit Face ID bestätigen.
import { onBeforeUnmount, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import jsQR from 'jsqr';
import { approveLink, toast } from '../lib/store.js';
import Icon from '../components/Icon.vue';

const route = useRoute();
const router = useRouter();
const video = ref(null);
const link = ref(route.params.linkId && route.params.code ? { linkId: route.params.linkId, code: route.params.code } : null);
const error = ref('');
const busy = ref(false);
let stream = null;
let frame = 0;
const canvas = document.createElement('canvas');

function parse(text) {
  const m = /#\/koppeln\/([0-9a-f-]{36})\/([0-9a-f]+)/i.exec(text);
  return m ? { linkId: m[1], code: m[2] } : null;
}

async function startCamera() {
  error.value = '';
  try {
    stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false });
    video.value.srcObject = stream;
    await video.value.play();
    scan();
  } catch {
    error.value = 'Die Kamera konnte nicht gestartet werden. Bitte den Kamera-Zugriff für Zwerg erlauben.';
  }
}

function scan() {
  const v = video.value;
  if (!v || !stream) return;
  if (v.readyState >= 2 && v.videoWidth) {
    const w = 480;
    const h = Math.round((v.videoHeight / v.videoWidth) * w);
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(v, 0, 0, w, h);
    const code = jsQR(ctx.getImageData(0, 0, w, h).data, w, h);
    const found = code && parse(code.data);
    if (found) {
      stopCamera();
      link.value = found;
      return;
    }
    if (code) error.value = 'Das ist kein Zwerg-Code.';
  }
  frame = requestAnimationFrame(scan);
}

function stopCamera() {
  cancelAnimationFrame(frame);
  stream?.getTracks().forEach((t) => t.stop());
  stream = null;
}

async function bestaetigen() {
  error.value = '';
  busy.value = true;
  try {
    await approveLink(link.value.linkId, link.value.code);
    toast('Gerät ist angemeldet');
    router.replace('/mehr');
  } catch (e) {
    error.value = e.message;
  } finally {
    busy.value = false;
  }
}

onMounted(() => {
  if (!link.value) startCamera();
});
onBeforeUnmount(stopCamera);
</script>

<template>
  <header class="topbar">
    <div class="topbar-inner">
      <router-link to="/mehr" class="icon-btn" aria-label="Zurück"><Icon name="back" /></router-link>
      <h1 class="grow">Gerät hinzufügen</h1>
    </div>
  </header>
  <main class="page">
    <template v-if="!link">
      <p>Öffne Zwerg auf dem Laptop, wähle <strong>„Mit dem iPhone verbinden“</strong> und richte die Kamera auf den QR-Code.</p>
      <div class="viewer">
        <video ref="video" playsinline muted></video>
        <div class="frame"></div>
      </div>
    </template>
    <template v-else>
      <section class="card stack confirm">
        <Icon name="laptop" :size="40" />
        <h2>Neues Gerät anmelden?</h2>
        <p class="muted">Das Gerät mit dem eben gescannten Code wird dauerhaft mit deinem Zugang angemeldet.</p>
        <button class="btn primary block" type="button" :disabled="busy" @click="bestaetigen">
          {{ busy ? 'Einen Moment …' : 'Mit Face ID bestätigen' }}
        </button>
        <router-link to="/mehr" class="btn block">Abbrechen</router-link>
      </section>
    </template>
    <p v-if="error" class="error">{{ error }}</p>
  </main>
</template>

<style scoped>
.grow { flex: 1; }
p { margin: 0; }
.viewer { position: relative; border-radius: 16px; overflow: hidden; background: #000; aspect-ratio: 3 / 4; max-height: 60vh; }
.viewer video { width: 100%; height: 100%; object-fit: cover; display: block; }
.frame { position: absolute; inset: 18%; border: 3px solid rgba(255, 255, 255, 0.85); border-radius: 14px; }
.confirm { align-items: center; text-align: center; }
</style>
