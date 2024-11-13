
-- ====================================================================================================
-- vital sign
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-iv/blob/master/concepts/measurement/vitalsign.sql
-- - https://github.com/MIT-LCP/eicu-code/blob/main/concepts/pivoted/pivoted-lab.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.vitalsign;
CREATE TABLE aims_eicu_crd_derived.vitalsign AS
WITH vw0 AS (
    SELECT patientunitstayid,
           nursingchartoffset,
           nursingchartentryoffset,
           CASE
               WHEN nursingchartcelltypevallabel = 'Heart Rate' AND
                    nursingchartcelltypevalname = 'Heart Rate' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue as numeric)
               ELSE NULL END
               AS heart_rate,
           CASE
               WHEN nursingchartcelltypevallabel = 'Invasive BP' AND
                    nursingchartcelltypevalname = 'Invasive BP Systolic' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue as numeric)
               ELSE NULL END
               AS sbp,
           CASE
               WHEN nursingchartcelltypevallabel = 'Invasive BP' AND
                    nursingchartcelltypevalname = 'Invasive BP Diastolic' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS dbp,
           CASE
               WHEN nursingchartcelltypevallabel = 'Invasive BP' AND
                    nursingchartcelltypevalname = 'Invasive BP Mean' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               -- other map fields
               WHEN nursingchartcelltypevallabel = 'MAP (mmHg)' AND
                    nursingchartcelltypevalname = 'Value' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               WHEN nursingchartcelltypevallabel = 'Arterial Line MAP (mmHg)' AND
                    nursingchartcelltypevalname = 'Value' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS mbp,
           CASE
               WHEN nursingchartcelltypevallabel = 'Non-Invasive BP' AND
                    nursingchartcelltypevalname = 'Non-Invasive BP Systolic' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS sbp_ni,
           CASE
               WHEN nursingchartcelltypevallabel = 'Non-Invasive BP' AND
                    nursingchartcelltypevalname = 'Non-Invasive BP Diastolic' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS dbp_ni,
           CASE
               WHEN nursingchartcelltypevallabel =
                    'Non-Invasive BP' AND
                    nursingchartcelltypevalname =
                    'Non-Invasive BP Mean' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS mbp_ni,
           CASE
               WHEN nursingchartcelltypevallabel =
                    'Respiratory Rate' AND
                    nursingchartcelltypevalname =
                    'Respiratory Rate' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS resp_rate,
           CASE
               WHEN nursingchartcelltypevallabel = 'Temperature' AND
                    nursingchartcelltypevalname =
                    'Temperature (C)' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS temperature,
           CASE
               WHEN nursingchartcelltypevallabel = 'O2 Saturation' AND
                    nursingchartcelltypevalname = 'O2 Saturation' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS spo2,
           CASE
               WHEN nursingchartcelltypevallabel = 'Bedside Glucose' AND
                    nursingchartcelltypevalname = 'Bedside Glucose' AND
                    REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$') AND
                    nursingchartvalue not in ('-', '.')
                   THEN CAST(nursingchartvalue AS numeric)
               ELSE NULL END
               AS glucose
    FROM physionet-data.eicu_crd.nursecharting
), vw1 AS (
    SELECT patientunitstayid,
           nursingchartoffset,
           nursingchartentryoffset,
           CASE
               WHEN heart_rate > 0 AND
                    heart_rate < 300
                   THEN heart_rate
               END
               AS heart_rate,
           CASE
               WHEN sbp > 0 AND
                    sbp < 400
                   THEN sbp
               END
               AS sbp,
           CASE
               WHEN dbp > 0 AND
                    dbp < 300
                   THEN dbp
               END
               AS dbp,
           CASE
               WHEN mbp > 0 AND
                    mbp < 300
                   THEN mbp
               END
               AS mbp,
           CASE
               WHEN sbp_ni > 0 AND
                    sbp_ni < 400
                   THEN sbp_ni
               END
               AS sbp_ni,
           CASE
               WHEN dbp_ni > 0 AND
                    dbp_ni < 300
                   THEN dbp_ni
               END
               AS dbp_ni,
           CASE
               WHEN mbp_ni > 0 AND
                    mbp_ni < 300
                   THEN mbp_ni
               END
               AS mbp_ni,
           CASE
               WHEN resp_rate > 0 AND
                    resp_rate < 70
                   THEN resp_rate
               END
               AS resp_rate,
           CASE
               WHEN temperature > 10 AND
                    temperature < 50
                   THEN temperature
               END
               AS temperature,
           CASE
               WHEN spo2 > 0 AND
                    spo2 <= 100
                   THEN spo2
               END
               AS spo2,
           CASE
               WHEN glucose > 0
                   THEN glucose
               END
               AS glucose
    FROM vw0
), vw2 AS (
    SELECT patientunitstayid,
           nursingchartoffset,
           nursingchartentryoffset,
           heart_rate,
           sbp,
           dbp,
           mbp,
           sbp_ni,
           dbp_ni,
           mbp_ni,
           resp_rate,
           temperature,
           spo2,
           glucose
    FROM vw1
    WHERE heart_rate IS NOT NULL
       OR sbp IS NOT NULL
       OR dbp IS NOT NULL
       OR mbp IS NOT NULL
       OR sbp_ni IS NOT NULL
       OR dbp_ni IS NOT NULL
       OR mbp_ni IS NOT NULL
       OR resp_rate IS NOT NULL
       OR temperature IS NOT NULL
       OR spo2 IS NOT NULL
       OR glucose IS NOT NULL
), vw3 AS (
    SELECT patientunitstayid,
           nursingchartoffset,
           nursingchartentryoffset,
           AVG(heart_rate) AS heart_rate,
           AVG(sbp) AS sbp,
           AVG(dbp) AS dbp,
           AVG(mbp) AS mbp,
           AVG(sbp_ni) AS sbp_ni,
           AVG(dbp_ni) AS dbp_ni,
           AVG(mbp_ni) AS mbp_ni,
           AVG(resp_rate) AS resp_rate,
           AVG(temperature) AS temperature,
           NULL AS temperature_site,
           AVG(spo2) AS spo2,
           AVG(glucose) AS glucose
    FROM vw2
    GROUP BY patientunitstayid, nursingchartoffset, nursingchartentryoffset
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       ie.intime_ho + le.nursingchartoffset AS chart_ho,
       le.nursingchartoffset                AS chart_io,
       le.nursingchartentryoffset,
       le.heart_rate,
       le.sbp,
       le.dbp,
       le.mbp,
       le.sbp_ni,
       le.dbp_ni,
       le.mbp_ni,
       le.resp_rate,
       le.temperature,
       le.temperature_site,
       le.spo2,
       le.glucose,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.nursingchartoffset AS charttime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN vw3 AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY subject_id, hadm_id, ie.intime_ho + le.nursingchartoffset;









