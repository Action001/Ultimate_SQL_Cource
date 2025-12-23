-- Удаление таблиц (в обратном порядке зависимостей)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS views CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS movies CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Создание таблиц

-- Пользователи
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    birth_date DATE NULL, -- Для проверки возраста
    balance NUMERIC(10, 2) DEFAULT 0.00, -- Кошелек пользователя
    registration_date DATE NOT NULL,
    last_activity TIMESTAMPTZ NULL -- TIMESTAMPTZ = TIMESTAMP WITH TIME ZONE
);

-- Жанры
CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(500) NULL
);

-- Фильмы
CREATE TABLE movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    genre_id INT REFERENCES genres(genre_id),
    release_year INT,
    duration_min INT,
    rating NUMERIC(3, 1),
    min_age INT DEFAULT 0, -- Возрастное ограничение (0, 6, 12, 16, 18)
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Подписки
CREATE TABLE subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    plan VARCHAR(20) CHECK (plan IN ('basic', 'premium', 'family')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    payment_method VARCHAR(30) NULL,
    CONSTRAINT chk_dates CHECK (end_date >= start_date)
);

-- Платежи
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('success', 'failed', 'pending')),
    description VARCHAR(200) NULL
);

-- Просмотры
CREATE TABLE views (
    view_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    movie_id INT REFERENCES movies(movie_id),
    watch_date TIMESTAMPTZ NOT NULL,
    watched_min INT NOT NULL,
    device_type VARCHAR(50) NULL,
    CONSTRAINT chk_watched CHECK (watched_min >= 0)
);

-- Отзывы
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    movie_id INT REFERENCES movies(movie_id),
    user_rating SMALLINT CHECK (user_rating BETWEEN 1 AND 10),
    review_text TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Аудит
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    operation_type VARCHAR(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    old_value TEXT NULL,
    new_value TEXT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50) DEFAULT CURRENT_USER
);

-- 2. Наполнение данными

-- Жанры
INSERT INTO genres (name, description)
VALUES 
    ('Фантастика', 'Фильмы о будущем и технологиях'),
    ('Драма', 'Эмоциональные истории о людях'),
    ('Комедия', 'Смешные и легкие фильмы'),
    ('Боевик', 'Экшн и динамичные сцены'),
    ('Ужасы', 'Страшные и напряженные фильмы'),
    ('Мультфильм', 'Анимационные фильмы для всех возрастов');

-- Фильмы
INSERT INTO movies (title, genre_id, release_year, duration_min, rating, min_age, is_available)
VALUES
    ('Матрица', 1, 1999, 136, 8.7, 16, TRUE),
    ('Крестный отец', 2, 1972, 175, 9.2, 16, TRUE),
    ('Титаник', 2, 1997, 195, 7.8, 12, TRUE),
    ('Мальчишник в Вегасе', 3, 2009, 100, 7.7, 18, TRUE),
    ('Джон Уик', 4, 2014, 101, 7.4, 16, TRUE),
    ('Оно', 5, 2017, 135, 7.3, 18, TRUE),
    ('Король Лев', 6, 1994, 88, 8.5, 0, TRUE),
    ('Назад в будущее', 1, 1985, 116, 8.5, 6, TRUE),
    ('Достать ножи', 3, 2019, 130, 7.9, 12, TRUE),
    ('Чужой', 5, 1979, 117, 8.4, 16, FALSE),
    ('Терминатор', 1, 1984, 107, 8.0, 16, TRUE),
    ('Шрек', 6, 2001, 90, 8.2, 6, TRUE);

