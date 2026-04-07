import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (request) => {
  const authorization = request.headers.get('Authorization') ?? '';
  const body = await request.json();

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authorization } } },
  );

  const { data, error } = await supabase.rpc('create_star', {
    p_primary_tag_id: body.primaryTagId,
    p_secondary_tag_ids: body.secondaryTagIds ?? [],
    p_content: body.content ?? null,
    p_visibility_status: body.visibility ?? 'public',
    p_emotion_intensity: body.emotionIntensity ?? 3,
  });

  return Response.json({ data, error }, { status: error ? 400 : 200 });
});

