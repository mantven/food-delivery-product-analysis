-- распределение курьеров по полу
SELECT
    sex,
    COUNT(DISTINCT courier_id) AS couriers_count,
    ROUND(
        COUNT(DISTINCT courier_id) * 100.0 /
        (SELECT COUNT(DISTINCT courier_id) FROM couriers),
        2
    ) AS couriers_percent
FROM couriers
GROUP BY sex
ORDER BY couriers_count DESC;

-- сопоставление курьеров с доставками
SELECT
    COUNT(DISTINCT dt.courier_id) AS couriers_in_deliveries,
    COUNT(DISTINCT c.courier_id) AS matched_couriers,
    COUNT(DISTINCT CASE WHEN c.courier_id IS NULL THEN dt.courier_id END) AS unmatched_couriers
FROM delivery_times_clean dt
LEFT JOIN couriers c
    ON dt.courier_id = c.courier_id;

SELECT
    COUNT(DISTINCT dt.courier_id) AS unmatched_couriers,
    COUNT(dt.order_id) AS unmatched_orders
FROM delivery_times_clean dt
LEFT JOIN couriers c
    ON dt.courier_id = c.courier_id
WHERE c.courier_id IS NULL;

DROP TABLE IF EXISTS courier_delivery_profile;

CREATE TABLE courier_delivery_profile AS
SELECT
    dt.order_id,
    dt.courier_id,
    dt.accept_time,
    dt.deliver_time,
    dt.delivery_time_minutes,
    c.birth_date,
    c.sex
FROM delivery_times_clean dt
JOIN couriers c
    ON dt.courier_id = c.courier_id
WHERE c.sex IS NOT NULL
  AND c.birth_date IS NOT NULL;

SELECT *
FROM courier_delivery_profile
LIMIT 20;

SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT order_id) AS orders_count,
    COUNT(DISTINCT courier_id) AS couriers_count
FROM courier_delivery_profile;

DROP TABLE IF EXISTS courier_delivery_profile_clean;

CREATE TABLE courier_delivery_profile_clean AS
SELECT
    order_id,
    courier_id,
    accept_time,
    deliver_time,
    delivery_time_minutes,
    birth_date,
    sex,

    date(
        CASE
            WHEN CAST(substr(birth_date, 7, 2) AS INTEGER) <= 22 THEN '20'
            ELSE '19'
        END ||
        substr(birth_date, 7, 2) || '-' ||
        substr(birth_date, 4, 2) || '-' ||
        substr(birth_date, 1, 2)
    ) AS birth_date_parsed,

    CAST(
        (
            julianday('2022-09-08') -
            julianday(
                date(
                    CASE
                        WHEN CAST(substr(birth_date, 7, 2) AS INTEGER) <= 22 THEN '20'
                        ELSE '19'
                    END ||
                    substr(birth_date, 7, 2) || '-' ||
                    substr(birth_date, 4, 2) || '-' ||
                    substr(birth_date, 1, 2)
                )
            )
        ) / 365.25
        AS INTEGER
    ) AS courier_age,

    CASE
        WHEN CAST(
            (
                julianday('2022-09-08') -
                julianday(
                    date(
                        CASE
                            WHEN CAST(substr(birth_date, 7, 2) AS INTEGER) <= 22 THEN '20'
                            ELSE '19'
                        END ||
                        substr(birth_date, 7, 2) || '-' ||
                        substr(birth_date, 4, 2) || '-' ||
                        substr(birth_date, 1, 2)
                    )
                )
            ) / 365.25
            AS INTEGER
        ) < 18 THEN 'under 18'

        WHEN CAST(
            (
                julianday('2022-09-08') -
                julianday(
                    date(
                        CASE
                            WHEN CAST(substr(birth_date, 7, 2) AS INTEGER) <= 22 THEN '20'
                            ELSE '19'
                        END ||
                        substr(birth_date, 7, 2) || '-' ||
                        substr(birth_date, 4, 2) || '-' ||
                        substr(birth_date, 1, 2)
                    )
                )
            ) / 365.25
            AS INTEGER
        ) BETWEEN 18 AND 24 THEN '18-24'

        WHEN CAST(
            (
                julianday('2022-09-08') -
                julianday(
                    date(
                        CASE
                            WHEN CAST(substr(birth_date, 7, 2) AS INTEGER) <= 22 THEN '20'
                            ELSE '19'
                        END ||
                        substr(birth_date, 7, 2) || '-' ||
                        substr(birth_date, 4, 2) || '-' ||
                        substr(birth_date, 1, 2)
                    )
                )
            ) / 365.25
            AS INTEGER
        ) BETWEEN 25 AND 34 THEN '25-34'

        WHEN CAST(
            (
                julianday('2022-09-08') -
                julianday(
                    date(
                        CASE
                            WHEN CAST(substr(birth_date, 7, 2) AS INTEGER) <= 22 THEN '20'
                            ELSE '19'
                        END ||
                        substr(birth_date, 7, 2) || '-' ||
                        substr(birth_date, 4, 2) || '-' ||
                        substr(birth_date, 1, 2)
                    )
                )
            ) / 365.25
            AS INTEGER
        ) BETWEEN 35 AND 44 THEN '35-44'

        ELSE '45+'
    END AS age_group

