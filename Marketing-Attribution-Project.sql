CREATE DATABASE marketing_attribution;
USE marketing_attribution;
CREATE TABLE attribution_data (
    user_id VARCHAR(100),
    timestamp VARCHAR(100),
    channel VARCHAR(100),
    campaign VARCHAR(200),
    conversion VARCHAR(20),
    revenue VARCHAR(50)
);
SHOW TABLES;
SELECT *
FROM attribution_data
LIMIT 10;
DESCRIBE attribution_data;
SELECT COUNT(*) AS total_rows
FROM attribution_data;
SELECT DISTINCT channel
FROM attribution_data;
SELECT conversion, COUNT(*) AS total
FROM attribution_data
GROUP BY conversion;
WITH first_touch AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY timestamp ASC
           ) AS rn
    FROM attribution_data
)

SELECT 
    channel,
    COUNT(*) AS first_click_conversions
FROM first_touch
WHERE rn = 1
AND conversion = 'Yes'
GROUP BY channel
ORDER BY first_click_conversions DESC;
WITH last_touch AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY timestamp DESC
           ) AS rn
    FROM attribution_data
)

SELECT 
    channel,
    COUNT(*) AS last_click_conversions
FROM last_touch
WHERE rn = 1
AND conversion = 'Yes'
GROUP BY channel
ORDER BY last_click_conversions DESC;
SELECT 
    AVG(touchpoints) AS avg_touchpoints
FROM (
    SELECT 
        user_id,
        COUNT(*) AS touchpoints
    FROM attribution_data
    GROUP BY user_id
) AS customer_journey;
SELECT 
    channel,
    COUNT(DISTINCT user_id) AS unique_customers
FROM attribution_data
GROUP BY channel
ORDER BY unique_customers DESC;
WITH customer_touchpoints AS (
    SELECT 
        user_id,
        channel,
        conversion,
        COUNT(*) OVER (PARTITION BY user_id) AS total_touchpoints
    FROM attribution_data
)

SELECT 
    channel,
    SUM(1.0 / total_touchpoints) AS linear_attribution_credit
FROM customer_touchpoints
WHERE conversion = 'Yes'
GROUP BY channel
ORDER BY linear_attribution_credit DESC;
SELECT 
    channel,
    COUNT(CASE WHEN conversion = 'Yes' THEN 1 END) * 100.0 / COUNT(*) AS conversion_rate
FROM attribution_data
GROUP BY channel
ORDER BY conversion_rate DESC;
SELECT 
    campaign,
    COUNT(CASE WHEN conversion = 'Yes' THEN 1 END) AS conversions
FROM attribution_data
GROUP BY campaign
ORDER BY conversions DESC;
WITH ranked_touchpoints AS (
    SELECT
        user_id,
        channel,
        conversion,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY timestamp ASC
        ) AS touch_order,

        COUNT(*) OVER (
            PARTITION BY user_id
        ) AS total_touchpoints

    FROM attribution_data
)

SELECT
    channel,

    SUM(
        touch_order * 1.0 / total_touchpoints
    ) AS time_decay_score

FROM ranked_touchpoints

WHERE conversion = 'Yes'

GROUP BY channel

ORDER BY time_decay_score DESC;
WITH first_click AS (
    SELECT
        user_id,
        channel,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY timestamp ASC
        ) AS rn,
        conversion
    FROM attribution_data
),

last_click AS (
    SELECT
        user_id,
        channel,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY timestamp DESC
        ) AS rn,
        conversion
    FROM attribution_data
)

SELECT
    f.channel AS first_click_channel,
    COUNT(*) AS first_click_conversions
FROM first_click f
WHERE f.rn = 1
AND f.conversion = 'Yes'
GROUP BY f.channel;
