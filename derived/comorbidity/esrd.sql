


 --- ESKD on hemodialysis or renal transplant
 --- icd 9 as in MIMIC IV did not work, so I used pasthistory instead

DROP TABLE IF EXISTS aims_eicu_crd_derived.esrd;
CREATE TABLE aims_eicu_crd_derived.esrd AS
WITH hx AS (
    SELECT ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           ad.dischyear AS disch_yr,
           CASE
               WHEN pasthistoryvalue LIKE "%dialysis%" THEN 1
               WHEN pasthistoryvalue LIKE "%renal transplantation%" THEN 1
               ELSE 0
               END      AS esrd
    FROM aims_eicu_crd_hosp.admissions AS ad
             INNER JOIN aims_eicu_crd_icu.icustays AS ie
                        ON ad.subject_id = ie.subject_id AND
                           ad.hadm_id = ie.hadm_id
             INNER JOIN physionet-data.eicu_crd_demo.pasthistory AS hx
                        ON ie.patientunitstayid = hx.patientunitstayid
)
SELECT subject_id,
       hadm_id,
       stay_id,
       disch_yr,
       esrd
FROM hx
WHERE esrd = 1

--63
