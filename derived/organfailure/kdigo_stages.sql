
-- ====================================================================================================
-- KDIGO - AKI stage
-- Version: 3.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- Purpose:
-- - This code is designed to classify AKI stage using creatinine and urine output according to
--   KDIGO AKI guidelines. This query checks if the patient had AKI according to KDIGO. AKI is
--   calculated every time a creatinine or urine output measurement occurs. Baseline creatinine is
--   defined as the lowest creatinine in the past or post 7 days.
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/organfailure/kdigo_stages.sql
-- - https://kdigo.org/wp-content/uploads/2016/10/KDIGO-2012-AKI-Guideline-English.pdf
-- History:
-- - 1.0: Create new query.
-- - 3.0 [2024-05-05]:
--   - Add both eICU and MIMIC style keys.
--   - Modify RRT part.
--   - Reset version number across all queries and databases.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.kdigo_stages;
CREATE TABLE aims_eicu_crd_derived.kdigo_stages AS
WITH cr_stg AS (
    SELECT cr.uniquepid,
           cr.patienthealthsystemstayid,
           cr.chart_ho,
           cr.chart_io,
           bl.cr_bl AS creat_bl,
           cr.creat_low_past_7day,
           cr.creat_low_past_48hr,
           cr.creat,
           -- WO1: The key difference between the MIMIC code and mine is that
           --      the MIMIC code relies on the lowest creatinine over the
           --      past 7 days as a baseline creatinine, while mine uses both
           --      the lowest creatinine over the past 7 days and average
           --      creatinine collected from the outpatient setting over the
           --      past 1 year.
           -- WO2: For the use of the average creatinine collected from the
           --      outpatient setting over the past 1 year as a baseline
           --      creatinine, I impose creatinine needs to be greater than
           --      the lowest creatinine over the past 7. I do not impose such
           --      restriction on using the lowest creatinine over the past 7
           --      as a baseline creatinine.
           CASE
               -- 3x baseline
               WHEN cr.creat >= (cr.creat_low_past_7day * 3.0)
                   THEN 3
               WHEN cr.creat >= (bl.cr_bl * 3.0) AND cr.creat > cr.creat_low_past_7day
                   THEN 3
               -- *OR* cr >= 4.0 with associated increase
               WHEN cr.creat >= 4
                   -- For patients reaching Stage 3 by SCr >4.0 mg/dl
                   -- require that the patient first achieve ...
                   --      an acute increase >= 0.3 within 48 hr
                   --      *or* an increase of >= 1.5 times baseline
                   AND (cr.creat_low_past_48hr <= 3.7 OR cr.creat >= (1.5 * cr.creat_low_past_7day))
                   THEN 3
               WHEN cr.creat >= 4
                   -- For patients reaching Stage 3 by SCr >4.0 mg/dl
                   -- require that the patient first achieve ... acute increase >= 0.3 within 48 hr
                   -- *or* an increase of >= 1.5 times baseline
                   AND (cr.creat_low_past_48hr <= 3.7 OR
                        (cr.creat >= (1.5 * bl.cr_bl)) AND cr.creat >= cr.creat_low_past_7day) THEN 3
               WHEN ((cr.creat - cr.creat_low_past_7day) > 0) AND
                    ((cr.creat >= bl.cr_bl * 2.0) AND (cr.creat < bl.cr_bl * 3.0))
                   THEN 2
               WHEN (cr.creat >= (cr.creat_low_past_48hr + 0.3)) OR
                    (((cr.creat - cr.creat_low_past_7day) > 0) AND
                     ((cr.creat >= bl.cr_bl * 1.5) AND (cr.creat < bl.cr_bl * 2.0)))
                   THEN 1
               ELSE 0
               END  AS aki_stage_creat,
           cr.subject_id,
           cr.hadm_id,
           cr.charttime
    FROM aims_eicu_crd_derived.kdigo_creatinine AS cr
             INNER JOIN aims_eicu_crd_derived.baseline_creatinine AS bl ON

                 cr.hadm_id = bl.hadm_id
)
-- stages for UO / creat
, uo_stg AS (
    SELECT uo.uniquepid,
           uo.patienthealthsystemstayid,
           uo.patientunitstayid,
           uo.chart_ho,
           uo.chart_io,
           uo.weight,
           uo.uo_rt_6hr,
           uo.uo_rt_12hr,
           uo.uo_rt_24hr,
           -- AKI stages according to urine output
           CASE
               WHEN uo.uo_rt_6hr IS NULL THEN NULL
               -- require patient to be in ICU for at least 6 hours to stage UO
               WHEN uo.charttime <= ie.intime_ho + (60 * 6)
                   THEN 0
               -- require the UO rate to be calculated over the
               -- duration specified in KDIGO
               -- Stage 3: <0.3 ml/kg/h for >=24 hours
               WHEN uo.uo_tm_24hr >= 24 AND uo.uo_rt_24hr < 0.3 THEN 3
               -- *or* anuria for >= 12 hours
               WHEN uo.uo_tm_12hr >= 12 AND uo.uo_rt_12hr = 0 THEN 3
               -- Stage 2: <0.5 ml/kg/h for >= 12 hours
               WHEN uo.uo_tm_12hr >= 12 AND uo.uo_rt_12hr < 0.5 THEN 2
               -- Stage 1: <0.5 ml/kg/h for 6–12 hours
               WHEN uo.uo_tm_6hr >= 6 AND uo.uo_rt_6hr < 0.5 THEN 1
               ELSE 0 END AS aki_stage_uo,
           uo.subject_id,
           uo.hadm_id,
           uo.stay_id,
           uo.charttime
    FROM aims_eicu_crd_derived.kdigo_uo AS uo
             INNER JOIN aims_eicu_crd_icu.icustays AS ie ON
                uo.subject_id = ie.subject_id AND
                uo.hadm_id = ie.hadm_id AND
                uo.stay_id = ie.stay_id AND
                uo.weight >= 20 AND uo.weight <= 500

),
-- get RRT data
rrt_stg AS (
    SELECT ie.uniquepid,
           ie.patienthealthsystemstayid,
           ie.patientunitstayid,
           tx.chart_ho,
           tx.chart_io,
           CASE
               WHEN tx.charttime IS NOT NULL
                   THEN 3
               END AS aki_stage_rrt,
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           tx.charttime
    FROM aims_eicu_crd_derived.rrt AS tx
             INNER JOIN aims_eicu_crd_icu.icustays AS ie
                        ON tx.patientunitstayid = ie.stay_id
    WHERE HD = 1
       OR SLED = 1
       OR crrt = 1
),
-- get all charttimes documented
tm_stg AS (
    SELECT uniquepid, patienthealthsystemstayid, chart_ho, chart_io,
           subject_id, hadm_id, charttime
    FROM cr_stg
    UNION DISTINCT
    SELECT uniquepid, patienthealthsystemstayid, chart_ho, chart_io,
           subject_id, hadm_id, charttime
    FROM uo_stg
    UNION DISTINCT
    SELECT uniquepid, patienthealthsystemstayid, chart_ho, chart_io,
           subject_id, hadm_id, charttime
    FROM rrt_stg
)
,
-- WO3: cr_stg_1d0, cr_stg_1d, uo_stg_1d0, and uo_stg_1d are new codes to
--      adjust the resolution for collecting the sample for creatinine and
--      urine outcomes. Creatinine are collected every 6+ hours (1 day, or
--      even longer), while urine outcomes are collected every hour during
--      the ICU stay.
cr_stg_1d0 AS (
    SELECT tm.subject_id,
           tm.hadm_id,
           tm.charttime,
           cr.aki_stage_creat,
           FIRST_VALUE(cr.aki_stage_creat) OVER (
               PARTITION BY tm.hadm_id, tm.charttime
               ORDER BY
                   CASE WHEN cr.aki_stage_creat IS NULL then 0
                   ELSE 1 END DESC,
                   cr.charttime DESC
               )        AS aki_stage_creat_1d,
           ROW_NUMBER() OVER (
               PARTITION BY tm.hadm_id, tm.charttime
               ORDER BY cr.charttime DESC
               )        AS rn,
    FROM tm_stg AS tm
             LEFT JOIN cr_stg AS cr ON
                tm.subject_id = cr.subject_id AND
                tm.hadm_id = cr.hadm_id AND
                tm.charttime >= cr.charttime AND
                cr.charttime > tm.charttime - 1440
)
, cr_stg_1d AS (
    SELECT subject_id,
           hadm_id,
           charttime,
           aki_stage_creat_1d
    FROM cr_stg_1d0
    WHERE rn = 1
)
, uo_stg_1d0 AS (
    SELECT tm.subject_id,
           tm.hadm_id,
           tm.charttime,
           uo.aki_stage_uo,
           FIRST_VALUE(uo.aki_stage_uo) OVER (
               PARTITION BY tm.hadm_id, tm.charttime
               ORDER BY
                   CASE WHEN uo.aki_stage_uo IS NULL then 0 ELSE 1 END DESC,
                   uo.charttime DESC
               )        AS aki_stage_uo_1d,
           ROW_NUMBER() OVER (
               PARTITION BY tm.hadm_id, tm.charttime
               ORDER BY uo.charttime DESC
               )        AS rn
    FROM tm_stg AS tm
             LEFT JOIN uo_stg AS uo ON
                tm.subject_id = uo.subject_id AND
                tm.hadm_id = uo.hadm_id AND
                tm.charttime >= uo.charttime AND
                uo.charttime > tm.charttime - 1440
), uo_stg_1d AS (
    SELECT subject_id,
           hadm_id,
           charttime,
           aki_stage_uo_1d
    FROM uo_stg_1d0
    WHERE rn = 1
)
, rrt_stg_all AS (
    SELECT tm.subject_id,
           tm.hadm_id,
           tm.charttime,
           MAX(rr.aki_stage_rrt) AS aki_stage_rrt_all
    FROM tm_stg AS tm
             LEFT JOIN rrt_stg AS rr ON
                tm.subject_id = rr.subject_id AND
                tm.hadm_id = rr.hadm_id AND
                tm.charttime >= rr.charttime
    GROUP BY tm.subject_id, tm.hadm_id, tm.charttime
)
SELECT ad.uniquepid,
       ad.patienthealthsystemstayid,
       tm.chart_ho,
       tm.chart_io,
       cr.creat_bl,
       cr.creat_low_past_7day,
       cr.creat_low_past_48hr,
       cr.creat,
       cr.aki_stage_creat,
       GREATEST(
               COALESCE(cr1.aki_stage_creat_1d, 0),
               COALESCE(rr2.aki_stage_rrt_all, 0)
       ) AS aki_stage_creat_1d,
       uo.uo_rt_6hr,
       uo.uo_rt_12hr,
       uo.uo_rt_24hr,
       uo.aki_stage_uo,
       GREATEST(
               COALESCE(uo1.aki_stage_uo_1d, 0),
               COALESCE(rr2.aki_stage_rrt_all, 0)
       ) AS aki_stage_uo_1d,
       rr.aki_stage_rrt,
       rr2.aki_stage_rrt_all,
       -- Classify AKI using both creatinine/urine output criteria
       GREATEST(
               COALESCE(cr1.aki_stage_creat_1d, 0),
               COALESCE(uo1.aki_stage_uo_1d, 0),
               COALESCE(rr2.aki_stage_rrt_all, 0)
           )         AS aki_stage,
       ad.subject_id,
       ad.hadm_id,
       tm.charttime
