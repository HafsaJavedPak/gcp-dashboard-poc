# Project 2 — Dashboard Migration POC

Builds on Project 1's BigQuery data. Demonstrates migrating a BI dashboard
from a "logic-in-the-BI-tool" setup (Looker Studio on raw data) to a
"logic-in-the-warehouse" setup (BigQuery views + scheduled snapshot, read by
self-hosted Metabase) — and proves the numbers match.

## What gets created (all new, no overlap with Project 1)

| Object | Type | Naming |
|---|---|---|
| `reporting` | BigQuery dataset (US) | new layer alongside raw/staging/marts |
| `reporting.stg_work_orders` | view | cleaned/deduped over raw |
| `reporting.revenue_by_shop_daily` | view | primary metric |
| `reporting.service_type_mix` | view | breakdown tile |
| `reporting.status_breakdown` | view | status funnel tile |
| `reporting.revenue_by_shop_daily_snapshot` | table | materialized by scheduled query |
| `reporting-daily-revenue-refresh` | scheduled query | every 24h |
| `bi-metabase` | service account | read-only BI identity |

## Run order

- **A.** Enable the Data Transfer API.
- **B.** Create the `reporting` dataset and the four views (in numeric order).
- **C.** Create + run the scheduled query (materialize the snapshot now too).
- **D.** Create the `bi-metabase` service account + key.
- **E.** `cp metabase/.env.example metabase/.env`, edit it, `docker compose up -d`.
- **Looker Studio:** build the "legacy" dashboard in the UI (no CLI exists).
- **Validate:** run `docs/VALIDATION.md` section 2; expect `mismatched_rows = 0`.

See the chat message for the exact bash for each step.

## Folder map

```
gcp-dashboard-poc/
├── reporting/        # BigQuery view DDL + the snapshot SELECT
├── metabase/         # docker-compose + .env.example
└── docs/VALIDATION.md
```
