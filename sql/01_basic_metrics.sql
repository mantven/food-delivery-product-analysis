-- Просмотр данных
SELECT *
FROM courier_actions
LIMIT 10;


-- Количество строк
SELECT COUNT(*) AS total_rows
FROM courier_actions;


-- Типы действий
SELECT 
    action,
    COUNT(*) AS actions_count
FROM courier_actions
GROUP BY action;


-- Количество заказов и курьеров
SELECT 
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT courier_id) AS unique_couriers
FROM courier_actions;


-- Принятые и доставленные заказы и delivery rate
SELECT
    COUNT(DISTINCT CASE WHEN action = 'accept_order' THEN order_id END) AS accepted_orders,
    COUNT(DISTINCT CASE WHEN action = 'deliver_order' THEN order_id END) AS delivered_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN action = 'deliver_order' THEN order_id END) * 100.0 /
        COUNT(DISTINCT CASE WHEN action = 'accept_order' THEN order_id END),
        2
    ) AS delivery_rate_percent
FROM courier_actions;


-- Кол-во недоставленных заказов
SELECT COUNT(*) AS not_delivered_orders
FROM (
    SELECT DISTINCT order_id
    FROM courier_actions
    WHERE action = 'accept_order'
      AND order_id NOT IN (
          SELECT DISTINCT order_id
          FROM courier_actions
          WHERE action = 'deliver_order'
      )
);


-- Топ курьеров
SELECT
    courier_id,
    COUNT(DISTINCT order_id) AS delivered_orders
FROM courier_actions
WHERE action = 'deliver_order'
GROUP BY courier_id
ORDER BY delivered_orders DESC
LIMIT 10;

-- Пользователи по количеству заказов
WITH user_order_counts AS (
    SELECT
        user_id,
        COUNT(DISTINCT order_id) AS orders_count
    FROM successful_orders
    GROUP BY user_id
)

SELECT
    orders_count,
    COUNT(user_id) AS users_count
FROM user_order_counts
GROUP BY orders_count
ORDER BY orders_count;


-- Успешные заказы по дням
SELECT
    date(order_time) AS order_date,
    COUNT(DISTINCT order_id) AS successful_orders,
    COUNT(DISTINCT user_id) AS active_users
FROM successful_orders
GROUP BY date(order_time)
ORDER BY order_date;