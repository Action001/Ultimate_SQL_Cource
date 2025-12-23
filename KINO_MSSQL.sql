-- Обязательно выполните создание БД перед запуском этого скрипта:
-- CREATE DATABASE KINO;
-- GO
-- USE KINO;
-- GO

-- Удаление таблиц (в обратном порядке зависимостей)
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS views;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS users;
GO

-- 1. Создание таблиц
-- Пользователи
CREATE TABLE users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username NVARCHAR(50) NOT NULL,
    email NVARCHAR(100) UNIQUE NOT NULL,
    birth_date DATE NULL, -- [NEW] Для проверки возраста
    balance DECIMAL(10, 2) DEFAULT 0.00, -- [NEW] Кошелек пользователя
    registration_date DATE NOT NULL,
    last_activity DATETIMEOFFSET NULL
);
GO

-- Жанры
CREATE TABLE genres (
    genre_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(50) NOT NULL,
    description NVARCHAR(500) NULL
);
GO

-- Фильмы
CREATE TABLE movies (
    movie_id INT PRIMARY KEY IDENTITY(1,1),
    title NVARCHAR(100) NOT NULL,
    genre_id INT FOREIGN KEY REFERENCES genres(genre_id),
    release_year INT,
    duration_min INT,
    rating DECIMAL(3, 1),
    min_age INT DEFAULT 0, -- [NEW] Возрастное ограничение (0, 6, 12, 16, 18)
    is_available BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- Подписки
CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES users(user_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    [plan] NVARCHAR(20) CHECK ([plan] IN ('basic', 'premium', 'family')),
    status NVARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    payment_method NVARCHAR(30) NULL, -- Оставим как инфо-поле, реальные транзакции в payments
    CONSTRAINT chk_dates CHECK (end_date >= start_date)
);
GO

-- [NEW] Платежи (История транзакций для Stored Procedures)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES users(user_id),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_date DATETIME2 DEFAULT SYSDATETIME(),
    status NVARCHAR(20) CHECK (status IN ('success', 'failed', 'pending')),
    description NVARCHAR(200) NULL -- Например: "Оплата подписки Premium"
);
GO

-- Просмотры
CREATE TABLE views (
    view_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES users(user_id),
    movie_id INT FOREIGN KEY REFERENCES movies(movie_id),
    watch_date DATETIME2 NOT NULL,
    watched_min INT NOT NULL,
    device_type NVARCHAR(50) NULL,
    CONSTRAINT chk_watched CHECK (watched_min >= 0)
);
GO

