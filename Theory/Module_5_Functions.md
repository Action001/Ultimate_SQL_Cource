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
*   `DATEADD(part, number, date)` — прибавить время.
*   `DATEDIFF(part, start, end)` — разница дат.
*   `YEAR(date)`, `MONTH(date)` — извлечение части.

**PostgreSQL:**
*   `CURRENT_TIMESTAMP` или `NOW()`.
*   `date + interval '1 day'` — арифметика.
*   `AGE(end, start)` — разница.
*   `EXTRACT(year FROM date)` — извлечение.

## 5.3. Строковые функции
*   `LEN` (MSSQL) / `LENGTH` (Postgres) — длина строки.
*   `UPPER`, `LOWER` — регистр.
*   `SUBSTRING` — часть строки.
*   `CONCAT` (или `+` / `||`) — склеивание строк.

