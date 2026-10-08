<script setup>
// Netzdiagramm: eine Achse je Bewertungsfaktor (1–5), eine Fläche je Idee.
import { computed, ref } from 'vue';

const props = defineProps({
  axes: { type: Array, required: true }, // [{ id, label }]
  series: { type: Array, required: true }, // [{ id, name, color, values: { axisId: 1..5 } }]
});

const SIZE = 420;
const C = SIZE / 2;
const R = 140;
const hover = ref(null);

function point(i, v) {
  const a = (Math.PI * 2 * i) / props.axes.length - Math.PI / 2;
  const r = (R * v) / 5;
  return [C + r * Math.cos(a), C + r * Math.sin(a)];
}
const rings = [1, 2, 3, 4, 5];
const ringPaths = computed(() =>
  rings.map((v) => props.axes.map((_, i) => point(i, v).join(',')).join(' ')),
);
const spokes = computed(() => props.axes.map((_, i) => point(i, 5)));
const labels = computed(() =>
  props.axes.map((a, i) => {
    const [x, y] = point(i, 6.15);
    const anchor = Math.abs(x - C) < 8 ? 'middle' : x > C ? 'start' : 'end';
    return { ...a, x, y, anchor };
  }),
);
const shapes = computed(() =>
  props.series.map((s) => {
    const pts = props.axes.map((a, i) => ({ axis: a, value: s.values[a.id] ?? 0, xy: point(i, s.values[a.id] ?? 0) }));
    return { ...s, pts, path: pts.map((p) => p.xy.join(',')).join(' ') };
  }),
);
</script>

<template>
  <figure class="radar">
    <svg :viewBox="`-60 -10 ${SIZE + 120} ${SIZE + 20}`" role="img" aria-label="Netzdiagramm der Bewertungen. Die Tabelle darunter enthält alle Werte.">
      <g class="grid">
        <polygon v-for="(p, i) in ringPaths" :key="i" :points="p" />
        <line v-for="(s, i) in spokes" :key="`s${i}`" :x1="C" :y1="C" :x2="s[0]" :y2="s[1]" />
      </g>
      <text v-for="v in [1, 3, 5]" :key="`r${v}`" class="ring-label" :x="C + 4" :y="C - (R * v) / 5 - 3">{{ v }}</text>
      <g v-for="s in shapes" :key="s.id">
        <polygon :points="s.path" class="area" :style="{ fill: s.color, stroke: s.color }" />
        <circle
          v-for="(p, i) in s.pts"
          :key="i"
          :cx="p.xy[0]"
          :cy="p.xy[1]"
          r="4.5"
          class="dot"
          :style="{ fill: s.color }"
          @mouseenter="hover = i"
          @mouseleave="hover = null"
        ><title>{{ s.name }} · {{ p.axis.label }}: {{ p.value || '–' }}</title></circle>
      </g>
      <text
        v-for="(l, i) in labels"
        :key="`l${i}`"
        class="axis-label"
        :class="{ active: hover === i }"
        :x="l.x"
        :y="l.y"
        :text-anchor="l.anchor"
        dominant-baseline="middle"
        tabindex="0"
        @mouseenter="hover = i"
        @mouseleave="hover = null"
        @focus="hover = i"
        @blur="hover = null"
      >{{ l.label }}</text>
    </svg>
    <div v-if="hover !== null" class="tip" role="status">
      <strong>{{ axes[hover].label }}</strong>
      <span v-for="s in series" :key="s.id" class="tip-row">
        <span class="swatch" :style="{ background: s.color }"></span>{{ s.name }}: {{ s.values[axes[hover].id] ?? '–' }}
      </span>
    </div>
  </figure>
</template>

<style scoped>
.radar { margin: 0; position: relative; }
svg { width: 100%; height: auto; max-width: 560px; display: block; margin: 0 auto; overflow: visible; }
.grid polygon { fill: none; stroke: var(--line); stroke-width: 1; }
.grid line { stroke: var(--line); stroke-width: 1; }
.ring-label { font-size: 10px; fill: var(--muted); }
.area { fill-opacity: 0.1; stroke-width: 2; stroke-linejoin: round; }
.dot { stroke: var(--surface); stroke-width: 2; }
.axis-label { font-size: 11px; fill: var(--muted); cursor: default; outline: none; }
.axis-label.active { fill: var(--text); font-weight: 600; }
.tip {
  position: absolute;
  top: 8px;
  left: 8px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 8px 10px;
  border-radius: 8px;
  background: var(--surface);
  border: 1px solid var(--line);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  font-size: 13px;
  pointer-events: none;
}
.tip-row { display: flex; align-items: center; gap: 6px; }
.swatch { width: 10px; height: 10px; border-radius: 3px; }
</style>
