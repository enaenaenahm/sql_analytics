-- Поиск оптимального тура (TSP) по графу городов через рекурсивный CTE. 


-- 1. Подготовка таблицы рёбер графа
DROP TABLE IF EXISTS nodes;

CREATE TABLE nodes (
    point1 TEXT,
    point2 TEXT,
    cost   INT
);

-- 2. Наполнение графа (4 города, неориентированные рёбра)
INSERT INTO nodes (point1, point2, cost) VALUES
    ('a', 'b', 10), ('b', 'a', 10),
    ('a', 'c', 15), ('c', 'a', 15),
    ('a', 'd', 20), ('d', 'a', 20),
    ('b', 'c', 35), ('c', 'b', 35),
    ('b', 'd', 25), ('d', 'b', 25),
    ('c', 'd', 30), ('d', 'c', 30);

-- 3. Рекурсивный обход всех маршрутов, начинающихся с 'a'.
-- cycle = TRUE, когда следующий город уже есть в пути —
-- это останавливает рекурсию и предотвращает бесконечный цикл.
WITH RECURSIVE tours AS (
    SELECT
        point2                       AS next_city,
        cost                         AS total_cost,
        ARRAY[point1, point2]        AS path,
        FALSE                        AS cycle
    FROM nodes
    WHERE point1 = 'a'

    UNION ALL

    SELECT
        n.point2                         AS next_city,
        t.total_cost + n.cost            AS total_cost,
        t.path || n.point2               AS path,
        n.point2 = ANY(t.path)           AS cycle
    FROM tours t
    JOIN nodes n ON t.next_city = n.point1
    WHERE NOT t.cycle
),

-- 4. Оставляем только завершённые туры:
-- длина 5 (4 города + возврат), начинается и заканчивается на 'a'.
completed_tours AS (
    SELECT total_cost, path
    FROM tours
    WHERE array_length(path, 1) = 5
      AND path[1] = 'a'
      AND path[array_length(path, 1)] = 'a'
)

-- 5. Выбираем тур(ы) минимальной стоимости.
-- Подзапрос MIN считается только по completed_tours —
-- это исключает попадание незавершённых путей длиной 5.
SELECT
    total_cost,
    ARRAY_TO_STRING(path, ',') AS tour
FROM completed_tours
WHERE total_cost = (SELECT MIN(total_cost) FROM completed_tours)
ORDER BY total_cost, tour;