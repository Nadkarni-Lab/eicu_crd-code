
-- ====================================================================================================
-- admissions
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
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS eicu_crd_hosp.admissions;
CREATE TABLE eicu_crd_hosp.admissions AS
SELECT uniquepid
     , patienthealthsystemstayid
     -- time relies on offsets from hospital admission.
     , 0                                                  AS admit_ho
     , MAX(hospitaldischargeoffset - hospitaladmitoffset) AS disch_ho
     , MAX(hospitaladmittime24)                           AS admit_ho24
     , MAX(hospitaldischargetime24)                       AS disch_ho24
     , MAX(hospitaldischargeyear)                         AS dischyear
     , MAX(
        IF(hospitalDischargeStatus = 'Expired'
            , hospitaldischargeoffset - hospitaladmitoffset
            , NULL))                                      AS deathho
     , NULL                                               AS admission_type
     , NULL                                               AS admit_provider_id
     , MAX(hospitalAdmitSource)                           AS admission_location
     , MAX(hospitaldischargelocation)                     AS discharge_location
     , NULL                                               AS insurance
     , NULL                                                  language
     , NULL                                               AS marital_status
     , MAX(ethnicity)                                     AS race
     , NULL                                               AS edreg_ho
     , NULL                                               AS edout_ho
     , MAX(IF(hospitalDischargeStatus = 'Expired', 1, 0)) AS hospital_expire
     -- MIMIC style
     , uniquepid                                          AS subject_id
     , patienthealthsystemstayid                          AS hadm_id
     -- time relies on offsets from hospital admission.
     , 0                                                  AS admittime
     , MAX(hospitaldischargeoffset - hospitaladmitoffset) AS dischtime
     , MAX(hospitaladmitoffset)                           AS admittime24
     , MAX(hospitaldischargetime24)                       AS dischtime24
     , MAX(
        IF(hospitalDischargeStatus = 'Expired'
            , hospitaldischargeoffset - hospitaladmitoffset
            , NULL))                                      AS deathtime
     , MAX(hospitaladmittime24)                           AS admittime24_hr
     , MAX(hospitaldischargetime24)                       AS dischtime24_hr
     , NULL                                               AS edregtime
     , NULL                                               AS edouttime
FROM `physionet-data.eicu_crd.patient`
GROUP BY uniquepid, patienthealthsystemstayid
ORDER BY uniquepid, MAX(hospitaldischargeyear), patienthealthsystemstayid;









