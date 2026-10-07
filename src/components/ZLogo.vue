<script setup>
// Das Zwerg-Logo: ein kräftiges „Z“ mit bis zu zwei weichgezeichneten, größeren Echos,
// jeweils durch einen schmalen Spalt in Hintergrundfarbe abgesetzt.
const props = defineProps({
  size: { type: Number, default: 32 },
  echoes: { type: Number, default: 2 },
  animate: { type: Boolean, default: false },
  label: { type: String, default: '' },
});
const P = '-26,-26 26,-26 26,-12 -4.4,13 26,13 26,27 -26,27 -26,13 4.4,-12 -26,-12';
const uid = Math.random().toString(36).slice(2, 8);
</script>

<template>
  <svg
    :width="size"
    :height="size"
    viewBox="-60 -60 120 120"
    :role="label ? 'img' : undefined"
    :aria-label="label || undefined"
    :aria-hidden="label ? undefined : 'true'"
    :class="{ animate }"
  >
    <defs v-if="props.echoes > 0">
      <filter :id="`za${uid}`" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.8" /></filter>
      <filter :id="`zb${uid}`" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3.5" /></filter>
    </defs>
    <g v-if="props.echoes > 1" class="echo e2">
      <g :filter="`url(#zb${uid})`">
        <polygon transform="scale(2.2)" opacity="0.15" fill="currentColor" :points="P" />
      </g>
    </g>
    <g v-if="props.echoes > 0" class="echo e1">
      <polygon transform="scale(1.57)" fill="var(--bg)" stroke="var(--bg)" stroke-width="4.84" stroke-linejoin="round" :points="P" />
      <g :filter="`url(#za${uid})`">
        <polygon transform="scale(1.57)" opacity="0.32" fill="currentColor" :points="P" />
      </g>
    </g>
    <polygon fill="var(--bg)" stroke="var(--bg)" stroke-width="7.6" stroke-linejoin="round" :points="P" />
    <polygon fill="currentColor" :points="P" />
  </svg>
</template>

<style scoped>
.animate .echo {
  transform-box: view-box;
  transform-origin: 0 0;
  animation: zw-grow 1100ms cubic-bezier(0.2, 0.7, 0.2, 1) both;
}
.animate .e2 { animation-delay: 120ms; }
@keyframes zw-grow {
  from { transform: scale(0.55); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}
@media (prefers-reduced-motion: reduce) {
  .animate .echo { animation: none; }
}
</style>
