
-- ====================================================================================================
-- patients
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

DROP TABLE IF EXISTS eicu_crd_hosp.patients;
CREATE TABLE eicu_crd_hosp.patients AS
SELECT uniquepid
     -- MIMIC style
     , uniquepid     AS subject_id
     , MAX(
        CASE
            WHEN gender = 'Male' THEN 'M'
            WHEN gender = 'Female' THEN 'F'
            END)     AS gender
     , NULL          AS anchor_age
     , NULL          AS anchor_year
     , NULL          AS anchor_year_group
     , MAX(
        IF(hospitaldischargestatus = 'Expired'
            , hospitaldischargeoffset - hospitaladmitoffset
            , NULL)) AS dod
FROM `physionet-data.eicu_crd.patient`
GROUP BY uniquepid
ORDER BY uniquepid;









