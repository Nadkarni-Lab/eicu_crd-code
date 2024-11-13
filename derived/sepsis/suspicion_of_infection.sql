
-- ====================================================================================================
-- suspicion_of_infection
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- - 
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

-- antibiotic >= 2
-- time received first antibiotic as t_sus
DROP TABLE IF EXISTS aims_eicu_crd_derived.suspicion_of_infection;
CREATE TABLE aims_eicu_crd_derived.suspicion_of_infection AS
WITH ab_tbl0 AS (
    SELECT abx.patientunitstayid,
           abx.start_ho,
           abx.stop_ho,
           abx.start_io,
           abx.stop_io,
           abx.subject_id,
           abx.hadm_id,
           abx.stay_id,
           abx.antibiotic,
           abx.starttime                      AS antibiotic_time,
           abx.stoptime                       AS antibiotic_stoptime,
           -- create a unique identifier for each patient antibiotic
           ROW_NUMBER() OVER
               (
               PARTITION BY abx.patientunitstayid
               ORDER BY abx.starttime, abx.stoptime, abx.antibiotic
               )                              AS ab_id
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN aims_eicu_crd_derived.antibiotic AS abx
                        ON ie.patientunitstayid = abx.patientunitstayid
),
ab_tbl01 AS (
    SELECT patientunitstayid, MAX(ab_id) AS abx_count
    FROM ab_tbl0
    GROUP BY patientunitstayid
),
ab_tbl AS (
SELECT ie.patientunitstayid,
       ab_tbl0.ab_id,
       ab_tbl0.antibiotic,
       ab_tbl0.antibiotic_time                                      AS antibiotic_ho,
       ab_tbl0.antibiotic_time - ie.intime_ho                       AS antibiotic_io,
       ab_tbl01.abx_count                                           AS antibiotic_count,

       CASE
           WHEN antibiotic_time IS NULL AND
                antibiotic IS NULL
               THEN 0
           ELSE 1
           END                                                      AS suspected_infection,
       -- MIMIC style
       ab_tbl0.subject_id,
       ab_tbl0.stay_id,
       ab_tbl0.hadm_id,
       ab_tbl0.antibiotic_time                                      AS suspected_infection_time

FROM ab_tbl0
         INNER JOIN aims_eicu_crd_icu.icustays AS ie
                    ON ab_tbl0.patientunitstayid = ie.patientunitstayid
         INNER JOIN ab_tbl01
                    ON ab_tbl0.patientunitstayid = ab_tbl01.patientunitstayid
WHERE ab_tbl01.abx_count > 1
)
SELECT *
FROM ab_tbl
WHERE ab_id = 1
ORDER BY patientunitstayid, ab_id;









