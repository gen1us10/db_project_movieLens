# **ETL proces datasetu MovieLens**

Táto implementácia ETL procesu v Snowflake slúži na analýzu dát z MovieLens datasetu, pričom sa zameriava na skúmanie správania používateľov a ich preferencií na základe hodnotení filmov a demografických údajov. Cieľom je vytvoriť dátový model, ktorý umožní multidimenzionálnu analýzu a vizualizáciu kľúčových metrík."

---
## **1. Úvod a popis zdrojových dát**
Cieľom tohto projektu je analyzovať dáta týkajúce sa filmov, používateľov a ich hodnotení. Táto analýza umožňuje identifikovať trendy v preferenciách používateľov, najpopulárnejšie filmy a vzorce správania.
Zdrojové dáta pochádzajú z MovieLens datasetu dostupného [tu](https://grouplens.org/datasets/movielens/). Dataset obsahuje päť hlavných tabuliek:
- `movies`
- `ratings`
- `users`
- `genres`
- `occupations`

Účelom ETL procesu je tieto dáta pripraviť, transformovať a sprístupniť pre multidimenzionálnu analýzu.

---
### **1.1 Dátová architektúra**

### **ERD diagram**
Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na **entitno-relačnom diagrame (ERD)**:

<p align="center">
  <img src="https://github.com/gen1us10/db_project_movieLens/blob/main/MovieLens_ERD.png" alt="ERD Schema">
  <br>
  <em>Obrázok 1 Entitno-relačná schéma MovieLens</em>
</p>

---
## **2 Dimenzionálny model**

Navrhnutý bol **hviezdicový model (star schema)**, pre efektívnu analýzu kde centrálny bod predstavuje faktová tabuľka **`fact_ratings`**, ktorá je prepojená s nasledujúcimi dimenziami:
- **`dim_movies`**: Obsahuje podrobné informácie o filmoch (názov, rok vydania)
- **`dim_users`**: Obsahuje demografické informácie o používateľoch, napríklad vekovú skupinu, pohlavie a povolanie.
- **`dim_genres`**: Zoznamy rôznych filmových žánrov.
- **`dim_date`**: Zahrňuje informácie o dátumoch hodnotení (deň, mesiac, rok, štvrťrok).
- **`dim_time`**: Obsahuje podrobné časové údaje (hodina, AM/PM).

Štruktúra hviezdicovej schémy je znázornená na nasledujúcom obrázku. Schéma zobrazuje vzťahy medzi tabuľkou faktov a dimenziami, čím zjednodušuje pochopenie a implementáciu modelu.

<p align="center">
  <img src="https://github.com/gen1us10/db_project_movieLens/blob/main/star_schema.png" alt="Star Schema">
  <br>
  <em>Obrázok 2 Schéma hviezdy pre MovieLens</em>
</p>

---
## **3. ETL proces v Snowflake**
ETL proces pozostával z troch hlavných fáz: `extrahovanie` (Extract), `transformácia` (Transform) a `načítanie` (Load). Tento proces bol implementovaný v Snowflake s cieľom pripraviť zdrojové dáta zo staging vrstvy do viacdimenzionálneho modelu vhodného na analýzu a vizualizáciu.

---
### **3.1 Extract (Extrahovanie dát)**
Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do Snowflake prostredníctvom interného stage úložiska s názvom `my_stage`. Stage v Snowflake slúži ako dočasné úložisko na import alebo export dát. Vytvorenie stage bolo zabezpečené príkazom:

#### Príklad kódu:
```sql
CREATE OR REPLACE STAGE my_stage;
```
Do stage boli následne nahraté súbory obsahujúce údaje o používateľoch, filmoch, hodnoteniach, žánroch a iných entitách. Dáta boli importované do staging tabuliek pomocou príkazu COPY INTO. Pre každú tabuľku sa použil podobný príkaz:

```sql
COPY INTO users_staging
FROM @my_stage/users.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```

V prípade nekonzistentných záznamov bol použitý parameter ON_ERROR = 'CONTINUE', ktorý zabezpečil pokračovanie procesu bez prerušenia pri chybách.

---
### **3.2 Transfor (Transformácia dát)**
Transformácia dát bola kľúčovou fázou, v ktorej sa staging dáta vyčistili, obohatili a transformovali do štruktúry vhodnej pre viacdimenzionálny model. Tento model je typu "hviezda" a pozostáva z faktovej tabuľky a dimenzií.
**Dimenzia `dim_users`**
Tabuľka  `dim_users` obsahuje údaje o používateľoch, ako sú veková skupina, pohlavie a povolanie. Na základe veku boli používateľom priradené kategórie:
```sql
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
```
**Dimenzia `dim_users`**
Tabuľka  `dim_movies` obsahuje informácie o filmoch, vrátane názvu a roku vydania:
```sql
CREATE TABLE dim_movies AS
SELECT DISTINCT
    m.id AS dim_movieId, 
    m.title AS title,
    m.release_year AS release_year
FROM movies_staging m;
```
**Dimenzia `dim_genres`**
Tabuľka  `dim_genres` obsahuje informácie o filmoch, vrátane názvu a roku vydania:
```sql
CREATE TABLE dim_genres AS
SELECT DISTINCT
    g.id AS dim_genreId, 
    g.name AS genre_name
FROM genres_staging g;
```
**Dimenzia `dim_date`**
Tabuľka  `dim_date` je navrhnutá tak, aby umožňovala podrobnú časovú analýzu. Obsahuje informácie o dátumoch hodnotení, vrátane dňa, mesiaca, roku a týždňa:
```sql
CREATE TABLE dim_date AS
SELECT DISTINCT
    DATE(r.rated_at) AS dim_date,
    EXTRACT(YEAR FROM r.rated_at) AS year,
    EXTRACT(MONTH FROM r.rated_at) AS month,
    EXTRACT(DAY FROM r.rated_at) AS day,
    EXTRACT(DOW FROM r.rated_at) AS day_of_week,
    EXTRACT(WEEK FROM r.rated_at) AS week
FROM ratings_staging r;
```
**Dimenzia `dim_time`**
Dimenzia `dim_time` obsahuje detailné časové údaje, ako sú hodiny, minúty a sekundy:
```sql
CREATE TABLE dim_time AS
SELECT DISTINCT
    EXTRACT(HOUR FROM r.rated_at) AS hour,
    EXTRACT(MINUTE FROM r.rated_at) AS minute,
    EXTRACT(SECOND FROM r.rated_at) AS second
FROM ratings_staging r;
```
**Faktová tabuľka `fact_ratings`**
Tabuľka  `fact_ratings` obsahuje záznamy o hodnoteniach používateľov, prepojenia na všetky dimenzie a kľúčové metriky, ako je hodnota hodnotenia:
```sql
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
```
---
### **3.3 Load (Načítanie dát)**
Po úspešnom vytvorení dimenzií a faktovej tabuľky boli staging tabuľky odstránené, aby sa optimalizovalo využitie úložiska:
```sql
DROP TABLE IF EXISTS users_staging;
DROP TABLE IF EXISTS movies_staging;
DROP TABLE IF EXISTS genres_staging;
DROP TABLE IF EXISTS ratings_staging;
DROP TABLE IF EXISTS occupations_staging;
```
ETL proces v Snowflake umožnil transformáciu pôvodných dát zo .csv formátu do viacdimenzionálneho modelu typu hviezda. Tento model podporuje analýzu používateľských preferencií a hodnotení filmov, pričom 
poskytuje základ pre vizualizácie a reporty.

---
### **4 Vizualizácia dát**

Dashboard obsahuje `5 vizualizácií`, ktoré poskytujú základný prehľad o kľúčových metrikách a trendoch týkajúcich sa filmov, používateľov a hodnotení. Tieto vizualizácie odpovedajú na dôležité otázky a umožňujú lepšie pochopiť správanie používateľov a ich preferencie.

<p align="center">
  <img src="https://github.com/gen1us10/db_project_movieLens/blob/main/movielens_dashboard.png" alt="ERD Schema">
  <br>
  <em>Obrázok 3 Dashboard MovieLens datasetu</em>
</p>

---
### **Graf 1: Filmy s najvyšším priemerným hodnotením a počtom hodnotení (Top 30)**
Táto vizualizácia zobrazuje 30 filmov s najvyšším priemerným hodnotením a počtom hodnotení. Poskytuje prehľad o najkvalitnejších a najobľúbenejších filmoch podľa používateľských recenzií. Tieto informácie môžu byť využité na odporúčanie filmov pre konkrétne cieľové skupiny.
```sql
SELECT 
    dim_movies.title,
    AVG(fact_ratings.rating_value) AS avg_rating,
    COUNT(fact_ratings.rating_value) AS total_ratings
FROM fact_ratings
JOIN dim_movies ON fact_ratings.movie_id = dim_movies.dim_movieId
GROUP BY dim_movies.title
ORDER BY avg_rating DESC, total_ratings DESC
LIMIT 30;
```
---
### **Graf 2: Priemerné skóre podľa vekovej skupiny**
Graf znázorňuje, ako sa priemerné hodnotenie filmov líši podľa vekových skupín používateľov. Tieto údaje pomáhajú lepšie pochopiť preferencie rôznych vekových kategórií a prispôsobiť obsah podľa ich preferencií.

```sql
SELECT u.age_group, AVG(r.rating_value) AS avg_rating
FROM fact_ratings r
JOIN dim_users u ON r.user_id = u.dim_userId
GROUP BY u.age_group
ORDER BY avg_rating DESC;
```
---
### **Graf 3: Popularita filmov podľa roku vydania**
Vizualizácia ukazuje počet hodnotení filmov podľa roku ich vydania. Pomáha identifikovať obdobia s najväčšou produkciou populárnych filmov a trendy v čase.

```sql
SELECT m.release_year, COUNT(r.fact_rating_id) AS num_ratings
FROM fact_ratings r
JOIN dim_movies m ON r.movie_id = m.dim_movieId
GROUP BY m.release_year
ORDER BY num_ratings DESC;
```
---
### **Graf 4: Najobľúbenejšie značky podľa žánru**
Táto vizualizácia zobrazuje najčastejšie používané značky (tagy) pri filmoch v jednotlivých žánroch. Pomáha pochopiť, aké témy alebo charakteristiky sú pre používateľov dôležité pri hodnotení filmov.

```sql
SELECT t.tags, g.genre_name, COUNT(t.id) AS num_tags
FROM tags_staging t
JOIN genres_movies_staging gm ON t.movie_id = gm.movie_id
JOIN dim_genres g ON gm.genre_id = g.dim_genreId
GROUP BY t.tags, g.genre_name
ORDER BY num_tags DESC;
```
---
### **Graf 5: Preferencie žánrov podľa pohlavia**
Graf ukazuje, aké filmové žánre preferujú muži a ženy. Tieto informácie môžu byť využité na personalizované odporúčania filmov podľa pohlavia.

```sql
SELECT u.gender, g.genre_name, COUNT(r.fact_rating_id) AS num_ratings
FROM fact_ratings r
JOIN dim_users u ON r.user_id = u.dim_userId
JOIN dim_genres g ON r.genre_id = g.dim_genreId
GROUP BY u.gender, g.genre_name
ORDER BY u.gender, num_ratings DESC;
```

Dashboard poskytuje komplexný pohľad na dáta, pričom zodpovedá dôležité otázky týkajúce sa preferencií a správania používateľov. Vizualizácie umožňujú jednoduchú interpretáciu dát a môžu byť využité na optimalizáciu odporúčacích systémov, marketingových stratégií a filmových kampaní.

---

**Autor:** Nikita Martynenko
