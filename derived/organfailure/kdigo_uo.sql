
-- ====================================================================================================
-- KDIGO - Urine output
-- Version: 3.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- - This code is designed to preprocess urine output data based on KIDGO AKI guidelines.
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/organfailure/kdigo_uo.sql
-- - https://kdigo.org/wp-content/uploads/2016/10/KDIGO-2012-AKI-Guideline-English.pdf
-- History:
-- - 1.0: Create new query.
-- - 3.0 [2024-05-05]:
--   - Add both eICU and MIMIC style keys.
--   - Reset version number across all queries and databases.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.kdigo_uo;
CREATE TABLE aims_eicu_crd_derived.kdigo_uo AS
WITH uo_stg1 AS (
    SELECT ie.uniquepid,
           ie.patienthealthsystemstayid,
           ie.patientunitstayid,
           uo.chart_ho,
           uo.chart_io,
           uo.chart_io AS minutes_since_icu_admit,
           COALESCE(
               (uo.charttime - LAG(uo.charttime) OVER (PARTITION BY ie.patientunitstayid ORDER BY uo.charttime)) / 60,
               1
           ) AS hours_since_previous_row,
           uo.urineoutput,
           -- MIMIC style
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           uo.charttime
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN aims_eicu_crd_derived.urine_output AS uo
                        ON ie.stay_id = uo.stay_id
), uo_stg2 AS (
    SELECT uniquepid,
           patienthealthsystemstayid,
           patientunitstayid,
           chart_ho,
           chart_io,
           hours_since_previous_row,
           urineoutput,
           -- Use the RANGE partition to limit the summation to the last X hours.
           -- RANGE operates using numeric, so we convert the charttime into
           -- seconds since admission, and then filter to X seconds prior to the
           -- current row, where X can be 21600 (6 hours), 43200 (12 hours),
           -- or 86400 (24 hours).
           SUM(urineoutput) OVER
               (
               PARTITION BY stay_id
               ORDER BY minutes_since_icu_admit
               RANGE BETWEEN 360 PRECEDING AND CURRENT ROW
               ) AS urineoutput_6hr,

           SUM(urineoutput) OVER
               (
               PARTITION BY stay_id
               ORDER BY minutes_since_icu_admit
               RANGE BETWEEN 720 PRECEDING AND CURRENT ROW
               ) AS urineoutput_12hr,

           SUM(urineoutput) OVER
               (
               PARTITION BY stay_id
               ORDER BY minutes_since_icu_admit
               RANGE BETWEEN 1440 PRECEDING AND CURRENT ROW
               ) AS urineoutput_24hr,

           -- repeat the summations using the hours_since_previous_row column
           -- this gives us the amount of time the UO was calculated over
           SUM(hours_since_previous_row) OVER
               (
               PARTITION BY stay_id
               ORDER BY minutes_since_icu_admit
               RANGE BETWEEN 360 PRECEDING AND CURRENT ROW
               ) AS uo_tm_6hr,

           SUM(hours_since_previous_row) OVER
               (
               PARTITION BY stay_id
               ORDER BY minutes_since_icu_admit
               RANGE BETWEEN 720 PRECEDING AND CURRENT ROW
               ) AS uo_tm_12hr,

           SUM(hours_since_previous_row) OVER
               (
               PARTITION BY stay_id
               ORDER BY minutes_since_icu_admit
               RANGE BETWEEN 1440 PRECEDING AND CURRENT ROW
               ) AS uo_tm_24hr,
           -- MIMIC style
           subject_id,
           hadm_id,
           stay_id,
           charttime
    FROM uo_stg1
)
SELECT ur.uniquepid,
       ur.patienthealthsystemstayid,
       ur.patientunitstayid,
       ur.chart_ho,
       ur.chart_io,
       wd.weight,
       ur.urineoutput_6hr,
       ur.urineoutput_12hr,
       ur.urineoutput_24hr,

       -- calculate rates while requiring UO documentation over at least N hours
       -- as specified in KDIGO guidelines 2012 pg19
       CASE
           WHEN uo_tm_6hr >= 6 AND uo_tm_6hr < 12
               THEN ROUND(
                   CAST((ur.urineoutput_6hr / wd.weight / uo_tm_6hr) AS NUMERIC), 4
               )
           ELSE NULL END AS uo_rt_6hr,
       CASE
           WHEN uo_tm_12hr >= 12
               THEN ROUND(
                   CAST((ur.urineoutput_12hr / wd.weight / uo_tm_12hr) AS NUMERIC)
               , 4
               )
           ELSE NULL END AS uo_rt_12hr,
       CASE
           WHEN uo_tm_24hr >= 24
               THEN ROUND(
                   CAST((ur.urineoutput_24hr / wd.weight / uo_tm_24hr) AS NUMERIC)
               , 4
               )
           ELSE NULL END AS uo_rt_24hr,

       -- number of hours between current UO time and earliest charted UO
       -- within the X hour window
       uo_tm_6hr,
       uo_tm_12hr,
       uo_tm_24hr,
       -- MIMIC style
       ur.subject_id,
       ur.hadm_id,
       ur.stay_id,
       ur.charttime
FROM uo_stg2 AS ur
         LEFT JOIN aims_eicu_crd_derived.weight_durations AS wd
                   ON ur.stay_id = wd.stay_id AND
                      ur.charttime >= wd.starttime AND
                      ur.charttime < wd.endtime AND
                      wd.weight >= 20 AND wd.weight <= 500
ORDER BY ur.subject_id, ur.hadm_id, ur.stay_id, ur.charttime;









