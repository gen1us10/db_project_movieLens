CREATE DATABASE MovieLens_DB;

CREATE SCHEMA MovieLens_DB.staging;

USE SCHEMA MovieLens_DB.staging;

-- Table age_group (staging)
CREATE TABLE age_group_staging (
    id INT PRIMARY KEY,
    name VARCHAR(45)
);

-- Table occupations (staging)
CREATE TABLE occupations_staging (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

-- Table users (staging)
CREATE OR REPLACE TABLE users_staging (
    id INT PRIMARY KEY,
    age INT,
    gender CHAR(1),
    occupation_id INT,
    zip_code VARCHAR(255),
    FOREIGN KEY (occupation_id) REFERENCES occupations_staging(id),
    FOREIGN KEY (age) REFERENCES age_group_staging(id)
);

-- Table movies (staging)
CREATE TABLE movies_staging (
    id INT PRIMARY KEY,
    title VARCHAR(255),
    release_year CHAR(4)
);

-- Table genres (staging)
CREATE TABLE genres_staging (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

-- Table genres_movies (staging)
CREATE TABLE genres_movies_staging (
    id INT PRIMARY KEY,
    movie_id INT,
    genre_id INT,
    FOREIGN KEY (movie_id) REFERENCES movies_staging(id),
    FOREIGN KEY (genre_id) REFERENCES genres_staging(id)
);

-- Table ratings (staging)
CREATE TABLE ratings_staging (
    id INT PRIMARY KEY,
    user_id INT,
    movie_id INT,
    rating INT,
    rated_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users_staging(id),
    FOREIGN KEY (movie_id) REFERENCES movies_staging(id)
);

-- Table tags (staging)
CREATE TABLE tags_staging (
    id INT PRIMARY KEY,
    user_id INT,
    movie_id INT,
    tags VARCHAR(4000),
    created_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users_staging(id),
    FOREIGN KEY (movie_id) REFERENCES movies_staging(id)
);

-- Creating a stage for data loading
CREATE OR REPLACE STAGE my_stage;

-- Creating my_stage for .csv files
COPY INTO age_group_staging
FROM @my_stage/age_group.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO occupations_staging
FROM @my_stage/occupations.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO users_staging
FROM @my_stage/users.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO movies_staging
FROM @my_stage/movies.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO genres_staging
FROM @my_stage/genres.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO genres_movies_staging
FROM @my_stage/genres_movies.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO ratings_staging
FROM @my_stage/ratings.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO tags_staging
FROM @my_stage/tags.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' FIELD_DELIMITER = ',' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';



-- dim_users
-- dim_users
CREATE TABLE dim_users AS
SELECT DISTINCT
    u.id AS dim_userId,
    CASE 
        WHEN u.age < 18 THEN 'Under 18'
        WHEN u.age BETWEEN 18 AND 24 THEN '18-24'
        WHEN u.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN u.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN u.age BETWEEN 45 AND 54 THEN '45-54'
        WHEN u.age >= 55 THEN '55+'
        ELSE 'Unknown'
    END AS age_group,
    u.gender AS gender,
    o.name AS occupation_name
FROM users_staging u
JOIN occupations_staging o ON u.occupation_id = o.id; 

-- dim_movies
CREATE TABLE dim_movies AS
SELECT DISTINCT
    m.id AS dim_movieId, 
    m.title AS title,
    m.release_year AS release_year
FROM movies_staging m;

-- dim_genres
CREATE TABLE dim_genres AS
SELECT DISTINCT
    g.id AS dim_genreId, 
    g.name AS genre_name
FROM genres_staging g;

-- dim_date
CREATE TABLE dim_date AS
SELECT DISTINCT
    DATE(r.rated_at) AS dim_date,
    EXTRACT(YEAR FROM r.rated_at) AS year,
    EXTRACT(MONTH FROM r.rated_at) AS month,
    EXTRACT(DAY FROM r.rated_at) AS day,
    EXTRACT(DOW FROM r.rated_at) AS day_of_week,
    EXTRACT(WEEK FROM r.rated_at) AS week
FROM ratings_staging r;

-- dim_time
CREATE TABLE dim_time AS
SELECT DISTINCT
    EXTRACT(HOUR FROM r.rated_at) AS hour,
    EXTRACT(MINUTE FROM r.rated_at) AS minute,
    EXTRACT(SECOND FROM r.rated_at) AS second
FROM ratings_staging r;

-- fact_ratings
CREATE TABLE fact_ratings AS
SELECT
    r.id AS fact_rating_id, 
    r.user_id AS user_id,
    r.movie_id AS movie_id,
    gm.genre_id AS genre_id,  
    DATE(r.rated_at) AS date_id,
    EXTRACT(HOUR FROM r.rated_at) AS time_id,
    r.rating AS rating_value
FROM ratings_staging r
JOIN genres_movies_staging gm ON r.movie_id = gm.movie_id;

-- DROP staging tables
DROP TABLE IF EXISTS users_staging;
DROP TABLE IF EXISTS movies_staging;
DROP TABLE IF EXISTS genres_staging;
DROP TABLE IF EXISTS ratings_staging;
DROP TABLE IF EXISTS occupations_staging;


