// Zwerg · KI-Unterstützung über die Claude API.
// Der API-Schlüssel liegt nur hier als Secret ANTHROPIC_API_KEY. Ohne Schlüssel bleibt die KI aus.
// Lange Aufgaben (Einschätzung, Recherche, Chat) laufen im Hintergrund; das Ergebnis landet in der
// Datenbank und erscheint per Live-Abgleich in der App.
import Anthropic from 'npm:@anthropic-ai/sdk';
import { createClient } from 'npm:@supabase/supabase-js@2';

declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void };

const ORIGIN = Deno.env.get('ZWERG_ORIGIN') ?? 'https://el-programs.github.io';
const API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const USD_TO_EUR = 0.92; // Näherung für die Kostenanzeige
const PRICES: Record<string, { input: number; output: number }> = {
  // US-Dollar je 1 Mio. Token
  'claude-opus-5-5': { input: 4, output: 20 },
  'claude-sonnet-5-5': { input: 2, output: 10 },
};
const SEARCH_USD = 10 / 1000; // Websuche: 10 $ je 1.000 Suchen

const cors = {
  'Access-Control-Allow-Origin': ORIGIN,
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function serviceKey(): string {
  const legacy = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (legacy) return legacy;
  const keys = JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}');
  return keys.default ?? Object.values(keys)[0];
}

const db = createClient(Deno.env.get('SUPABASE_URL')!, serviceKey(), {
  auth: { persistSession: false, autoRefreshToken: false },
});
const claude = API_KEY ? new Anthropic({ apiKey: API_KEY, maxRetries: 2 }) : null;

class Fehler extends Error {
  constructor(message: string, public status = 400) {
    super(message);
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });
}

// deno-lint-ignore no-explicit-any
function check(res: { data: any; error: { message: string } | null }): any {
  if (res.error) throw new Error(res.error.message);
  return res.data;
}

async function requireMember(req: Request) {
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const { data, error } = await db.auth.getUser(token);
  if (error || !data.user) throw new Fehler('Bitte zuerst anmelden.', 401);
  const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
  const profile = check(await db.from('profiles').select('*').eq('user_id', data.user.id).maybeSingle());
  if (!profile) throw new Fehler('Kein Zugang.', 403);
  const revoked = check(
    await db.from('devices').select('id').eq('session_id', payload.session_id).not('revoked_at', 'is', null).maybeSingle(),
  );
  if (revoked) throw new Fehler('Dieses Gerät wurde gesperrt.', 403);
  return profile;
}

function monthStart() {
  const d = new Date();
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1)).toISOString();
}

async function budget() {
  const settings = check(await db.from('ai_settings').select('*').eq('id', 1).single());
  const rows = check(await db.from('ai_usage').select('cost_eur').gte('created_at', monthStart()));
  const used = rows.reduce((s: number, r: { cost_eur: number }) => s + Number(r.cost_eur), 0);
  return { settings, used, limit: Number(settings.monthly_limit_eur) };
}

// Vor jedem Aufruf: Schlüssel vorhanden, Person hat KI nicht ausgeschaltet, Monatslimit nicht erreicht.
async function guard(profile: { ai_level: string }) {
  if (!claude) throw new Fehler('Die KI ist noch nicht eingerichtet (kein API-Schlüssel hinterlegt).', 409);
  if (profile.ai_level === 'aus') throw new Fehler('Du hast die KI in deinen Einstellungen ausgeschaltet.', 403);
  const b = await budget();
  if (b.used >= b.limit) {
    throw new Fehler(`Das KI-Monatslimit von ${b.limit.toFixed(2)} € ist erreicht. Ihr könnt es unter Mehr → KI anheben.`, 402);
  }
  return b.settings.model as string;
}

// deno-lint-ignore no-explicit-any
async function bookUsage(profileId: string, kind: string, model: string, usage: any) {
  const p = PRICES[model] ?? PRICES['claude-opus-5-5'];
  const input = (usage?.input_tokens ?? 0) + (usage?.cache_creation_input_tokens ?? 0) + (usage?.cache_read_input_tokens ?? 0);
  const output = usage?.output_tokens ?? 0;
  const searches = usage?.server_tool_use?.web_search_requests ?? 0;
  const usd = (input * p.input + output * p.output) / 1e6 + searches * SEARCH_USD;
  const cost = Math.round(usd * USD_TO_EUR * 10000) / 10000;
  check(await db.from('ai_usage').insert({
    profile_id: profileId, kind, model, input_tokens: input, output_tokens: output, searches, cost_eur: cost,
  }));
  return cost;
}

