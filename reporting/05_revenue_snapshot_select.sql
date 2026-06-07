-- This SELECT is the body of the scheduled query (see README step C).
-- The scheduled query writes its result into:
--   reporting.revenue_by_shop_daily_snapshot   (WRITE_TRUNCATE, every 24h)
-- Materializing the daily aggregate means Metabase reads a small physical
-- table instead of re-scanning raw on every dashboard load -> faster + cheaper.

SELECT * FROM `emerald-energy-483903-f3.reporting.revenue_by_shop_daily`;
