import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const firebaseClientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL") ?? "";
const firebasePrivateKey = (Deno.env.get("FIREBASE_PRIVATE_KEY") ?? "")
  .replaceAll("\\n", "\n");

type ReactionPayload = {
  reactionId?: string;
};

type ReactionRow = {
  id: string;
  star_id: string;
  sender_user_id: string;
  reaction_types: {
    code: string;
    label_ko: string;
  };
  stars: {
    user_id: string;
    content: string;
  };
};

type ProfileRow = {
  nickname: string | null;
  push_token: string | null;
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    validateEnvironment();

    const payload = (await request.json()) as ReactionPayload;
    const reactionId = payload.reactionId?.trim();
    if (!reactionId) {
      return jsonResponse({ error: "reactionId is required" }, { status: 400 });
    }

    const authHeader = request.headers.get("Authorization") ?? "";
    const requesterUserId = await getRequesterUserId(authHeader);
    if (!requesterUserId) {
      return jsonResponse({ error: "Unauthorized" }, { status: 401 });
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);
    const reaction = await fetchReaction(adminClient, reactionId);
    if (!reaction) {
      return jsonResponse({ error: "Reaction not found" }, { status: 404 });
    }

    if (reaction.sender_user_id !== requesterUserId) {
      return jsonResponse({ error: "Forbidden" }, { status: 403 });
    }

    const [recipientProfile, senderProfile] = await Promise.all([
      fetchProfile(adminClient, reaction.stars.user_id),
      fetchProfile(adminClient, reaction.sender_user_id),
    ]);

    const pushToken = recipientProfile?.push_token?.trim();
    if (!pushToken) {
      return jsonResponse(
        { delivered: false, skipped: true, reason: "missing_push_token" },
        { status: 200 },
      );
    }

    const accessToken = await issueFirebaseAccessToken();
    const notification = buildNotificationMessage(
      reaction,
      senderProfile?.nickname,
    );
    const sendResult = await sendFirebaseMessage(
      accessToken,
      pushToken,
      notification,
      reaction,
    );

    if (!sendResult.ok) {
      const errorBody = await readJson(sendResult.response);
      if (isExpiredTokenError(errorBody)) {
        await adminClient
          .from("profiles")
          .update({ push_token: null })
          .eq("id", reaction.stars.user_id);
      }

      return jsonResponse(
        { delivered: false, error: errorBody },
        { status: sendResult.response.status },
      );
    }

    return jsonResponse({ delivered: true }, { status: 200 });
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
    ["SUPABASE_ANON_KEY", supabaseAnonKey],
    ["SUPABASE_SERVICE_ROLE_KEY", supabaseServiceRoleKey],
    ["FIREBASE_PROJECT_ID", firebaseProjectId],
    ["FIREBASE_CLIENT_EMAIL", firebaseClientEmail],
    ["FIREBASE_PRIVATE_KEY", firebasePrivateKey],
  ];

  for (const [name, value] of required) {
    if (!value) {
      throw new Error(`${name} is not configured`);
    }
  }
}

async function getRequesterUserId(
  authHeader: string,
): Promise<string | null> {
  if (!authHeader) {
    return null;
  }

  const client = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });
  const {
    data: { user },
  } = await client.auth.getUser();
  return user?.id ?? null;
}

async function fetchReaction(
  client: ReturnType<typeof createClient>,
  reactionId: string,
): Promise<ReactionRow | null> {
  const { data, error } = await client
    .from("reactions")
    .select(
      `
        id,
        star_id,
        sender_user_id,
        reaction_types!inner(code,label_ko),
        stars!inner(user_id,content)
      `,
    )
    .eq("id", reactionId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data as ReactionRow | null;
}

async function fetchProfile(
  client: ReturnType<typeof createClient>,
  userId: string,
): Promise<ProfileRow | null> {
  const { data, error } = await client
    .from("profiles")
    .select("nickname,push_token")
    .eq("id", userId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data as ProfileRow | null;
}

function buildNotificationMessage(
  reaction: ReactionRow,
  senderNickname: string | null,
): { title: string; body: string } {
  const trimmedSender = senderNickname?.trim() ?? "";
  const sender = trimmedSender.length > 0 ? trimmedSender : "Someone";
  const starPreview = truncateText(reaction.stars.content, 26);

  switch (reaction.reaction_types.code) {
    case "WARM_COFFEE":
      return {
        title: "Coffee sent",
        body: `${sender} sent coffee to your star: "${starPreview}"`,
      };
    case "LETTER":
      return {
        title: "Letter sent",
        body: `${sender} sent a letter to your star: "${starPreview}"`,
      };
    default:
      return {
        title: "New reaction received",
        body:
          `${sender} sent a ${reaction.reaction_types.label_ko} reaction to your star: "${starPreview}"`,
      };
  }
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
  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const encodedHeader = base64UrlEncodeJson(header);
  const encodedPayload = base64UrlEncodeJson(payload);
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(firebasePrivateKey),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
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
  reaction: ReactionRow,
): Promise<{ ok: boolean; response: Response }> {
  const response = await fetch(
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
            type: "reaction",
            reactionId: reaction.id,
            starId: reaction.star_id,
            reactionTypeCode: reaction.reaction_types.code,
          },
          android: {
            priority: "high",
          },
        },
      }),
    },
  );

  return {
    ok: response.ok,
    response,
  };
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