// Gemeinsame Haltung der KI in allen Funktionen.
const HALTUNG = `Du bist ein kritischer, erfahrener Gründungsberater für zwei Gesellschafter-Geschäftsführer eines
bestehenden mittelständischen Betriebs in Deutschland, die nebenher eine zweite Firma gründen wollen.
Sei ehrlich und konkret, kein Ja-Sager: Benenne Schwächen, Risiken und Denkfehler klar, auch wenn die Idee gut klingt.
Trenne immer sauber zwischen
- FAKTEN (belegbar, nur mit Quelle oder als allgemein bekannt gekennzeichnet),
- SCHÄTZUNGEN (Zahlen oder Größenordnungen, die du ableitest – mit kurzer Begründung),
- ANNAHMEN (Dinge, die die Gründer prüfen müssen).
Erfinde keine Zahlen, Studien oder Quellen. Wenn du etwas nicht weißt, sag es. Antworte auf Deutsch, klar und knapp.`;

// deno-lint-ignore no-explicit-any
async function ask(model: string, params: any) {
  // Bei einer Ablehnung durch Sicherheitsfilter springt automatisch ein passendes Ersatzmodell ein.
  return await claude!.beta.messages.create({
    model,
    betas: ['server-side-fallback-2026-07-01'],
    fallbacks: 'default',
    ...params,
    // deno-lint-ignore no-explicit-any
  } as any);
}

// deno-lint-ignore no-explicit-any
function textOf(message: any) {
  return message.content.filter((b: { type: string }) => b.type === 'text').map((b: { text: string }) => b.text).join('');
}

// deno-lint-ignore no-explicit-any
function ensureAnswer(message: any) {
  if (message.stop_reason === 'refusal') throw new Error('Die KI hat diese Anfrage abgelehnt.');
}

async function ideaContext(ideaId: string) {
  const idea = check(await db.from('ideas').select('*').eq('id', ideaId).maybeSingle());
  if (!idea) throw new Fehler('Notiz nicht gefunden.', 404);
  const field = idea.search_field_id
    ? check(await db.from('search_fields').select('name').eq('id', idea.search_field_id).maybeSingle())
    : null;
  const comments = check(await db.from('comments').select('body, created_at').eq('idea_id', ideaId).order('created_at').limit(30));
  const links = (idea.links ?? []).map((l: { url: string; label?: string }) => `- ${l.label || l.url}: ${l.url}`).join('\n');
  return {
    idea,
    text: [
      `Titel: ${idea.title || '(ohne Titel)'}`,
      `Beschreibung: ${idea.description || '(keine)'}`,
      field ? `Suchfeld: ${field.name}` : '',
      idea.tags?.length ? `Schlagworte: ${idea.tags.join(', ')}` : '',
      links ? `Links:\n${links}` : '',
      comments.length ? `Bisherige Kommentare der Gründer:\n${comments.map((c: { body: string }) => `- ${c.body}`).join('\n')}` : '',
    ].filter(Boolean).join('\n'),
  };
}

// Hintergrundaufgabe mit Fehlerprotokoll im Ergebnis-Datensatz.
function background(resultId: string, task: () => Promise<{ content: unknown; cost: number }>) {
  EdgeRuntime.waitUntil((async () => {
    try {
      const { content, cost } = await task();
      await db.from('ai_results').update({ status: 'fertig', content, cost_eur: cost, finished_at: new Date().toISOString() }).eq('id', resultId);
    } catch (e) {
      console.error(e);
      const msg = e instanceof Anthropic.APIError
        ? `Die KI ist gerade nicht erreichbar (${e.status ?? 'Fehler'}). Bitte später erneut versuchen.`
        : e instanceof Error ? e.message : 'Unbekannter Fehler';
      await db.from('ai_results').update({ status: 'fehler', error: msg, finished_at: new Date().toISOString() }).eq('id', resultId);
    }
  })());
}

async function newResult(kind: string, profileId: string, model: string, extra: Record<string, unknown>) {
  return check(await db.from('ai_results').insert({ kind, created_by: profileId, model, status: 'laeuft', ...extra }).select('id').single()).id as string;
}

