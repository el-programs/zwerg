// Erzeugt die App-Icons (PNG) aus dem Zwerg-Logo. Aufruf: npm run icons
import { writeFileSync } from 'node:fs';
import { Resvg } from '@resvg/resvg-js';

const P = '-26,-26 26,-26 26,-12 -4.4,13 26,13 26,27 -26,27 -26,13 4.4,-12 -26,-12';
const BG = '#2B2D31';
const Z = '#C8743F';

// App-Icon: Anthrazit, kupferfarbenes „Z“ mit einem Echo (für kleine Größen gut lesbar).
function appIcon(padding) {
  const s = 1 - padding;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-60 -60 120 120">
  <defs><filter id="w" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.4"/></filter></defs>
  <rect x="-60" y="-60" width="120" height="120" fill="${BG}"/>
  <g transform="scale(${(s * 0.84).toFixed(3)})">
    <g filter="url(#w)"><polygon transform="scale(1.4)" opacity="0.36" fill="${Z}" points="${P}"/></g>
    <polygon fill="${BG}" stroke="${BG}" stroke-width="7.6" stroke-linejoin="round" points="${P}"/>
    <polygon fill="${Z}" points="${P}"/>
  </g>
</svg>`;
}

// Browser-Tab: nur das „Z“.
const favicon = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-30 -30 60 60"><polygon fill="${Z}" points="${P}"/></svg>`;

function png(svg, size, file) {
  const out = new Resvg(svg, { fitTo: { mode: 'width', value: size } }).render().asPng();
  writeFileSync(new URL(`../public/${file}`, import.meta.url), out);
}

writeFileSync(new URL('../public/favicon.svg', import.meta.url), favicon + '\n');
png(favicon, 32, 'favicon-32.png');
png(appIcon(0), 192, 'icon-192.png');
png(appIcon(0), 512, 'icon-512.png');
png(appIcon(0.22), 512, 'icon-maskable-512.png');
png(appIcon(0.08), 180, 'apple-touch-icon.png');
console.log('Icons erzeugt.');
