
-- ====================================================================================================
-- blood differential
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-iv/blob/master/concepts/measurement/blood_differential.sql
-- - https://github.com/MIT-LCP/eicu-code/blob/main/concepts/pivoted/pivoted-lab.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.blood_differential;
CREATE TABLE aims_eicu_crd_derived.blood_differential AS
-- remove duplicate labs if they exist at the same time
WITH vw0 AS
(
    SELECT patientunitstayid,
           labname,
           labresultoffset,
           labresultrevisedoffset
  FROM physionet-data.eicu_crd.lab
    WHERE labname IN
          ('-basos',
           '-eos',
           '-lymphs',
           '-monos',
           '-polys',
           '-bands'
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
               ) as rn
    FROM physionet-data.eicu_crd.lab AS lab
             INNER JOIN vw0
                        ON lab.patientunitstayid = vw0.patientunitstayid
                            AND lab.labname = vw0.labname
                            AND lab.labresultoffset = vw0.labresultoffset
                            AND lab.labresultrevisedoffset = vw0.labresultrevisedoffset
    -- only valid lab values
    WHERE (lab.labname = '-basos' AND lab.labresult >= 0 AND lab.labresult <= 100)
       OR (lab.labname = '-eos' AND lab.labresult >= 0 AND lab.labresult <= 100)
       OR (lab.labname = '-lymphs' AND lab.labresult >= 0 AND lab.labresult <= 100)
       OR (lab.labname = '-monos' AND lab.labresult >= 0 AND lab.labresult <= 100)
       OR (lab.labname = '-polys' AND lab.labresult >= 0 AND lab.labresult <= 100)
       OR (lab.labname = '-bands' AND lab.labresult >= 0 AND lab.labresult <= 100)
), vw2 AS (
    SELECT patientunitstayid,
           labresultoffset                                                  AS chartoffset,
           MAX(CASE WHEN labname = '-basos' then labresult ELSE NULL END)   AS basophils,
           MAX(CASE WHEN labname = '-eos' then labresult ELSE NULL END)     AS eosinophils,
           MAX(CASE WHEN labname = '-lymphsp' then labresult ELSE NULL END) AS lymphocytes,
           MAX(CASE WHEN labname = '-monos' then labresult ELSE NULL END)   AS monocytes,
           MAX(CASE WHEN labname = '-polys' then labresult ELSE NULL END)   AS neutrophils,
           MAX(CASE WHEN labname = '-bands' then labresult ELSE NULL END)   AS bands
    FROM vw1
    WHERE rn = 1
    GROUP BY patientunitstayid, labresultoffset
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime_ho + le.chartoffset AS chart_ho,
       le.chartoffset                AS chart_io,
       le.basophils,
       le.eosinophils,
       le.lymphocytes,
       le.monocytes,
       le.neutrophils,
       le.bands,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.chartoffset AS charttime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN vw2 AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY subject_id, hadm_id, ie.stay_id, ie.intime_ho + le.chartoffset









