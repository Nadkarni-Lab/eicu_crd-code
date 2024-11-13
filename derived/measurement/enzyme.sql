
-- ====================================================================================================
-- enzyme
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-iv/blob/master/concepts/measurement/enzyme.sql
-- - https://github.com/MIT-LCP/eicu-code/blob/main/concepts/pivoted/pivoted-lab.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.enzyme;
CREATE TABLE aims_eicu_crd_derived.enzyme AS
WITH vw0 AS (
    SELECT patientunitstayid,
           labname,
           labresultoffset,
           labresultrevisedoffset
    FROM `physionet-data.eicu_crd.lab`
    WHERE labname IN
          ('ALT (SGPT)', -- alt
           'alkaline phos.', -- alp
           'AST (SGOT)', -- ast
           'amylase', -- amylase
           'total bilirubin', -- bilirubin_total
           'direct bilirubin', -- bilirubin_direct
           'CPK', -- ck_cpk
           'CPK-MB', -- ck_mb
           'LDH' --ld_ldh
              )
    GROUP BY patientunitstayid, labname, labresultoffset, labresultrevisedoffset
    HAVING COUNT(DISTINCT labresult)<=1
), vw1 AS (
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
    WHERE lab.labresult > 0
), vw2 AS (
    SELECT patientunitstayid,
           labresultoffset AS chartoffset,
           MAX(CASE WHEN labname = 'ALT (SGPT)' THEN labresult ELSE NULL END) AS alt,
           MAX(CASE WHEN labname = 'alkaline phos.' THEN labresult ELSE NULL END) AS alp,
           MAX(CASE WHEN labname = 'AST (SGOT)' THEN labresult ELSE NULL END) AS ast,
           MAX(CASE WHEN labname = 'amylase' THEN labresult ELSE NULL END) AS amylase,
           MAX(CASE WHEN labname = 'total bilirubin' THEN labresult ELSE NULL END) AS bilirubin_total,
           MAX(CASE WHEN labname = 'direct bilirubin' THEN labresult ELSE NULL END) AS bilirubin_direct,
           MAX(CASE WHEN labname = 'CPK' THEN labresult ELSE NULL END) AS ck_cpk,
           MAX(CASE WHEN labname = 'CPK-MB' THEN labresult ELSE NULL END) AS ck_mb,
           MAX(CASE WHEN labname = 'LDH' THEN labresult ELSE NULL END) AS ld_ldh
    FROM vw1
    WHERE rn = 1
    GROUP BY patientunitstayid, labresultoffset
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime_ho + le.chartoffset            AS chart_ho,
       le.chartoffset                           AS chart_io,
       le.alt,
       le.alp,
       le.ast,
       le.amylase,
       le.bilirubin_total,
       le.bilirubin_direct,
       le.bilirubin_total - le.bilirubin_direct AS bilirubin_indirect,
       le.ck_cpk,
       le.ck_mb,
       NULL                                     AS ggt,
       le.ld_ldh,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.chartoffset            AS charttime,
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN vw2 AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY subject_id, hadm_id, ie.intime_ho + le.chartoffset;









