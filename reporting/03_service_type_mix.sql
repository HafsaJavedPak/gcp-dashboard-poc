-- reporting.service_type_mix
-- Which service lines drive revenue (a dashboard breakdown tile).

CREATE OR REPLACE VIEW `emerald-energy-483903-f3.reporting.service_type_mix` AS
SELECT
  service_type,
  COUNT(*)        AS work_orders,
  SUM(total_cost) AS revenue,
  AVG(total_cost) AS avg_ticket
FROM `emerald-energy-483903-f3.reporting.stg_work_orders`
WHERE status = 'completed'
GROUP BY service_type
ORDER BY revenue DESC;
