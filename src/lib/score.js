// Berechnungen für Gewichtung, Bewertung und Ranking.
// Punkte: 1–5 je Faktor, 5 = sehr gut für uns. Gewicht: 0–5, 0 = spielt keine Rolle.
// Gesamtpunktzahl = gewichteter Durchschnitt, umgerechnet auf 0–100.
import { state } from './store.js';

export const ABWEICHUNG = 2; // ab dieser Differenz wird hervorgehoben

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
    sum += w * s;
    max += w * 5;
  }
  return max ? Math.round((sum / max) * 100) : null;
}

// Stand einer Idee für das Ranking.
export function ideaResult(ideaId) {
  const ev = evaluation(ideaId);
  if (ev?.finalized_at) {
    return { kind: 'final', score: total(jointScores(ideaId)), ko: ev.ko_ids.length > 0, koIds: ev.ko_ids };
  }
  const submitted = state.profiles.filter((p) => hasSubmittedRating(ideaId, p.id));
  const visible = submitted.filter((p) => Object.keys(personalScores(ideaId, p.id)).length);
  if (!visible.length) return { kind: submitted.length ? 'teilweise' : 'offen', score: null, ko: false, submitted };
  const scores = visible.map((p) => total(personalScores(ideaId, p.id))).filter((x) => x !== null);
  const ko = visible.some((p) => personalKoIds(ideaId, p.id).length);
  return {
    kind: visible.length === state.profiles.length ? 'vorlaeufig' : 'teilweise',
    score: scores.length ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : null,
    ko,
    submitted,
  };
}

export const RESULT_LABEL = {
  final: 'Endbewertung',
  vorlaeufig: 'vorläufig',
  teilweise: 'erst eine Bewertung',
  offen: 'noch nicht bewertet',
};

// Aktive Ideen mit Ergebnis, die bewerteten nach Punkten sortiert (ohne KO), dahinter KO und offene.
export function rankedIdeas() {
  const rows = state.ideas.filter((i) => i.status !== 'geparkt').map((idea) => ({ idea, result: ideaResult(idea.id) }));
  const bewertet = rows.filter((r) => r.result.score !== null && !r.result.ko).sort((a, b) => b.result.score - a.result.score);
  return {
    bewertet,
    ko: rows.filter((r) => r.result.ko),
    offen: rows.filter((r) => r.result.score === null && !r.result.ko),
  };
}
