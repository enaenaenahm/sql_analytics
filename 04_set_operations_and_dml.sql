--1. Пиццы Kate в диапазоне 800–1000 с датами посещений
SELECT pizza_name, price, p.name AS pizzeria_name, pv.visit_date
FROM menu
INNER JOIN pizzeria p ON p.id = menu.pizzeria_id
INNER JOIN person_visits pv ON p.id = pv.pizzeria_id
INNER JOIN person p2 ON p2.id = pv.person_id
WHERE price BETWEEN 800 AND 1000 AND p2.name = 'Kate'
ORDER BY 1,2,3;

--2. Позиции меню, которые ни разу не заказывали
SELECT id AS menu_id
FROM menu
EXCEPT  
SELECT menu_id
FROM person_order 
order by 1;

--3. Название, цена и пиццерия для незаказанных позиций
SELECT pizza_name, price, p.name
FROM
 (SELECT id AS menu_id
 FROM menu
 EXCEPT SELECT menu_id
 FROM person_order) AS t1
INNER JOIN menu ON t1.menu_id = menu.id
INNER JOIN pizzeria p ON p.id = menu.pizzeria_id
ORDER BY 1,2;

--4. Симметричная разница: пиццерии, где были только женщины или только мужчины (по посещениям)
(SELECT p2.name AS pizzeria_name
 FROM person p
 INNER JOIN person_visits pv ON p.id = pv.person_id
 INNER JOIN pizzeria p2 ON p2.id = pv.pizzeria_id
 WHERE p.gender = 'female'
 EXCEPT ALL SELECT p2.name
 FROM person p
 INNER JOIN person_visits pv ON p.id = pv.person_id
 INNER JOIN pizzeria p2 ON p2.id = pv.pizzeria_id
 WHERE p.gender = 'male')
UNION
(SELECT p2.name
 FROM person p
 INNER JOIN person_visits pv ON p.id = pv.person_id
 INNER JOIN pizzeria p2 ON p2.id = pv.pizzeria_id
 WHERE p.gender = 'male'
 EXCEPT ALL SELECT p2.name
 FROM person p
 INNER JOIN person_visits pv ON p.id = pv.person_id
 INNER JOIN pizzeria p2 ON p2.id = pv.pizzeria_id
 WHERE p.gender = 'female')
ORDER BY 1;

--5. Симметричная разница по заказам: пиццерии, где заказывали только женщины или только мужчины
(SELECT p2.name AS pizzeria_name
 FROM person p
 INNER JOIN person_order po ON p.id = po.person_id
 INNER JOIN menu m ON m.id = po.menu_id
 INNER JOIN pizzeria p2 ON p2.id = m.pizzeria_id
 WHERE p.gender = 'female'
 EXCEPT
 SELECT p2.name
 FROM person p
 INNER JOIN person_order po ON p.id = po.person_id
 INNER JOIN menu m ON m.id = po.menu_id
 INNER JOIN pizzeria p2 ON p2.id = m.pizzeria_id
 WHERE p.gender = 'male')
UNION
(SELECT p2.name
 FROM person p
 INNER JOIN person_order po ON p.id = po.person_id
 INNER JOIN menu m ON m.id = po.menu_id
 INNER JOIN pizzeria p2 ON p2.id = m.pizzeria_id
 WHERE p.gender = 'male'
 EXCEPT
 SELECT p2.name
 FROM person p
 INNER JOIN person_order po ON p.id = po.person_id
 INNER JOIN menu m ON m.id = po.menu_id
 INNER JOIN pizzeria p2 ON p2.id = m.pizzeria_id
 WHERE p.gender = 'female');

--6. Пиццерии, которые Andrey посещал, но не заказывал
SELECT p2.name
FROM person_visits
INNER JOIN person p ON p.id = person_visits.person_id
INNER JOIN pizzeria p2 ON p2.id = person_visits.pizzeria_id
WHERE p.name = 'Andrey'
EXCEPT 
SELECT p2.name
FROM person_order
INNER JOIN person p ON p.id = person_order.person_id
INNER JOIN menu m ON m.id = person_order.menu_id
INNER JOIN pizzeria p2 ON p2.id = m.pizzeria_id
WHERE p.name = 'Andrey'
ORDER BY 1;

--7. Пары пиццерий с одинаковой пиццей по одинаковой цене
SELECT m1.pizza_name,
    p1.name AS pizzeria_name_1,
    p2.name AS pizzeria_name_2,
    m1.price
FROM menu m1
INNER JOIN menu m2 ON m1.id <> m2.id
AND m1.price = m2.price
AND m1.pizzeria_id > m2.pizzeria_id
AND m1.pizza_name = m2.pizza_name
INNER JOIN pizzeria p1 ON m1.pizzeria_id = p1.id
INNER JOIN pizzeria p2 ON m2.pizzeria_id = p2.id
ORDER BY 1;

--8. Добавление одной позиции меню
INSERT INTO menu VALUES (19,2,'greek pizza',800);

--9. Добавление позиции с вычисляемыми идентификаторами
INSERT INTO menu values 
((SELECT max(id)+1 FROM menu ),
(SELECT id FROM pizzeria WHERE name = 'Dominos'),
'sicilian pizza',
900);

--10. Регистрация двух посещений Dominos (Denis и Irina)
INSERT INTO person_visits VALUES(
(SELECT max(id)+1 FROM person_visits),
(SELECT id FROM person WHERE name ='Denis'),
(SELECT id FROM pizzeria WHERE name = 'Dominos'),
'2022-02-24');

INSERT INTO person_visits VALUES(
(SELECT max(id)+1 FROM person_visits),
(SELECT id FROM person WHERE name = 'Irina'),
(SELECT id FROM pizzeria WHERE name = 'Dominos'),
'2022-02-24');

--11. Заказы sicilian pizza от Denis и Irina
INSERT INTO person_order 
VALUES(
(SELECT max(id)+1 FROM person_order),
(SELECT id FROM person WHERE name = 'Denis'),
(SELECT id FROM menu WHERE pizza_name = 'sicilian pizza'),
'2022-02-24');

INSERT INTO person_order 
VALUES(
(SELECT max(id)+1 FROM person_order),
(SELECT id FROM person WHERE name = 'Irina'),
(SELECT id FROM menu WHERE pizza_name = 'sicilian pizza'),
'2022-02-24');

--12. Скидка 10% на greek pizza
UPDATE menu
SET price = ROUND(price*0.9)
WHERE pizza_name = 'greek pizza';

--13. Массовая вставка: заказ greek pizza всеми клиентами
INSERT INTO person_order
SELECT g+
    (SELECT max(id)
    FROM person_order) AS id, id AS person_id,

    (SELECT id
    FROM menu
    WHERE pizza_name = 'greek pizza') AS menu_id, '2022-02-25' AS order_date
    FROM person
    INNER JOIN generate_series(1, 
    (SELECT count (*)
    FROM person)) AS g ON g = person.id;

--14. Удаление заказов и позиции меню greek pizza
DELETE FROM person_order
WHERE order_date = '2022-02-25';

DELETE FROM menu
WHERE pizza_name = 'greek pizza';