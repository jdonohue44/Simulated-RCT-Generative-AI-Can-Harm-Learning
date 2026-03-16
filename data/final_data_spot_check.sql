select count(distinct "Student ID") from final_data fd;
-- 943 students

select count(distinct "Class") from final_data fd;
-- 50 classrooms

-- Treatment arm distribution
SELECT "Treatment arm", COUNT(DISTINCT "Student ID") AS n_students
FROM final_data GROUP BY "Treatment arm";

/*
|Treatment arm|n_students|
|-------------|----------|
|augmented    |312       |
|control      |349       |
|vanilla      |282       |
*/

-- Share of students per arm (%)
SELECT "Treatment arm",
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM final_data GROUP BY "Treatment arm";

/*
|Treatment arm|pct |
|-------------|----|
|augmented    |33.8|
|control      |35.9|
|vanilla      |30.3|
*/

-- Classrooms per treatment arm (randomization check)
SELECT "Treatment arm", COUNT(DISTINCT "Class") AS n_classes
FROM final_data GROUP BY "Treatment arm";

/*
|Treatment arm|n_classes|
|-------------|---------|
|augmented    |16       |
|control      |19       |
|vanilla      |15       |
*/





-- 



-- Part2Tot and Part3Tot descriptive stats
SELECT
  ROUND(AVG(Part2Tot), 3)  AS mean_part2,
  ROUND(MIN(Part2Tot), 3)  AS min_part2,
  ROUND(MAX(Part2Tot), 3)  AS max_part2,
  ROUND(AVG(Part3Tot), 3)  AS mean_part3,
  ROUND(MIN(Part3Tot), 3)  AS min_part3,
  ROUND(MAX(Part3Tot), 3)  AS max_part3
FROM final_data;

-- Missing values on key analysis variables
SELECT
  SUM(CASE WHEN Part2Tot IS NULL THEN 1 ELSE 0 END)   AS missing_part2,
  SUM(CASE WHEN Part3Tot IS NULL THEN 1 ELSE 0 END)   AS missing_part3,
  SUM(CASE WHEN gpa_prev IS NULL THEN 1 ELSE 0 END)   AS missing_gpa_prev,
  SUM(CASE WHEN GPTBase  IS NULL THEN 1 ELSE 0 END)   AS missing_gptbase,
  SUM(CASE WHEN GPTTutor IS NULL THEN 1 ELSE 0 END)   AS missing_gpttut,
  SUM(CASE WHEN female   IS NULL THEN 1 ELSE 0 END)   AS missing_female,
  SUM(CASE WHEN chatgpt_use IS NULL THEN 1 ELSE 0 END) AS missing_chatgpt
FROM final_data;

-- gpa_prev range and distribution
SELECT
  ROUND(MIN(gpa_prev), 3)  AS min_gpa,
  ROUND(MAX(gpa_prev), 3)  AS max_gpa,
  ROUND(AVG(gpa_prev), 3)  AS mean_gpa,
  ROUND(AVG(CASE WHEN gpa_prev < 0.5 THEN 1.0 ELSE 0.0 END), 3) AS pct_below_half
FROM final_data;

-- Year and Session breakdown
SELECT Year, Session, COUNT(DISTINCT "Student ID") AS n_students
FROM final_data GROUP BY Year, Session ORDER BY Year, Session;

-- Honors vs. non-Honors counts
SELECT Honors, COUNT(DISTINCT "Student ID") AS n_students
FROM final_data GROUP BY Honors;
