--1. Создаёт представление с полными данными о клиентах-женщинах. 
--Демонстрирует CREATE VIEW с фильтром по полу.
CREATE VIEW v_persons_female AS
SELECT id, name, age, gender, address
FROM person
WHERE gender = 'female';

--2. Представление «мужчины»
CREATE VIEW v_persons_male AS
SELECT id, name, age, gender, address
FROM person
WHERE gender = 'male';

--3. Объединение имён из двух представлений
SELECT name FROM v_persons_female
UNION
SELECT name
FROM v_persons_male
ORDER BY 1;

--4. Представление «сгенерированные даты»
CREATE VIEW v_generated_dates AS
SELECT generated_date::date
FROM generate_series('2022-01-01'::timestamp, '2022-01-31'::timestamp, '1 day') generated_date
ORDER BY 1;

--5. Пропущенные даты визитов
SELECT generated_date missing_date
FROM v_generated_dates
EXCEPT
SELECT visit_date
FROM person_visits
ORDER BY 1;

--6. Представление «симметричная разница посещений 2 и 6 января»
CREATE VIEW v_symmetric_union AS
(	SELECT person_id
	FROM person_visits
	WHERE visit_date = '2022-01-02'
	EXCEPT
	SELECT person_id
	FROM person_visits
	WHERE visit_date = '2022-01-06')
UNION
(	SELECT person_id
	FROM person_visits
	WHERE visit_date = '2022-01-06'
	EXCEPT
	SELECT person_id
	FROM person_visits
	WHERE visit_date = '2022-01-02')
	
ORDER BY 1;

--7. Представление «цена со скидкой»
CREATE VIEW v_price_with_discount AS
SELECT p.name,
		m.pizza_name, 
		m.price, 
		(SELECT (m2.price *0.9)::INT discount_price FROM menu m2 WHERE m2.id = m.id)
FROM person_order po
LEFT JOIN person p ON p.id = po.person_id
LEFT JOIN menu m ON m.id = po.menu_id
ORDER BY 1, 2;

--8. Материализованное представление «визиты и еда Дмитрия»
CREATE MATERIALIZED VIEW mv_dmitriy_visits_and_eats AS
SELECT pz.name
FROM person_visits pv
FULL JOIN menu ON menu.pizzeria_id = pv.pizzeria_id
FULL JOIN pizzeria pz ON pz.id = menu.pizzeria_id
FULL JOIN person p ON p.id = pv.person_id
WHERE p.name = 'Dmitriy' AND pv.visit_date = '2022-01-08' AND menu.price < 800;

--9. Вспомогательное представление find_pizza
CREATE VIEW find_pizza AS
	SELECT pizzeria.id pizzeria_id, menu.id menu_id
	FROM pizzeria
	JOIN menu ON menu.pizzeria_id = pizzeria.id
	WHERE menu.price < 800 AND pizzeria.name != 'Papa Johns'
	ORDER BY 1
	LIMIT 1;

--10. Вставка визита Dmitriy на основе find_pizza
INSERT INTO person_visits (id, person_id, pizzeria_id, visit_date)
SELECT
		(SELECT MAX(id) + 1 FROM person_visits),
		(SELECT id FROM person WHERE name = 'Dmitriy'),
		(SELECT pizzeria_id FROM find_pizza),
		'2022-01-08';

--11. Вставка заказа Dmitriy на основе find_pizza
INSERT INTO person_order (id, person_id, menu_id, order_date)
SELECT
		(SELECT MAX(id) + 1 FROM person_order),
		(SELECT id FROM person WHERE name = 'Dmitriy'),
		(SELECT menu_id FROM find_pizza),
		'2022-01-08';

--12. Удаление временного представления и обновление материализованного
DROP VIEW find_pizza;
REFRESH MATERIALIZED VIEW mv_dmitriy_visits_and_eats;

--13. Удаление всех представлений
DROP VIEW v_generated_dates, v_persons_female, v_persons_male, 
			v_price_with_discount, v_symmetric_union;
DROP MATERIALIZED VIEW mv_dmitriy_visits_and_eats;