-- reporting.stg_work_orders
-- The "pushed-down" cleaning logic: instead of the BI tool cleaning data,
-- the warehouse does it. Self-contained (reads raw directly) so this POC works
-- whether or not the dbt models from Project 1 have been run.
-- Run order: this view FIRST (the others depend on it).

CREATE OR REPLACE VIEW `emerald-energy-483903-f3.reporting.stg_work_orders` AS
WITH deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY work_order_id ORDER BY updated_at DESC
    ) AS rn
  FROM `emerald-energy-483903-f3.raw.work_orders`
)
SELECT
  work_order_id,
  shop_id,
  customer_id,
  INITCAP(vehicle_make) AS vehicle_make,
  vehicle_model,
  vehicle_year,
  service_type,
  LOWER(status)         AS status,
  labor_hours,
  parts_cost,
  labor_cost,
  total_cost,
  technician_id,
  created_at,
  updated_at
FROM deduped
WHERE rn = 1
  AND total_cost >= 0;
