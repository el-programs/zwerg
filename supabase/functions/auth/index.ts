// Zwerg · Anmeldung per Passkey (WebAuthn), Einladungs-Links und Geräte-Kopplung per QR-Code.
// Läuft als Supabase Edge Function. Der Dienstschlüssel bleibt hier auf dem Server.
import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  generateAuthenticationOptions,
  generateRegistrationOptions,
  verifyAuthenticationResponse,
  verifyRegistrationResponse,
} from 'npm:@simplewebauthn/server@13';
import { isoBase64URL } from 'npm:@simplewebauthn/server@13/helpers';

const RP_ID = Deno.env.get('ZWERG_RP_ID') ?? 'el-programs.github.io';
const ORIGIN = Deno.env.get('ZWERG_ORIGIN') ?? 'https://el-programs.github.io';
const APP_URL = Deno.env.get('ZWERG_APP_URL') ?? 'https://el-programs.github.io/zwerg/';
const CHALLENGE_TTL_MS = 5 * 60 * 1000;
const LINK_TTL_MS = 5 * 60 * 1000;
const INVITE_TTL_MS = 24 * 60 * 60 * 1000;

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

class Fehler extends Error {
  constructor(message: string, public status = 400) {
    super(message);
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

function randomToken(bytes = 24) {
  const a = crypto.getRandomValues(new Uint8Array(bytes));
  return Array.from(a, (b) => b.toString(16).padStart(2, '0')).join('');
}

async function sha256(text: string) {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(d), (b) => b.toString(16).padStart(2, '0')).join('');
}

// deno-lint-ignore no-explicit-any
function check(res: { data: any; error: { message: string } | null }): any {
  if (res.error) throw new Error(res.error.message);
  return res.data;
}

// Legt bei Bedarf das Login-Konto einer Person an und liefert einen einmaligen Anmelde-Token,
// den der Browser mit supabase.auth.verifyOtp() gegen eine Sitzung tauscht.
async function sessionTokenFor(profileId: string) {
  const profile = check(await db.from('profiles').select('*').eq('id', profileId).single());
  const email = `${profile.slug}@zwerg.example.com`;
  if (!profile.user_id) {
    const created = await db.auth.admin.createUser({ email, email_confirm: true });
    if (created.error) throw new Error(created.error.message);
    check(await db.from('profiles').update({ user_id: created.data.user.id }).eq('id', profile.id));
  }
  const link = await db.auth.admin.generateLink({ type: 'magiclink', email });
  if (link.error) throw new Error(link.error.message);
  return { tokenHash: link.data.properties.hashed_token, name: profile.name };
}

async function storeChallenge(challenge: string, purpose: 'register' | 'login', profileId?: string) {
  await db.from('webauthn_challenges').delete().lt('created_at', new Date(Date.now() - CHALLENGE_TTL_MS).toISOString());
  const row = check(
    await db.from('webauthn_challenges').insert({ challenge, purpose, profile_id: profileId ?? null }).select('id').single(),
  );
  return row.id as string;
}

async function takeChallenge(id: string, purpose: 'register' | 'login') {
  const row = check(await db.from('webauthn_challenges').delete().eq('id', id).select('*').maybeSingle());
  if (!row || row.purpose !== purpose || Date.now() - new Date(row.created_at).getTime() > CHALLENGE_TTL_MS) {
    throw new Fehler('Die Anfrage ist abgelaufen. Bitte erneut versuchen.');
  }
  return row;
}

async function openInvite(token: string) {
  if (!token) throw new Fehler('Einladungs-Link fehlt.');
  const invite = check(await db.from('invites').select('*, profiles!invites_profile_id_fkey(*)').eq('token_hash', await sha256(token)).maybeSingle());
  if (!invite || invite.used_at || new Date(invite.expires_at).getTime() < Date.now()) {
    throw new Fehler('Dieser Einladungs-Link ist ungültig oder abgelaufen.', 410);
  }
  return invite;
}

// Prüft eine Passkey-Bestätigung und liefert die zugehörige Person.
async function verifyAssertion(challengeId: string, response: any) {
  const challenge = await takeChallenge(challengeId, 'login');
  const cred = check(await db.from('webauthn_credentials').select('*').eq('id', response?.id ?? '').maybeSingle());
  if (!cred) throw new Fehler('Dieser Passkey ist in Zwerg nicht (mehr) hinterlegt.', 401);
  const result = await verifyAuthenticationResponse({
    response,
    expectedChallenge: challenge.challenge,
    expectedOrigin: ORIGIN,
    expectedRPID: RP_ID,
    requireUserVerification: true,
    credential: {
      id: cred.id,
      publicKey: isoBase64URL.toBuffer(cred.public_key),
      counter: Number(cred.counter),
      transports: cred.transports,
    },
  });
  if (!result.verified) throw new Fehler('Passkey konnte nicht bestätigt werden.', 401);
  check(
    await db.from('webauthn_credentials')
      .update({ counter: result.authenticationInfo.newCounter, last_used_at: new Date().toISOString() })
      .eq('id', cred.id),
  );
  return { profileId: cred.profile_id as string, credentialId: cred.id as string };
}

// Angemeldete Person aus dem mitgeschickten Zugangs-Token; gesperrte Geräte werden abgewiesen.
async function requireMember(req: Request) {
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const { data, error } = await db.auth.getUser(token);
  if (error || !data.user) throw new Fehler('Bitte zuerst anmelden.', 401);
  const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
  const sessionId = payload.session_id as string;
  const profile = check(await db.from('profiles').select('*').eq('user_id', data.user.id).maybeSingle());
  if (!profile) throw new Fehler('Kein Zugang.', 403);
  const revoked = check(
    await db.from('devices').select('id').eq('session_id', sessionId).not('revoked_at', 'is', null).maybeSingle(),
  );
  if (revoked) throw new Fehler('Dieses Gerät wurde gesperrt.', 403);
  return { profile, sessionId };
}

const actions: Record<string, (body: any, req: Request) => Promise<unknown>> = {
  async 'invite-info'(body) {
    const invite = await openInvite(body.token);
    return { name: invite.profiles.name };
  },

  async 'register-options'(body) {
    const invite = await openInvite(body.token);
    const profile = invite.profiles;
    const existing = check(await db.from('webauthn_credentials').select('id, transports').eq('profile_id', profile.id));
    const options = await generateRegistrationOptions({
      rpName: 'Zwerg',
      rpID: RP_ID,
      userName: profile.name,
      userDisplayName: profile.name,
      userID: new TextEncoder().encode(profile.id),
      attestationType: 'none',
      excludeCredentials: existing.map((c: any) => ({ id: c.id, transports: c.transports })),
      authenticatorSelection: { residentKey: 'required', userVerification: 'required' },
    });
    const challengeId = await storeChallenge(options.challenge, 'register', profile.id);
    return { challengeId, options, name: profile.name };
  },

  async 'register-verify'(body) {
    const invite = await openInvite(body.token);
    const challenge = await takeChallenge(body.challengeId, 'register');
    if (challenge.profile_id !== invite.profile_id) throw new Fehler('Ungültige Anfrage.');
    const result = await verifyRegistrationResponse({
      response: body.response,
      expectedChallenge: challenge.challenge,
      expectedOrigin: ORIGIN,
      expectedRPID: RP_ID,
      requireUserVerification: true,
    });
    if (!result.verified || !result.registrationInfo) throw new Fehler('Passkey konnte nicht eingerichtet werden.');
    const { credential } = result.registrationInfo;
    check(
      await db.from('webauthn_credentials').insert({
        id: credential.id,
        profile_id: invite.profile_id,
        public_key: isoBase64URL.fromBuffer(credential.publicKey),
        counter: credential.counter,
        transports: credential.transports ?? [],
      }),
    );
    check(await db.from('invites').update({ used_at: new Date().toISOString() }).eq('token_hash', invite.token_hash));
    return { ...(await sessionTokenFor(invite.profile_id)), credentialId: credential.id };
  },

  async 'login-options'() {
    const options = await generateAuthenticationOptions({ rpID: RP_ID, userVerification: 'required' });
    const challengeId = await storeChallenge(options.challenge, 'login');
    return { challengeId, options };
  },

  async 'login-verify'(body) {
    const { profileId, credentialId } = await verifyAssertion(body.challengeId, body.response);
    return { ...(await sessionTokenFor(profileId)), credentialId };
  },

  // Laptop: startet die Kopplung und zeigt den QR-Code an.
  async 'link-start'() {
    await db.from('device_links').delete().lt('expires_at', new Date().toISOString());
    const approveCode = randomToken(16);
    const pollSecret = randomToken(24);
    const row = check(
      await db.from('device_links').insert({
        approve_code_hash: await sha256(approveCode),
        poll_secret_hash: await sha256(pollSecret),
        expires_at: new Date(Date.now() + LINK_TTL_MS).toISOString(),
      }).select('id, expires_at').single(),
    );
    return { linkId: row.id, approveCode, pollSecret, expiresAt: row.expires_at };
  },

  // Laptop: fragt regelmäßig nach, ob das iPhone die Kopplung bestätigt hat.
  async 'link-poll'(body) {
    const link = check(await db.from('device_links').select('*').eq('id', body.linkId ?? '').maybeSingle());
    if (!link || link.poll_secret_hash !== (await sha256(body.pollSecret ?? ''))) throw new Fehler('Unbekannte Kopplung.', 404);
    if (link.status === 'pending') {
      return { status: new Date(link.expires_at).getTime() < Date.now() ? 'expired' : 'pending' };
    }
    if (link.status !== 'approved') return { status: 'expired' };
    const updated = check(
      await db.from('device_links').update({ status: 'consumed' }).eq('id', link.id).eq('status', 'approved').select('id'),
    );
    if (!updated.length) return { status: 'expired' };
    return { status: 'approved', ...(await sessionTokenFor(link.profile_id)) };
  },

  // iPhone: bestätigt die Kopplung nach dem Scannen mit Face ID.
  async 'link-approve'(body, req) {
    const { profile } = await requireMember(req);
    const { profileId } = await verifyAssertion(body.challengeId, body.response);
    if (profileId !== profile.id) throw new Fehler('Bitte mit deinem eigenen Passkey bestätigen.', 403);
    const link = check(await db.from('device_links').select('*').eq('id', body.linkId ?? '').maybeSingle());
    if (
      !link || link.status !== 'pending' || new Date(link.expires_at).getTime() < Date.now() ||
      link.approve_code_hash !== (await sha256(body.approveCode ?? ''))
    ) {
      throw new Fehler('Der QR-Code ist abgelaufen. Bitte am Laptop einen neuen anzeigen lassen.', 410);
    }
    check(await db.from('device_links').update({ status: 'approved', profile_id: profile.id }).eq('id', link.id));
    return { ok: true };
  },

  async 'invite-create'(body, req) {
    const { profile } = await requireMember(req);
    const target = check(await db.from('profiles').select('*').eq('slug', body.slug ?? '').maybeSingle());
    if (!target) throw new Fehler('Unbekannte Person.');
    const token = randomToken(24);
    const expiresAt = new Date(Date.now() + INVITE_TTL_MS).toISOString();
    check(
      await db.from('invites').insert({
        token_hash: await sha256(token),
        profile_id: target.id,
        created_by: profile.id,
        expires_at: expiresAt,
      }),
    );
    return { url: `${APP_URL}#/einladung/${token}`, name: target.name, expiresAt };
  },

  async 'device-register'(body, req) {
    const { profile, sessionId } = await requireMember(req);
    const label = String(body.label ?? 'Gerät').slice(0, 80);
    const kind = body.kind === 'qr' ? 'qr' : 'passkey';
    check(
      await db.from('devices').upsert(
        {
          profile_id: profile.id,
          session_id: sessionId,
          label,
          kind,
          credential_id: kind === 'passkey' ? body.credentialId ?? null : null,
          last_seen_at: new Date().toISOString(),
        },
        { onConflict: 'session_id' },
      ),
    );
    return { ok: true };
  },

  async 'device-seen'(_body, req) {
    const { sessionId } = await requireMember(req);
    await db.from('devices').update({ last_seen_at: new Date().toISOString() }).eq('session_id', sessionId);
    return { ok: true };
  },

  // Sperrt ein Gerät. Bei Passkey-Geräten wird auch der Passkey entfernt.
  async 'device-revoke'(body, req) {
    await requireMember(req);
    const device = check(await db.from('devices').select('*').eq('id', body.deviceId ?? '').maybeSingle());
    if (!device) throw new Fehler('Gerät nicht gefunden.', 404);
    check(await db.from('devices').update({ revoked_at: new Date().toISOString() }).eq('id', device.id));
    if (device.credential_id) {
      check(await db.from('webauthn_credentials').delete().eq('id', device.credential_id));
    }
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
