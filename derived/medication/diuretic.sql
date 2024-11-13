
-- ====================================================================================================
-- Diuretic
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- - The objective of this query is to extract diuretic medication.
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.diuretic;
CREATE TABLE aims_eicu_crd_derived.diuretic AS
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime + rx.drugstartoffset AS start_ho,
       rx.drugstartoffset             AS start_io,
       ie.intime + rx.drugstopoffset  AS end_ho,
       rx.drugstopoffset              AS end_io,
       NULL                           AS orderid,
       rx.drugname                    AS drug_label,
       NULL                           AS drug_rate,
       rx.dosage                      AS drug_amount,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime + rx.drugstartoffset AS starttime,
       ie.intime + rx.drugstopoffset  AS endtime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN physionet-data.eicu_crd.medication AS rx
                    ON ie.patientunitstayid = rx.patientunitstayid
WHERE LOWER(rx.drugname) LIKE '%furosemide%'
   OR LOWER(rx.drugname) LIKE '%bumetanide%'
   OR LOWER(rx.drugname) LIKE '%torsemide%'
   OR LOWER(rx.drugname) LIKE '%ethacrynic%'
ORDER BY ie.subject_id, ie.hadm_id, ie.stay_id, rx.drugstartoffset, rx.drugstopoffset, rx.drugname;









