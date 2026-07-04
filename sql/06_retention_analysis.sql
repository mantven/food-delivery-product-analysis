-- Retention по дням после первого заказа
WITH first_orders AS (
    SELECT
        user_id,
        date(MIN(order_time)) AS cohort_date
    FROM successful_orders
    GROUP BY user_id
),

user_activity AS (
    SELECT DISTINCT
        user_id,
        date(order_time) AS activity_date
    FROM successful_orders
),

retention AS (
    SELECT
        f.cohort_date,
        CAST(julianday(a.activity_date) - julianday(f.cohort_date) AS INTEGER) AS day_number,
        COUNT(DISTINCT a.user_id) AS retained_users
    FROM first_orders f
    JOIN user_activity a
        ON f.user_id = a.user_id
    GROUP BY f.cohort_date, day_number
),

cohort_sizes AS (
    SELECT
        cohort_date,
        COUNT(DISTINCT user_id) AS cohort_users
    FROM first_orders
    GROUP BY cohort_date
)

SELECT
    r.cohort_date,
    r.day_number,
    c.cohort_users,
    r.retained_users,
    ROUND(r.retained_users * 100.0 / c.cohort_users, 2) AS retention_rate_percent
FROM retention r
JOIN cohort_sizes c
    ON r.cohort_date = c.cohort_date
WHERE r.day_number BETWEEN 0 AND 14
ORDER BY r.cohort_date, r.day_number;




--Упрощённая таблица retention по дням
WITH first_orders AS (
    SELECT
        user_id,
        date(MIN(order_time)) AS first_order_date
    FROM successful_orders
    GROUP BY user_id
),

user_activity AS (
    SELECT DISTINCT
        user_id,
        date(order_time) AS activity_date
    FROM successful_orders
),

retention_by_user AS (
    SELECT
        f.user_id,
        CAST(julianday(a.activity_date) - julianday(f.first_order_date) AS INTEGER) AS day_number
    FROM first_orders f
    JOIN user_activity a
        ON f.user_id = a.user_id
),

total_users AS (
    SELECT COUNT(DISTINCT user_id) AS users_count
    FROM first_orders
)

SELECT
    day_number,
    COUNT(DISTINCT user_id) AS retained_users,
    ROUND(
        COUNT(DISTINCT user_id) * 100.0 / (SELECT users_count FROM total_users),
        2
    ) AS retention_rate_percent
FROM retention_by_user
WHERE day_number BETWEEN 0 AND 14
GROUP BY day_number
ORDER BY day_number;