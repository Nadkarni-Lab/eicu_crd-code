
-- ====================================================================================================
-- icustay_times
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/demographics/icustay_times.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.icustay_times;
CREATE TABLE aims_eicu_crd_derived.icustay_times AS
WITH t1 AS
(
    SELECT patientunitstayid,
           MIN(observationoffset) as intime_hr_io,
           MAX(observationoffset) as outtime_hr_io
    -- ToDo: nursecharting (eICU) and vitalperiodic (eICU) are two sources of HR.
    --       Need to confirm vitalperiodic (eICU) contains only data from the ICU setting.
    FROM `physionet-data.eicu_crd.vitalperiodic` AS ce
    -- only look at heart rate
    WHERE heartrate IS NOT NULL
      AND 225 >= heartrate
      AND heartrate >= 25
    GROUP BY patientunitstayid
), t2 AS (
    SELECT *
    FROM t1
    WHERE outtime_hr_io > 0
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       -- ho: offset from hospital admission.
       ie.intime_ho + t2.intime_hr_io  AS intime_hr_ho,
       ie.intime_ho + t2.outtime_hr_io AS outtime_hr_ho,
       -- io: offset from ICU admission.
       t2.intime_hr_io,
       t2.outtime_hr_io,
       -- MIMIC style
       ie.subject_id,
       ie.hospital_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + t2.intime_hr_io  AS intime_hr,
       ie.intime_ho + t2.outtime_hr_io AS outtime_hr,
FROM aims_eicu_crd_icu.icustays AS ie
         LEFT JOIN t2
                   ON ie.patientunitstayid = t2.patientunitstayid
ORDER BY ie.subject_id, ie.hadm_id, ie.intime_ho + t2.intime_hr_io;









