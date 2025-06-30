-- Персональные скидки клиентов: DDL, наполнение, аналитика,
-- ограничения, индексирование и управление последовательностями.
-- СУБД: PostgreSQL. Файл предполагает, что таблица person_discounts
-- ещё не создана (запускать один раз).

-- 1. Создание таблицы персональных скидок
CREATE TABLE person_discounts (
    id BIGINT PRIMARY KEY,
    person_id BIGINT NOT NULL,
    pizzeria_id BIGINT NOT NULL,
    discount NUMERIC(5,2) NOT NULL,
    CONSTRAINT fk_person_discounts_person_id
        FOREIGN KEY (person_id) REFERENCES person(id),
    CONSTRAINT fk_person_discounts_pizzeria_id
        FOREIGN KEY (pizzeria_id) REFERENCES pizzeria(id),
    CONSTRAINT uk_person_discounts_unique
        UNIQUE (person_id, pizzeria_id)
);

-- 2. Комментарии к таблице и столбцам
COMMENT ON TABLE person_discounts IS 'Таблица для хранения персональных скидок клиентов в пиццериях';
COMMENT ON COLUMN person_discounts.id IS 'Первичный ключ таблицы';
COMMENT ON COLUMN person_discounts.person_id IS 'Идентификатор клиента';
COMMENT ON COLUMN person_discounts.pizzeria_id IS 'Идентификатор пиццерии';
COMMENT ON COLUMN person_discounts.discount IS 'Размер скидки в процентах (от 0 до 100)';

-- 3. Наполнение: скидка зависит от количества заказов клиента в пиццерии
INSERT INTO person_discounts (id, person_id, pizzeria_id, discount)
WITH order_counts AS (
    SELECT
        person_id,
        pizzeria_id,
        COUNT(*) AS amount_of_orders
    FROM (
        SELECT po.person_id, m.pizzeria_id
        FROM person_order po
        JOIN menu m ON po.menu_id = m.id
    ) AS person_pizzeria_orders
    GROUP BY person_id, pizzeria_id
)
SELECT
    ROW_NUMBER() OVER () AS id,
    person_id,
    pizzeria_id,
    CASE
        WHEN amount_of_orders = 1 THEN 10.5
        WHEN amount_of_orders = 2 THEN 22
        ELSE 30
    END AS discount
FROM order_counts;

-- 4. Аналитический запрос: цена со скидкой по каждому заказу
SELECT
    p.name AS name,
    m.pizza_name AS pizza_name,
    m.price AS price,
    ROUND(m.price * (100 - COALESCE(pd.discount, 0)) / 100) AS discount_price,
    pz.name AS pizzeria_name
FROM person_order po
JOIN person p ON po.person_id = p.id
JOIN menu m ON po.menu_id = m.id
JOIN pizzeria pz ON m.pizzeria_id = pz.id
LEFT JOIN person_discounts pd
    ON p.id = pd.person_id AND pz.id = pd.pizzeria_id
ORDER BY p.name, m.pizza_name;

-- 5. Уникальный индекс и проверка плана запроса.
-- Примечание: ограничение uk_person_discounts_unique уже создаёт
-- индекс по (person_id, pizzeria_id). Явный CREATE UNIQUE INDEX
-- оставлен как демонстрация проверки использования индекса через
-- EXPLAIN ANALYZE.
CREATE UNIQUE INDEX idx_person_discounts_unique
    ON person_discounts(person_id, pizzeria_id);

SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT * FROM person_discounts
WHERE person_id = 1 AND pizzeria_id = 1;
SET enable_seqscan = ON;

-- 6. Ужесточение ограничений через ALTER TABLE.
-- Примечание: CHECK (... IS NOT NULL) не добавлен — SET NOT NULL
-- уже гарантирует отсутствие NULL; оставлен только содержательный
-- CHECK на диапазон скидки.
ALTER TABLE person_discounts
    ALTER COLUMN person_id SET NOT NULL,
    ALTER COLUMN pizzeria_id SET NOT NULL,
    ALTER COLUMN discount SET NOT NULL,
    ALTER COLUMN discount SET DEFAULT 0,
    ADD CONSTRAINT ch_range_discount
        CHECK (discount >= 0 AND discount <= 100);

-- 7. Расширенные комментарии: бизнес-контекст и правила
COMMENT ON TABLE person_discounts IS
'Таблица для хранения персональных скидок клиентов в пиццериях.
Бизнес-цель: повышение лояльности клиентов за счёт индивидуальных
предложений и увеличение продаж за счёт стимулирования повторных заказов.';

COMMENT ON COLUMN person_discounts.id IS
'Уникальный идентификатор записи о скидке. Первичный ключ таблицы.';

COMMENT ON COLUMN person_discounts.person_id IS
'Идентификатор клиента. Внешний ключ к таблице person.
Определяет, для какого клиента действует скидка.';

COMMENT ON COLUMN person_discounts.pizzeria_id IS
'Идентификатор пиццерии. Внешний ключ к таблице pizzeria.
Определяет, в какой пиццерии действует скидка.';

COMMENT ON COLUMN person_discounts.discount IS
'Размер персональной скидки в процентах (от 0 до 100).
Значение по умолчанию: 0.
Бизнес-правила: скидка зависит от количества заказов клиента в пиццерии.';

-- 8. Управление последовательностью для автоинкремента id.
-- Наполнение в блоке 3 задало id через ROW_NUMBER. Чтобы новые
-- вставки без явного id автоматически продолжали нумерацию, создаём
-- последовательность, стартуем от MAX(id)+1 и назначаем nextval
-- как DEFAULT для id.
CREATE SEQUENCE IF NOT EXISTS seq_person_discounts START WITH 1;

SELECT setval(
    'seq_person_discounts',
    COALESCE((SELECT MAX(id) FROM person_discounts), 0) + 1,
    false  -- следующее значение nextval = MAX(id)+1
);

ALTER TABLE person_discounts
    ALTER COLUMN id SET DEFAULT nextval('seq_person_discounts');
