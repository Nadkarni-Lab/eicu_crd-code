
-- ====================================================================================================
-- chemistry
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-iv/blob/master/concepts/measurement/chemistry.sql
-- - https://github.com/MIT-LCP/eicu-code/blob/main/concepts/pivoted/pivoted-lab.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.chemistry;
CREATE TABLE aims_eicu_crd_derived.chemistry AS
-- remove duplicate labs if they exist at the same time
WITH vw0 AS
(
    SELECT patientunitstayid,
           labname,
           labresultoffset,
           labresultrevisedoffset
  FROM physionet-data.eicu_crd.lab
    WHERE labname IN
          ('albumin',
           'total protein',
           'anion gap',
           'bicarbonate',
           'BUN',
           'calcium',
           'chloride',
           'glucose', 'bedside glucose', 
           'sodium',
           'potassium'
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
    WHERE (lab.labname = 'albumin' AND lab.labresult > 0 AND lab.labresult <= 10)
       OR (lab.labname = 'total protein' AND lab.labresult > 0 AND lab.labresult <= 20)
       OR (lab.labname = 'anion gap' AND lab.labresult >= 0 AND lab.labresult <= 10000)
       OR (lab.labname = 'bicarbonate' AND lab.labresult > 0 AND lab.labresult <= 10000)
       OR (lab.labname = 'BUN' AND lab.labresult > 0 AND lab.labresult <= 300)
       OR (lab.labname = 'calcium' AND lab.labresult > 0 AND lab.labresult <= 10000)
       OR (lab.labname = 'chloride' AND lab.labresult > 0 AND lab.labresult <= 10000)
       OR (lab.labname IN ('glucose', 'bedside glucose') AND lab.labresult > 0 AND lab.labresult <= 10000)
       OR (lab.labname = 'sodium' AND lab.labresult > 0 AND lab.labresult <= 200)
       OR (lab.labname = 'potassium' AND lab.labresult > 0 AND lab.labresult <= 30)
), vw2 AS (
    SELECT patientunitstayid,
           labresultoffset                                                                       AS chartoffset,
           MAX(CASE WHEN labname = 'albumin' then labresult ELSE NULL END)                       AS albumin,
           NULL                                                                                  AS globulin,
           MAX(CASE WHEN labname = 'total protein' then labresult ELSE NULL END)                 AS total_protein,
           MAX(CASE WHEN labname = 'anion gap' then labresult ELSE NULL END)                     AS aniongap,
           MAX(CASE WHEN labname = 'bicarbonate' then labresult ELSE NULL END)                   AS bicarbonate,
           MAX(CASE WHEN labname = 'BUN' then labresult ELSE NULL END)                           AS bun,
           MAX(CASE WHEN labname = 'calcium' then labresult ELSE NULL END)                       AS calcium,
           MAX(CASE WHEN labname = 'chloride' then labresult ELSE NULL END)                      AS chloride,
           MAX(CASE WHEN labname IN ('glucose', 'bedside glucose') then labresult ELSE NULL END) AS glucose,
           MAX(CASE WHEN labname = 'sodium' then labresult ELSE NULL END)                        AS sodium,
           MAX(CASE WHEN labname = 'potassium' then labresult ELSE NULL END)                     AS potassium
    FROM vw1
    WHERE rn = 1
    GROUP BY patientunitstayid, labresultoffset
), vw3 AS (
    SELECT ie.uniquepid,
           ie.patienthealthsystemstayid,
           ie.patientunitstayid,
           ie.intime_ho + le.chartoffset AS chart_ho,
           le.chartoffset                AS chart_io,
           le.albumin,
           le.globulin,
           le.total_protein,
           le.aniongap,
           le.bicarbonate,
           le.bun,
           le.calcium,
           le.chloride,
           le.glucose,
           le.sodium,
           le.potassium,
           -- MIMIC style
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           ie.intime_ho + le.chartoffset AS charttime
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN vw2 AS le
                        ON ie.patientunitstayid = le.patientunitstayid
    ORDER BY subject_id, hadm_id, ie.intime_ho + le.chartoffset
)
SELECT COALESCE(l1.uniquepid, l2.uniquepid)                                 AS uniquepid,
       COALESCE(l1.patienthealthsystemstayid, l2.patienthealthsystemstayid) AS patienthealthsystemstayid,
       COALESCE(l1.patientunitstayid, l2.patientunitstayid)                 AS patientunitstayid,
       COALESCE(l1.chart_ho, l2.chart_ho)                                   AS chart_ho,
       COALESCE(l1.chart_io, l2.chart_io)                                   AS chart_io,
       l1.albumin,
       l1.globulin,
       l1.total_protein,
       l1.aniongap,
       l1.bicarbonate,
       l1.bun,
       l1.calcium,
       l1.chloride,
       l2.creatinine,
       l1.glucose,
       l1.sodium,
       l1.potassium,
-- MIMIC style
       COALESCE(l1.subject_id, l2.subject_id)                               AS subject_id,
       COALESCE(l1.hadm_id, l2.hadm_id)                                     AS hadm_id,
       COALESCE(l1.stay_id, l2.stay_id)                                     AS stay_id,
       COALESCE(l1.charttime, l2.charttime)                                 AS charttime
FROM vw3 AS l1
         FULL JOIN aims_eicu_crd_derived.creatinine AS l2
                   ON l1.stay_id = l2.stay_id AND
                      l1.charttime = l2.charttime
ORDER BY COALESCE(l1.subject_id, l2.subject_id), COALESCE(l1.hadm_id, l2.hadm_id), COALESCE(l1.stay_id, l2.stay_id), COALESCE(l1.charttime, l2.charttime);









