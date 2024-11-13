
-- ====================================================================================================
-- Creatinine
-- Version: 1.2
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- Purpose:
-- - The primary purpose of this code is to extract creatinine measurements while addressing the issue
--   of possible outliers encountered during clinical practice. Creatinine measurements are prone to
--   displaying unusually high or low levels, which can lead to inaccurate readings. To tackle this
--   problem, the code identifies and excludes abnormal measurements by leveraging repeated
--   measurements taken during clinical practice. These measurements are retained in the database. The
--   code's main function is to remove creatinine measurements that have increased by either 2 times
--   or 0.5 times within a 36-hour window and subsequently returned to a value near their previous
--   measurement within 6 hours. By applying this filtering process, the code ensures that the
--   extracted creatinine data is more reliable for further analysis and interpretation in medical
--   contexts.
-- ToDo:
-- - Erroneously high or low creatinine during the outpatient setting.
-- History:
-- - 1.0: Create new query.
-- - 1.1: Add constraint for creatinine less than 0.3.
-- - 1.2: Minor error fix.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.creatinine;
CREATE TABLE aims_eicu_crd_derived.creatinine AS
-- remove duplicate labs if they exist at the same time
WITH cr0 AS
(
    SELECT ie.uniquepid,
           ie.patienthealthsystemstayid,
           ie.patientunitstayid,
           ie.intime_ho + le.labresultoffset AS chart_ho,
           le.labresultoffset                AS chart_io,
           le.labresultrevisedoffset,
           le.labname,
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           ie.intime_ho + le.labresultoffset AS charttime
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd.lab` AS le
                        ON ie.patientunitstayid = le.patientunitstayid
    WHERE labname = 'creatinine'
      AND le.labresult >= 0.1
      AND le.labresult <= 30.00
    GROUP BY ie.uniquepid, ie.patienthealthsystemstayid, ie.patientunitstayid,
             ie.intime_ho, le.labresultoffset, le.labresultrevisedoffset, le.labname,
             ie.subject_id, ie.hadm_id, ie.stay_id
    HAVING COUNT(DISTINCT le.labresult) <= 1
), cr1 AS (
    -- get all creatinine
    SELECT cr0.uniquepid,
           cr0.patienthealthsystemstayid,
           cr0.patientunitstayid,
           cr0.chart_ho,
           cr0.chart_io,
           le.labresult AS creatinine,
           cr0.subject_id,
           cr0.hadm_id,
           cr0.stay_id,
           cr0.charttime,
           ROW_NUMBER() OVER
               (
               PARTITION BY cr0.hadm_id, cr0.charttime
               ORDER BY le.labresultrevisedoffset DESC
               )        AS rn
    FROM physionet-data.eicu_crd.lab AS le
             INNER JOIN cr0
                        ON le.patientunitstayid = cr0.patientunitstayid AND
                           le.labname = cr0.labname AND
                           le.labresultoffset = cr0.chart_io
    -- only valid lab values
    WHERE le.labname = 'creatinine'
      AND le.labresult >= 0.1
      AND le.labresult <= 30.00
), cr2 AS (
    SELECT uniquepid,
           patienthealthsystemstayid,
           patientunitstayid,
           chart_ho,
           chart_io,
           creatinine,
           subject_id,
           hadm_id,
           stay_id,
           charttime
    FROM cr1
    WHERE rn = 1
), cr3 AS (
    SELECT *,
           LAG(charttime, 1) OVER (PARTITION BY hadm_id ORDER BY charttime)  AS charttime_lag1,
           LEAD(charttime, 1) OVER (PARTITION BY hadm_id ORDER BY charttime) AS charttime_lead1,
           LEAD(charttime, 2) OVER (PARTITION BY hadm_id ORDER BY charttime) AS charttime_lead2,
           LAG(creatinine, 1) OVER (PARTITION BY hadm_id ORDER BY charttime)   AS creatinine_lag1,
           LEAD(creatinine, 1) OVER (PARTITION BY hadm_id ORDER BY charttime)  AS creatinine_lead1,
           LEAD(creatinine, 2) OVER (PARTITION BY hadm_id ORDER BY charttime)  AS creatinine_lead2
    FROM cr2
    ORDER BY hadm_id, charttime
)
SELECT uniquepid,
       patienthealthsystemstayid,
       patientunitstayid,
       chart_ho,
       chart_io,
       creatinine,
       subject_id,
       hadm_id,
       stay_id,
       charttime
FROM cr3
-- Increased 2 or 0.5 times within 36 hours and return to near previous measurement following 6 hours.
WHERE NOT (
	(charttime <= (charttime_lag1 + 60*36) AND
           charttime_lead1 <= (charttime + 60 * 6) AND
           ((creatinine > 2 * creatinine_lag1 AND creatinine > 2 * creatinine_lead1) OR
            (creatinine < 0.5 * creatinine_lag1 AND creatinine < 0.5 * creatinine_lead1))) OR
	        -- Ankit said he hasn't had a chance to see creatinine less than 0.3.
	        -- Still, such a number is still possible. Therefore, we add one more constraint:
	        -- - creatinine is less than 0.3,
	        -- - increased 2 or 0.5 times within 180 days,
	        -- - and returns to near previous measurement following 180 days.
	        (charttime <= (charttime_lag1 + 60 * 24 * 180) AND
	         charttime_lead1 <= (charttime + 60 * 24 * 180) AND
	         creatinine < 0.3 AND
	         ((creatinine > 2 * creatinine_lag1 AND creatinine > 2 * creatinine_lead1) OR
	          (creatinine < 0.5 * creatinine_lag1 AND creatinine < 0.5 * creatinine_lead1)))
		  )
ORDER BY subject_id, hadm_id, charttime;