-- Отзывы
CREATE TABLE reviews (
    review_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY REFERENCES users(user_id),
    movie_id INT FOREIGN KEY REFERENCES movies(movie_id),
    user_rating TINYINT CHECK (user_rating BETWEEN 1 AND 10),
    review_text NVARCHAR(MAX) NULL,
    created_at DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- [NEW] Аудит (Для триггеров)
-- Таблица для логирования изменений важных данных
CREATE TABLE audit_logs (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    table_name NVARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    operation_type NVARCHAR(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    old_value NVARCHAR(MAX) NULL,
    new_value NVARCHAR(MAX) NULL,
    changed_at DATETIME2 DEFAULT SYSDATETIME(),
    changed_by NVARCHAR(50) DEFAULT SYSTEM_USER -- Кто менял (технический юзер SQL)
);
GO

-- 2. Наполнение данными

-- Жанры
INSERT INTO genres (name, description)
VALUES 
    (N'Фантастика', N'Фильмы о будущем и технологиях'),
    (N'Драма', N'Эмоциональные истории о людях'),
    (N'Комедия', N'Смешные и легкие фильмы'),
    (N'Боевик', N'Экшн и динамичные сцены'),
    (N'Ужасы', N'Страшные и напряженные фильмы'),
    (N'Мультфильм', N'Анимационные фильмы для всех возрастов');
GO

-- Фильмы (Добавлен min_age)
INSERT INTO movies (title, genre_id, release_year, duration_min, rating, min_age, is_available)
VALUES
    (N'Матрица', 1, 1999, 136, 8.7, 16, 1),
    (N'Крестный отец', 2, 1972, 175, 9.2, 16, 1),
    (N'Титаник', 2, 1997, 195, 7.8, 12, 1),
    (N'Мальчишник в Вегасе', 3, 2009, 100, 7.7, 18, 1), -- Только для взрослых
    (N'Джон Уик', 4, 2014, 101, 7.4, 16, 1),
    (N'Оно', 5, 2017, 135, 7.3, 18, 1),
    (N'Король Лев', 6, 1994, 88, 8.5, 0, 1), -- Для всех
    (N'Назад в будущее', 1, 1985, 116, 8.5, 6, 1),
    (N'Достать ножи', 3, 2019, 130, 7.9, 12, 1),
    (N'Чужой', 5, 1979, 117, 8.4, 16, 0),
    (N'Терминатор', 1, 1984, 107, 8.0, 16, 1),
    (N'Шрек', 6, 2001, 90, 8.2, 6, 1);
GO

-- Пользователи (Добавлены birth_date и balance)
INSERT INTO users (username, email, registration_date, last_activity, birth_date, balance)
VALUES
    (N'ivan_ivanov', 'ivan@mail.com', '2023-01-15', '2023-11-05 18:00:00 +03:00', '1990-05-15', 1500.00), -- Взрослый, есть деньги
    (N'anna_smith', 'anna@mail.com', '2023-02-20', '2023-11-10 20:30:00 -05:00', '1995-10-20', 0.00),
    (N'max_petrov', 'max@mail.com', '2023-03-10', '2023-10-15 09:00:00 +03:00', '2005-03-10', 500.00), -- 18 лет исполнилось в 2023
    (N'olga_kuz', 'olga@mail.com', '2023-04-05', NULL, '1988-12-05', 200.00),
    (N'alex_brown', 'alex@mail.com', '2023-05-12', '2023-11-20 22:15:00 +01:00', '2010-06-01', 1000.00), -- Ребенок (13 лет), деньги есть
    (N'sophia_lee', 'sophia@mail.com', '2023-06-18', '2023-11-21 10:00:00 +09:00', '1992-09-18', 3000.00),
    (N'dmitry_volk', 'dmitry@mail.com', '2023-07-22', '2023-09-01 14:20:00 +03:00', '1985-07-22', 0.00),
    (N'elena_sun', 'elena@mail.com', '2023-08-30', '2023-11-18 19:45:00 +04:00', '1999-11-30', 100.00),
    (N'pavel_gorn', 'pavel@mail.com', '2023-09-14', NULL, '2015-02-14', 50.00), -- Ребенок (8 лет)
    (N'marina_blue', 'marina@mail.com', '2023-10-25', '2023-11-22 08:30:00 +03:00', '1998-04-25', 5000.00),
    (N'ghost_user', 'ghost@nomail.com', '2023-11-01', NULL, '1990-01-01', 0.00),
    (N'newbie_no_sub', 'new@mail.com', '2023-11-20', '2023-11-20 10:00:00 +00:00', '2000-01-01', 10000.00); -- Богат, но без подписки
GO

-- Подписки
INSERT INTO subscriptions (user_id, start_date, end_date, [plan], payment_method, status)
VALUES
    (1, '2023-01-15', '2023-04-15', 'basic', 'credit_card', 'expired'),
    (1, '2023-05-01', '2024-05-01', 'premium', 'credit_card', 'active'),
    (2, '2023-02-20', '2023-05-20', 'basic', 'paypal', 'expired'),
    (3, '2023-03-10', '2023-06-10', 'family', 'credit_card', 'cancelled'),
    (4, '2023-04-05', '2023-07-05', 'premium', 'crypto', 'expired'),
    (5, '2023-05-12', '2023-08-12', 'basic', 'credit_card', 'expired'),
    (6, '2023-06-18', '2023-09-18', 'premium', 'paypal', 'expired'),
    (6, '2023-10-01', '2024-10-01', 'family', 'paypal', 'active'),
    (7, '2023-07-22', '2023-10-22', 'family', 'credit_card', 'expired'),
    (8, '2023-08-30', '2023-11-30', 'basic', 'paypal', 'active'),
    (9, '2023-09-14', '2023-12-14', 'premium', 'crypto', 'active'),
    (10, '2023-10-25', '2024-01-25', 'family', 'credit_card', 'active');
GO

-- Платежи (Примеры пополнений и оплат)
INSERT INTO payments (user_id, amount, payment_date, status, description)
VALUES
    (1, 1000.00, '2023-01-15T10:00:00', 'success', N'Пополнение баланса'),
    (1, 300.00, '2023-01-15T10:05:00', 'success', N'Оплата подписки Basic'),
    (5, 500.00, '2023-05-12T09:00:00', 'failed', N'Ошибка банка'), -- Неудачный платеж
    (6, 2000.00, '2023-06-18T12:00:00', 'success', N'Пополнение баланса'),
    (12, 10000.00, '2023-11-20T09:00:00', 'success', N'Крупное пополнение');
GO

-- Просмотры
INSERT INTO views (user_id, movie_id, watch_date, watched_min, device_type)
VALUES
    (1, 1, '2023-01-20T19:00:00', 136, 'smart_tv'),
    (1, 1, '2023-02-10T15:00:00', 30, 'mobile'),
    (1, 2, '2023-01-25T20:30:00', 10, 'mobile'),
    (2, 3, '2023-02-22T18:45:00', 195, 'desktop'),
    (3, 5, '2023-03-15T21:10:00', 101, 'smart_tv'),
    (12, 1, '2023-11-20T11:00:00', 0, 'mobile'),
    (5, 8, '2023-05-18T22:00:00', 116, 'mobile'), -- Юзеру 5 (Alex Brown, 2010 г.р.) 13 лет. Смотрит "Назад в будущее" (6+). ОК.
    (5, 1, '2023-05-19T22:00:00', 10, 'mobile'), -- Тот же ребенок пытается смотреть "Матрицу" (16+). Вот кейс для триггера!
    (6, 10, '2023-06-25T23:30:00', 117, 'desktop'),
    (8, 4, '2023-08-05T20:00:00', 100, 'tablet'),
    (9, 6, '2023-09-12T21:45:00', 135, 'mobile'),
    (10, 9, '2023-10-28T19:30:00', 130, 'desktop'),
    (1, 11, '2023-11-01T18:00:00', 107, 'smart_tv'),
    (3, 3, '2023-11-10T19:20:00', 90, 'tablet'),
    (4, 5, '2023-11-15T22:10:00', 50, 'desktop');
GO

-- Отзывы
INSERT INTO reviews (user_id, movie_id, user_rating, review_text)
VALUES
    (1, 1, 10, N'Шедевр киберпанка!'),
    (1, 2, 9, N'Классика, но немного затянуто'),
    (2, 3, 8, NULL),
    (3, 5, 6, N'Ожидал большего от боевика'),
    (5, 8, 10, N'Лучший фильм о путешествиях во времени'),
    (6, 10, 10, N'В космосе никто не услышит твой крик...'),
    (10, 9, 7, N'Интересный сюжет, но концовка странная');
GO

-- 3. Индексы
CREATE INDEX idx_movies_genre ON movies(genre_id);
CREATE INDEX idx_views_user ON views(user_id);
CREATE INDEX idx_views_movie ON views(movie_id);
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_reviews_movie ON reviews(movie_id);
CREATE INDEX idx_payments_user ON payments(user_id);
GO
