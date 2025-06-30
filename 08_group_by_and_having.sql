-- Агрегатные метрики: количество визитов/заказов, топ-N,
-- статистика цен, средний рейтинг, география спроса.

-- 1. Количество посещений по каждому клиенту
SELECT person_id, count(visit_date) AS count_of_visits
FROM person_visits
GROUP BY person_id
ORDER BY count_of_visits DESC, person_id;

-- 2. Топ-4 клиента по количеству посещений
SELECT p.name, count(visit_date) AS count_of_visits
FROM person_visits pv
JOIN person p ON p.id = pv.person_id
GROUP BY p.name
ORDER BY count_of_visits DESC, p.name
LIMIT 4;

-- 3. Топ-3 пиццерии по посещениям и топ-3 по заказам
(SELECT p.name, count(visit_date) AS count, 'visit' AS action_type
 FROM person_visits pv
 JOIN pizzeria p ON p.id = pv.pizzeria_id
 GROUP BY p.name
 ORDER BY count DESC
 LIMIT 3)
UNION
(SELECT p.name, count(order_date) AS count, 'order' AS action_type
 FROM person_order po
 JOIN menu m ON m.id = po.menu_id
 JOIN pizzeria p ON p.id = m.pizzeria_id
 GROUP BY p.name
 ORDER BY count DESC
 LIMIT 3)
ORDER BY action_type, count DESC;

-- 4. Суммарная активность пиццерий: визиты + заказы
SELECT name, sum(total_count) AS total_count
FROM (
    SELECT p.name, count(visit_date) AS total_count
    FROM person_visits pv
    JOIN pizzeria p ON p.id = pv.pizzeria_id
    GROUP BY p.name
    UNION ALL
    SELECT p.name, count(order_date) AS total_count
    FROM person_order po
    JOIN menu m ON m.id = po.menu_id
    JOIN pizzeria p ON p.id = m.pizzeria_id
    GROUP BY p.name
) AS combined_counts
GROUP BY name
ORDER BY total_count DESC, name;

-- 5. Клиенты с более чем 3 посещениями
SELECT p.name, count(visit_date) AS count_of_visits
FROM person_visits
JOIN person p ON p.id = person_visits.person_id
GROUP BY p.name
HAVING count(visit_date) > 3;

-- 6. Уникальные клиенты, сделавшие хотя бы один заказ
SELECT DISTINCT p.name
FROM person_order po
JOIN person p ON p.id = po.person_id
ORDER BY p.name;

-- 7. Статистика по пиццериям: заказы, средний/макс/мин чек
SELECT p.name,
       count(po.order_date) AS count_of_orders,
       ROUND(AVG(m.price), 2) AS average_price,
       ROUND(MAX(m.price), 0) AS max_price,
       ROUND(MIN(m.price), 0) AS min_price
FROM person_order po
JOIN menu m ON m.id = po.menu_id
JOIN pizzeria p ON m.pizzeria_id = p.id
GROUP BY p.name
ORDER BY p.name;

-- 8. Средний рейтинг всех пиццерий
SELECT ROUND(AVG(rating), 4) AS global_rating FROM pizzeria;

-- 9. Число заказов по адресам и пиццериям
SELECT p.address,
       pz.name,
       count(po.order_date) AS count_of_orders
FROM person_order po
JOIN person p ON p.id = po.person_id
JOIN menu m ON m.id = po.menu_id
JOIN pizzeria pz ON pz.id = m.pizzeria_id
GROUP BY p.address, pz.name
ORDER BY p.address, pz.name;

-- 10. Сравнение формулы с средним возрастом по адресам
SELECT address,
       ROUND(MAX(age) - (CAST(MIN(age) AS DECIMAL) / NULLIF(MAX(age), 0)), 2) AS formula,
       ROUND(AVG(age), 2) AS average,
       CASE
           WHEN (MAX(age) - (CAST(MIN(age) AS DECIMAL) / NULLIF(MAX(age), 0))) > AVG(age) THEN 'true'
           ELSE 'false'
       END AS comparison
FROM person
GROUP BY address
ORDER BY address;