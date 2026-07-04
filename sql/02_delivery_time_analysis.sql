DROP TABLE IF EXISTS delivery_times;

CREATE TABLE delivery_times AS
SELECT
    a.order_id,
    a.courier_id,

    datetime(
        '20' || substr(a.time, 7, 2) || '-' ||
        substr(a.time, 4, 2) || '-' ||
        substr(a.time, 1, 2) || ' ' ||
        substr(a.time, 10, 5) || ':00'
    ) AS accept_time,

    datetime(
        '20' || substr(d.time, 7, 2) || '-' ||
        substr(d.time, 4, 2) || '-' ||
        substr(d.time, 1, 2) || ' ' ||
        substr(d.time, 10, 5) || ':00'
    ) AS deliver_time,

    ROUND(
        (
            julianday(
                datetime(
                    '20' || substr(d.time, 7, 2) || '-' ||
                    substr(d.time, 4, 2) || '-' ||
                    substr(d.time, 1, 2) || ' ' ||
                    substr(d.time, 10, 5) || ':00'
                )
            )
            -
            julianday(
                datetime(
                    '20' || substr(a.time, 7, 2) || '-' ||
                    substr(a.time, 4, 2) || '-' ||
                    substr(a.time, 1, 2) || ' ' ||
                    substr(a.time, 10, 5) || ':00'
                )
            )
        ) * 24 * 60,
        2
    ) AS delivery_time_minutes

FROM courier_actions a
JOIN courier_actions d
    ON a.order_id = d.order_id
   AND a.courier_id = d.courier_id
WHERE a.action = 'accept_order'
  AND d.action = 'deliver_order';

DROP TABLE IF EXISTS delivery_times_clean;

CREATE TABLE delivery_times_clean AS
SELECT *
FROM delivery_times
WHERE delivery_time_minutes > 0;

-- Среднее время доставки
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes,
    ROUND(MIN(delivery_time_minutes), 2) AS min_delivery_time_minutes,
    ROUND(MAX(delivery_time_minutes), 2) AS max_delivery_time_minutes
FROM delivery_times_clean;

-- Распределение доставок по времени
SELECT
    CASE
        WHEN delivery_time_minutes <= 15 THEN '0-15 min'
        WHEN delivery_time_minutes <= 30 THEN '16-30 min'
        WHEN delivery_time_minutes <= 45 THEN '31-45 min'
        WHEN delivery_time_minutes <= 60 THEN '46-60 min'
        ELSE '60+ min'
    END AS delivery_time_group,
    COUNT(*) AS orders_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM delivery_times), 2) AS orders_percent
FROM delivery_times_clean
GROUP BY delivery_time_group
ORDER BY 
    CASE delivery_time_group
        WHEN '0-15 min' THEN 1
        WHEN '16-30 min' THEN 2
        WHEN '31-45 min' THEN 3
        WHEN '46-60 min' THEN 4
        WHEN '60+ min' THEN 5
    END;


-- Самые долгие доставки
SELECT
    order_id,
    courier_id,
    accept_time,
    deliver_time,
    delivery_time_minutes
FROM delivery_times_clean
ORDER BY delivery_time_minutes DESC
LIMIT 20;

-- Среднее время доставки по курьерам
SELECT
    courier_id,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM delivery_times_clean
GROUP BY courier_id
HAVING COUNT(order_id) >= 20
ORDER BY avg_delivery_time_minutes ASC
LIMIT 20;