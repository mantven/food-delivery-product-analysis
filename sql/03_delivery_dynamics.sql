-- Количество доставок по дням
SELECT
    date(deliver_time) AS delivery_date,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY date(deliver_time)
ORDER BY delivery_date;

-- Количество доставок по часам
SELECT
    strftime('%H', deliver_time) AS delivery_hour,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY strftime('%H', deliver_time)
ORDER BY delivery_hour;

-- Самые загруженные часы
SELECT
    strftime('%H', deliver_time) AS delivery_hour,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY strftime('%H', deliver_time)
ORDER BY delivered_orders DESC
LIMIT 10;

-- Часы с самым долгим средним временем доставки
SELECT
    strftime('%H', deliver_time) AS delivery_hour,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY strftime('%H', deliver_time)
HAVING COUNT(order_id) >= 100
ORDER BY avg_delivery_time_minutes DESC;