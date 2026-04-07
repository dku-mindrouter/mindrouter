# Mindrouter Routing Rules

## Feed Ranking

The feed stays rules-based during MVP.

| Rule | Score |
| --- | ---: |
| same primary emotion | +40 |
| same emotion group | +20 |
| same time bucket | +15 |
| created within last 24 hours | +10 |
| not yet seen | +15 |
| too many reactions | -20 |
| own star | -30 |
| blocked or deleted | exclude |

## Feed Exclusions

- blocked users in either direction
- deleted stars
- private stars
- already-seen stars when alternatives exist

## Safety Rules

- free-text chat is not supported
- star content is capped at 80 characters
- duplicate reactions to the same star by one sender are blocked
- self-reactions are blocked
- reaction daily cap is enforced in the RPC layer
- crisis-risk or self-harm phrases should be moderated before general feed exposure

