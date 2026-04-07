# Contributing

## Branch Model

- `main`: production-ready history only
- `dev`: integration branch for the current MVP
- `feature/*`: short-lived work branches created from `dev`

## Two-Person Split

### Frontend owner

- [apps/mobile](/Users/yuchan/Desktop/git/mindrouter/apps/mobile) UI, routing, Riverpod state, Dio integration, local notifications

### Backend owner

- [supabase](/Users/yuchan/Desktop/git/mindrouter/supabase) migrations, RLS, RPC functions, Edge Functions, feed routing, safety rules

### Shared decisions

- [docs/prd.md](/Users/yuchan/Desktop/git/mindrouter/docs/prd.md)
- [docs/api-contract.md](/Users/yuchan/Desktop/git/mindrouter/docs/api-contract.md)
- [docs/routing-rules.md](/Users/yuchan/Desktop/git/mindrouter/docs/routing-rules.md)

## Pull Request Rules

- Start every branch from `dev`
- Keep frontend and backend scope separated unless the change is inherently cross-cutting
- Use squash merge
- Include manual QA notes in the PR template
- Do not change routing weights, emotion tags, or reaction labels without updating the matching docs

## Suggested First Branches

- `feature/mobile-shell-and-theme`
- `feature/mobile-auth-and-today-flow`
- `feature/backend-initial-schema`
- `feature/backend-feed-and-reaction-rpc`