FROM courier_delivery_profile
WHERE delivery_time_minutes > 0;

SELECT
    COUNT(*) AS rows_count,
    COUNT(DISTINCT order_id) AS orders_count,
    COUNT(DISTINCT courier_id) AS couriers_count,
    MIN(courier_age) AS min_age,
    MAX(courier_age) AS max_age,
    ROUND(AVG(courier_age), 2) AS avg_age
FROM courier_delivery_profile_clean;

SELECT
    sex,
    COUNT(DISTINCT courier_id) AS couriers_count,
    COUNT(order_id) AS delivered_orders
FROM courier_delivery_profile_clean
GROUP BY sex;


--анализ пола и времени доставки
SELECT
    sex,
    COUNT(DISTINCT courier_id) AS active_couriers,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes,
    ROUND(MIN(delivery_time_minutes), 2) AS min_delivery_time_minutes,
    ROUND(MAX(delivery_time_minutes), 2) AS max_delivery_time_minutes
FROM courier_delivery_profile_clean
GROUP BY sex
ORDER BY avg_delivery_time_minutes;

--анализ возраста и времени доставки
SELECT
    age_group,
    COUNT(DISTINCT courier_id) AS active_couriers,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM courier_delivery_profile_clean
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN 'under 18' THEN 1
        WHEN '18-24' THEN 2
        WHEN '25-34' THEN 3
        WHEN '35-44' THEN 4
        WHEN '45+' THEN 5
    END;

--анализ нагрузки по полу
WITH courier_stats AS (
    SELECT
        courier_id,
        sex,
        COUNT(order_id) AS delivered_orders,
        AVG(delivery_time_minutes) AS avg_delivery_time_minutes
    FROM courier_delivery_profile_clean
    GROUP BY courier_id, sex
)

SELECT
    sex,
    COUNT(courier_id) AS couriers_count,
    ROUND(AVG(delivered_orders), 2) AS avg_orders_per_courier,
    MIN(delivered_orders) AS min_orders_per_courier,
    MAX(delivered_orders) AS max_orders_per_courier,
    ROUND(AVG(avg_delivery_time_minutes), 2) AS avg_courier_delivery_time
FROM courier_stats
GROUP BY sex
ORDER BY avg_courier_delivery_time;

--возрастная группа и время доставки
SELECT
    age_group,
    COUNT(DISTINCT courier_id) AS active_couriers,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM courier_delivery_profile_clean
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN 'under 18' THEN 1
        WHEN '18-24' THEN 2
        WHEN '25-34' THEN 3
        WHEN '35-44' THEN 4
        WHEN '45+' THEN 5
    END;

--пол + возраст + время доставки
SELECT
    sex,
    age_group,
    COUNT(DISTINCT courier_id) AS active_couriers,
    COUNT(order_id) AS delivered_orders,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time_minutes
FROM courier_delivery_profile_clean
GROUP BY sex, age_group
HAVING COUNT(order_id) >= 100
ORDER BY
    sex,
    CASE age_group
        WHEN 'under 18' THEN 1
        WHEN '18-24' THEN 2
        WHEN '25-34' THEN 3
        WHEN '35-44' THEN 4
        WHEN '45+' THEN 5
    END;