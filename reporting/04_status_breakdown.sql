-- reporting.status_breakdown
-- Open vs in_progress vs completed vs cancelled (a status funnel tile).

CREATE OR REPLACE VIEW `emerald-energy-483903-f3.reporting.status_breakdown` AS
SELECT
  status,
  COUNT(*)        AS work_orders,
  SUM(total_cost) AS total_value
FROM `emerald-energy-483903-f3.reporting.stg_work_orders`
GROUP BY status;
