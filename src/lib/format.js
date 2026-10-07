// Kleine Helfer für Anzeige und Geräte.

const MONATE = ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.'];

export function datum(iso) {
  const d = new Date(iso);
  const heute = new Date();
  const text = `${d.getDate()}. ${MONATE[d.getMonth()]}`;
  return d.getFullYear() === heute.getFullYear() ? text : `${text} ${d.getFullYear()}`;
}

export function relativ(iso) {
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 60) return 'gerade eben';
  if (diff < 3600) return `vor ${Math.floor(diff / 60)} Min.`;
  if (diff < 86400) return `vor ${Math.floor(diff / 3600)} Std.`;
  if (diff < 2 * 86400) return 'gestern';
  return datum(iso);
}

export function geraeteName() {
  const ua = navigator.userAgent;
  let geraet = 'Computer';
  if (/iPhone/.test(ua)) geraet = 'iPhone';
  else if (/iPad/.test(ua) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1)) geraet = 'iPad';
  else if (/Android/.test(ua)) geraet = 'Android';
  else if (/Windows/.test(ua)) geraet = 'Windows-PC';
  else if (/Macintosh/.test(ua)) geraet = 'Mac';
  let browser = '';
  if (/Edg\//.test(ua)) browser = 'Edge';
  else if (/Firefox\//.test(ua)) browser = 'Firefox';
  else if (/Chrome\//.test(ua) || /CriOS/.test(ua)) browser = 'Chrome';
  else if (/Safari\//.test(ua)) browser = 'Safari';
  const app = window.matchMedia?.('(display-mode: standalone)').matches ? 'App' : browser;
  return app ? `${geraet} · ${app}` : geraet;
}

export const PHASEN = [
  { nr: 1, name: 'Ideenfindung' },
  { nr: 2, name: 'Machbarkeit & Auswahl' },
  { nr: 3, name: 'Pilot & Vorbereitung' },
  { nr: 4, name: 'Gründung' },
];

export function phaseName(nr) {
  return PHASEN.find((p) => p.nr === nr)?.name ?? '';
}

export const AKZENTE = [
  { id: 'petrol', name: 'Petrol', hell: '#2F6F73', dunkel: '#8DB0B2' },
  { id: 'taube', name: 'Taubenblau', hell: '#3E5F8A', dunkel: '#95A7BF' },
  { id: 'schiefer', name: 'Schiefer', hell: '#4F5D6B', dunkel: '#9EA6AE' },
  { id: 'salbei', name: 'Salbei', hell: '#4F6F52', dunkel: '#9EB0A0' },
  { id: 'moos', name: 'Moos', hell: '#66703A', dunkel: '#ABB093' },
  { id: 'ocker', name: 'Ocker', hell: '#8C6A2F', dunkel: '#C0AD8D' },
  { id: 'terrakotta', name: 'Terrakotta', hell: '#A0563F', dunkel: '#CBA295' },
  { id: 'pflaume', name: 'Pflaume', hell: '#6E4F6E', dunkel: '#AF9EAF' },
];

export function applyAppearance(theme, accent) {
  const el = document.documentElement;
  if (theme === 'hell' || theme === 'dunkel') el.dataset.theme = theme;
  else delete el.dataset.theme;
  if (accent && accent !== 'petrol') el.dataset.accent = accent;
  else delete el.dataset.accent;
  try {
    localStorage.setItem('zwerg-theme', theme || 'system');
    localStorage.setItem('zwerg-accent', accent || 'petrol');
  } catch {
    /* privater Modus */
  }
}
