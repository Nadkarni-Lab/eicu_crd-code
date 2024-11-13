
-- ====================================================================================================
-- icustays
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- -
-- History:
-- - 1.0 [          ]: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS eicu_crd_icu.icustays;
CREATE TABLE eicu_crd_icu.icustays AS
WITH ie AS (
    SELECT uniquepid
         , hospitalid
         , patienthealthsystemstayid
         , patientunitstayid
         -- ToDo
         , NULL                                      AS first_careunit
         , NULL                                      AS last_careunit
         , hospitaldischargeyear
         -- ho: offset from hospital admission.
         , hospitaladmitoffset * -1                  AS intime_ho
         , unitdischargeoffset - hospitaladmitoffset AS outtime_ho
         -- io: offset from ICU admission.
         , 0                                         AS intime_io
         , unitdischargeoffset                       AS outtime_io
         , unitdischargeoffset                       AS los
         -- MIMIC style
         , uniquepid                                 AS subject_id
         , hospitalid                                AS hospital_id
         , patienthealthsystemstayid                 AS hadm_id
         , patientunitstayid                         AS stay_id
         -- intime and outtime rely on offsets from hospital admission.
         , hospitaladmitoffset * -1                  AS intime
         , unitdischargeoffset - hospitaladmitoffset AS outtime
         , hospitaldischargeyear                     AS dischyear
    FROM `physionet-data.eicu_crd.patient`
)
SELECT *
FROM ie
ORDER BY subject_id, hadm_id, intime;









