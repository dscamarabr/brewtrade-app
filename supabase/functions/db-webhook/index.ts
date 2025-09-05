// supabase/functions/db-webhook/index.ts

const PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL")!;
const PRIVATE_KEY_RAW = Deno.env.get("FIREBASE_PRIVATE_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const PRIVATE_KEY = PRIVATE_KEY_RAW.replace(/\\n/g, "\n");

let cachedAccessToken: { token: string; exp: number } | null = null;

function base64UrlEncode(input: Uint8Array): string {
  const bin = Array.from(input).map(b => String.fromCharCode(b)).join("");
  const b64 = btoa(bin);
  return b64.replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function base64UrlEncodeString(str: string): string {
  return base64UrlEncode(new TextEncoder().encode(str));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

async function createJwtAssertion(): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600
  };

  const encHeader = base64UrlEncodeString(JSON.stringify(header));
  const encPayload = base64UrlEncodeString(JSON.stringify(payload));
  const signingInput = `${encHeader}.${encPayload}`;

  const keyData = pemToArrayBuffer(PRIVATE_KEY);
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signingInput)
  );

  const encSignature = base64UrlEncode(new Uint8Array(signature));
  return `${signingInput}.${encSignature}`;
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.exp - 60 > now) {
    return cachedAccessToken.token;
  }

  const assertion = await createJwtAssertion();
  const body = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion
  }).toString();

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Falha ao obter access_token: ${res.status} ${errText}`);
  }

  const json = await res.json();
  const token = json.access_token as string;
  const expiresIn = Number(json.expires_in ?? 3600);
  const exp = now + expiresIn;

  cachedAccessToken = { token, exp };
  return token;
}

Deno.serve(async (req) => {
  try {
    const rawBody = await req.text();
    console.log("Corpo bruto recebido:", rawBody);

    let parsed;
    try {
      parsed = JSON.parse(rawBody);
    } catch (err) {
      console.error("Erro ao fazer parse do JSON:", err);
      return new Response(JSON.stringify({ success: false, error: "JSON inválido" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }

    const { type, record } = parsed;

    if (type !== "INSERT" || !record) {
      console.warn("Evento ignorado:", type);
      return new Response(JSON.stringify({ success: false, error: "Evento não é INSERT ou record ausente" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }

    const {
      tp_notificacao,
      id_usuario_remetente,
      id_usuario_destinatario,
      id_notificacao
    } = record;

    // 1️⃣ Buscar tokens ativos
    const tokensRes = await fetch(
      `${SUPABASE_URL}/rest/v1/tb_push_tokens?user_id=eq.${id_usuario_destinatario}&ativo=eq.true&select=token,user_id`,
      {
        headers: {
          "apikey": SUPABASE_SERVICE_ROLE,
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE}`,
          "Content-Type": "application/json"
        }
      }
    );

    const tokensData = await tokensRes.json();

    if (!tokensData.length) {
      console.error("Nenhum token ativo encontrado para usuário:", id_usuario_destinatario);
      return new Response(JSON.stringify({ success: false, error: "Token não encontrado" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }

    // 2️⃣ Verificar se permite notificações
    const cervejeiroRes = await fetch(
      `${SUPABASE_URL}/rest/v1/tb_cervejeiro?id=eq.${tokensData[0].user_id}&select=permite_notificacoes`,
      {
        headers: {
          "apikey": SUPABASE_SERVICE_ROLE,
          "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE}`,
          "Content-Type": "application/json"
        }
      }
    );

    const cervejeiroData = await cervejeiroRes.json();
    const permiteNotificacoes = cervejeiroData[0]?.permite_notificacoes === true;

    if (!permiteNotificacoes) {
      console.log("Usuário não permite notificações");
      return new Response(JSON.stringify({ success: false, error: "Usuário não permite notificações" }), {
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }

    const token = tokensData[0].token;
    const titulo = tp_notificacao;
    const corpo = record.mensagem_push ?? "Você recebeu uma nova notificação";

    const accessToken = await getAccessToken();

    const acao = tp_notificacao === 'Cadastro Cerveja'
      ? 'abrir_pesquisa_filtrada'
      : 'acao_desconhecida';

    const fcmMessage = {
      message: {
        token,
        notification: {
          title: titulo,
          body: corpo
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "cervejas_high"
          }
        },
        data: {
          tipo: tp_notificacao.toLowerCase().replace(/\s+/g, '_'),
          acao,
          usuario_id: String(id_usuario_remetente),
          id_notificacao: String(id_notificacao)
        }
      }
    };

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(fcmMessage)
      }
    );

    const text = await fcmRes.text();

    if (!fcmRes.ok) {
      console.error("Erro FCM:", fcmRes.status, text);

      try {
        const json = JSON.parse(text);
        const errorCode = json?.error?.details?.[0]?.errorCode;

        if (errorCode === "UNREGISTERED") {
          console.warn("Token FCM inválido detectado. Inativando...");

          await fetch(`${SUPABASE_URL}/rest/v1/tb_push_tokens?token=eq.${token}`, {
            method: "PATCH",
            headers: {
              "apikey": SUPABASE_SERVICE_ROLE,
              "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE}`,
              "Content-Type": "application/json",
              "Prefer": "return=minimal"
            },
            body: JSON.stringify({ ativo: false })
          });
        }
      } catch (err) {
        console.error("Erro ao tentar inativar token FCM:", err);
      }

      return new Response(JSON.stringify({ success: false, error: text }), {
        status: 500,
        headers: { "Content-Type": "application/json" }
      });
    }

    console.log("Notificação enviada com sucesso:", text);
    return new Response(JSON.stringify({ success: true, result: text }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (err: any) {
    console.error("Erro inesperado:", err);
    return new Response(JSON.stringify({ success: false, error: err?.message ?? String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
});