FROM aims_eicu_crd_hosp.admissions AS ad
         -- get all possible charttimes as listed in tm_stg
         LEFT JOIN tm_stg AS tm
                   ON ad.subject_id = tm.subject_id AND
                      ad.hadm_id = tm.hadm_id
         LEFT JOIN cr_stg AS cr
                   ON ad.subject_id = cr.subject_id AND
                      ad.hadm_id = cr.hadm_id AND
                      tm.charttime = cr.charttime
         LEFT JOIN uo_stg AS uo
                   ON ad.subject_id = uo.subject_id AND
                      ad.hadm_id = uo.hadm_id AND
                      tm.charttime = uo.charttime
         LEFT JOIN rrt_stg AS rr
                   ON ad.subject_id = rr.subject_id AND
                      ad.hadm_id = rr.hadm_id AND
                      tm.charttime = rr.charttime
         LEFT JOIN cr_stg_1d AS cr1
                   ON ad.subject_id = cr1.subject_id AND
                      ad.hadm_id = cr1.hadm_id AND
                      tm.charttime = cr1.charttime
         LEFT JOIN uo_stg_1d AS uo1
                   ON ad.subject_id = uo1.subject_id AND
                      ad.hadm_id = uo1.hadm_id AND
                      tm.charttime = uo1.charttime
         LEFT JOIN rrt_stg_all AS rr2
                   ON ad.subject_id = rr2.subject_id AND
                      ad.hadm_id = rr2.hadm_id AND
                      tm.charttime = rr2.charttime
WHERE cr.aki_stage_creat IS NOT NULL
   OR uo.aki_stage_uo IS NOT NULL
   OR rr.aki_stage_rrt IS NOT NULL
ORDER BY ad.subject_id, ad.hadm_id, tm.charttime;









