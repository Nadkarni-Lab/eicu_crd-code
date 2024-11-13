
-- ====================================================================================================
-- icustay_hourly
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/demographics/icustay_hourly.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

-- This query generates a row for every hour the patient is in the ICU.
-- The hours are based on clock-hours (i.e. 02:00, 03:00).
-- The hour clock starts 24 hours before the first heart rate measurement.
-- Note that the time of the first heart rate measurement is ceilinged to the hour.

-- this query extracts the cohort and every possible hour they were in the ICU
-- this table can be to other tables on ICUSTAY_ID and (ENDTIME - 1 hour,ENDTIME]

-- get first/last measurement time
DROP TABLE IF EXISTS aims_eicu_crd_derived.icustay_hourly;
CREATE TABLE aims_eicu_crd_derived.icustay_hourly AS
WITH all_hours AS
(
    SELECT it.patientunitstayid,
           -- it.intime_hr_ho,
           -- it.outtime_hr_ho,
           -- it.intime_hr_io,
           -- it.outtime_hr_io,
           -- ceiling the intime to the nearest hour by adding 59 minutes then truncating
           -- note thart we truncate by parsing as string, rather than using DATETIME_TRUNC
           -- this is done to enable compatibility with psql

           CEIL(it.intime_hr_ho / 60) * 60                                      AS end_ho,
           intime_hr_io + (CEIL(it.intime_hr_ho / 60) * 60 - intime_hr_ho)      AS end_io,

           -- create integers for each charttime in hours from admission
           -- so 0 is admission time, 1 is one hour after admission, etc, up to ICU disch
           --  we allow 24 hours before ICU admission (to grab labs before admit)
           GENERATE_ARRAY(-24, CEIL((it.outtime_hr_ho - it.intime_hr_ho) / 60)) as hrs

    FROM `aims_eicu_crd_derived.icustay_times` AS it
), hourly AS (
    SELECT patientunitstayid,
           -- intime_hr_ho,
           -- outtime_hr_ho,
           -- intime_hr_io,
           -- outtime_hr_io,
           CAST(hr AS INT64)               AS hr,
           CAST(end_ho + hr * 60 AS INT64) AS end_ho,
           CAST(end_io + hr * 60 AS INT64) AS end_io,
           -- MIMIC style
           patientunitstayid               AS stay_id,
           CAST(end_ho + hr * 60 AS INT64) AS endtime
    FROM all_hours
             CROSS JOIN UNNEST(all_hours.hrs) AS hr
)
SELECT *
FROM hourly
ORDER BY stay_id, endtime;









