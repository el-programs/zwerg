// Berechnungen für Gewichtung, Bewertung und Ranking.
// Antwort je Faktor auf einer Fünferskala, gespeichert als 1–5 und gerechnet als 0–4 Punkte
// (die rechte Antwort ist immer die beste für uns). Gewicht: 0–5, 0 = spielt keine Rolle.
// Gesamtpunktzahl = Summe (Punkte × Gewicht) / Summe (4 × Gewicht), umgerechnet auf 0–100.
import { state } from './store.js';

export const ABWEICHUNG = 2; // ab dieser Differenz wird hervorgehoben

export const SKALEN = {
  menge: ['keine', 'wenig', 'mittel', 'viel', 'sehr viel'],
  qualitaet: ['sehr schlecht', 'schlecht', 'mittel', 'gut', 'sehr gut'],
};

// Gespeicherter Wert 1–5 → Punkte 0–4.
export const punkte = (score) => (score ? score - 1 : null);

// Antwort in Worten, z. B. „viel“.
export function antwort(c, score) {
  return score ? (SKALEN[c.scale] ?? SKALEN.qualitaet)[score - 1] : '–';
}

export function activeCriteria() {
  return state.criteria.filter((c) => !c.archived);
}

export function activeKo() {
  return state.koCriteria.filter((k) => !k.archived);
}

export function hasSubmittedWeights(profileId) {
  return state.weightSubs.some((w) => w.profile_id === profileId);
}

export function personalWeight(profileId, criterionId) {
  return state.weights.find((w) => w.profile_id === profileId && w.criterion_id === criterionId)?.weight ?? null;
}

// Gewichte für die Berechnung: gemeinsame, sonst Mittel der abgegebenen, sonst 1.
export function effectiveWeight(c) {
  if (c.joint_weight !== null && c.joint_weight !== undefined) return c.joint_weight;
  const own = state.profiles
    .filter((p) => hasSubmittedWeights(p.id))
    .map((p) => personalWeight(p.id, c.id))
    .filter((w) => w !== null);
  if (own.length) return own.reduce((a, b) => a + b, 0) / own.length;
  return 1;
}

export function jointWeightsSet() {
  const list = activeCriteria();
  return list.length > 0 && list.every((c) => c.joint_weight !== null && c.joint_weight !== undefined);
}

export function hasSubmittedRating(ideaId, profileId) {
  return state.ratingSubs.some((s) => s.idea_id === ideaId && s.profile_id === profileId);
}

export function personalScores(ideaId, profileId) {
  const map = {};
  for (const r of state.ratings) if (r.idea_id === ideaId && r.profile_id === profileId) map[r.criterion_id] = r;
  return map;
}

export function jointScores(ideaId) {
  const map = {};
  for (const r of state.jointRatings) if (r.idea_id === ideaId) map[r.criterion_id] = r;
  return map;
}

export function personalKoIds(ideaId, profileId) {
  return state.personalKo.filter((k) => k.idea_id === ideaId && k.profile_id === profileId).map((k) => k.ko_id);
}

export function evaluation(ideaId) {
  return state.evaluations.find((e) => e.idea_id === ideaId) ?? null;
}

// scores: { criterionId: { score } } → 0–100 oder null
export function total(scores) {
  let sum = 0;
  let max = 0;
  for (const c of activeCriteria()) {
    const w = effectiveWeight(c);
    const s = scores[c.id]?.score;
    if (!w || !s) continue;
    sum += w * (s - 1);
    max += w * 4;
  }
  return max ? Math.round((sum / max) * 100) : null;
}

// Stand einer Idee für das Ranking. Bewertet wird gemeinsam in einem Durchgang.
export function ideaResult(ideaId) {
  const ev = evaluation(ideaId);
  const joint = jointScores(ideaId);
  const crit = activeCriteria();
  const rated = crit.filter((c) => joint[c.id]?.score).length;
  // Nur aktive KO-Kriterien zählen. „Trifft zu“ schließt aus, „später prüfen“ ist nur ein Hinweis.
  const aktiv = new Set(activeKo().map((k) => k.id));
  const koIds = (ev?.ko_ids ?? []).filter((k) => aktiv.has(k));
  const checkIds = (ev?.ko_check_ids ?? []).filter((k) => aktiv.has(k) && !koIds.includes(k));
  const base = { ko: koIds.length > 0, koIds, checkIds, rated, of: crit.length };
  if (ev?.finalized_at) return { ...base, kind: 'final', score: total(joint) };
  if (crit.length && rated === crit.length) return { ...base, kind: 'vorlaeufig', score: total(joint) };
  return { ...base, kind: rated ? 'teilweise' : 'offen', score: null };
}

export const RESULT_LABEL = {
  final: 'Endbewertung',
  vorlaeufig: 'noch nicht abgeschlossen',
  teilweise: 'Bewertung in Arbeit',
  offen: 'noch nicht bewertet',
};

// Aktive Ideen mit Ergebnis, die bewerteten nach Punkten sortiert (ohne KO), dahinter KO und offene.
export function rankedIdeas() {
  // Nur Ideen aus Runde 2 (weiterverfolgt) kommen ins Ranking.
  const rows = state.ideas
    .filter((i) => i.status !== 'geparkt' && i.shortlist === 'weiter')
    .map((idea) => ({ idea, result: ideaResult(idea.id) }));
  const bewertet = rows.filter((r) => r.result.score !== null && !r.result.ko).sort((a, b) => b.result.score - a.result.score);
  return {
    bewertet,
    ko: rows.filter((r) => r.result.ko),
    offen: rows.filter((r) => r.result.score === null && !r.result.ko),
  };
}
