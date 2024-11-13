
-- ====================================================================================================
-- complete blood count
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-iv/blob/master/concepts/measurement/complete_blood_count.sql
-- - https://github.com/MIT-LCP/eicu-code/blob/main/concepts/pivoted/pivoted-lab.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.complete_blood_count;
CREATE TABLE aims_eicu_crd_derived.complete_blood_count AS
-- remove duplicate labs if they exist at the same time
WITH vw0 AS
(
    SELECT patientunitstayid,
           labname,
           labresultoffset,
           labresultrevisedoffset
  FROM physionet-data.eicu_crd.lab
    WHERE labname IN
          ('Hct',
           'Hgb',
           'MCH',
           'MCHC',
           'MCV',
           'platelets x 1000',
           'RBC',
           'RDW',
           'WBC x 1000'
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
    WHERE (lab.labname = 'Hct' AND lab.labresult >= 5 AND lab.labresult <= 75)
       OR (lab.labname = 'Hgb' AND lab.labresult > 0 AND lab.labresult <= 9999)
       OR (lab.labname = 'MCH' AND lab.labresult > 0)
       OR (lab.labname = 'MCHC' AND lab.labresult > 0)
       OR (lab.labname = 'MCV' AND lab.labresult > 0)
       OR (lab.labname = 'platelets x 1000' AND lab.labresult > 0 AND lab.labresult <= 9999)
       OR (lab.labname = 'RBC' AND lab.labresult > 0)
       OR (lab.labname = 'RDW' AND lab.labresult > 0)
       OR (lab.labname = 'WBC x 1000' AND lab.labresult > 0 AND lab.labresult <= 100)
), vw2 AS (
    SELECT patientunitstayid,
           labresultoffset                                                          AS chartoffset,
           MAX(CASE WHEN labname = 'Hct' then labresult ELSE NULL END)              AS hematocrit,
           MAX(CASE WHEN labname = 'Hgb' then labresult ELSE NULL END)              AS hemoglobin,
           MAX(CASE WHEN labname = 'MCH' then labresult ELSE NULL END)              AS mch,
           MAX(CASE WHEN labname = 'MCHC' then labresult ELSE NULL END)             AS mchc,
           MAX(CASE WHEN labname = 'MCV' then labresult ELSE NULL END)              AS mcv,
           MAX(CASE WHEN labname = 'platelets x 1000' then labresult ELSE NULL END) AS platelet,
           MAX(CASE WHEN labname = 'RBC' then labresult ELSE NULL END)              AS rbc,
           MAX(CASE WHEN labname = 'RDW' then labresult ELSE NULL END)              AS rdw,
           NULL                                                                     AS rdwsd,
           MAX(CASE WHEN labname = 'WBC x 1000' then labresult ELSE NULL END)       AS wbc
    FROM vw1
    WHERE rn = 1
    GROUP BY patientunitstayid, labresultoffset
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime_ho + le.chartoffset AS chart_ho,
       le.chartoffset                AS chart_io,
       le.hematocrit,
       le.hemoglobin,
       le.mch,
       le.mchc,
       le.mcv,
       le.platelet,
       le.rbc,
       le.rdw,
       le.rdwsd,
       le.wbc,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.chartoffset AS charttime,
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN vw2 AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY ie.subject_id, ie.hadm_id, ie.stay_id, ie.intime_ho + le.chartoffset;