const actions: Record<string, (body: any, req: Request) => Promise<unknown>> = {
  async status(_body, req) {
    await requireMember(req);
    const b = await budget();
    return { configured: !!claude, used: b.used, limit: b.limit, model: b.settings.model };
  },

  // Ideen zu einem Suchfeld vorschlagen
  async vorschlaege(body, req) {
    const profile = await requireMember(req);
    const model = await guard(profile);
    const field = body.searchFieldId
      ? check(await db.from('search_fields').select('id, name').eq('id', body.searchFieldId).maybeSingle())
      : null;
    const existing = check(await db.from('ideas').select('title').order('created_at', { ascending: false }).limit(60));
    const hint = String(body.hint ?? '').slice(0, 500);
    const resultId = await newResult('vorschlaege', profile.id, model, { search_field_id: field?.id ?? null, prompt: hint });
    background(resultId, async () => {
      const msg = await ask(model, {
        max_tokens: 6000,
        output_config: {
          effort: 'medium',
          format: {
            type: 'json_schema',
            schema: {
              type: 'object',
              additionalProperties: false,
              required: ['ideen'],
              properties: {
                ideen: {
                  type: 'array',
                  items: {
                    type: 'object',
                    additionalProperties: false,
                    required: ['titel', 'beschreibung', 'warum', 'haken', 'erster_test'],
                    properties: {
                      titel: { type: 'string' },
                      beschreibung: { type: 'string' },
                      warum: { type: 'string' },
                      haken: { type: 'string' },
                      erster_test: { type: 'string' },
                    },
                  },
                },
              },
            },
          },
        },
        system: HALTUNG,
        messages: [{
          role: 'user',
          content: `Schlage 6 unterschiedliche, konkrete Geschäftsideen vor${field ? ` aus dem Suchfeld „${field.name}“` : ''}.
Rahmen: nebenberuflich startbar, geringes Anfangsrisiko, mit echten Kunden günstig testbar, Standort Süddeutschland.
${hint ? `Zusätzliche Hinweise der Gründer: ${hint}\n` : ''}Diese Ideen gibt es schon (nicht wiederholen): ${existing.map((i: { title: string }) => i.title).filter(Boolean).join('; ') || 'keine'}.
Je Idee: Titel (kurz), Beschreibung (2–3 Sätze), warum es passen könnte, der größte Haken, ein erster günstiger Test.`,
        }],
      });
      ensureAnswer(msg);
      const cost = await bookUsage(profile.id, 'vorschlaege', model, msg.usage);
      return { content: JSON.parse(textOf(msg)), cost };
    });
    return { resultId };
  },

  // Kritische Einschätzung mit Bewertungsvorschlag je Faktor
  async einschaetzung(body, req) {
    const profile = await requireMember(req);
    const model = await guard(profile);
    const ctx = await ideaContext(body.ideaId);
    const criteria = check(await db.from('criteria').select('id, name, description').eq('archived', false).order('sort'));
    const kurz = !!body.kurz;
    const resultId = await newResult('einschaetzung', profile.id, model, { idea_id: ctx.idea.id, prompt: kurz ? 'kurz' : '' });
    background(resultId, async () => {
      const msg = await ask(model, {
        max_tokens: kurz ? 4000 : 10000,
        output_config: {
          effort: kurz ? 'low' : 'medium',
          format: {
            type: 'json_schema',
            schema: {
              type: 'object',
              additionalProperties: false,
              required: ['fazit', 'staerken', 'schwaechen', 'risiken', 'fakten', 'schaetzungen', 'annahmen', 'offene_fragen', 'bewertung'],
              properties: {
                fazit: { type: 'string' },
                staerken: { type: 'array', items: { type: 'string' } },
                schwaechen: { type: 'array', items: { type: 'string' } },
                risiken: { type: 'array', items: { type: 'string' } },
                fakten: { type: 'array', items: { type: 'string' } },
                schaetzungen: { type: 'array', items: { type: 'string' } },
                annahmen: { type: 'array', items: { type: 'string' } },
                offene_fragen: { type: 'array', items: { type: 'string' } },
                bewertung: {
                  type: 'array',
                  items: {
                    type: 'object',
                    additionalProperties: false,
                    required: ['faktor_id', 'punkte', 'begruendung'],
                    properties: {
                      faktor_id: { type: 'string', enum: criteria.map((c: { id: string }) => c.id) },
                      punkte: { type: 'integer', enum: [1, 2, 3, 4, 5] },
                      begruendung: { type: 'string' },
                    },
                  },
                },
              },
            },
          },
        },
        system: HALTUNG,
        messages: [{
          role: 'user',
          content: `Schätze diese Geschäftsidee kritisch ein${kurz ? ' (Kurz-Check: je Liste höchstens 3 Punkte, knappe Sätze)' : ''}.

${ctx.text}

Bewerte zusätzlich jeden Faktor von 1 bis 5 (5 = sehr günstig für die Gründer, auch bei Risiko, Wettbewerb oder Aufwand) mit einem Satz Begründung.
Faktoren (faktor_id: Name – Erklärung):
${criteria.map((c: { id: string; name: string; description: string }) => `${c.id}: ${c.name}${c.description ? ` – ${c.description}` : ''}`).join('\n')}`,
        }],
      });
      ensureAnswer(msg);
      const cost = await bookUsage(profile.id, 'einschaetzung', model, msg.usage);
      return { content: JSON.parse(textOf(msg)), cost };
    });
    return { resultId };
  },

  // Marktrecherche mit aktuellen Webdaten und Quellen
  async recherche(body, req) {
    const profile = await requireMember(req);
    const model = await guard(profile);
    const ctx = await ideaContext(body.ideaId);
    const frage = String(body.frage ?? '').slice(0, 600);
    const resultId = await newResult('recherche', profile.id, model, { idea_id: ctx.idea.id, prompt: frage });
    background(resultId, async () => {
      const tools = [{
        type: 'web_search_20260209',
        name: 'web_search',
        max_uses: 6,
        user_location: { type: 'approximate', country: 'DE', timezone: 'Europe/Berlin' },
      }];
      // deno-lint-ignore no-explicit-any
      const messages: any[] = [{
        role: 'user',
        content: `Recherchiere den Markt für diese Geschäftsidee mit aktuellen Webquellen, Schwerpunkt Deutschland bzw. DACH.

${ctx.text}
${frage ? `\nBesondere Frage der Gründer: ${frage}\n` : ''}
Gliedere die Antwort mit diesen Überschriften (Markdown, ## …):
## Kurzfazit
## Marktgröße und Nachfrage
## Wettbewerb (konkrete Anbieter mit Namen)
## Preise und Margen
## Rechtliches und Hürden
## Fakten, Schätzungen, Annahmen
(unter der letzten Überschrift drei Listen: „Fakten“ nur mit Quelle, „Schätzungen“ mit Begründung, „Annahmen“ zum Prüfen)
## Nächste Schritte zur Prüfung
Nenne nur Zahlen, die du in Quellen gefunden hast, oder kennzeichne sie klar als Schätzung.`,
      }];
      let msg;
      let cost = 0;
      for (let i = 0; i < 3; i++) {
        msg = await ask(model, { max_tokens: 12000, output_config: { effort: 'medium' }, system: HALTUNG, tools, messages });
        cost += await bookUsage(profile.id, 'recherche', model, msg.usage);
        if (msg.stop_reason !== 'pause_turn') break;
        messages.push({ role: 'assistant', content: msg.content });
      }
      if (!msg) throw new Error('Keine Antwort erhalten.');
      ensureAnswer(msg);
      // Quellen aus den Zitaten sammeln
      const quellen = new Map<string, { url: string; title: string }>();
      for (const block of msg.content) {
        if (block.type === 'text' && Array.isArray(block.citations)) {
          for (const c of block.citations) {
            if (c.type === 'web_search_result_location') quellen.set(c.url, { url: c.url, title: c.title ?? c.url });
          }
        }
      }
      return { content: { text: textOf(msg), quellen: [...quellen.values()] }, cost };
    });
    return { resultId };
  },

  // Chat-Sparring zu einer Idee
  async chat(body, req) {
    const profile = await requireMember(req);
    const model = await guard(profile);
    const nachricht = String(body.nachricht ?? '').trim().slice(0, 4000);
    if (!nachricht) throw new Fehler('Leere Nachricht.');
    const ctx = await ideaContext(body.ideaId);
    const verlauf = check(await db.from('ai_chat').select('role, content, status').eq('idea_id', ctx.idea.id).eq('status', 'fertig').order('created_at').limit(40));
    check(await db.from('ai_chat').insert({ idea_id: ctx.idea.id, profile_id: profile.id, role: 'user', content: nachricht }));
    const antwort = check(await db.from('ai_chat').insert({ idea_id: ctx.idea.id, role: 'assistant', status: 'laeuft' }).select('id').single());
    EdgeRuntime.waitUntil((async () => {
      try {
        const msg = await ask(model, {
          max_tokens: 4000,
          output_config: { effort: 'low' },
          system: `${HALTUNG}\n\nIhr sprecht über diese Idee:\n${ctx.text}\n\nAntworte im Gespräch kurz (meist 3–8 Sätze), stelle Rückfragen, wenn etwas unklar ist.`,
          messages: [
            ...verlauf.map((m: { role: string; content: string }) => ({ role: m.role, content: m.content })),
            { role: 'user', content: `${profile.name}: ${nachricht}` },
          ],
        });
        ensureAnswer(msg);
        await bookUsage(profile.id, 'chat', model, msg.usage);
        await db.from('ai_chat').update({ content: textOf(msg), status: 'fertig' }).eq('id', antwort.id);
      } catch (e) {
        console.error(e);
        await db.from('ai_chat').update({ content: 'Die KI ist gerade nicht erreichbar. Bitte später erneut versuchen.', status: 'fehler' }).eq('id', antwort.id);
      }
    })());
    return { ok: true };
  },
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Nur POST.' }, 405);
  try {
    const body = await req.json();
    const action = actions[body?.action];
    if (!action) throw new Fehler('Unbekannte Aktion.');
    return json(await action(body, req));
  } catch (e) {
    if (e instanceof Fehler) return json({ error: e.message }, e.status);
    console.error(e);
    return json({ error: 'Interner Fehler. Bitte später erneut versuchen.' }, 500);
  }
});
