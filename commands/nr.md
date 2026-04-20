# New Relic — Query, Debug, and Inspect

Use this skill to query New Relic via the NerdGraph API and REST v2 API:
NRQL queries, error investigation, alert inspection, dashboard data, APM metrics.

## Credentials

Read from environment variables. Ensure they are loaded before running commands (e.g. from a `.env` file, your shell profile, or a secrets manager):

- `NEW_RELIC_API_KEY` — User API key
- `NEW_RELIC_ACCOUNT_ID` — Your New Relic account ID
- `NEW_RELIC_APP_NAME` — The APM application name (as it appears in New Relic)

## Execute a NRQL query

```bash
curl -s https://api.newrelic.com/graphql \
  -H "Content-Type: application/json" \
  -H "API-Key: $NEW_RELIC_API_KEY" \
  -d "{\"query\": \"{ actor { account(id: $NEW_RELIC_ACCOUNT_ID) { nrql(query: \\\"NRQL_HERE\\\") { results } } } }\"}" \
  | jq '.data.actor.account.nrql.results'
```

## Common NRQL patterns (replace `$APP_NAME` with the value of `NEW_RELIC_APP_NAME`)

### Error rate by endpoint (last 1 hour)
```nrql
SELECT percentage(count(*), WHERE error IS true) FROM Transaction
WHERE appName = '$APP_NAME' FACET request.uri SINCE 1 hour ago LIMIT 20
```

### p95 / p99 latency by endpoint
```nrql
SELECT percentile(duration, 95, 99) FROM Transaction
WHERE appName = '$APP_NAME' FACET request.uri SINCE 1 hour ago LIMIT 20
```

### Recent errors with context
```nrql
SELECT message, request.uri FROM Log
WHERE level = 'error' SINCE 15 minutes ago LIMIT 50
```

### Structured log events (last 24h)
```nrql
SELECT *
FROM Log WHERE outcome IS NOT NULL SINCE 24 hours ago LIMIT 50
```

### Checkout / payment sessions — success vs failure
```nrql
SELECT count(*) FROM Log WHERE message LIKE '%checkout%'
FACET outcome SINCE 24 hours ago
```

### Webhook events — volume and errors
```nrql
SELECT count(*) AS total,
  filter(count(*), WHERE httpResponseCode != 200) AS errors
FROM Transaction WHERE request.uri = '/api/webhook'
AND appName = '$APP_NAME' SINCE 24 hours ago TIMESERIES 1 hour
```

### Failures by tenant / user (last 7 days)
```nrql
SELECT count(*) FROM Log WHERE level = 'error'
FACET tenant_id SINCE 7 days ago
```

### Key domain events (last 7 days)
```nrql
SELECT count(*) FROM Log
WHERE event IS NOT NULL
FACET event SINCE 7 days ago
```

### Specific entity activity
```nrql
SELECT timestamp, level, message, outcome, event FROM Log
WHERE tenant_id = 'ENTITY_ID' SINCE 24 hours ago LIMIT 100
```

### Slowest transactions
```nrql
SELECT percentile(duration, 99) FROM Transaction
WHERE appName = '$APP_NAME' FACET request.uri SINCE 1 hour ago LIMIT 10
```

### Active grace periods (log-derived)
```nrql
SELECT count(*) FROM Log WHERE message LIKE '%grace_period%'
FACET outcome SINCE 7 days ago
```

## List alert policies
```bash
curl -s https://api.newrelic.com/v2/alerts_policies.json \
  -H "X-Api-Key: $NEW_RELIC_API_KEY" | jq '.policies[] | {id, name}'
```

## List NRQL conditions for a policy
```bash
curl -s "https://api.newrelic.com/v2/alerts_nrql_conditions.json?policy_id=POLICY_ID" \
  -H "X-Api-Key: $NEW_RELIC_API_KEY" | jq '.nrql_conditions[] | {id, name, enabled}'
```

## List dashboards
```bash
curl -s https://api.newrelic.com/graphql \
  -H "Content-Type: application/json" \
  -H "API-Key: $NEW_RELIC_API_KEY" \
  -d '{"query":"{ actor { entitySearch(query: \"type = DASHBOARD\") { results { entities { name guid } } } } }"}' \
  | jq '.data.actor.entitySearch.results.entities[] | {name, guid}'
```

## Workflow

When the user asks a natural-language question:
1. Translate to NRQL using the patterns above
2. Execute via NerdGraph with `curl` + `jq`
3. Return raw results + plain-English summary

When the user asks about alerts or policies:
1. Use REST v2 endpoints above
2. Summarise what exists, flag anything misconfigured

When the user asks to create or modify a resource:
1. Confirm the change with the user before executing
2. Use NerdGraph mutations or REST v2 as appropriate
