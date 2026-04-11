create table if not exists public.star_views (
  id bigserial primary key,
  viewer_user_id uuid not null references public.profiles(id) on delete cascade,
  star_id uuid not null references public.stars(id) on delete cascade,
  seen_at timestamptz not null default now(),
  unique (viewer_user_id, star_id)
);

alter table public.star_views enable row level security;

drop policy if exists star_views_select_own on public.star_views;
create policy star_views_select_own
on public.star_views
for select
to authenticated
using (viewer_user_id = auth.uid());

drop policy if exists star_views_insert_own on public.star_views;
create policy star_views_insert_own
on public.star_views
for insert
to authenticated
with check (viewer_user_id = auth.uid());

drop policy if exists star_views_update_own on public.star_views;
create policy star_views_update_own
on public.star_views
for update
to authenticated
using (viewer_user_id = auth.uid())
with check (viewer_user_id = auth.uid());

create index if not exists idx_star_views_star_id_seen_at
on public.star_views (star_id, seen_at desc);
