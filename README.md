# **ETL proces datasetu MovieLens**

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake pre analýzu dát z **MovieLens** datasetu. Projekt sa zameriava na preskúmanie správania používateľov a ich čitateľských preferencií na základe hodnotení kníh a demografických údajov používateľov. Výsledný dátový model umožňuje multidimenzionálnu analýzu a vizualizáciu kľúčových metrik.

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
