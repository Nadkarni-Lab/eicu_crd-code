
-- ====================================================================================================
-- age
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/demographics/age.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.age;
CREATE TABLE aims_eicu_crd_derived.age AS
SELECT uniquepid,
       patienthealthsystemstayid,
       0                         AS admit_ho,
       MAX(CASE
               WHEN age IS NOT NULL AND
                    age <> '> 89'
                   THEN SAFE_CAST(age AS INTEGER)
               WHEN age IS NOT NULL AND
                    age = '> 89'
                   THEN 90
           END)                  AS anchor_age,
       NULL                      AS anchor_year,
       MAX(CASE
               WHEN age IS NOT NULL AND
                    age <> '> 89'
                   THEN SAFE_CAST(age AS INTEGER)
               WHEN age IS NOT NULL AND
                    age = '> 89'
                   THEN 90
           END)                  AS age,
       -- MIMIC style
       uniquepid                 AS subject_id,
       patienthealthsystemstayid AS hadm_id,
       0                         AS admittime
FROM `physionet-data.eicu_crd.patient`
GROUP BY uniquepid, patienthealthsystemstayid
ORDER BY uniquepid, patienthealthsystemstayid;









