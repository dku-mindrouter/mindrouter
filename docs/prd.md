# Mindrouter MVP PRD

## Product Goal

Deliver one safe emotional support loop:

1. user records today's emotion as a star
2. another user discovers the star in a constellation-style feed
3. the other user sends a predefined reaction
4. the original user receives a nudge or record update

## MVP Scope

### Included

- authentication and basic profile
- emotion selection plus a short sentence
- star creation with a time bucket
- constellation feed and star detail
- predefined reaction sending
- reaction receipt nudges
- profile stats, streak, and 7-day history
- report and block flows

### Excluded

- free-text chat
- AI counseling
- location-based discovery
- heavy gamification
- advanced admin tooling

## Experience Principles

- dark, calm, and low-pressure UI
- no direct messaging between users
- rules-based routing before any ML or AI ranking
- supportive copy that suggests, not commands

## Sprint Breakdown

### Sprint 0

- repo bootstrap
- design tokens and routing skeleton
- initial data model and API contracts
- fixed emotion tags, reactions, and nudge templates

### Sprint 1

- auth and profile
- emotion selection and star creation
- one-star-per-day enforcement
- basic content moderation

### Sprint 2

- constellation feed
- star detail and predefined reactions
- duplicate reaction prevention
- reaction receipt persistence

### Sprint 3

- nudges
- streak and recent history
- empty, loading, and failure states

### Sprint 4

- report and block
- routing tuning
- QA and beta readiness

