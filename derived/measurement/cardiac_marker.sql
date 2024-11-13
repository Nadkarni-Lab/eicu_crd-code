
-- ====================================================================================================
-- cardiac marker
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-iv/blob/master/concepts/measurement/cardiac_marker.sql
-- - https://github.com/MIT-LCP/eicu-code/blob/main/concepts/pivoted/pivoted-lab.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.cardiac_marker;
CREATE TABLE aims_eicu_crd_derived.cardiac_marker AS
-- remove duplicate labs if they exist at the same time
WITH vw0 AS (
    SELECT patientunitstayid,
           labname,
           labresultoffset,
           labresultrevisedoffset
    FROM `physionet-data.eicu_crd.lab`
    WHERE labname IN
          ('troponin - T', -- troponin_t
           'CPK-MB' -- ck_mb
              )
    GROUP BY patientunitstayid, labname, labresultoffset, labresultrevisedoffset
    HAVING COUNT(DISTINCT labresult)<=1
), vw1 AS (
    -- get the last lab to be revised
    SELECT lab.patientunitstayid,
           lab.labname,
           lab.labresultoffset,
           lab.labresultrevisedoffset,
           lab.labresult,
           ROW_NUMBER() OVER
               (
               PARTITION BY lab.patientunitstayid, lab.labname, lab.labresultoffset
               ORDER BY lab.labresultrevisedoffset DESC
               ) AS rn
    FROM `physionet-data.eicu_crd.lab` AS lab
             INNER JOIN vw0
                        ON lab.patientunitstayid = vw0.patientunitstayid
                            AND lab.labname = vw0.labname
                            AND lab.labresultoffset = vw0.labresultoffset
                            AND lab.labresultrevisedoffset = vw0.labresultrevisedoffset
    -- only valid lab values
), vw2 AS (
    SELECT patientunitstayid,
           labresultoffset AS chartoffset,
           MAX(CASE WHEN labname = 'troponin - T' THEN labresult ELSE NULL END) AS troponin_t,
           MAX(CASE WHEN labname = 'CPK-MB' THEN labresult ELSE NULL END) AS ck_mb
    FROM vw1
    WHERE rn = 1
    GROUP BY patientunitstayid, labresultoffset
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime_ho + le.chartoffset            AS chart_ho,
       le.chartoffset                           AS chart_io,
       le.troponin_t,
       le.ck_mb,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.chartoffset            AS charttime,
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN vw2 AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY subject_id, hadm_id, ie.stay_id, ie.intime_ho + le.chartoffset;









