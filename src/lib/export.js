// Excel-Export aller Daten. Die Bibliothek wird erst beim Export nachgeladen.
import { state, fieldName, profile } from './store.js';
import { activeCriteria, effectiveWeight, ideaResult, jointScores, personalScores, RESULT_LABEL } from './score.js';
import { rechne, SZENARIEN, zahl } from './business.js';
import { phaseName as standardPhase } from './format.js';

const phaseName = (nr) => state.phases.find((p) => p.nr === nr)?.name ?? standardPhase(nr);

const STATUS = { offen: 'Offen', in_arbeit: 'In Arbeit', erledigt: 'Erledigt' };
const ARTEN = { gespraech: 'Kundengespräch', test: 'Test / Pilot', umfrage: 'Umfrage', sonstiges: 'Sonstiges' };

// Kalenderdatum als Excel-Datum (ohne Zeitzonen-Verschiebung).
function tag(value) {
  if (!value) return null;
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    const [y, m, d] = value.split('-').map(Number);
    return new Date(Date.UTC(y, m - 1, d));
  }
  const d = new Date(value);
  return new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
}

const ideaTitle = (id) => (id ? state.ideas.find((i) => i.id === id)?.title || 'Ohne Titel' : '');
const name = (id) => profile(id)?.name ?? '';
const kopf = (titles) => titles.map((value) => ({ value, fontWeight: 'bold' }));
const zelle = (value) => {
  if (value === null || value === undefined || value === '') return null;
  if (value instanceof Date) return { value, type: Date, format: 'dd.mm.yyyy' };
  if (typeof value === 'string' && value.length > 60) return { value, wrap: true };
  return { value };
};
const zeilen = (rows) => rows.map((r) => r.map(zelle));

function blatt(sheet, titles, rows, widths) {
  return {
    sheet,
    data: [kopf(titles), ...zeilen(rows)],
    columns: widths.map((width) => ({ width })),
    stickyRowsCount: 1,
  };
}

