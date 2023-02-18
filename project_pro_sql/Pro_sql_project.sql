--1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».

SELECT COUNT(*)
FROM stackoverflow.posts p
JOIN stackoverflow.post_types pt ON p.post_type_id = pt.id
WHERE pt.type = 'Question' AND
      (p.score > 300 OR p.favorites_count >= 100)
      
-- 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
      
WITH q AS (
SELECT COUNT(*) AS cnt
FROM stackoverflow.posts p
JOIN stackoverflow.post_types pt ON p.post_type_id = pt.id
WHERE pt.type ='Question'  AND
      p.creation_date::date BETWEEN '2008-11-1' AND '2008-11-18')
      
-- 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.

SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.users u
JOIN stackoverflow.badges b ON u.id = b.user_id
WHERE u.creation_date::date = b.creation_date::date

-- 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

SELECT COUNT(DISTINCT q.id)
FROM (SELECT p.id
     FROM stackoverflow.posts p
     JOIN stackoverflow.votes v ON p.id = v.post_id
     JOIN stackoverflow.users u ON p.user_id = u.id
     WHERE u.display_name LIKE 'Joel Coehoorn' AND
           v.id >= 1
     GROUP BY p.id) AS q
     
/* 5. 
Выгрузите все поля таблицы vote_types. 
Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.
*/

SELECT *,
       RANK() OVER (ORDER BY vt.id DESC)
FROM stackoverflow.vote_types vt
ORDER BY vt.id

/* 6. 
Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
*/

SELECT DISTINCT v.user_id,
       COUNT(v.user_id) OVER (PARTITION BY v.user_id)
FROM stackoverflow.votes v
JOIN stackoverflow.vote_types vt ON v.vote_type_id = vt.id
WHERE vt.name = 'Close'
ORDER BY 2 DESC, 1 DESC
LIMIT 10;

/* 7. 
Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
*/

WITH q AS(
SELECT DISTINCT b.user_id,
       COUNT(b.id) OVER (PARTITION BY b.user_id) AS cnt
FROM stackoverflow.badges b
WHERE b.creation_date::date BETWEEN '2008-11-15' AND '2008-12-15')

SELECT *,
       DENSE_RANK() OVER (ORDER BY cnt DESC)
FROM q
ORDER BY cnt DESC, user_id
LIMIT 10;

/* 8. 
Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
*/

SELECT p.title,
       p.user_id,
       p.score,
       ROUND(AVG(p.score) OVER (PARTITION BY p.user_id))
FROM stackoverflow.posts p
WHERE p.title NOT LIKE '' AND p.score != 0

/* 9. 
Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список.
*/

SELECT p.title
FROM stackoverflow.posts p
WHERE p.user_id IN (SELECT b.user_id
                    FROM stackoverflow.badges b
                    GROUP BY b.user_id
                    HAVING COUNT(b.id) > 1000) AND
                    p.title NOT LIKE ''

/* 10. 
Напишите запрос, который выгрузит данные о пользователях из США (англ. United States). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.
*/               

SELECT u.id,
       u.views,
       CASE
           WHEN u.views >= 350 THEN 1
           WHEN u.views < 350 AND u.views >= 100 THEN 2
           WHEN u.views < 100 THEN 3
       END
FROM stackoverflow.users u
WHERE u.location LIKE '%United States%' AND u.views > 0

/* 11. 
Дополните предыдущий запрос. 
Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
*/


WITH gr AS (
SELECT u.id,
       u.views,
       CASE
           WHEN u.views >= 350 THEN 1
           WHEN u.views < 350 AND u.views >= 100 THEN 2
           WHEN u.views < 100 THEN 3
       END
FROM stackoverflow.users u
WHERE u.location LIKE '%United States%' AND u.views > 0),
q AS(
SELECT gr.id,
       gr.views,
       gr.case,
       MAX(gr.views) OVER (PARTITION BY gr.case)
FROM gr
ORDER BY gr.views DESC, gr.id)

SELECT q.id,
       q.views,
       q.case
FROM q
WHERE q.views = q.max

/* 12. 
Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением. 
*/

WITH q AS (
SELECT EXTRACT('DAY' FROM u.creation_date::date) AS nday,
       COUNT(u.id) AS cnt
FROM stackoverflow.users u
WHERE u.creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY EXTRACT('DAY' FROM u.creation_date::date))

