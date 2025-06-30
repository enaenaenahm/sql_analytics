--1. Индексы для внешних ключей в person_visits и menu
CREATE INDEX idx_person_visits_pizzeria_id ON person_visits (pizzeria_id);
CREATE INDEX idx_person_visits_person_id ON person_visits (person_id);
CREATE INDEX idx_menu_pizzeria_id ON menu (pizzeria_id);
CREATE INDEX idx_person_order_menu_id ON person_order (menu_id);
CREATE INDEX idx_person_order_person_id ON person_order (person_id);

--2. Просмотр всех индексов в базе
SELECT * FROM pg_indexes;

--3. Отключение последовательного сканирования и анализ плана для JOIN
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT pizza_name, piz.name AS pizzeria_name
FROM menu
INNER JOIN pizzeria piz ON menu.pizzeria_id = piz.id;

--4. Индекс по выражению upper(name)
CREATE INDEX idx_person_name ON person (upper(name));
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT name
FROM person
WHERE upper(name) = 'ANDREY';

--5. Составной индекс по (person_id, menu_id, order_date)
CREATE INDEX idx_person_order_multi ON person_order (person_id, menu_id,order_date);
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT person_id, menu_id,order_date
FROM person_order
WHERE person_id = 8 AND menu_id = 19;

--6. Уникальный индекс по (pizzeria_id, pizza_name)
CREATE UNIQUE INDEX idx_menu_unique ON menu (pizzeria_id, pizza_name);
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT pizzeria_id, pizza_name
FROM menu
WHERE pizzeria_id = 1 AND pizza_name = 'pepperoni pizza';

--7. Частичный уникальный индекс с условием по дате
CREATE UNIQUE INDEX idx_person_order_order_date ON person_order (person_id, menu_id)
WHERE order_date = '2022-01-01';
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT person_id, menu_id
FROM person_order
WHERE order_date = '2022-01-01';

--8. Индекс по rating и анализ оконной функции
CREATE INDEX idx_1 ON pizzeria(rating);
SET enable_seqscan = ON;
EXPLAIN ANALYZE SELECT
    m.pizza_name AS pizza_name,
    max(rating) OVER (PARTITION BY rating ORDER BY rating ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS k
FROM  menu m
INNER JOIN pizzeria pz ON m.pizzeria_id = pz.id
ORDER BY 1,2;