export function sheets() {
  const crit = activeCriteria();
  const ideen = [...state.ideas].sort((a, b) => (a.created_at < b.created_at ? -1 : 1));

  const ideenRows = ideen.map((i) => {
    const r = ideaResult(i.id);
    return [
      i.title || 'Ohne Titel', i.description, fieldName(i.search_field_id), i.status === 'geparkt' ? 'geparkt' : 'aktiv',
      `${i.phase} · ${phaseName(i.phase)}`, i.is_favorite ? 'ja' : '', r.score, RESULT_LABEL[r.kind], r.ko ? 'ja' : '',
      i.park_reason ?? '', (i.tags ?? []).join(', '), name(i.created_by), tag(i.created_at),
    ];
  });

  const bewertungRows = [];
  for (const i of ideen) {
    const joint = jointScores(i.id);
    const pers = state.profiles.map((p) => personalScores(i.id, p.id));
    if (!Object.keys(joint).length && pers.every((m) => !Object.keys(m).length)) continue;
    for (const c of crit) {
      const notizen = state.profiles.map((p, n) => (pers[n][c.id]?.note ? `${p.kuerzel}: ${pers[n][c.id].note}` : '')).filter(Boolean).join(' · ');
      bewertungRows.push([i.title || 'Ohne Titel', c.name, Math.round(effectiveWeight(c) * 10) / 10, ...pers.map((m) => m[c.id]?.score ?? null), joint[c.id]?.score ?? null, notizen]);
    }
  }

  const bcRows = [];
  for (const bc of state.businessCases) {
    for (const s of SZENARIEN) {
      const v = bc.scenarios?.[s.id];
      if (!v) continue;
      const r = rechne(v);
      bcRows.push([
        ideaTitle(bc.idea_id), s.name, zahl(v.investition), zahl(v.fixkosten), zahl(v.variable), zahl(v.preis), zahl(v.absatz),
        r ? Math.round(r.umsatzMonat) : null, r ? Math.round(r.gewinnMonat) : null, r?.breakEven ?? null, r?.amortisation ?? null,
      ]);
    }
  }

  const aufgaben = [...state.tasks].sort((a, b) => ((a.due_date ?? '9') < (b.due_date ?? '9') ? -1 : 1));
  const entscheidungen = [...state.decisions].sort((a, b) => (a.decided_on < b.decided_on ? 1 : -1));
  const feedback = [...state.feedback].sort((a, b) => (a.held_on < b.held_on ? 1 : -1));
  const notizen = [...state.notes].sort((a, b) => (a.created_at < b.created_at ? 1 : -1));
  const meetings = [...state.meetings].sort((a, b) => (a.held_on < b.held_on ? 1 : -1));
  const meetingRows = [];
  for (const m of meetings) {
    const kopfzeile = [tag(m.held_on), m.title || 'Besprechung', (m.attendees ?? []).map(name).concat(m.guests ? [m.guests] : []).join(', ')];
    if (m.notes?.trim()) meetingRows.push([...kopfzeile, 'Notizen', m.notes, '']);
    const items = state.meetingItems.filter((i) => i.meeting_id === m.id).sort((a, b) => a.sort - b.sort);
    for (const i of items) meetingRows.push([...kopfzeile, i.title, i.notes, i.result]);
    if (!items.length && !m.notes?.trim()) meetingRows.push([...kopfzeile, '', '', '']);
  }

  return [
    blatt('Ideen', ['Titel', 'Beschreibung', 'Suchfeld', 'Status', 'Phase', 'Favorit', 'Punkte (0–100)', 'Bewertungsstand', 'KO', 'Parkgrund', 'Schlagworte', 'Von', 'Angelegt'], ideenRows, [32, 50, 20, 9, 26, 8, 13, 20, 5, 30, 20, 10, 11]),
    blatt('Bewertungen', ['Idee', 'Faktor', 'Gewicht', ...state.profiles.map((p) => p.name), 'Gemeinsam', 'Notizen'], bewertungRows, [32, 30, 9, ...state.profiles.map(() => 9), 11, 40]),
    blatt('Business Case', ['Idee', 'Szenario', 'Investition €', 'Fixkosten/Monat €', 'Variable Kosten/Einheit €', 'Preis/Einheit €', 'Absatz/Monat', 'Umsatz/Monat €', 'Ergebnis/Monat €', 'Break-even (Einheiten/Monat)', 'Amortisation (Monate)'], bcRows, [32, 13, 13, 16, 20, 14, 13, 15, 16, 22, 18]),
    blatt('Aufgaben', ['Aufgabe', 'Status', 'Wer', 'Fällig', 'Idee', 'Phase', 'Notizen', 'Erledigt am'], aufgaben.map((t) => [t.title, STATUS[t.status], name(t.assignee), tag(t.due_date), ideaTitle(t.idea_id), t.phase ? `${t.phase} · ${phaseName(t.phase)}` : '', t.notes, tag(t.done_at)]), [40, 11, 10, 11, 28, 26, 40, 11]),
    blatt('Entscheidungen', ['Datum', 'Entscheidung', 'Details', 'Begründung', 'Idee', 'Von', 'Automatisch'], entscheidungen.map((d) => [tag(d.decided_on), d.title, d.decision, d.reason, ideaTitle(d.idea_id), name(d.created_by), d.automatic ? 'ja' : '']), [11, 45, 45, 45, 28, 10, 11]),
    blatt('Pilot-Feedback', ['Idee', 'Datum', 'Art', 'Kontakt', 'Zusammenfassung', 'Problem (1–5)', 'Kaufinteresse (1–5)', 'Zahlungsbereitschaft', 'Zitat', 'Erkenntnisse'], feedback.map((f) => [ideaTitle(f.idea_id), tag(f.held_on), ARTEN[f.kind] ?? f.kind, f.contact, f.summary, f.problem, f.interest, f.price, f.quote, f.learnings]), [28, 11, 16, 22, 45, 12, 16, 22, 35, 40]),
    blatt('Notizen', ['Datum', 'Von', 'Notiz', 'Angeheftet', 'Daraus entstandene Idee'], notizen.map((n) => [tag(n.created_at), name(n.created_by), n.body, n.pinned ? 'ja' : '', ideaTitle(n.idea_id)]), [11, 10, 70, 11, 30]),
    blatt('Meetings', ['Datum', 'Meeting', 'Dabei', 'Punkt', 'Notiz', 'Ergebnis'], meetingRows, [11, 28, 24, 30, 50, 40]),
  ];
}

export function dateiname(basis, endung) {
  return `Zwerg-${basis}-${new Date().toLocaleDateString('sv-SE')}.${endung}`;
}

// Am iPhone über das Teilen-Menü (In Dateien sichern, Mail …), sonst als normaler Download.
export async function teilenOderLaden(blob, name) {
  const file = new File([blob], name, { type: blob.type });
  if (window.matchMedia('(pointer: coarse)').matches && navigator.canShare?.({ files: [file] })) {
    try {
      await navigator.share({ files: [file], title: name });
      return;
    } catch (e) {
      if (e?.name === 'AbortError') return;
    }
  }
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 10000);
}

export async function excelExport() {
  const { default: writeExcelFile } = await import('write-excel-file/universal');
  const blob = await writeExcelFile(sheets(), { fontFamily: 'Calibri', fontSize: 11 }).toBlob();
  await teilenOderLaden(blob, dateiname('Export', 'xlsx'));
}
