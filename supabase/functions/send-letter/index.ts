import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const openAiApiKey = Deno.env.get("OPENAI_API_KEY") ?? "";
const openAiModel = Deno.env.get("OPENAI_LETTER_MODERATION_MODEL") ??
  "gpt-5-mini";

const appErrorCodes = new Set([
  "UNAUTHORIZED",
  "FORBIDDEN",
  "INVALID_ARGUMENT",
  "STAR_NOT_FOUND",
  "DAILY_REACTION_LIMIT_EXCEEDED",
  "ALREADY_REACTED",
  "BLOCKED_RELATIONSHIP",
  "SELF_REACTION_NOT_ALLOWED",
  "INTERNAL_ERROR",
]);

type SendLetterPayload = {
  starId?: string;
  content?: string;
};

type LetterReview = {
  allowed: boolean;
  category: string;
  reason: string;
};

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    validateEnvironment();

    const authHeader = request.headers.get("Authorization") ?? "";
    if (!authHeader) {
      return appErrorResponse("UNAUTHORIZED", 401);
    }
    const accessToken = authHeader.replace(/^Bearer\s+/i, "").trim();
    if (!accessToken) {
      return appErrorResponse("UNAUTHORIZED", 401);
    }

    const payload = (await request.json()) as SendLetterPayload;
    const starId = payload.starId?.trim();
    const content = payload.content?.trim();

    if (!starId || !content || content.length > 240) {
      return appErrorResponse("INVALID_ARGUMENT", 400);
    }

    const review = await reviewLetterContent(content);
    if (!review.allowed) {
      return appErrorResponse("LETTER_BLOCKED_BY_MODERATION", 422, {
        category: review.category,
        reason: review.reason,
      });
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser(
      accessToken,
    );
    const senderUserId = userData.user?.id;
    if (userError || !senderUserId) {
      return appErrorResponse("UNAUTHORIZED", 401);
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);
    const { data, error } = await adminClient.rpc("send_moderated_letter", {
      p_sender_user_id: senderUserId,
      p_star_id: starId,
      p_content: content,
    });

    if (error) {
      const code = normalizeAppErrorCode(error.message);
      return appErrorResponse(code, statusForAppErrorCode(code), {
        original: error.message,
      });
    }

    return jsonResponse({ data }, { status: 200 });
  } catch (error) {
    if (isOpenAiQuotaError(error) || isOpenAiUnavailableError(error)) {
      return appErrorResponse("LETTER_MODERATION_UNAVAILABLE", 503);
    }

    return appErrorResponse("INTERNAL_ERROR", 500, {
      reason: error instanceof Error ? error.message : String(error),
    });
  }
});

function validateEnvironment(): void {
  const required = [
    ["SUPABASE_URL", supabaseUrl],
    ["SUPABASE_ANON_KEY", supabaseAnonKey],
    ["SUPABASE_SERVICE_ROLE_KEY", supabaseServiceRoleKey],
    ["OPENAI_API_KEY", openAiApiKey],
  ];

  for (const [name, value] of required) {
    if (!value) {
      throw new Error(`${name} is not configured`);
    }
  }
}

async function reviewLetterContent(content: string): Promise<LetterReview> {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAiApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: openAiModel,
      input: [
        {
          role: "system",
          content:
            "You review anonymous Korean comfort letters before delivery. Block messages that could hurt the recipient: insults, blame, mockery, humiliation, threats, harassment, coercion, sexual content, hate, self-harm encouragement, or manipulative guilt. Allow gentle encouragement, empathy, neutral advice, and supportive concern. Return only the JSON schema.",
        },
        {
          role: "user",
          content: JSON.stringify({ letter: content }),
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "letter_safety_review",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              allowed: { type: "boolean" },
              category: {
                type: "string",
                enum: [
                  "safe",
                  "insult",
                  "harassment",
                  "threat",
                  "guilt_or_blame",
                  "sexual",
                  "hate",
                  "self_harm",
                  "other_harmful",
                ],
              },
              reason: { type: "string" },
            },
            required: ["allowed", "category", "reason"],
          },
        },
      },
      max_output_tokens: 200,
    }),
  });

  const body = await readJson(response);
  if (!response.ok) {
    throw new OpenAiError(response.status, body);
  }

  const outputText = extractOutputText(body);
  if (!outputText) {
    throw new Error("OpenAI response did not include output text");
  }

  const parsed = JSON.parse(outputText) as Partial<LetterReview>;
  return {
    allowed: parsed.allowed === true,
    category: typeof parsed.category === "string"
      ? parsed.category
      : "other_harmful",
    reason: typeof parsed.reason === "string" ? parsed.reason : "",
  };
}

function extractOutputText(body: Record<string, unknown>): string | null {
  const outputText = body["output_text"];
  if (typeof outputText === "string") {
    return outputText;
  }

  const output = body["output"];
  if (!Array.isArray(output)) {
    return null;
  }

  for (const item of output) {
    if (!isRecord(item)) {
      continue;
    }

    const content = item["content"];
    if (!Array.isArray(content)) {
      continue;
    }

    for (const contentItem of content) {
      if (!isRecord(contentItem)) {
        continue;
      }
      const text = contentItem["text"];
      if (typeof text === "string") {
        return text;
      }
    }
  }

  return null;
}

function normalizeAppErrorCode(value: string): string {
  const match = value.match(/\b[A-Z][A-Z0-9_]{2,}\b/);
  const candidate = match?.[0] ?? "INTERNAL_ERROR";
  return appErrorCodes.has(candidate) ? candidate : "INTERNAL_ERROR";
}

function statusForAppErrorCode(code: string): number {
  switch (code) {
    case "UNAUTHORIZED":
      return 401;
    case "FORBIDDEN":
    case "BLOCKED_RELATIONSHIP":
    case "SELF_REACTION_NOT_ALLOWED":
      return 403;
    case "STAR_NOT_FOUND":
      return 404;
    case "ALREADY_REACTED":
    case "DAILY_REACTION_LIMIT_EXCEEDED":
      return 409;
    case "INVALID_ARGUMENT":
      return 400;
    default:
      return 500;
  }
}

class OpenAiError extends Error {
  constructor(public status: number, public body: Record<string, unknown>) {
    super(JSON.stringify(body));
  }
}

function isOpenAiQuotaError(error: unknown): boolean {
  if (!(error instanceof OpenAiError)) {
    return false;
  }

  const serialized = JSON.stringify(error.body).toLowerCase();
  return error.status === 429 &&
    (serialized.includes("insufficient_quota") ||
      serialized.includes("quota") ||
      serialized.includes("billing"));
}

function isOpenAiUnavailableError(error: unknown): boolean {
  if (!(error instanceof OpenAiError)) {
    return false;
  }

  return error.status === 401 ||
    error.status === 402 ||
    error.status === 408 ||
    error.status === 429 ||
    error.status >= 500;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
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

function appErrorResponse(
  code: string,
  status: number,
  extra: Record<string, unknown> = {},
): Response {
  return jsonResponse(
    {
      APP_ERROR_CODE: code,
      ...extra,
    },
    { status },
  );
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
