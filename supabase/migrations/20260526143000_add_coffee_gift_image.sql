alter table public.coffee_gift_deliveries
  add column if not exists image_url text;

insert into storage.buckets (id, name, public, file_size_limit)
values ('coffee-gift-images', 'coffee-gift-images', true, 5242880)
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880;

drop policy if exists coffee_gift_images_insert_own on storage.objects;
create policy coffee_gift_images_insert_own
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'coffee-gift-images'
  and name like (auth.uid()::text || '/%')
);

drop policy if exists coffee_gift_images_select_public on storage.objects;
create policy coffee_gift_images_select_public
on storage.objects
for select
to authenticated
using (bucket_id = 'coffee-gift-images');

drop function if exists public.get_received_gifts(int, int);

create or replace function public.get_received_gifts(
  p_limit int default 30,
  p_offset int default 0
)
returns table (
  gift_id uuid,
  star_id uuid,
  star_content varchar(80),
  gift_type varchar(32),
  title varchar(80),
  description varchar(160),
  status varchar(24),
  image_url text,
  created_at timestamptz,
  opened_at timestamptz
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_limit int;
  v_offset int;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  v_limit := greatest(least(coalesce(p_limit, 30), 50), 1);
  v_offset := greatest(coalesce(p_offset, 0), 0);

  return query
  select
    g.id as gift_id,
    g.star_id,
    s.content as star_content,
    g.gift_type,
    g.title,
    g.description,
    g.status,
    g.image_url,
    g.created_at,
    g.opened_at
  from public.coffee_gift_deliveries g
  join public.stars s on s.id = g.star_id
  where g.recipient_user_id = v_user_id
    and g.is_deleted = false
  order by g.created_at desc
  limit v_limit
  offset v_offset;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

drop function if exists public.open_gift(uuid);

create or replace function public.open_gift(
  p_gift_id uuid
)
returns table (
  gift_id uuid,
  star_id uuid,
  star_content varchar(80),
  gift_type varchar(32),
  title varchar(80),
  description varchar(160),
  status varchar(24),
  image_url text,
  created_at timestamptz,
  opened_at timestamptz
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_gift_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if not exists (
    select 1
    from public.coffee_gift_deliveries g
    where g.id = p_gift_id
      and g.recipient_user_id = v_user_id
      and g.is_deleted = false
  ) then
    perform public.raise_app_error('GIFT_NOT_FOUND');
  end if;

  update public.coffee_gift_deliveries
  set opened_at = coalesce(opened_at, now())
  where id = p_gift_id;

  return query
  select
    g.id as gift_id,
    g.star_id,
    s.content as star_content,
    g.gift_type,
    g.title,
    g.description,
    g.status,
    g.image_url,
    g.created_at,
    g.opened_at
  from public.coffee_gift_deliveries g
  join public.stars s on s.id = g.star_id
  where g.id = p_gift_id;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

drop function if exists public.send_reaction(uuid, bigint);
drop function if exists public.send_reaction(uuid, bigint, text);

create or replace function public.send_reaction(
  p_star_id uuid,
  p_reaction_type_id bigint,
  p_gift_image_url text default null
)
returns table (
  reaction_id uuid,
  star_id uuid,
  reaction_count int,
  created_at timestamptz
)
language plpgsql
security definer
as $$
declare
  v_sender_user_id uuid;
  v_sender_timezone varchar(64);
  v_local_date date;
  v_target_owner_id uuid;
  v_today_count int;
  v_reaction_id uuid;
  v_reaction_created_at timestamptz;
  v_reaction_count int;
  v_gift_image_url text := nullif(trim(coalesce(p_gift_image_url, '')), '');
begin
  v_sender_user_id := auth.uid();
  if v_sender_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_star_id is null or p_reaction_type_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select s.user_id
  into v_target_owner_id
  from public.stars s
  where s.id = p_star_id and s.is_deleted = false;

  if v_target_owner_id is null then
    perform public.raise_app_error('STAR_NOT_FOUND');
  end if;

  if v_target_owner_id = v_sender_user_id then
    perform public.raise_app_error('SELF_REACTION_NOT_ALLOWED');
  end if;

  if exists (
    select 1
    from public.blocks b
    where
      (b.blocker_user_id = v_sender_user_id and b.blocked_user_id = v_target_owner_id)
      or (b.blocker_user_id = v_target_owner_id and b.blocked_user_id = v_sender_user_id)
  ) then
    perform public.raise_app_error('BLOCKED_RELATIONSHIP');
  end if;

  if not exists (
    select 1
    from public.reaction_types rt
    where rt.id = p_reaction_type_id and rt.is_active = true
  ) then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if exists (
    select 1
    from public.reactions r
    where r.star_id = p_star_id
      and r.sender_user_id = v_sender_user_id
      and (
        (
          p_reaction_type_id in (5, 6)
          and r.reaction_type_id = p_reaction_type_id
        )
        or (
          p_reaction_type_id not in (5, 6)
          and r.reaction_type_id not in (5, 6)
        )
      )
  ) then
    perform public.raise_app_error('ALREADY_REACTED');
  end if;

  select p.timezone
  into v_sender_timezone
  from public.profiles p
  where p.id = v_sender_user_id and p.is_active = true;

  if v_sender_timezone is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  v_local_date := (now() at time zone v_sender_timezone)::date;

  select count(*)
  into v_today_count
  from public.reactions r
  where r.sender_user_id = v_sender_user_id
    and r.created_local_date = v_local_date;

  if v_today_count >= 20 then
    perform public.raise_app_error('DAILY_REACTION_LIMIT_EXCEEDED');
  end if;

  begin
    insert into public.reactions (
      star_id,
      sender_user_id,
      reaction_type_id,
      created_local_date
    )
    values (
      p_star_id,
      v_sender_user_id,
      p_reaction_type_id,
      v_local_date
    )
    returning id, reactions.created_at into v_reaction_id, v_reaction_created_at;
  exception
    when unique_violation then
      perform public.raise_app_error('ALREADY_REACTED');
  end;

  if p_reaction_type_id = 5 then
    insert into public.coffee_gift_deliveries (
      star_id,
      reaction_id,
      sender_user_id,
      recipient_user_id,
      image_url
    )
    values (
      p_star_id,
      v_reaction_id,
      v_sender_user_id,
      v_target_owner_id,
      v_gift_image_url
    );
  end if;

  update public.stars
  set reaction_count = stars.reaction_count + 1
  where id = p_star_id
  returning stars.reaction_count into v_reaction_count;

  insert into public.daily_logs (user_id, date, reaction_sent_count, created_at, updated_at)
  values (v_sender_user_id, v_local_date, 1, now(), now())
  on conflict (user_id, date)
  do update set
    reaction_sent_count = public.daily_logs.reaction_sent_count + 1,
    updated_at = now();

  return query
  select
    v_reaction_id as reaction_id,
    p_star_id as star_id,
    v_reaction_count as reaction_count,
    v_reaction_created_at as created_at;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

grant execute on function public.get_received_gifts(int, int) to authenticated;
grant execute on function public.open_gift(uuid) to authenticated;
grant execute on function public.send_reaction(uuid, bigint, text) to authenticated;
