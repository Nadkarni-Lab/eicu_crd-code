
-- ====================================================================================================
-- Baseline creatinine
-- Version: 2.1
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- Purpose:
-- - This code is extract baseline creatinine level.
-- Reference:
-- - ToDo.
-- History:
-- - 1.0: Create new query.
-- - 2.0: Update retrospective periods for observed baseline creatinine, and utilize the first
--        measurement during each hospitalization to determine baseline creatinine.
-- - 2.1: Fix minor bugs.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.baseline_creatinine;
CREATE TABLE aims_eicu_crd_derived.baseline_creatinine AS
WITH cr_obs AS (
    SELECT uniquepid,
           patienthealthsystemstayid,
           chart_ho,
           chart_io,
           creatinine AS cr,
           subject_id,
           hadm_id,
           charttime
    FROM aims_eicu_crd_derived.chemistry
    WHERE creatinine IS NOT NULL
), cr_est_bl0 AS (
    -- Back-calculation with MDRD equation assuming an eGFR of 75 ml/min/1.73 m2.
    SELECT ag.uniquepid,
           ag.patienthealthsystemstayid,
           ag.age,
           p.gender,
           CASE
               WHEN p.gender = 'F' THEN
                   POWER(75.0 / 186.0 / POWER(ag.age, -0.203) / 0.742, -1 / 1.154)
               ELSE
                   POWER(75.0 / 186.0 / POWER(ag.age, -0.203), -1 / 1.154)
               END
               AS cr_est_bl,
           ag.subject_id,
           ag.hadm_id
    FROM aims_eicu_crd_derived.age AS ag
             LEFT JOIN aims_eicu_crd_hosp.patients AS p
                       ON ag.subject_id = p.subject_id
    WHERE ag.age >= 18
), cr_est_bl AS (
    SELECT uniquepid,
           patienthealthsystemstayid,
           age,
           gender,
           ROUND(cr_est_bl, 2) AS cr_est_bl,
           subject_id,
           hadm_id
    FROM cr_est_bl0
), cr_adm AS (
    -- First cr hospital admission
    SELECT adm.uniquepid,
           adm.patienthealthsystemstayid,
           le.cr                      AS cr_adm_bl,
           ROW_NUMBER() OVER
               (PARTITION BY adm.subject_id, adm.hadm_id
               ORDER BY le.charttime) AS rn,
           adm.subject_id,
           adm.hadm_id
    FROM aims_eicu_crd_hosp.admissions AS adm
             INNER JOIN cr_obs AS le
                        ON adm.subject_id = le.subject_id AND
                           adm.hadm_id = le.hadm_id AND
                           adm.admittime <= le.charttime AND
                           le.charttime <= adm.dischtime
    ORDER BY adm.subject_id, adm.hadm_id, le.charttime
), cr_adm_bl0 AS (
    SELECT uniquepid,
           patienthealthsystemstayid,
           cr_adm_bl,
           subject_id,
           hadm_id
    FROM cr_adm
    WHERE rn = 1
), cr_adm_bl AS (
    SELECT uniquepid,
           patienthealthsystemstayid,
           ROUND(cr_adm_bl, 2) AS cr_adm_bl,
           subject_id,
           hadm_id
    FROM cr_adm_bl0
), id AS (
    SELECT uniquepid, patienthealthsystemstayid,
           subject_id, hadm_id
    FROM cr_est_bl
    UNION
    DISTINCT
    SELECT uniquepid, patienthealthsystemstayid,
           subject_id, hadm_id
    FROM cr_adm_bl
)
SELECT id.uniquepid,
       id.patienthealthsystemstayid,
       est.cr_est_bl,
       adm.cr_adm_bl,
       COALESCE(
               LEAST(adm.cr_adm_bl, est.cr_est_bl),
               est.cr_est_bl
       ) AS cr_bl,
       id.subject_id,
       id.hadm_id
FROM id
         LEFT JOIN cr_est_bl AS est
                   ON id.subject_id = est.subject_id AND
                      id.hadm_id = est.hadm_id
         LEFT JOIN cr_adm_bl AS adm
                   ON id.subject_id = adm.subject_id AND
                      id.hadm_id = adm.hadm_id
WHERE id.hadm_id IS NOT NULL
ORDER BY subject_id, hadm_id;









