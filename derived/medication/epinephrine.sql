
-- ====================================================================================================
-- epinephrine
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/medication/epinephrine.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

-- SELECT drugname,
--        count(*) AS nobs
-- FROM aims_eicu_crd_icu.icustays AS ie
--          INNER JOIN `physionet-data.eicu_crd.infusiondrug` AS rx
--                     ON ie.patientunitstayid = rx.patientunitstayid
-- WHERE LOWER(rx.drugname) LIKE '%epinephrine%'
--   AND LOWER(rx.drugname) NOT LIKE '%norepinephrine%'
--   AND REGEXP_CONTAINS(rx.drugrate, '[0-9]*[.]?[0-9]+')
--   AND NOT REGEXP_CONTAINS(rx.drugrate, '^[0-9]*[.]?[0-9]+$')
--   AND rx.drugrate <> ''
--   AND rx.drugrate <> '.'
-- GROUP BY drugname;

DROP TABLE IF EXISTS aims_eicu_crd_derived.epinephrine;
CREATE TABLE aims_eicu_crd_derived.epinephrine AS
WITH rx1 AS (
    SELECT ie.uniquepid,
           ie.patienthealthsystemstayid,
           ie.patientunitstayid,
           ie.intime_ho + rx.infusionoffset AS start_ho,
           rx.infusionoffset                AS start_io,
           rx.drugname,
           CASE
               WHEN lower(rx.drugname) LIKE '%(mcg/kg/min)%'
                   THEN round(SAFE_CAST(rx.drugrate AS NUMERIC), 3)
               WHEN lower(rx.drugname) LIKE '%(mcg/kg/hr)%'
                   THEN round(SAFE_CAST(rx.drugrate AS NUMERIC) / 60, 3)
               WHEN lower(rx.drugname) LIKE '%(mg/kg/min)%'
                   THEN SAFE_CAST(rx.drugrate AS NUMERIC) * 1000
               WHEN lower(rx.drugname) LIKE '%(mcg/min)%'
                   THEN CASE
                            WHEN rx.patientweight IS NOT NULL AND rx.patientweight > 10
                                THEN round(SAFE_CAST(rx.drugrate AS NUMERIC) / rx.patientweight, 3)
                            ELSE round(SAFE_CAST(rx.drugrate AS NUMERIC) / 80, 3) END
               WHEN lower(rx.drugname) LIKE '%(mcg/hr)%'
                   THEN CASE
                            WHEN rx.patientweight IS NOT NULL AND rx.patientweight > 10
                                THEN round(SAFE_CAST(rx.drugrate AS NUMERIC) / rx.patientweight / 60, 3)
                            ELSE round(SAFE_CAST(rx.drugrate AS NUMERIC) / 80 / 60, 3) END
               WHEN lower(rx.drugname) LIKE '%(ml/hr)%'
                   THEN CASE
                            WHEN rx.patientweight IS NOT NULL AND rx.patientweight > 10
                                THEN round(
                                    SAFE_CAST(rx.drugrate AS NUMERIC) * 1000 /
                                    SAFE_CAST(rx.volumeoffluid AS NUMERIC) / rx.patientweight / 60, 3)
                            ELSE round(
                                    SAFE_CAST(rx.drugrate AS NUMERIC) * 1000 /
                                    SAFE_CAST(rx.volumeoffluid AS NUMERIC) / 80 / 60, 3) END
               ELSE round(SAFE_CAST(rx.drugrate AS NUMERIC), 3)
               END                          AS drugrate,
           rx.infusionrate,
           rx.drugamount,
           rx.volumeoffluid,
           rx.patientweight,
           -- MIMIC style
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           ie.intime_ho + rx.infusionoffset AS starttime,
           CASE
               WHEN lower(rx.drugname) LIKE '%(mcg/kg/min)%'
                   THEN round(SAFE_CAST(rx.drugrate AS NUMERIC), 3)
               WHEN lower(rx.drugname) LIKE '%(mcg/kg/hr)%'
                   THEN round(SAFE_CAST(rx.drugrate AS NUMERIC) / 60, 3)
               WHEN lower(rx.drugname) LIKE '%(mg/kg/min)%'
                   THEN SAFE_CAST(rx.drugrate AS NUMERIC) * 1000
               WHEN lower(rx.drugname) LIKE '%(mcg/min)%'
                   THEN CASE
                            WHEN rx.patientweight IS NOT NULL AND rx.patientweight > 10
                                THEN round(SAFE_CAST(rx.drugrate AS NUMERIC) / rx.patientweight, 3)
                            ELSE round(SAFE_CAST(rx.drugrate AS NUMERIC) / 80, 3) END
               WHEN lower(rx.drugname) LIKE '%(mcg/hr)%'
                   THEN CASE
                            WHEN rx.patientweight IS NOT NULL AND rx.patientweight > 10
                                THEN round(SAFE_CAST(rx.drugrate AS NUMERIC) / rx.patientweight / 60, 3)
                            ELSE round(SAFE_CAST(rx.drugrate AS NUMERIC) / 80 / 60, 3) END
               WHEN lower(rx.drugname) LIKE '%(ml/hr)%'
                   THEN CASE
                            WHEN rx.patientweight IS NOT NULL AND rx.patientweight > 10
                                THEN round(
                                    SAFE_CAST(rx.drugrate AS NUMERIC) * 1000 /
                                    SAFE_CAST(rx.volumeoffluid AS NUMERIC) / rx.patientweight / 60, 3)
                            ELSE round(
                                    SAFE_CAST(rx.drugrate AS NUMERIC) * 1000 /
                                    SAFE_CAST(rx.volumeoffluid AS NUMERIC) / 80 / 60, 3) END
               ELSE round(SAFE_CAST(rx.drugrate AS NUMERIC), 3)
               END                          AS vaso_rate,
	           -- endtime imputation purpose
	           ie.intime_ho,
	           ie.intime_io,
	           ie.intime,
	           ie.outtime_ho,
	           ie.outtime_io,
	           ie.outtime
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd.infusiondrug` AS rx
                        ON ie.patientunitstayid = rx.patientunitstayid
    WHERE LOWER(rx.drugname) LIKE '%epinephrine%'
      AND LOWER(rx.drugname) NOT LIKE '%norepinephrine%'
      AND rx.drugname NOT IN ('Epinephrine (mg/hr)', 'Epinephrine ()')
      AND REGEXP_CONTAINS(rx.drugrate, '^[0-9]*[.]?[0-9]+$')
      AND rx.drugrate <> ''
      AND rx.drugrate <> '.'
    ORDER BY ie.subject_id, ie.hadm_id, ie.intime_ho + rx.infusionoffset
), rx2 AS (
    SELECT uniquepid,
           patienthealthsystemstayid,
           patientunitstayid,
           start_ho,
           start_io,
           LEAD(start_ho) OVER (
               PARTITION BY stay_id
               ORDER BY starttime
               ) AS end_ho,
           LEAD(start_io) OVER (
               PARTITION BY stay_id
               ORDER BY starttime
               ) AS end_io,
           drugname,
           drugrate,
           infusionrate,
           drugamount,
           volumeoffluid,
           patientweight,
           -- MIMIC style
           subject_id,
           hadm_id,
           stay_id,
           starttime,
           LEAD(starttime) OVER (
               PARTITION BY stay_id
               ORDER BY starttime
               ) AS endtime,
           vaso_rate,
           -- endtime imputation purpose
           intime_ho,
           intime_io,
           intime,
           outtime_ho,
           outtime_io,
           outtime
    FROM rx1
    ORDER BY subject_id, hadm_id, stay_id, starttime
)
SELECT uniquepid,
       patienthealthsystemstayid,
       patientunitstayid,
       start_ho,
       start_io,
       CASE
           WHEN end_ho IS NULL
               THEN LEAST(start_ho + 60 * 4, outtime_ho)
           ELSE LEAST(start_ho + 60 * 4, end_ho)
           END AS end_ho,
       CASE
           WHEN end_io IS NULL
               THEN LEAST(start_io + 60 * 4, outtime_io)
           ELSE LEAST(start_io + 60 * 4, end_io)
           END AS end_io,
       drugname,
       drugrate,
       infusionrate,
       drugamount,
       volumeoffluid,
       patientweight,
       -- MIMIC style
       subject_id,
       hadm_id,
       stay_id,
       starttime,
       CASE
           WHEN endtime IS NULL
               THEN LEAST(starttime + 60 * 4, outtime)
           ELSE LEAST(starttime + 60 * 4, endtime)
           END AS endtime,
       vaso_rate,
       -- endtim
FROM rx2
ORDER BY subject_id, hadm_id, stay_id, starttime;









