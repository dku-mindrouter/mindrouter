import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const firebaseClientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL") ?? "";
const firebasePrivateKey = (Deno.env.get("FIREBASE_PRIVATE_KEY") ?? "")
  .replaceAll("\\n", "\n");
const cronSecret = Deno.env.get("DELIVER_LETTERS_CRON_SECRET") ?? "";

type LetterRow = {
  id: string;
  star_id: string;
  recipient_user_id: string;
  content: string;
  stars: {
    content: string;
  };
  profiles: {
    push_token: string | null;
  };
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    validateEnvironment();
    if (request.headers.get("x-cron-secret") !== cronSecret) {
      return jsonResponse({ error: "Unauthorized" }, { status: 401 });
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);
    const letters = await fetchDueLetters(adminClient);
    if (letters.length === 0) {
      return jsonResponse({ delivered: 0 }, { status: 200 });
    }

    const accessToken = await issueFirebaseAccessToken();
    let delivered = 0;

    for (const letter of letters) {
      const pushToken = letter.profiles.push_token?.trim();
      if (pushToken) {
        const response = await sendFirebaseMessage(
          accessToken,
          pushToken,
          buildNotification(letter),
          letter,
        );

        if (!response.ok) {
          const errorBody = await readJson(response);
          if (isExpiredTokenError(errorBody)) {
            await adminClient
              .from("profiles")
              .update({ push_token: null })
              .eq("id", letter.recipient_user_id);
          }
        }
      }

      await adminClient
        .from("letter_deliveries")
        .update({ delivered_at: new Date().toISOString() })
        .eq("id", letter.id)
        .is("delivered_at", null);
      delivered += 1;
    }

    return jsonResponse({ delivered }, { status: 200 });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      { status: 500 },
    );
  }
});

function validateEnvironment(): void {
  const required = [
    ["SUPABASE_URL", supabaseUrl],
    ["SUPABASE_SERVICE_ROLE_KEY", supabaseServiceRoleKey],
    ["FIREBASE_PROJECT_ID", firebaseProjectId],
    ["FIREBASE_CLIENT_EMAIL", firebaseClientEmail],
    ["FIREBASE_PRIVATE_KEY", firebasePrivateKey],
    ["DELIVER_LETTERS_CRON_SECRET", cronSecret],
  ];

  for (const [name, value] of required) {
    if (!value) {
      throw new Error(`${name} is not configured`);
    }
  }
}

async function fetchDueLetters(
  client: ReturnType<typeof createClient>,
): Promise<LetterRow[]> {
  const { data, error } = await client
    .from("letter_deliveries")
    .select(
      `
        id,
        star_id,
        recipient_user_id,
        content,
        stars!inner(content),
        profiles!letter_deliveries_recipient_user_id_fkey(push_token)
      `,
    )
    .lte("deliver_at", new Date().toISOString())
    .is("delivered_at", null)
    .eq("is_deleted", false)
    .order("deliver_at", { ascending: true })
    .limit(100);

  if (error) {
    throw error;
  }

  return (data ?? []) as LetterRow[];
}

function buildNotification(letter: LetterRow): { title: string; body: string } {
  const starPreview = truncateText(letter.stars.content, 26);
  return {
    title: "익명 편지가 도착했어요",
    body: `"${starPreview}" 별에 편지가 도착했어요.`,
  };
}

async function issueFirebaseAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const assertion = await createServiceAccountJwt({
    iss: firebaseClientEmail,
    sub: firebaseClientEmail,
    aud: "https://oauth2.googleapis.com/token",
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    iat: now,
    exp: now + 3600,
  });

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const body = await readJson(response);
  const accessToken = body["access_token"];
  if (!response.ok || typeof accessToken !== "string") {
    throw new Error(
      `Failed to issue Firebase access token: ${JSON.stringify(body)}`,
    );
  }

  return accessToken;
}

async function createServiceAccountJwt(
  payload: Record<string, string | number>,
): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const encodedHeader = base64UrlEncodeJson(header);
  const encodedPayload = base64UrlEncodeJson(payload);
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(firebasePrivateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll("\n", "")
    .trim();
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

function base64UrlEncodeJson(input: unknown): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(JSON.stringify(input)));
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

async function sendFirebaseMessage(
  accessToken: string,
  pushToken: string,
  notification: { title: string; body: string },
  letter: LetterRow,
): Promise<Response> {
  return fetch(
    `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json; charset=utf-8",
      },
      body: JSON.stringify({
        message: {
          token: pushToken,
          notification,
          data: {
            type: "letter",
            letterId: letter.id,
            starId: letter.star_id,
          },
          android: { priority: "high" },
        },
      }),
    },
  );
}

function isExpiredTokenError(errorBody: Record<string, unknown>): boolean {
  const serialized = JSON.stringify(errorBody);
  return serialized.includes("UNREGISTERED") ||
    serialized.includes("registration-token-not-registered");
}

function truncateText(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }
  return `${value.substring(0, maxLength - 3)}...`;
}

async function readJson(response: Response): Promise<Record<string, unknown>> {
  const text = await response.text();
  if (!text) {
    return {};
  }
  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch (_) {
    return { raw: text };
  }
}

function jsonResponse(
  body: Record<string, unknown>,
  init: ResponseInit,
): Response {
  return new Response(JSON.stringify(body), {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
      ...(init.headers ?? {}),
    },
  });
}
