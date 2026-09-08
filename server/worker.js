// BetweenUs 消息中转 Worker（Cloudflare Workers + KV）
//
// 配对：
//   POST /pair/generate              生成 6 位配对码，返回 { code }
//   POST /pair/bind { code }         用对方的码完成绑定，返回 { token }
//
// 触感中转（双通道）：
//   POST /touch { kind }             发送触感（Bearer token 鉴权）
//                                    kind = 预设 rawValue 或自定义文案（≤10 字），ack 为已读回执
//                                    → 暂存对方收件箱（轮询通道，始终启用）
//                                    → APNs 推送（配置了 APNS 密钥才启用）
//   GET  /touch/pending              轮询拉取未取走的触感（取走即删）
//
// 设备：
//   POST /device/register { apnsToken }  上报本机 APNs token（APNs 通道用）
//
// 部署见 server/README.md

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/touch/pending' && request.method === 'GET') {
      return await handlePending(env, request);
    }

    if (request.method !== 'POST') {
      return json({ error: 'method not allowed' }, 405);
    }

    const body = await request.json().catch(() => ({}));

    try {
      switch (url.pathname) {
        case '/pair/generate':
          return await handleGenerate(env);
        case '/pair/bind':
          return await handleBind(env, body);
        case '/touch':
          return await handleTouch(env, request, body);
        case '/device/register':
          return await handleRegister(env, request, body);
        default:
          return json({ error: 'not found' }, 404);
      }
    } catch (err) {
      return json({ error: String(err) }, 500);
    }
  }
};

// ---------- 配对 ----------

async function handleGenerate(env) {
  const code = randomCode();
  const tokenA = crypto.randomUUID();
  await env.BETWEENUS_KV.put(`code:${code}`, JSON.stringify({ a: tokenA }), { expirationTtl: 600 });
  await env.BETWEENUS_KV.put(`user:${tokenA}`, JSON.stringify({ apnsToken: null, partner: null }));
  return json({ code });
}

async function handleBind(env, body) {
  const code = String(body.code || '');
  const record = await env.BETWEENUS_KV.get(`code:${code}`, 'json');
  if (!record) return json({ error: '配对码无效或已过期' }, 404);

  const tokenA = record.a;
  const tokenB = crypto.randomUUID();

  const userA = await env.BETWEENUS_KV.get(`user:${tokenA}`, 'json');
  await env.BETWEENUS_KV.put(`user:${tokenA}`, JSON.stringify({ ...userA, partner: tokenB }));
  await env.BETWEENUS_KV.put(`user:${tokenB}`, JSON.stringify({ apnsToken: null, partner: tokenA }));
  await env.BETWEENUS_KV.delete(`code:${code}`);

  return json({ token: tokenB });
}

// ---------- 触感中转 ----------

async function handleTouch(env, request, body) {
  const token = bearerToken(request);
  if (!token) return json({ error: 'unauthorized' }, 401);

  const user = await env.BETWEENUS_KV.get(`user:${token}`, 'json');
  if (!user || !user.partner) return json({ error: '尚未配对' }, 403);

  const kind = String(body.kind || '');
  const isAck = kind === 'ack';
  const isCustom = isCustomKind(kind);
  if (!isAck && !isCustom && !touchTitle(kind)) return json({ error: 'invalid kind' }, 400);

  // 通道一：暂存到对方收件箱（轮询通道，始终启用；ack 同样走这里回传）
  await env.BETWEENUS_KV.put(
    `pending:${user.partner}`,
    JSON.stringify({ kind, at: Date.now() }),
    { expirationTtl: 86400 }
  );

  // 通道二：APNs 推送（仅配置了 APNs 密钥且非 ack 时启用；失败不阻塞轮询通道）
  try {
    const partner = await env.BETWEENUS_KV.get(`user:${user.partner}`, 'json');
    if (!isAck && partner && partner.apnsToken && env.APNS_KEY_ID) {
      const resp = await sendApns(env, partner.apnsToken, {
        aps: {
          alert: { title: '对方发来一个触感', body: touchTitle(kind) ?? kind },
          sound: 'default',
          'content-available': 1
        },
        kind
      });
      if (!resp.ok) console.warn(`APNs rejected: ${resp.status}`);
    }
  } catch (err) {
    console.warn(`APNs failed: ${err}`);
  }

  return json({ ok: true });
}

async function handlePending(env, request) {
  const token = bearerToken(request);
  if (!token) return json({ error: 'unauthorized' }, 401);

  const key = `pending:${token}`;
  const record = await env.BETWEENUS_KV.get(key, 'json');
  if (!record) return json({ kind: null });

  await env.BETWEENUS_KV.delete(key);
  return json({ kind: record.kind, at: record.at });
}

async function handleRegister(env, request, body) {
  const token = bearerToken(request);
  if (!token) return json({ error: 'unauthorized' }, 401);

  const user = await env.BETWEENUS_KV.get(`user:${token}`, 'json');
  if (!user) return json({ error: 'invalid token' }, 401);

  await env.BETWEENUS_KV.put(`user:${token}`, JSON.stringify({ ...user, apnsToken: String(body.apnsToken || '') }));
  return json({ ok: true });
}

// ---------- APNs ----------

async function sendApns(env, deviceToken, payload) {
  const jwt = await apnsJWT(env);
  const host = env.APNS_PRODUCTION === 'true'
    ? 'https://api.push.apple.com'
    : 'https://api.sandbox.push.apple.com';

  return fetch(`${host}/3/device/${deviceToken}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${jwt}`,
      'apns-topic': env.APNS_BUNDLE_ID,
      'apns-push-type': 'alert',
      'apns-priority': '5',
      'content-type': 'application/json'
    },
    body: JSON.stringify(payload)
  });
}

async function apnsJWT(env) {
  const header = { alg: 'ES256', kid: env.APNS_KEY_ID };
  const payload = { iss: env.APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) };
  const input = `${b64u(JSON.stringify(header))}.${b64u(JSON.stringify(payload))}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(env.APNS_AUTH_KEY),
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    key,
    new TextEncoder().encode(input)
  );
  return `${input}.${b64u(sig)}`;
}

// ---------- 工具 ----------

function bearerToken(request) {
  const header = request.headers.get('authorization') || '';
  return header.startsWith('Bearer ') ? header.slice(7) : null;
}

function randomCode() {
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, b => b % 10).join('');
}

const TOUCH_TITLES = {
  // 心意
  missYou: '想你了',
  hug: '抱一下',
  loveYou: '爱你',
  // 特别
  thinking: '在想你',
  goodNight: '晚安',
  sorry: '对不起',
  // 日常
  goodMorning: '早安',
  busy: '在忙'
};

// 自定义文案上限，与 iOS 端输入限制一致
const MAX_CUSTOM_LEN = 10;

// 自定义触感：非 ack 且非预设的任意短文本（payload 自包含，无需对方预存）
function isCustomKind(kind) {
  return typeof kind === 'string' && kind.length > 0 && kind.length <= MAX_CUSTOM_LEN;
}

function touchTitle(kind) {
  return TOUCH_TITLES[kind];
}

function b64u(str) {
  const bytes = typeof str === 'string' ? new TextEncoder().encode(str) : new Uint8Array(str);
  let bin = '';
  bytes.forEach(b => { bin += String.fromCharCode(b); });
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToDer(pem) {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const bin = atob(base64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { 'content-type': 'application/json' } });
}