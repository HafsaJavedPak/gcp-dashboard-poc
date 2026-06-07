# Dashboard Migration — Validation

**Scope:** prove that the migrated reporting layer (BigQuery views + scheduled
snapshot, consumed by Metabase) returns the **same numbers** as the legacy
Looker Studio dashboard built directly on `raw.work_orders`.

**Headline metric under test:** completed-order revenue per shop per day.

---

## 1. What changed in the migration

| | Legacy (before) | Migrated (after) |
|---|---|---|
| Where the logic lives | Inside Looker Studio (aggregations, filters, calculated fields) | In BigQuery SQL views (`reporting.*`) |
| Data the BI tool touches | `raw.work_orders` directly | Pre-modeled `reporting` views + snapshot table |
| Refresh of heavy aggregate | Recomputed on every dashboard load | Materialized daily by a scheduled query |
| BI tool | Looker Studio | Self-hosted Metabase (Docker) |

The migration **moves transformation logic out of the BI layer and down into the
warehouse**, so any tool (Looker Studio, Metabase, a notebook) sees one
consistent definition of "revenue."

---

## 2. Validation method

Equivalence is proven by re-deriving the metric **independently** from `raw`
and diffing it against the migrated view. If the two disagree on any
(shop, day), the test fails. Run in the BigQuery console or with `bq query`.

```sql
WITH migrated AS (
  SELECT shop_id, order_date, work_orders, revenue
  FROM `emerald-energy-483903-f3.reporting.revenue_by_shop_daily`
),
independent AS (             -- re-implements the agreed spec straight from raw
  SELECT
    shop_id,
    DATE(created_at) AS order_date,
    COUNT(*)         AS work_orders,
    SUM(total_cost)  AS revenue
  FROM (
    SELECT *, ROW_NUMBER() OVER (
      PARTITION BY work_order_id ORDER BY updated_at DESC) AS rn
    FROM `emerald-energy-483903-f3.raw.work_orders`
  )
  WHERE rn = 1 AND LOWER(status) = 'completed' AND total_cost >= 0
  GROUP BY shop_id, order_date
)
SELECT COUNT(*) AS mismatched_rows
FROM migrated m
FULL OUTER JOIN independent i USING (shop_id, order_date)
WHERE m.work_orders IS DISTINCT FROM i.work_orders
   OR ABS(COALESCE(m.revenue, 0) - COALESCE(i.revenue, 0)) > 0.01;
```

**Pass condition:** `mismatched_rows = 0`.

---

## 3. Snapshot freshness check

The materialized snapshot must equal the live view at refresh time:

```sql
SELECT
  (SELECT COUNT(*) FROM `emerald-energy-483903-f3.reporting.revenue_by_shop_daily`)            AS view_rows,
  (SELECT COUNT(*) FROM `emerald-energy-483903-f3.reporting.revenue_by_shop_daily_snapshot`)   AS snapshot_rows;
```

`view_rows = snapshot_rows` immediately after a scheduled-query run. A growing
gap over the day is expected (new orders land in the view; the snapshot updates
on its 24h cadence) and is itself a thing the dashboard can surface.

---

## 4. Sign-off

| Check | Expected | Result | Date | By |
|---|---|---|---|---|
| Row-level equivalence (sec. 2) | `mismatched_rows = 0` | | | |
| Snapshot freshness (sec. 3) | equal right after refresh | | | |
| Spot-check: top shop by revenue matches in both dashboards | identical | | | |

---

## 5. Known limitations / production hardening

- The `reporting` views re-implement the cleaning logic rather than building on
  the dbt `marts` models. In production, point reporting at the dbt outputs so
  there is a single source of truth instead of two copies of the logic.
- Metabase reads via a service-account **key file** here. In production prefer
  workload identity (no long-lived keys) and scope the BI account to the
  `reporting` dataset only (or use BigQuery authorized views) rather than a
  project-wide read role.
