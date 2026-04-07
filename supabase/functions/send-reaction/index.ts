import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (request) => {
  const authorization = request.headers.get('Authorization') ?? '';
  const body = await request.json();

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authorization } } },
  );

  const { data, error } = await supabase.rpc('send_reaction', {
    p_star_id: body.starId,
    p_reaction_type_id: body.reactionTypeId,
  });

  return Response.json({ data, error }, { status: error ? 400 : 200 });
});

