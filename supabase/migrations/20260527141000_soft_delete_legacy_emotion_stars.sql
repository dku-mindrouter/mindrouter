update public.stars s
set is_deleted = true
where s.is_deleted = false
  and exists (
    select 1
    from public.star_emotion_maps sem
    join public.emotion_tags et on et.id = sem.tag_id
    where sem.star_id = s.id
      and (
        et.is_active = false
        or et.id in (7, 8, 9, 10)
      )
  );
