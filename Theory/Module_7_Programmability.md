# Теория к Модулю 7: Программируемые объекты

Это уже "Backend на стороне БД". Синтаксис сильно зависит от СУБД (T-SQL vs PL/pgSQL).

## 7.1. User Defined Functions (Функции)
Возвращают значение (скалярное или таблицу). Обычно используются в `SELECT` или `WHERE`.

**Пример: Функция для расчета цены с налогом**

**MSSQL:**
```sql
CREATE FUNCTION fn_GetPriceWithTax (@price DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @price * 1.20; -- +20% НДС
END;
```

**PostgreSQL:**
```sql
CREATE FUNCTION fn_GetPriceWithTax(price NUMERIC) 
RETURNS NUMERIC AS $$
BEGIN
    RETURN price * 1.20;
END;
$$ LANGUAGE plpgsql;
```

## 7.2. Stored Procedures (Хранимые процедуры)
Набор команд. Могут менять данные, использовать транзакции, циклы, переменные.

**Пример: Перевод средств между пользователями (Транзакция)**

**MSSQL:**
```sql
CREATE PROCEDURE sp_Transfer (@from_user INT, @to_user INT, @amount DECIMAL(10,2))
AS
BEGIN
    BEGIN TRANSACTION;
    
    -- Проверка баланса
    IF (SELECT balance FROM users WHERE user_id = @from_user) >= @amount
    BEGIN
        UPDATE users SET balance = balance - @amount WHERE user_id = @from_user;
        UPDATE users SET balance = balance + @amount WHERE user_id = @to_user;
        COMMIT;
    END
    ELSE
    BEGIN
        ROLLBACK;
        THROW 50000, 'Not enough money', 1;
    END
END;
```

**PostgreSQL:**
```sql
CREATE PROCEDURE sp_transfer(from_u INT, to_u INT, amount NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    -- В Postgres процедуры автоматически поддерживают транзакции (если нет явного BEGIN/COMMIT внутри блока)
    -- Но для явного управления (rollback) нужна логика:
    
    IF (SELECT balance FROM users WHERE user_id = from_u) >= amount THEN
        UPDATE users SET balance = balance - amount WHERE user_id = from_u;
        UPDATE users SET balance = balance + amount WHERE user_id = to_u;
    ELSE
        RAISE EXCEPTION 'Not enough money'; 
        -- Это вызовет автоматический ROLLBACK всей транзакции
    END IF;
END;
$$;
```

### Транзакции
Гарантируют атомарность (все или ничего).
*   `BEGIN TRANSACTION` (MSSQL) / `BEGIN` (Postgres)
*   `COMMIT` — сохранить изменения.
*   `ROLLBACK` — отменить изменения.

## 7.3. Triggers (Триггеры)
Скрипты, срабатывающие автоматически при событиях (`INSERT`, `UPDATE`, `DELETE`).

**Магические таблицы:**
*   **MSSQL:** `inserted` (новые данные), `deleted` (старые данные).
*   **Postgres:** `NEW` (новая строка), `OLD` (старая строка).

**Пример 1: Валидация (Запрет коротких отзывов)**
*Логика: Если длина отзыва < 10 символов, отменить вставку.*

**MSSQL:**
```sql
CREATE TRIGGER trg_CheckReview ON reviews
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE LEN(review_text) < 10)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50000, 'Review is too short', 1;
    END
END;
```

**PostgreSQL:**
```sql
CREATE FUNCTION fn_check_review() RETURNS TRIGGER AS $$
BEGIN
    IF LENGTH(NEW.review_text) < 10 THEN
        RAISE EXCEPTION 'Review is too short';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_review
BEFORE INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION fn_check_review();
```

**Пример 2: Аудит (Логирование изменений фильма)**
*Логика: При изменении рейтинга фильма, писать лог.*

**MSSQL:**
```sql
CREATE TRIGGER trg_LogMovieRating ON movies
AFTER UPDATE
AS
BEGIN
    IF UPDATE(rating)
    BEGIN
        INSERT INTO audit_logs (table_name, record_id, old_value, new_value)
        SELECT 'movies', i.movie_id, CAST(d.rating AS NVARCHAR), CAST(i.rating AS NVARCHAR)
        FROM inserted i JOIN deleted d ON i.movie_id = d.movie_id;
    END
END;
```
