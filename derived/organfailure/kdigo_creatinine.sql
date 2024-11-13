
-- ====================================================================================================
-- kdigo_creatinine
-- Version: 3.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/organfailure/kdigo_creatinine.sql
-- - https://kdigo.org/wp-content/uploads/2016/10/KDIGO-2012-AKI-Guideline-English.pdf
-- History:
-- - 1.0 [          ]: Create new query.
-- - 3.0 [2024-05-05]:
--   - Add both eICU and MIMIC style keys.
--   - Reset version number across all queries and databases.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.kdigo_creatinine;
CREATE TABLE aims_eicu_crd_derived.kdigo_creatinine AS
WITH cr AS (
    SELECT le.uniquepid,
           le.patienthealthsystemstayid,
           le.chart_ho,
           le.chart_io,
           ROUND(AVG(le.creatinine), 2) AS creat,
           -- MIMIC style
           le.subject_id,
           le.hadm_id,
           le.charttime
    FROM aims_eicu_crd_hosp.admissions AS adm
             INNER JOIN aims_eicu_crd_derived.chemistry AS le
                        ON adm.subject_id = le.subject_id AND
                           adm.hadm_id = le.hadm_id
    WHERE le.charttime IS NOT NULL
      AND le.creatinine IS NOT NULL
      AND le.charttime >= adm.admittime - (60 * 24 * 7) --- 7 days before ICU admission,
    GROUP BY le.uniquepid, le.patienthealthsystemstayid, le.chart_ho, le.chart_io,
             le.subject_id, le.hadm_id, le.charttime
), cr48 AS (
    -- add in the lowest value in the previous or post 48 hours
    SELECT cr.subject_id,
           cr.hadm_id,
           cr.charttime,
           MIN(cr48.creat) AS creat_low_past_48hr
    FROM cr
             -- add in all creatinine values in the last 48 hours
             LEFT JOIN cr cr48
                       ON cr.subject_id = cr48.subject_id AND
                          cr.hadm_id = cr48.hadm_id AND
                          cr48.charttime <= cr.charttime AND
                          cr48.charttime >= cr.charttime - (60 * 24 * 2) ---- 48 hours
    GROUP BY cr.subject_id, cr.hadm_id, cr.charttime
), cr7 AS (
    -- add in the lowest value in the previous 7 days
    SELECT cr.subject_id,
           cr.hadm_id,
           cr.charttime,
           MIN(cr7.creat) AS creat_low_past_7day
    FROM cr
             -- add in all creatinine values in the last 7 days
             LEFT JOIN cr cr7
                       ON cr.subject_id = cr7.subject_id AND
                          cr.hadm_id = cr7.hadm_id AND
                          cr7.charttime <= cr.charttime AND
                          cr7.charttime >= cr.charttime - (60 * 24 * 7) ---- 7 days
    GROUP BY cr.subject_id, cr.hadm_id, cr.charttime
)
SELECT cr.uniquepid,
       cr.patienthealthsystemstayid,
       cr.chart_ho,
       cr.chart_io,
       cr.creat,
       cr48.creat_low_past_48hr,
       cr7.creat_low_past_7day,
       cr.subject_id,
       cr.hadm_id,
       cr.charttime
FROM cr
         LEFT JOIN cr48 ON
             cr.subject_id = cr48.subject_id AND
             cr.hadm_id = cr48.hadm_id AND
             cr.charttime = cr48.charttime
         LEFT JOIN cr7 ON
             cr.subject_id = cr7.subject_id AND
             cr.hadm_id = cr7.hadm_id AND
             cr.charttime = cr7.charttime
ORDER BY cr.subject_id, cr.hadm_id, cr.charttime









