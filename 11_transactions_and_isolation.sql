-- Демонстрация работы транзакций, уровней изоляции (ACID)
-- и механизма блокировок (MVCC) в PostgreSQL.
-- Сценарии выполнялись в двух параллельных сессиях (Session A и Session B).


-- СЦЕНАРИЙ 1: Базовый COMMIT и ROLLBACK (Скриншот 1)
-- Демонстрация атомарности: изменения применяются только после COMMIT.
BEGIN;
UPDATE pizzeria SET rating = 5 WHERE name = 'Pizza Hut';
SELECT * FROM pizzeria WHERE name = 'Pizza Hut'; -- Внутри транзакции видим 5
COMMIT;
-- В новом окне/сессии видим, что рейтинг изменился на 5.


-- СЦЕНАРИЙ 2: Read Committed и Non-repeatable Read (Скриншот 2)
-- Уровень изоляции по умолчанию. Чтение внутри транзакции видит чужие COMMIT.
-- Session A:
BEGIN;
SELECT * FROM pizzeria WHERE name = 'Pizza Hut'; -- Видим 5
-- Session B (в другом окне):
-- UPDATE pizzeria SET rating = 3.6 WHERE name = 'Pizza Hut'; COMMIT;
-- Session A (продолжение):
SELECT * FROM pizzeria WHERE name = 'Pizza Hut'; -- Видим 3.6 (Non-repeatable read)
COMMIT;


-- СЦЕНАРИЙ 3: Repeatable Read и ошибка сериализации (Скриншоты 3 и 4)
-- В Repeatable Read транзакция видит снимок данных (snapshot) на момент начала.
-- Session A:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM pizzeria WHERE name = 'Pizza Hut'; -- Видим 3.6
-- Session B:
-- UPDATE pizzeria SET rating = 4 WHERE name = 'Pizza Hut'; COMMIT;
-- Session A (пытается обновить строку, которую изменил кто-то другой):
UPDATE pizzeria SET rating = 3.6 WHERE name = 'Pizza Hut'; 
-- ERROR: could not serialize access due to concurrent update
COMMIT; -- Произойдет ROLLBACK


-- СЦЕНАРИЙ 4: Read Committed и фантомное чтение (Phantom Read) (Скриншоты 5 и 6)
-- Агрегатные функции (SUM) могут меняться внутри транзакции, если другая сессия делает INSERT.
-- Session A:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT SUM(rating) FROM pizzeria; -- 21.9
-- Session B:
-- INSERT INTO pizzeria VALUES (10, 'Kazan Pizza', 5); COMMIT;
-- Session A (продолжение):
SELECT SUM(rating) FROM pizzeria; -- 26.9 (Увидели новую строку)
COMMIT;


-- СЦЕНАРИЙ 5: Repeatable Read и защита от фантомов (Скриншот 7)
-- В Repeatable Read агрегаты стабильны.
-- Session A:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT SUM(rating) FROM pizzeria; -- 26.9
-- Session B:
-- INSERT INTO pizzeria VALUES (11, 'Kazan Pizza 2', 4); COMMIT;
-- Session A (продолжение):
SELECT SUM(rating) FROM pizzeria; -- 26.9 (Фантомы не видны)
COMMIT;
-- После COMMIT следующая транзакция увидит уже 30.9.


-- СЦЕНАРИЙ 6: Взаимная блокировка (Deadlock) (Скриншот 8)
-- PostgreSQL автоматически обнаруживает deadlock и прерывает одну из транзакций.
-- Session A:
BEGIN;
UPDATE pizzeria SET rating = 4 WHERE name = 'Kazan Pizza';
-- Session B:
-- BEGIN;
-- UPDATE pizzeria SET rating = 4 WHERE name = 'Kazan Pizza 2';
-- Session A:
UPDATE pizzeria SET rating = 3 WHERE name = 'Kazan Pizza 2'; 
-- Ожидает блокировку от Session B
-- Session B:
-- UPDATE pizzeria SET rating = 3 WHERE name = 'Kazan Pizza';
-- ERROR: deadlock detected. Process waits for ShareLock...
ROLLBACK;