alter table public.profiles enable row level security;
alter table public.stars enable row level security;
alter table public.reactions enable row level security;
alter table public.reports enable row level security;
alter table public.blocks enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists stars_select_visible_or_own on public.stars;
create policy stars_select_visible_or_own
on public.stars
for select
to authenticated
using (
  (
    user_id = auth.uid()
  )
  or
  (
    visibility_status = 'public'
    and is_deleted = false
    and (expires_at is null or expires_at > now())
    and not exists (
      select 1
      from public.blocks b
      where
        (b.blocker_user_id = auth.uid() and b.blocked_user_id = stars.user_id)
        or (b.blocker_user_id = stars.user_id and b.blocked_user_id = auth.uid())
    )
  )
);

drop policy if exists stars_insert_own on public.stars;
create policy stars_insert_own
on public.stars
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists reactions_select_own on public.reactions;
create policy reactions_select_own
on public.reactions
for select
to authenticated
using (sender_user_id = auth.uid());

drop policy if exists reactions_insert_own on public.reactions;
create policy reactions_insert_own
on public.reactions
for insert
to authenticated
with check (sender_user_id = auth.uid());

drop policy if exists reports_select_own on public.reports;
create policy reports_select_own
on public.reports
for select
to authenticated
using (reporter_user_id = auth.uid());

drop policy if exists reports_insert_own on public.reports;
create policy reports_insert_own
on public.reports
for insert
to authenticated
with check (reporter_user_id = auth.uid());

drop policy if exists blocks_select_own on public.blocks;
create policy blocks_select_own
on public.blocks
for select
to authenticated
using (blocker_user_id = auth.uid());

drop policy if exists blocks_insert_own on public.blocks;
create policy blocks_insert_own
on public.blocks
for insert
to authenticated
with check (blocker_user_id = auth.uid());

create or replace function public.trg_reactions_enforce_constraints()
returns trigger
language plpgsql
as $$
declare
  v_owner_user_id uuid;
  v_sender_timezone varchar(64);
  v_today_count int;
begin
  select s.user_id
  into v_owner_user_id
  from public.stars s
  where s.id = new.star_id and s.is_deleted = false;

  if v_owner_user_id is null then
    perform public.raise_app_error('STAR_NOT_FOUND');
  end if;

  if new.sender_user_id = v_owner_user_id then
    perform public.raise_app_error('SELF_REACTION_NOT_ALLOWED');
  end if;

  if exists (
    select 1
    from public.blocks b
    where
      (b.blocker_user_id = new.sender_user_id and b.blocked_user_id = v_owner_user_id)
      or (b.blocker_user_id = v_owner_user_id and b.blocked_user_id = new.sender_user_id)
  ) then
    perform public.raise_app_error('BLOCKED_RELATIONSHIP');
  end if;

  if not exists (
    select 1
    from public.reaction_types rt
    where rt.id = new.reaction_type_id and rt.is_active = true
  ) then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if new.created_local_date is null then
    select p.timezone
    into v_sender_timezone
    from public.profiles p
    where p.id = new.sender_user_id and p.is_active = true;

    if v_sender_timezone is null then
      perform public.raise_app_error('INVALID_ARGUMENT');
    end if;

    new.created_local_date := (now() at time zone v_sender_timezone)::date;
  end if;

  select count(*)
  into v_today_count
  from public.reactions r
  where
    r.sender_user_id = new.sender_user_id
    and r.created_local_date = new.created_local_date;

  if v_today_count >= 20 then
    perform public.raise_app_error('DAILY_REACTION_LIMIT_EXCEEDED');
  end if;

  return new;
end;
$$;

drop trigger if exists trg_reactions_enforce_constraints on public.reactions;
create trigger trg_reactions_enforce_constraints
before insert on public.reactions
for each row
execute function public.trg_reactions_enforce_constraints();

create index if not exists idx_stars_created_at_time_bucket
on public.stars (created_at desc, time_bucket);

create index if not exists idx_star_emotion_maps_tag_id_star_id
on public.star_emotion_maps (tag_id, star_id);

create index if not exists idx_reactions_star_id_created_at
on public.reactions (star_id, created_at desc);
