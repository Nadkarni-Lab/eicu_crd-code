
-- ====================================================================================================
-- Renal replacement therapy
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- Purpose:
-- - The objective of this query is to extract renal replacement therapy.
-- Reference:
-- - 
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

-- RRT for AKI patients
-- CRRT or IHD (not include PD)
-- Creates a table with stay_id / time / dialysis type (if present)
DROP TABLE IF EXISTS aims_eicu_crd_derived.rrt;
CREATE TABLE aims_eicu_crd_derived.rrt AS
WITH ce AS (
    SELECT ie.uniquepid,
           ie.patienthealthsystemstayid,
           ie.patientunitstayid,
           ie.intime_ho + tx.treatmentoffset AS chart_ho,
           tx.treatmentoffset                AS chart_io,
           tx.treatmentstring,
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           ie.intime_ho + tx.treatmentoffset AS charttime
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd.treatment` AS tx
                        ON ie.patientunitstayid = tx.patientunitstayid
    WHERE tx.treatmentstring LIKE '%renal|dialysis|SLED%'
       OR tx.treatmentstring LIKE '%renal|dialysis|C V V H%'
       OR tx.treatmentstring LIKE '%renal|dialysis|C A V H D%'
       OR tx.treatmentstring LIKE '%renal|dialysis|C V V H D%'
       OR tx.treatmentstring LIKE '%renal|dialysis|hemodialysis%'
       OR tx.treatmentstring LIKE '%renal|dialysis|peritoneal dialysis%'
)
SELECT *,
       CASE
           WHEN treatmentstring LIKE "%renal|dialysis|C V V H%" OR
                treatmentstring LIKE "%renal|dialysis|C A V H D%" OR
                treatmentstring LIKE "%renal|dialysis|C V V H D%"
               THEN 1
           ELSE NULL
           END AS crrt,
       CASE
           WHEN treatmentstring LIKE "%renal|dialysis|SLED%" THEN 1
           ELSE NULL
           END AS SLED,
       CASE
           WHEN treatmentstring LIKE "%renal|dialysis|hemodialysis%" THEN 1
           ELSE NULL
           END AS HD,
       CASE
           WHEN treatmentstring LIKE "%renal|dialysis|peritoneal dialysis%" THEN 1
           ELSE NULL
           END AS PD
FROM ce
ORDER BY hadm_id, charttime;









