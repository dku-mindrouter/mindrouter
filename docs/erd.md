# Mindrouter ERD

```mermaid
erDiagram
  PROFILES ||--o{ STARS : creates
  EMOTION_TAGS ||--o{ STARS : primary_tag
  STARS ||--o{ STAR_SECONDARY_TAGS : has
  EMOTION_TAGS ||--o{ STAR_SECONDARY_TAGS : secondary_tag
  STARS ||--o{ REACTIONS : receives
  REACTION_TYPES ||--o{ REACTIONS : type
  PROFILES ||--o{ REACTIONS : sends
  PROFILES ||--o{ NUDGES : receives
  PROFILES ||--o{ DAILY_LOGS : owns
  PROFILES ||--o{ BLOCKS : blocks
  PROFILES ||--o{ REPORTS : files
  STARS ||--o{ REPORTS : target
  PROFILES ||--o{ STAR_VIEWS : views
  STARS ||--o{ STAR_VIEWS : viewed
```

## Core Tables

- `profiles`: public profile and device metadata
- `emotion_tags`: fixed emotion taxonomy for MVP
- `stars`: daily emotional posts
- `star_secondary_tags`: optional supporting emotions
- `reaction_types`: predefined reactions only
- `reactions`: one safe reaction per sender per star
- `nudges`: rules-based cards and reaction receipt items
- `daily_logs`: streak and activity tracking
- `blocks`: user-level safety exclusion
- `reports`: content safety reports
- `star_views`: supports excluding already-seen stars from the feed

