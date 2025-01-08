-- Graf 1: Zoznam filmov s najvyšším priemerným hodnotením a počtom hodnotení. (top 30)
SELECT 
    dim_movies.title,
    AVG(fact_ratings.rating_value) AS avg_rating,
    COUNT(fact_ratings.rating_value) AS total_ratings
FROM fact_ratings
JOIN dim_movies ON fact_ratings.movie_id = dim_movies.dim_movieId
GROUP BY dim_movies.title
ORDER BY avg_rating DESC, total_ratings DESC
LIMIT 30;

-- Graf 2: Priemerné skóre podľa vekovej skupiny
SELECT u.age_group, AVG(r.rating_value) AS avg_rating
FROM fact_ratings r
JOIN dim_users u ON r.user_id = u.dim_userId
GROUP BY u.age_group
ORDER BY avg_rating DESC;

-- Graf 3: Popularita filmov podľa roku vydania
SELECT m.release_year, COUNT(r.fact_rating_id) AS num_ratings
FROM fact_ratings r
JOIN dim_movies m ON r.movie_id = m.dim_movieId
GROUP BY m.release_year
ORDER BY num_ratings DESC;

-- Graf 4: Najobľúbenejšie značky podľa žánru
SELECT t.tags, g.genre_name, COUNT(t.id) AS num_tags
FROM tags_staging t
JOIN genres_movies_staging gm ON t.movie_id = gm.movie_id
JOIN dim_genres g ON gm.genre_id = g.dim_genreId
GROUP BY t.tags, g.genre_name
ORDER BY num_tags DESC;

-- Graf 5: Aké žánre preferujú muži a ženy
SELECT u.gender, g.genre_name, COUNT(r.fact_rating_id) AS num_ratings
FROM fact_ratings r
JOIN dim_users u ON r.user_id = u.dim_userId
JOIN dim_genres g ON r.genre_id = g.dim_genreId
GROUP BY u.gender, g.genre_name
ORDER BY u.gender, num_ratings DESC;

