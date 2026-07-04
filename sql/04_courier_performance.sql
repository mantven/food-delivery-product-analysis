-- Топ-10 курьеров по количеству доставок
SELECT
    courier_id,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY courier_id
ORDER BY delivered_orders DESC
LIMIT 10;

-- Самые быстрые курьеры
SELECT
    courier_id,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY courier_id
HAVING COUNT(order_id) >= 20
ORDER BY avg_delivery_time_minutes ASC
LIMIT 10;

-- Самые медленные курьеры
SELECT
    courier_id,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY courier_id
HAVING COUNT(order_id) >= 20
ORDER BY avg_delivery_time_minutes DESC
LIMIT 10;

-- Общая статистика по курьерам
WITH courier_stats AS (
    SELECT
        courier_id,
        COUNT(order_id) AS delivered_orders,
        AVG(delivery_time_minutes) AS avg_delivery_time_minutes
    FROM delivery_times_clean
    GROUP BY courier_id
)

SELECT
    COUNT(*) AS couriers_count,
    ROUND(AVG(delivered_orders), 2) AS avg_orders_per_courier,
    MIN(delivered_orders) AS min_orders_per_courier,
    MAX(delivered_orders) AS max_orders_per_courier,
    ROUND(AVG(avg_delivery_time_minutes), 2) AS avg_courier_delivery_time
FROM courier_stats;