-- Пользователи
-- Обратите внимание: формат даты 'YYYY-MM-DD', формат timestamp с зоной 'YYYY-MM-DD HH:MM:SS+TZ'
INSERT INTO users (username, email, registration_date, last_activity, birth_date, balance)
VALUES
    ('ivan_ivanov', 'ivan@mail.com', '2023-01-15', '2023-11-05 18:00:00+03', '1990-05-15', 1500.00),
    ('anna_smith', 'anna@mail.com', '2023-02-20', '2023-11-10 20:30:00-05', '1995-10-20', 0.00),
    ('max_petrov', 'max@mail.com', '2023-03-10', '2023-10-15 09:00:00+03', '2005-03-10', 500.00),
    ('olga_kuz', 'olga@mail.com', '2023-04-05', NULL, '1988-12-05', 200.00),
    ('alex_brown', 'alex@mail.com', '2023-05-12', '2023-11-20 22:15:00+01', '2010-06-01', 1000.00),
    ('sophia_lee', 'sophia@mail.com', '2023-06-18', '2023-11-21 10:00:00+09', '1992-09-18', 3000.00),
    ('dmitry_volk', 'dmitry@mail.com', '2023-07-22', '2023-09-01 14:20:00+03', '1985-07-22', 0.00),
    ('elena_sun', 'elena@mail.com', '2023-08-30', '2023-11-18 19:45:00+04', '1999-11-30', 100.00),
    ('pavel_gorn', 'pavel@mail.com', '2023-09-14', NULL, '2015-02-14', 50.00),
    ('marina_blue', 'marina@mail.com', '2023-10-25', '2023-11-22 08:30:00+03', '1998-04-25', 5000.00),
    ('ghost_user', 'ghost@nomail.com', '2023-11-01', NULL, '1990-01-01', 0.00),
    ('newbie_no_sub', 'new@mail.com', '2023-11-20', '2023-11-20 10:00:00+00', '2000-01-01', 10000.00);

-- Подписки
INSERT INTO subscriptions (user_id, start_date, end_date, plan, payment_method, status)
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

-- Платежи
INSERT INTO payments (user_id, amount, payment_date, status, description)
VALUES
    (1, 1000.00, '2023-01-15 10:00:00', 'success', 'Пополнение баланса'),
    (1, 300.00, '2023-01-15 10:05:00', 'success', 'Оплата подписки Basic'),
    (5, 500.00, '2023-05-12 09:00:00', 'failed', 'Ошибка банка'),
    (6, 2000.00, '2023-06-18 12:00:00', 'success', 'Пополнение баланса'),
    (12, 10000.00, '2023-11-20 09:00:00', 'success', 'Крупное пополнение');

-- Просмотры
INSERT INTO views (user_id, movie_id, watch_date, watched_min, device_type)
VALUES
    (1, 1, '2023-01-20 19:00:00', 136, 'smart_tv'),
    (1, 1, '2023-02-10 15:00:00', 30, 'mobile'),
    (1, 2, '2023-01-25 20:30:00', 10, 'mobile'),
    (2, 3, '2023-02-22 18:45:00', 195, 'desktop'),
    (3, 5, '2023-03-15 21:10:00', 101, 'smart_tv'),
    (12, 1, '2023-11-20 11:00:00', 0, 'mobile'),
    (5, 8, '2023-05-18 22:00:00', 116, 'mobile'),
    (5, 1, '2023-05-19 22:00:00', 10, 'mobile'),
    (6, 10, '2023-06-25 23:30:00', 117, 'desktop'),
    (8, 4, '2023-08-05 20:00:00', 100, 'tablet'),
    (9, 6, '2023-09-12 21:45:00', 135, 'mobile'),
    (10, 9, '2023-10-28 19:30:00', 130, 'desktop'),
    (1, 11, '2023-11-01 18:00:00', 107, 'smart_tv'),
    (3, 3, '2023-11-10 19:20:00', 90, 'tablet'),
    (4, 5, '2023-11-15 22:10:00', 50, 'desktop');

-- Отзывы
INSERT INTO reviews (user_id, movie_id, user_rating, review_text)
VALUES
    (1, 1, 10, 'Шедевр киберпанка!'),
    (1, 2, 9, 'Классика, но немного затянуто'),
    (2, 3, 8, NULL),
    (3, 5, 6, 'Ожидал большего от боевика'),
    (5, 8, 10, 'Лучший фильм о путешествиях во времени'),
    (6, 10, 10, 'В космосе никто не услышит твой крик...'),
    (10, 9, 7, 'Интересный сюжет, но концовка странная');

-- 3. Индексы
CREATE INDEX idx_movies_genre ON movies(genre_id);
CREATE INDEX idx_views_user ON views(user_id);
CREATE INDEX idx_views_movie ON views(movie_id);
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_reviews_movie ON reviews(movie_id);
CREATE INDEX idx_payments_user ON payments(user_id);

