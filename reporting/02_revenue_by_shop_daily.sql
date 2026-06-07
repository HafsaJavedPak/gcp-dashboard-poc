-- reporting.revenue_by_shop_daily
-- Primary dashboard metric: completed-order revenue per shop per day.

CREATE OR REPLACE VIEW `emerald-energy-483903-f3.reporting.revenue_by_shop_daily` AS
SELECT
  shop_id,
  DATE(created_at)      AS order_date,
  COUNT(*)              AS work_orders,
  SUM(total_cost)       AS revenue,
  AVG(labor_hours)      AS avg_labor_hours
FROM `emerald-energy-483903-f3.reporting.stg_work_orders`
WHERE status = 'completed'
GROUP BY shop_id, order_date;