SELECT q.nday,
       q.cnt,
       SUM(q.cnt) OVER (ORDER BY q.nday)
FROM q

/* 13. 
Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.
*/

WITH q AS (
SELECT DISTINCT p.user_id,
       MIN(p.creation_date) OVER (PARTITION BY p.user_id) AS min_dt
FROM stackoverflow.posts p)

SELECT q.user_id,
      ( q.min_dt - u.creation_date) AS diff
FROM q
JOIN stackoverflow.users u ON q.user_id = u.id

-- Часть 2.

/* 1. 
Выведите общую сумму просмотров постов за каждый месяц 2008 года. 
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
Результат отсортируйте по убыванию общего количества просмотров.
*/

SELECT DATE_TRUNC('month', p.creation_date)::date AS month_date,
       SUM(p.views_count)
FROM stackoverflow.posts p
GROUP BY month_date
ORDER BY 2 DESC

/* 2.
Выведите имена самых активных пользователей, которые в первый месяц после регистрации 
(включая день регистрации) дали больше 100 ответов. 
Вопросы, которые задавали пользователи, не учитывайте. 
Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке. 
*/

SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id =u.id
JOIN stackoverflow.post_types pt ON p.post_type_id = pt.id
WHERE pt.type LIKE '%Answer%' AND
      (p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month'))
GROUP BY u.display_name
HAVING COUNT(p.id) > 100
ORDER BY u.display_name

/* 3.
Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, 
которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
Отсортируйте таблицу по значению месяца по убыванию.
*/

WITH users_id AS (
SELECT u.id
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id = u.id
WHERE DATE_TRUNC('month', u.creation_date)::date = '2008-09-01'
      AND DATE_TRUNC('month', p.creation_date)::date = '2008-12-01'
GROUP BY u.id
HAVING COUNT(p.id) > 0)

SELECT DATE_TRUNC('month', p.creation_date)::date,
       COUNT(p.id)
FROM stackoverflow.posts p
WHERE p.user_id IN (SELECT *
                   FROM users_id)
GROUP BY DATE_TRUNC('month', p.creation_date)::date
ORDER BY DATE_TRUNC('month', p.creation_date)::date DESC

/* 4.
Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, 
а данные об одном и том же пользователе — по возрастанию даты создания поста.
*/

SELECT p.user_id,
       p.creation_date,
       p.views_count,
       SUM(views_count) OVER (PARTITION BY p.user_id ORDER BY p.creation_date)
FROM stackoverflow.posts p

/* 5.
Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
Нужно получить одно целое число — не забудьте округлить результат. 
*/

WITH q AS (
SELECT p.user_id,
       COUNT(DISTINCT p.creation_date::date) AS cnt
FROM stackoverflow.posts p
WHERE p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-07' 
GROUP BY p.user_id)

SELECT ROUND(AVG(cnt))
FROM q

/* 6.
На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
номер месяца;
количество постов за месяц;
процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, 
округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.
*/

WITH q AS (
SELECT EXTRACT('MONTH' FROM p.creation_date::date) AS nmon,
       COUNT(DISTINCT p.id) AS cnt
FROM stackoverflow.posts p
WHERE p.creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
GROUP BY EXTRACT('MONTH' FROM p.creation_date::date))


SELECT *,
       ROUND((cnt::numeric / LAG(cnt) OVER (ORDER BY nmon) - 1) * 100.0, 2)
FROM q

/* 7.
Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время. 
Выведите данные за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.
*/

WITH top_user AS (
SELECT p.user_id,
       COUNT(DISTINCT p.id) AS cnt
FROM stackoverflow.posts p
GROUP BY p.user_id
ORDER BY COUNT(DISTINCT p.id) DESC
LIMIT 1),
q AS (
SELECT p.user_id,
       p.creation_date,
    EXTRACT('WEEK' FROM p.creation_date) AS week_number
FROM stackoverflow.posts p
JOIN top_user tu USING(user_id)
WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01')

SELECT DISTINCT week_number::numeric,
       MAX(creation_date) OVER (PARTITION BY week_number) AS post_dt
FROM q
ORDER BY week_number;
































