--1. Фильтрация по адресу
SELECT name, age FROM person 
    WHERE 
        address = 'Kazan';

--2. Фильтрация по двум условиям с сортировкой
SELECT name, age FROM person
WHERE
    gender = 'female' 
    AND 
    address = 'Kazan'
ORDER BY
    name;

--3. Отбор по диапазону рейтинга (явные границы)
SELECT name, rating FROM pizzeria 
WHERE 
    (rating >= 3.5) AND (rating <= 5) 
ORDER BY 
    rating;

--4. Отбор по диапазону через BETWEEN
SELECT name, rating FROM pizzeria 
WHERE 
    (rating BETWEEN 3.5 AND 5) 
ORDER BY 
    rating;

--5. Уникальные идентификаторы посетителей с составным условием
SELECT DISTINCT person_id FROM person_visits 
WHERE 
    (visit_date BETWEEN '2022-01-06' AND '2022-01-09') 
    OR 
    (pizzeria_id = 2)
ORDER BY 
    person_id DESC;

--6. Формирование строкового профиля клиента
SELECT 
    name 
    || ' (age:' || age
    || ', gender:' || gender
    || ', address:' || address
    || ')'
    AS person_information
FROM 
    person
ORDER BY person_information ASC;

--7. Подзапрос в SELECT для получения имени
SELECT 
    (SELECT name from person WHERE id = person_order.person_id) AS name  -- this is an internal query in a main SELECT clause
FROM person_order
WHERE
    (
        (menu_id = 13)
        OR
        (menu_id = 14)
        OR
        (menu_id = 18))
    AND
    (
        (order_date = '2022-01-07'))

--8. Условная логика в подзапросе (флаг «Denis»)
SELECT 
    ( 
        SELECT name 
        
        FROM person WHERE id = person_order.person_id
    )
    ,
    (
        SELECT 
            CASE 
                WHEN name = 'Denis' THEN TRUE
                ELSE FALSE
            END
        AS isDenis

        FROM person WHERE id = person_order.person_id
    )
FROM person_order
WHERE
    (
        (menu_id = 13)
        OR
        (menu_id = 14)
        OR
        (menu_id = 18)
)
    AND
    ((order_date = '2022-01-07'))

--9. Сегментация по возрастным интервалам
SELECT 
    id,
    name,
    (
        SELECT 
            CASE 
                WHEN (age BETWEEN 10 AND 20) THEN 'interval #1'
                WHEN (age > 20 AND age < 24) THEN 'interval #2'
                ELSE 'interval #3'
            END
        AS interval_info
    )
FROM person
ORDER BY interval_info ASC;

--10. Фильтрация по чётности идентификатора
SELECT 
    id,
    person_id,
    menu_id,
    order_date
FROM person_order
WHERE (id % 2 = 0)
ORDER BY id ASC;

--11. Подзапрос в FROM с коррелированными подзапросами в SELECT
SELECT 
    (
        SELECT name 
        FROM person 
        WHERE id = pv.person_id 
    ) AS person_name,  -- this is an internal query in a main SELECT clause
    (   
        SELECT name
        FROM pizzeria 
        WHERE id = pv.pizzeria_id
    ) AS pizzeria_name  -- this is an internal query in a main SELECT clause
FROM 
(
    SELECT person_id, pizzeria_id 
    FROM person_visits 
    WHERE visit_date BETWEEN '2022-01-07' AND '2022-01-09'
) AS pv -- this is an internal query in a main FROM clause
ORDER BY 
    person_name ASC,
    pizzeria_name DESC;
