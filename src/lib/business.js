// Business-Case-Rechnung je Szenario (alle Beträge netto, Monatswerte).
export const SZENARIEN = [
  { id: 'vorsichtig', name: 'Vorsichtig' },
  { id: 'realistisch', name: 'Realistisch' },
  { id: 'optimistisch', name: 'Optimistisch' },
];

export const FELDER = [
  { id: 'investition', name: 'Investition (einmalig)', einheit: '€' },
  { id: 'fixkosten', name: 'Fixkosten pro Monat', einheit: '€' },
  { id: 'variable', name: 'Variable Kosten je Einheit', einheit: '€' },
  { id: 'preis', name: 'Verkaufspreis je Einheit (netto)', einheit: '€' },
  { id: 'absatz', name: 'Absatz pro Monat', einheit: 'Einheiten' },
];

export function zahl(v) {
  if (v === null || v === undefined || v === '') return null;
  let t = String(v).trim().replace(/\s|€/g, '');
  // Deutsche Schreibweise: 1.250,50 – ohne Komma gilt ein Punkt vor genau drei Ziffern als Tausenderpunkt.
  if (t.includes(',')) t = t.replace(/\./g, '').replace(',', '.');
  else if (/^-?\d{1,3}(\.\d{3})+$/.test(t)) t = t.replace(/\./g, '');
  const n = Number(t);
  return Number.isFinite(n) ? n : null;
}

export function rechne(s = {}) {
  const inv = zahl(s.investition) ?? 0;
  const fix = zahl(s.fixkosten) ?? 0;
  const varK = zahl(s.variable) ?? 0;
  const preis = zahl(s.preis);
  const absatz = zahl(s.absatz);
  if (preis === null || absatz === null) return null;
  const db = preis - varK; // Deckungsbeitrag je Einheit
  const umsatz = preis * absatz;
  const gewinn = db * absatz - fix;
  return {
    umsatzMonat: umsatz,
    umsatzJahr: umsatz * 12,
    dbEinheit: db,
    marge: preis > 0 ? db / preis : null,
    gewinnMonat: gewinn,
    gewinnJahr: gewinn * 12,
    breakEven: db > 0 ? Math.ceil(fix / db) : null, // Einheiten pro Monat
    amortisation: gewinn > 0 && inv > 0 ? Math.ceil(inv / gewinn) : inv === 0 && gewinn > 0 ? 0 : null, // Monate
  };
}

export function eur(v, nachkomma = 0) {
  if (v === null || v === undefined || !Number.isFinite(v)) return '–';
  return `${v.toLocaleString('de-DE', { minimumFractionDigits: nachkomma, maximumFractionDigits: nachkomma })} €`;
}

export function prozent(v) {
  if (v === null || v === undefined || !Number.isFinite(v)) return '–';
  return `${(v * 100).toLocaleString('de-DE', { maximumFractionDigits: 1 })} %`;
}
