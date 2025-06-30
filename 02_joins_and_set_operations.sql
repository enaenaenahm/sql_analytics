--1. Объединение идентификаторов и имён из двух таблиц
SELECT id AS object_id, pizza_name AS object_name
FROM menu
UNION
SELECT id, name
FROM person
ORDER BY 1, 2

--2. Объединение с сохранением дублей
SELECT pizza_name AS object_name
FROM menu
UNION ALL
SELECT name 
FROM person
ORDER BY 1;

--3. Пересечение названий пицц
SELECT pizza_name AS object_name
FROM menu
INTERSECT
SELECT pizza_name AS object_name
FROM menu
ORDER BY 1 DESC;

--4. Пересечение дат заказов и посещений по клиенту
SELECT order_date, person_id
FROM person_order
INTERSECT
SELECT visit_date, person_id
FROM person_visits
ORDER BY 1, 2 DESC;

--5. Разница множеств: клиенты с заказами, но без посещений
SELECT person_id
FROM person_order
WHERE order_date = '2022-01-07'
EXCEPT ALL
SELECT person_id
From person_visits
WHERE visit_date = '2022-01-07';

--6. Декартово произведение. Создаёт все возможные пары «клиент — пиццерия». 
--Показывает CROSS JOIN и сортировку по двум полям.
SELECT * FROM person
CROSS JOIN pizzeria
ORDER BY person.id, pizzeria.id;

--7. Пересечение дат и клиентов + присоединение имени
SELECT ACTION_DATE,
	PERSON.NAME
FROM
	(SELECT ORDER_DATE AS ACTION_DATE,
			PERSON_ID
		FROM PERSON_ORDER 
    INTERSECT 
    SELECT VISIT_DATE AS ACTION_DATE,
			PERSON_ID
		FROM PERSON_VISITS) AS INTER
INNER JOIN PERSON ON PERSON.ID = PERSON_ID
ORDER BY 1 ASC,
	2 DESC;

--8. Присоединение строкового профиля клиента к заказам
SELECT ORDER_DATE,
	PERSON_INFORMATION
FROM
	(SELECT NAME || ' (age:' || AGE || ')' AS PERSON_INFORMATION,
			ID
		FROM PERSON) AS TABLE1
INNER JOIN PERSON_ORDER ON PERSON_ORDER.PERSON_ID = TABLE1.ID
ORDER BY 1 ASC,
	2 ASC;

--9. Присоединение через NATURAL JOIN
SELECT ORDER_DATE,
	PERSON_INFORMATION
FROM
	(SELECT NAME || ' (age:' || AGE || ')' AS PERSON_INFORMATION,
			ID
		FROM PERSON) AS TABLE1
NATURAL JOIN (SELECT order_date, person_id AS ID FROM PERSON_ORDER) AS nj
ORDER BY 1 ASC,
	2 ASC;

--10. Пиццерии без посещений через NOT IN
SELECT name 
FROM pizzeria
WHERE id NOT IN (SELECT pizzeria_id AS id FROM person_visits);

--11. Пиццерии без посещений через NOT EXISTS
SELECT NAME
FROM PIZZERIA
WHERE NOT EXISTS
		(SELECT PIZZERIA_ID
			FROM PERSON_VISITS
			WHERE PIZZERIA.ID = PIZZERIA_ID);

--12. Сводный отчёт по заказам: клиент — пицца — пиццерия
SELECT PERSON.NAME AS PERSON_NAME,
	PIZZA_NAME,
	PIZZERIA.NAME AS PIZZERIA_NAME
FROM PERSON
INNER JOIN PERSON_ORDER ON PERSON_ID = PERSON.ID
INNER JOIN MENU ON MENU_ID = MENU.ID
INNER JOIN PIZZERIA ON MENU.PIZZERIA_ID = PIZZERIA.ID
ORDER BY 1 ASC,
	2 ASC,
	3 ASC;

