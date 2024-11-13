
-- ====================================================================================================
-- height
-- Version: 1.1
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/measurement/height.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.height;
CREATE TABLE aims_eicu_crd_derived.height AS
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime_ho       AS chart_ho,
       ie.intime_io       AS chart_io,
       pt.admissionheight AS height,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho       AS charttime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN physionet-data.eicu_crd.patient AS pt
                    ON ie.patientunitstayid = pt.patientunitstayid
WHERE admissionheight IS NOT NULL
  AND admissionheight > 120 AND admissionheight < 230
ORDER BY ie.subject_id, ie.hadm_id, ie.intime_ho;









