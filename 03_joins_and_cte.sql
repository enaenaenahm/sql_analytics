--1. Пиццерии без посещений через RIGHT JOIN
SELECT pizzeria.name,
	   rating
FROM person_visits
RIGHT JOIN pizzeria ON
	pizzeria.id = person_visits.pizzeria_id
WHERE pizzeria_id IS NULL;

--2. Пропущенные даты посещений для клиентов 1 и 2
SELECT missing_date::date
FROM generate_series(
	'2022-01-01'::date, 
	'2022-01-10'::date, 
	'1 day'::interval) AS missing_date
LEFT JOIN (SELECT visit_date
    	   FROM person_visits
           WHERE person_id = 1 OR person_id = 2) AS visited_date 
ON  missing_date = visit_date
WHERE visit_date IS NULL
ORDER BY visit_date;

--3. Полный отчёт по посещениям за 1–3 января с заполнением пропусков
SELECT 
	COALESCE(person.name, '-') AS person_name,
	visit_date,
	COALESCE(pizzeria.name, '-') AS pizzeria_name
FROM (SELECT visit_date,
	  		 person_id,
	  		 pizzeria_id
	  FROM person_visits
	  WHERE visit_date = '2022-01-01' OR 
	 		visit_date = '2022-01-02' OR
	 		visit_date = '2022-01-03') AS person_ordered
FULL JOIN person ON person.id = person_id
FULL JOIN pizzeria ON pizzeria.id = pizzeria_id
ORDER BY person_name, visit_date, pizzeria_name;

--4. Пропущенные даты через CTE
WITH date_range AS (
  SELECT missing_date::date
  FROM generate_series(
      '2022-01-01'::date, 
      '2022-01-10'::date, 
      '1 day'::interval
  ) AS missing_date),
visited_date AS (
  SELECT visit_date
    FROM person_visits
    WHERE person_id = 1 OR person_id = 2
)
SELECT missing_date
FROM date_range
LEFT JOIN visited_date
ON missing_date = visit_date
WHERE visit_date IS NULL
ORDER BY visit_date;

--5. Пиццы «mushroom» и «pepperoni» с названием пиццерии и ценой
SELECT
	menu.pizza_name,
	table_pizzeria.name AS pizzeria_name,
	menu.price
FROM menu
JOIN pizzeria AS table_pizzeria
ON table_pizzeria.id = menu.pizzeria_id
WHERE pizza_name = 'mushroom pizza' OR pizza_name = 'pepperoni pizza'
ORDER BY menu.pizza_name, pizzeria_name;

--6. Женщины старше 25 лет
SELECT name FROM person
WHERE gender='female' AND 
	  age > 25
ORDER BY name;

--7. Заказы клиентов Denis и Anna: пицца и пиццерия
SELECT 
	menu.pizza_name AS pizza_name,
	pizzeria.name AS pizzeria_name
FROM person_order 
JOIN menu
	ON person_order.menu_id = menu.id
JOIN pizzeria
	ON pizzeria.id = menu.pizzeria_id
JOIN (SELECT id, name 
	  FROM person WHERE name = 'Denis' OR 
	 					name = 'Anna') AS person_table
	ON person_table.id = person_order.person_id
ORDER BY pizza_name, pizzeria_name;

--8. Пиццерии, где Dmitriy был 8 января и где есть пицца дешевле 800
SELECT pizzeria.name AS pizzeria_name
FROM pizzeria
JOIN menu ON
	menu.pizzeria_id = pizzeria.id AND
	price < 800
JOIN person_visits ON
	person_visits.pizzeria_id = menu.pizzeria_id AND
	visit_date = '2022-01-08'
JOIN person ON
	person.id = person_visits.person_id AND
	person.name = 'Dmitriy';

--9. Мужчины из Москвы и Самары, заказавшие pepperoni или mushroom
SELECT 
	person_table.name AS name
FROM (SELECT * 
	  FROM person 
	  WHERE address IN ('Moscow', 'Samara') AND
	 		gender = 'male') AS person_table
JOIN person_order ON 
	person_order.person_id = person_table.id
JOIN (SELECT * 
	  FROM menu 
	  WHERE menu.pizza_name = 'pepperoni pizza' OR
	 		menu.pizza_name = 'mushroom pizza') AS menu_table
	ON menu_table.id = person_order.menu_id
ORDER BY name DESC;

--10. Женщины, заказавшие и pepperoni, и cheese pizza
SELECT person.name AS name
FROM person
JOIN person_order ON
  person_order.person_id = person.id AND
  person.gender = 'female'
JOIN menu ON 
  person_order.menu_id = menu.id AND
  menu.pizza_name IN ('pepperoni pizza', 'cheese pizza')
GROUP BY name
HAVING COUNT (DISTINCT menu.pizza_name) = 2
ORDER BY name;

--11. Пары клиентов с одинаковым адресом
SELECT 
	person1.name AS person_name1, 
	person2.name AS person_name2, 
	person1.address AS common_address
FROM person AS person1 
JOIN person AS person2 
  ON person1.address = person2.address 
  AND person1.id > person2.id
ORDER BY person_name1, person_name2, common_address
