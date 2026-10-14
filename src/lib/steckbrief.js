// Steckbrief einer Geschäftsidee: kurze Leitfragen, damit alle Ideen gleich aufgebaut sind.
export const ERLOESMODELLE = ['Verkauf', 'Abo', 'Miete', 'Dienstleistung', 'Provision'];

export const FELDER = [
  { key: 'benefit', name: 'Nutzen', frage: 'Warum sollte jemand das kaufen? Welches Bedürfnis oder Problem sprechen wir an?' },
  { key: 'offer', name: 'Angebot', frage: 'Was genau bieten wir an?' },
  { key: 'customers', name: 'Zielkunden', frage: 'Wer zahlt dafür?', beispiel: 'z. B. kleine Handwerksbetriebe, Heimwerker' },
  { key: 'revenue', name: 'Erlösmodell', frage: 'Wie verdienen wir Geld?', erloes: true },
  { key: 'first_test', name: 'Erster Test', frage: 'Wie könnten wir die Idee ausprobieren?', optional: true },
  { key: 'origin', name: 'Auslöser', frage: 'Woher kommt die Idee?', optional: true },
];

export function ausgefuellt(idea, feld) {
  if (feld.erloes) return (idea.revenue_model ?? []).length > 0 || !!idea.revenue_note?.trim();
  return !!idea[feld.key]?.trim();
}

export function erloesText(idea) {
  return [(idea.revenue_model ?? []).join(', '), idea.revenue_note?.trim()].filter(Boolean).join(' · ');
}

// Fortschritt zählt nur die Pflicht-Leitfragen (ohne die optionalen).
export function fortschritt(idea) {
  const pflicht = FELDER.filter((f) => !f.optional);
  return { done: pflicht.filter((f) => ausgefuellt(idea, f)).length, of: pflicht.length };
}

export const leererSteckbrief = () => ({ benefit: '', offer: '', customers: '', revenue_model: [], revenue_note: '', first_test: '', origin: '' });
