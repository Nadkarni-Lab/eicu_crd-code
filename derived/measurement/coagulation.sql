
-- ====================================================================================================
-- coagulation
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-iv/blob/master/concepts/measurement/coagulation.sql
-- - https://github.com/MIT-LCP/eicu-code/blob/main/concepts/pivoted/pivoted-lab.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.coagulation;
CREATE TABLE aims_eicu_crd_derived.coagulation AS
-- remove duplicate labs if they exist at the same time
WITH vw0 AS
(
    SELECT patientunitstayid,
           labname,
           labresultoffset,
           labresultrevisedoffset
  FROM physionet-data.eicu_crd.lab
    WHERE labname IN
          ('fibrinogen',
           'PT - INR',
           'PT',
           'PTT'
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
    WHERE (lab.labname = 'fibrinogen' AND lab.labresult >= 0 AND lab.labresult <= 10000)
       OR (lab.labname = 'PT - INR' AND lab.labresult >= 0 AND lab.labresult <= 100)
       OR (lab.labname = 'PT' AND lab.labresult >= 0 AND lab.labresult <= 1000)
       OR (lab.labname = 'PTT' AND lab.labresult >= 0 AND lab.labresult <= 1000)
), vw2 AS (
    SELECT patientunitstayid,
           labresultoffset                                                    AS chartoffset,
           MAX(CASE WHEN labname = 'fibrinogen' then labresult ELSE NULL END) AS fibrinogen,
           MAX(CASE WHEN labname = 'PT - INR' then labresult ELSE NULL END)   AS inr,
           MAX(CASE WHEN labname = 'PT' then labresult ELSE NULL END)         AS pt,
           MAX(CASE WHEN labname = 'PTT' then labresult ELSE NULL END)        AS ptt
    FROM vw1
    WHERE rn = 1
    GROUP BY patientunitstayid, labresultoffset
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime_ho + le.chartoffset AS chart_ho,
       le.chartoffset                AS chart_io,
       NULL                          AS d_dimer,
       le.fibrinogen,
       NULL                          AS thrombin,
       le.inr,
       le.pt,
       le.ptt,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.chartoffset AS charttime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN vw2 AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY subject_id, hadm_id, ie.stay_id, ie.intime_ho + le.chartoffset









