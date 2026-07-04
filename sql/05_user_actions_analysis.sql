SELECT *
FROM user_actions
LIMIT 10;

SELECT COUNT(*) AS total_rows
FROM user_actions;

SELECT
    action,
    COUNT(*) AS actions_count
FROM user_actions
GROUP BY action
ORDER BY actions_count DESC;

-- кол-во пользоват и заказов
SELECT
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT order_id) AS unique_orders
FROM user_actions;

-- кол-во созд. и отмен. заказов
SELECT
    COUNT(DISTINCT CASE WHEN action = 'create_order' THEN order_id END) AS created_orders,
    COUNT(DISTINCT CASE WHEN action = 'cancel_order' THEN order_id END) AS canceled_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN action = 'cancel_order' THEN order_id END) * 100.0 /
        COUNT(DISTINCT CASE WHEN action = 'create_order' THEN order_id END),
        2
    ) AS cancel_rate_percent
FROM user_actions;

--успешные заказы и пользователей
SELECT
    COUNT(DISTINCT order_id) AS successful_orders,
    COUNT(DISTINCT user_id) AS users_with_successful_orders
FROM successful_orders;

--Repeat order rate
WITH user_order_counts AS (
    SELECT
        user_id,
        COUNT(DISTINCT order_id) AS orders_count
    FROM successful_orders
    GROUP BY user_id
)

SELECT
    COUNT(*) AS users_with_successful_orders,
    COUNT(CASE WHEN orders_count >= 2 THEN user_id END) AS users_with_repeat_orders,
    ROUND(
        COUNT(CASE WHEN orders_count >= 2 THEN user_id END) * 100.0 / COUNT(*),
        2
    ) AS repeat_order_rate_percent
FROM user_order_counts;

--Распределение пользователей по количеству заказов

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


--Заказы по дням
SELECT
    date(order_time) AS order_date,
    COUNT(DISTINCT order_id) AS successful_orders,
    COUNT(DISTINCT user_id) AS active_users
FROM successful_orders
GROUP BY date(order_time)
ORDER BY order_date;