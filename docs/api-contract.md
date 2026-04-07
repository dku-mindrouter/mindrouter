# Mindrouter API Contract

## Auth

### Supabase Auth

- `signInWithGoogle()`
- `signInWithApple()`
- `signOut()`

## RPC / Query Surface

### `create_star`

- Purpose: create today's star and update the user's daily log
- Input:
  - `primary_tag_id bigint`
  - `secondary_tag_ids bigint[]`
  - `content text`
  - `visibility_status text`
  - `emotion_intensity int`
- Output:
  - inserted star row

### `get_constellation_feed`

- Purpose: return ranked public stars for the current user
- Input:
  - `filter_name text`
  - `page_limit int`
  - `page_offset int`
- Output:
  - `star_id`
  - `content`
  - `primary_tag_name`
  - `time_bucket`
  - `reaction_count`
  - `relation_score`
  - `created_at`

### `send_reaction`

- Purpose: send one predefined reaction, update counts, and create a safe nudge for the star owner
- Input:
  - `star_id uuid`
  - `reaction_type_id bigint`
- Output:
  - inserted reaction row

### `nudge_preview`

- Purpose: generate rules-based copy before star creation or on the nudge screen
- Input:
  - `primary_tag_name text`
  - `time_bucket text`
- Output:
  - `title`
  - `body`
  - `risk_flag`

## Client Screens

- `/login`
- `/today`
- `/constellation`
- `/constellation/star/:id`
- `/nudges`
- `/profile`

