create or replace function public.send_moderated_letter(
  p_sender_user_id uuid,
  p_star_id uuid,
  p_content text
)
returns table (
  letter_id uuid,
  reaction_id uuid,
  star_id uuid,
  reaction_count int,
  deliver_at timestamptz
)
language plpgsql
security definer
as $$
declare
  v_sender_timezone varchar(64);
  v_local_date date;
  v_target_owner_id uuid;
  v_today_count int;
  v_reaction_id uuid;
  v_reaction_count int;
  v_letter_id uuid;
  v_deliver_at timestamptz;
begin
  if p_sender_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_star_id is null or p_content is null or length(btrim(p_content)) = 0 or length(p_content) > 240 then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select s.user_id
  into v_target_owner_id
  from public.stars s
  where s.id = p_star_id
    and s.is_deleted = false
    and s.visibility_status = 'public'
    and (s.expires_at is null or s.expires_at > now());

  if v_target_owner_id is null then
    perform public.raise_app_error('STAR_NOT_FOUND');
  end if;

  if v_target_owner_id = p_sender_user_id then
    perform public.raise_app_error('SELF_REACTION_NOT_ALLOWED');
  end if;

  if exists (
    select 1
    from public.blocks b
    where
      (b.blocker_user_id = p_sender_user_id and b.blocked_user_id = v_target_owner_id)
      or (b.blocker_user_id = v_target_owner_id and b.blocked_user_id = p_sender_user_id)
  ) then
    perform public.raise_app_error('BLOCKED_RELATIONSHIP');
  end if;

  if exists (
    select 1
    from public.reactions r
    where r.star_id = p_star_id
      and r.sender_user_id = p_sender_user_id
      and r.reaction_type_id = 6
  ) then
    perform public.raise_app_error('ALREADY_REACTED');
  end if;

  if exists (
    select 1
    from public.letter_deliveries l
    where l.star_id = p_star_id
      and l.sender_user_id = p_sender_user_id
      and l.is_deleted = false
  ) then
    perform public.raise_app_error('ALREADY_REACTED');
  end if;

  select p.timezone
  into v_sender_timezone
  from public.profiles p
  where p.id = p_sender_user_id and p.is_active = true;

  if v_sender_timezone is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  v_local_date := (now() at time zone v_sender_timezone)::date;

  select count(*)
  into v_today_count
  from public.reactions r
  where r.sender_user_id = p_sender_user_id
    and r.created_local_date = v_local_date;

  if v_today_count >= 20 then
    perform public.raise_app_error('DAILY_REACTION_LIMIT_EXCEEDED');
  end if;

  insert into public.reactions (
    star_id,
    sender_user_id,
    reaction_type_id,
    created_local_date
  )
  values (
    p_star_id,
    p_sender_user_id,
    6,
    v_local_date
  )
  returning id into v_reaction_id;

  v_deliver_at := now() + interval '1 day';

  insert into public.letter_deliveries (
    star_id,
    reaction_id,
    sender_user_id,
    recipient_user_id,
    content,
    deliver_at
  )
  values (
    p_star_id,
    v_reaction_id,
    p_sender_user_id,
    v_target_owner_id,
    btrim(p_content),
    v_deliver_at
  )
  returning id into v_letter_id;

  update public.stars
  set reaction_count = stars.reaction_count + 1
  where id = p_star_id
  returning stars.reaction_count into v_reaction_count;

  insert into public.daily_logs (user_id, date, reaction_sent_count, created_at, updated_at)
  values (p_sender_user_id, v_local_date, 1, now(), now())
  on conflict (user_id, date)
  do update set
    reaction_sent_count = public.daily_logs.reaction_sent_count + 1,
    updated_at = now();

  return query
  select
    v_letter_id as letter_id,
    v_reaction_id as reaction_id,
    p_star_id as star_id,
    v_reaction_count as reaction_count,
    v_deliver_at as deliver_at;
exception
  when unique_violation then
    perform public.raise_app_error('ALREADY_REACTED');
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

revoke execute on function public.send_letter(uuid, text) from public, anon, authenticated;
revoke execute on function public.send_moderated_letter(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.send_moderated_letter(uuid, uuid, text) to service_role;

notify pgrst, 'reload schema';
