insert into public.reaction_types (id, code, label_ko, icon, is_active)
values
  (5, 'WARM_COFFEE', '커피 보내기', 'coffee', true),
  (6, 'LETTER', '편지 보내기', 'letter', true)
on conflict (code) do update
set
  label_ko = excluded.label_ko,
  icon = excluded.icon,
  is_active = excluded.is_active;

select setval(
  pg_get_serial_sequence('public.reaction_types', 'id'),
  (select coalesce(max(id), 1) from public.reaction_types),
  true
);
