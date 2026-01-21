# Теория к Модулю 5: Логика и Функции

## 5.1. Условная логика (CASE)

Позволяет делать проверки "IF-THEN-ELSE" прямо внутри запроса.

**Синтаксис:**
```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE default_result
END
```

## 5.2. Работа с датами

Различия диалектов сильны.

**Microsoft SQL Server:**
*   `GETDATE()` — текущее время.
*   `DATEADD(day, 7, date)` — прибавить 7 дней (можно year, month, day).
*   `DATEDIFF(day, start, end)` — разница в днях (или year, month).
*   `YEAR(date)`, `MONTH(date)` — извлечение части.

**PostgreSQL:**
*   `CURRENT_DATE` — текущая дата.
*   `date + interval '7 days'` — арифметика.
*   `date1 - date2` — разница в днях (возвращает целое число).
*   `AGE(end, start)` — разница в годах/месяцах/днях.
*   `EXTRACT(year FROM date)` — извлечение.

## 5.3. Строковые функции
*   `LEN` (MSSQL) / `LENGTH` (Postgres) — длина строки.
*   `LEFT(str, n)`, `RIGHT(str, n)` — взять n символов слева/справа.
*   `UPPER`, `LOWER` — регистр.
*   `SUBSTRING(str, start, len)` — часть строки.
*   `CHARINDEX(sub, str)` (MSSQL) / `POSITION(sub IN str)` (Postgres) — поиск подстроки.
*   `CONCAT` (или `+` / `||`) — склеивание строк.

