<script setup>
// Zeigt einen Freitext gegliedert an: Zeilen mit „## “ werden zu aufklappbaren Abschnitten,
// „### “ zu aufklappbaren Gruppen darin, „- “ zu Aufzählungen. Alles andere bleibt Text.
import { computed } from 'vue';

const props = defineProps({ text: { type: String, default: '' } });

// Baum: [{ kind: 'text'|'liste', lines }, { kind: 'abschnitt', titel, inhalt: [...] }]
const baum = computed(() => {
  const wurzel = [];
  let abschnitt = null;
  let gruppe = null;
  const ziel = () => (gruppe ? gruppe.inhalt : abschnitt ? abschnitt.inhalt : wurzel);
  function zeile(kind, text) {
    const list = ziel();
    const letzte = list[list.length - 1];
    if (letzte && letzte.kind === kind) letzte.lines.push(text);
    else list.push({ kind, lines: [text] });
  }
  for (const roh of props.text.split('\n')) {
    const z = roh.trimEnd();
    if (z.startsWith('## ')) {
      abschnitt = { kind: 'abschnitt', titel: z.slice(3).trim(), inhalt: [] };
      gruppe = null;
      wurzel.push(abschnitt);
    } else if (z.startsWith('### ')) {
      gruppe = { kind: 'gruppe', titel: z.slice(4).trim(), inhalt: [] };
      (abschnitt ? abschnitt.inhalt : wurzel).push(gruppe);
    } else if (/^\s*[-•] /.test(z)) {
      zeile('liste', z.replace(/^\s*[-•] /, ''));
    } else if (z.trim()) {
      zeile('text', z);
    }
  }
  return wurzel;
});
const anzahl = (knoten) => knoten.inhalt.reduce((n, k) => n + (k.kind === 'liste' ? k.lines.length : k.kind === 'gruppe' ? anzahl(k) : 0), 0);
</script>

<template>
  <div class="glieder">
    <template v-for="(k, i) in baum" :key="i">
      <p v-if="k.kind === 'text'" class="txt">{{ k.lines.join('\n') }}</p>
      <ul v-else-if="k.kind === 'liste'"><li v-for="(l, j) in k.lines" :key="j">{{ l }}</li></ul>
      <details v-else class="abschnitt">
        <summary><span class="t">{{ k.titel }}</span><span v-if="anzahl(k)" class="n">{{ anzahl(k) }}</span></summary>
        <div class="inhalt">
          <template v-for="(u, j) in k.inhalt" :key="j">
            <p v-if="u.kind === 'text'" class="txt muted">{{ u.lines.join('\n') }}</p>
            <ul v-else-if="u.kind === 'liste'"><li v-for="(l, m) in u.lines" :key="m">{{ l }}</li></ul>
            <details v-else class="gruppe">
              <summary><span class="t">{{ u.titel }}</span><span v-if="anzahl(u)" class="n">{{ anzahl(u) }}</span></summary>
              <template v-for="(w, m) in u.inhalt" :key="m">
                <p v-if="w.kind === 'text'" class="txt muted">{{ w.lines.join('\n') }}</p>
                <ul v-else-if="w.kind === 'liste'"><li v-for="(l, x) in w.lines" :key="x">{{ l }}</li></ul>
              </template>
            </details>
          </template>
        </div>
      </details>
    </template>
  </div>
</template>

<style scoped>
.glieder { display: flex; flex-direction: column; gap: 8px; }
.txt { margin: 0; white-space: pre-line; line-height: 1.45; }
ul { margin: 0; padding-left: 20px; display: flex; flex-direction: column; gap: 3px; line-height: 1.4; }
details { border: 1px solid var(--line); border-radius: 10px; background: var(--surface); }
summary { display: flex; align-items: center; gap: 8px; padding: 10px 12px; cursor: pointer; list-style: none; font-weight: 600; }
summary::-webkit-details-marker { display: none; }
summary::before { content: '›'; display: inline-block; width: 12px; color: var(--muted); transition: transform 0.15s; font-size: 18px; line-height: 1; }
details[open] > summary::before { transform: rotate(90deg); }
.t { flex: 1; min-width: 0; }
.n { font-size: 12px; font-weight: 500; color: var(--muted); background: var(--chip); border-radius: 9px; padding: 0 7px; }
.inhalt { display: flex; flex-direction: column; gap: 8px; padding: 0 12px 12px; }
.gruppe { background: var(--bg); }
.gruppe summary { font-weight: 500; padding: 8px 10px; }
.gruppe > ul, .gruppe > .txt { padding: 0 12px 10px 30px; }
.gruppe > .txt { padding-left: 12px; }
</style>
