# Backend Handoff

## Frontend Status

Frontend work is now based on `feature/frontend-app-shell`, which was branched from the backend-aligned `features/auth-emotion-stellation` base.

Current frontend baseline:

- App boots successfully
- `flutter analyze` passes
- `flutter test` passes
- `flutter build apk --debug` passes

This baseline only stabilizes the frontend shell. It does not yet connect real Supabase initialization or the auth entry flow.

## What Backend Does Not Need To Worry About

- No frontend changes were made inside `supabase/`
- No migration files were edited
- No API contract files were rewritten
- Current work is limited to app shell, test, and analyzer stabilization

## Backend Items Needed For Frontend Integration

### Project Setup

- Supabase project URL
- Supabase anon key
- Confirmation that anonymous auth is enabled

### Required RPC Functions

Frontend expects these RPCs to exist and match [api-contract.md](/Users/yuchan/Desktop/git/mindrouter/docs/api-contract.md):

- `create_star`
- `get_today_status`
- `get_constellation_feed`
- `get_star_detail`
- `send_reaction`

### Required Tables Used Directly By Frontend

- `profiles`
- `emotion_tags`
- `reaction_types`
- `star_views`

## Concrete Expectations By Frontend

### Auth

Used from [lib/pages/auth/data/supabase_auth_data_source.dart](/Users/yuchan/Desktop/git/mindrouter/lib/pages/auth/data/supabase_auth_data_source.dart)

- `auth.signInAnonymously()` must be available
- `profiles` lookup must support:
  - `id`
  - `nickname`
  - `timezone`
  - `is_active`
  - `push_token`
- `profiles` upsert by `id` must work
- `profiles.push_token` update must work

### Emotion

Used from [lib/pages/emotion/data/supabase_emotion_data_source.dart](/Users/yuchan/Desktop/git/mindrouter/lib/pages/emotion/data/supabase_emotion_data_source.dart)

- `emotion_tags` query must return active rows with:
  - `id`
  - `name_ko`
  - `group_name`
  - `priority`
  - `is_active`
- `create_star` RPC must accept:
  - `p_content`
  - `p_tag_ids`
  - `p_time_bucket`
  - `p_visibility_status`
  - `p_emotion_intensity`
  - `p_expires_at`

### Constellation

Used from [lib/pages/constellation/data/supabase_constellation_data_source.dart](/Users/yuchan/Desktop/git/mindrouter/lib/pages/constellation/data/supabase_constellation_data_source.dart)

- `get_constellation_feed` RPC must accept:
  - `p_filter_name`
  - `p_limit`
  - `p_offset`
- `get_star_detail` RPC must accept:
  - `p_star_id`
- `get_today_status` RPC must be callable
- `star_views` upsert must work with:
  - `viewer_user_id`
  - `star_id`
  - `seen_at`

### Reaction

Used from [lib/pages/reaction/data/supabase_reaction_data_source.dart](/Users/yuchan/Desktop/git/mindrouter/lib/pages/reaction/data/supabase_reaction_data_source.dart)

- `reaction_types` query must return active rows with:
  - `id`
  - `code`
  - `label_ko`
  - `icon`
- `send_reaction` RPC must accept:
  - `p_star_id`
  - `p_reaction_type_id`
- `get_today_status` RPC response must include quota fields used by reaction flow

## Must-Confirm Contract Details

- RPC parameter names exactly match [docs/api-contract.md](/Users/yuchan/Desktop/git/mindrouter/docs/api-contract.md)
- Response keys are unchanged from the contract document
- Latest migrations are fully applied
- RLS allows the expected reads and writes for authenticated anonymous users
- Seed data exists for `emotion_tags` and `reaction_types`

## High-Risk Points To Confirm Early

- Whether anonymous auth is truly the intended login mode
- Whether `profiles.timezone` is always populated before calling quota and today-status logic
- Whether `star_views` should be directly written by frontend or should later move behind an RPC
- Whether any RPC response shape is still in flux

## Message Template For Backend Handoff

```text
프론트는 feature/frontend-app-shell 기준으로 부팅 가능한 상태까지 맞췄습니다.
현재는 앱 쉘만 안정화했고, supabase 마이그레이션이나 계약 파일은 건드리지 않았습니다.

실연동 들어가기 전에 아래 항목 확인 부탁드립니다.

- Supabase URL / anon key 전달
- anonymous auth 사용 가능 여부
- RPC: create_star, get_today_status, get_constellation_feed, get_star_detail, send_reaction
- 테이블: profiles, emotion_tags, reaction_types, star_views
- profiles 컬럼(id, nickname, timezone, is_active, push_token) 보장
- emotion_tags / reaction_types 시드 데이터 존재 여부
- star_views upsert 및 관련 RLS 허용 여부
- docs/api-contract.md 기준 응답 키와 시그니처 동일 여부
- 최신 migration 적용 여부

응답 필드명이나 RPC 시그니처가 바뀔 예정이면 프론트 연동 전에 먼저 공유 부탁드립니다.
```
