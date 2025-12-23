# Теория к Модулю 8: Автоматизация и Обслуживание

Этот модуль посвящен тому, как сделать базу данных быстрой, удобной и "самообслуживаемой".

## 8.1. Представления (Views)

**View** (Вьюха) — это сохраненный SELECT-запрос, к которому можно обращаться как к обычной таблице. Данные в ней не хранятся физически (если это не Materialized View), они вычисляются в момент обращения.

**Зачем нужно:**
1.  **Упрощение:** Спрятать сложный JOIN за простым именем.
2.  **Безопасность:** Дать пользователю доступ только к части колонок (например, скрыть email и пароль).

**Синтаксис:**
```sql
CREATE VIEW ViewName AS
SELECT ...
```

## 8.2. Индексы (Indexes)

Структуры данных (обычно B-Tree), ускоряющие поиск.

*   Без индекса: **Table Scan** (перебор всех строк). Медленно.
*   С индексом: **Index Seek** (быстрый поиск по дереву). Быстро.

**Минусы:** Индексы замедляют вставку (`INSERT`/`UPDATE`), так как при каждом изменении данных нужно перестраивать дерево.

**Синтаксис:**
```sql
CREATE INDEX idx_name ON table_name (column_name);
```

## 8.3. Регулярные задачи (Jobs)

Базы данных требуют регулярного ухода: бэкапы, очистка логов, пересчет статистики.

### MS SQL Server (SQL Agent)
В MSSQL джобы управляются системной базой `msdb`.

**Создание джоба T-SQL скриптом (пример):**
```sql
USE msdb;
GO
-- 1. Создаем джоб
EXEC sp_add_job @job_name = N'DailyCleanup';

-- 2. Добавляем шаг (что делать)
EXEC sp_add_jobstep
    @job_name = N'DailyCleanup',
    @step_name = N'CleanLogs',
    @subsystem = N'TSQL',
    @command = N'DELETE FROM KINO.dbo.audit_logs WHERE changed_at < DATEADD(year, -1, GETDATE())';

-- 3. Добавляем расписание (когда делать)
EXEC sp_add_jobschedule
    @job_name = N'DailyCleanup',
    @name = N'EveryNight',
    @freq_type = 4, -- Ежедневно
    @active_start_time = 010000; -- В 01:00 ночи

-- 4. Запускаем добавление джоба серверу
EXEC sp_add_jobserver @job_name = N'DailyCleanup';
```

### PostgreSQL (pg_cron)
В "голом" Postgres нет встроенного планировщика. Стандарт де-факто — расширение `pg_cron`.

**Установка и использование:**
```sql
-- Включаем расширение (требует предварительной настройки в postgresql.conf)
CREATE EXTENSION pg_cron;

-- Создаем задачу (Cron syntax: min hour day month week)
-- Запуск каждый день в 03:00 ночи
SELECT cron.schedule('0 3 * * *', $$DELETE FROM audit_logs WHERE changed_at < NOW() - interval '1 year'$$);

-- Посмотреть список задач
SELECT * FROM cron.job;
```

**Типовые задачи:**
*   Daily Backup.
*   Очистка старых данных (Data Purging).
*   Рассылка отчетов.

