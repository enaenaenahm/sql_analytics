-- TSP-обход графа через рекурсивный CTE: возвращает самый
-- дешёвый и самый дорогой завершённые туры.


-- 1. Рекурсивный обход всех маршрутов, начинающихся с 'a'.
-- cycle = TRUE, когда следующий город уже есть в пути, —
-- это останавливает рекурсию и предотвращает бесконечный цикл.
WITH RECURSIVE tours AS (
    SELECT
        point2                  AS next_city,
        cost                    AS total_cost,
        ARRAY[point1, point2]   AS path,
        FALSE                   AS cycle
    FROM nodes
    WHERE point1 = 'a'

    UNION ALL

    SELECT
        n.point2                AS next_city,
        t.total_cost + n.cost   AS total_cost,
        t.path || n.point2      AS path,
        n.point2 = ANY(t.path)  AS cycle
    FROM tours t
    JOIN nodes n ON t.next_city = n.point1
    WHERE NOT t.cycle
),

-- 2. Оставляем только завершённые туры:
-- длина 5 (4 города + возврат), начинается и заканчивается на 'a'.
filtered_tours AS (
    SELECT
        total_cost,
        ARRAY_TO_STRING(path, ',') AS tour
    FROM tours
    WHERE array_length(path, 1) = 5
      AND path[1] = 'a'
      AND path[array_length(path, 1)] = 'a'
)

-- 3. Самый дешёвый и самый дорогой туры.
-- UNION (без ALL) защищает от дублирования строки, если
-- MIN(total_cost) = MAX(total_cost) — например, когда
-- валидный тур всего один.
SELECT *
FROM filtered_tours
WHERE total_cost = (SELECT MIN(total_cost) FROM filtered_tours)

UNION

SELECT *
FROM filtered_tours
WHERE total_cost = (SELECT MAX(total_cost) FROM filtered_tours)

ORDER BY total_cost, tour;