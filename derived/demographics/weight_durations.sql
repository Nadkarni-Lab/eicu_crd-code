
-- ====================================================================================================
-- weight_durations
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/demographics/weight_durations.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

-- This query extracts weights for adult ICU patients with start/stop times
-- if an admission weight is given, then this is assigned from intime to outtime
DROP TABLE IF EXISTS aims_eicu_crd_derived.weight_durations;
CREATE TABLE aims_eicu_crd_derived.weight_durations AS
WITH wt_stg1 AS (
-- assign ascending row number
    SELECT ie.patientunitstayid,
           ie.intime_ho + wt.chartoffset AS chart_ho,
           wt.chartoffset                AS chart_io,
           wt.weight_type,
           wt.weight,
           ROW_NUMBER() OVER (
               PARTITION BY wt.patientunitstayid, wt.weight_type
               ORDER BY ie.intime_ho + wt.chartoffset
               )                         AS rn,
           -- MIMIC style
           ie.patientunitstayid          AS stay_id,
           ie.intime_ho + wt.chartoffset AS charttime
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd_derived.pivoted_weight` AS wt
                        ON ie.patientunitstayid = wt.patientunitstayid
    WHERE wt.weight IS NOT NULL
), wt_stg2 AS (
    -- change charttime to intime for the first admission weight recorded
    SELECT wt_stg1.stay_id,
           ie.intime,
           ie.outtime,
           wt_stg1.weight_type,
           CASE
               WHEN wt_stg1.weight_type = 'admit' AND wt_stg1.rn = 1
                   THEN ie.intime - (60 * 2)
               ELSE wt_stg1.charttime
               END AS starttime,
           wt_stg1.weight
    FROM wt_stg1
             INNER JOIN aims_eicu_crd_icu.icustays AS ie
                        ON ie.stay_id = wt_stg1.stay_id
), wt_stg3 AS (
    SELECT stay_id,
           intime,
           outtime,
           starttime,
           COALESCE
               (LEAD(starttime) OVER (PARTITION BY stay_id ORDER BY starttime),
                outtime + (60 * 2)
               ) AS endtime,
           weight,
           weight_type
    FROM wt_stg2
), wt1 AS (
    -- this table is the start/stop times from admit/daily weight in charted data
    SELECT stay_id,
           starttime,
           COALESCE
               (endtime,
                LEAD(starttime) OVER (PARTITION BY stay_id ORDER BY starttime),
               -- impute ICU discharge as the end of the final weight measurement
               -- plus a 2 hour "fuzziness" window
                outtime + (60 * 2)
               ) AS endtime,
           weight,
           weight_type
    FROM wt_stg3
), wt_fix AS (
-- if the intime for the patient is < the first charted daily weight
-- then we will have a "gap" at the start of their stay
-- to prevent this, we look for these gaps and backfill the first weight
-- this adds (153255-149657)=3598 rows, meaning this fix helps for up
-- to 3598 stay_id
    SELECT ie.stay_id,
           -- we add a 2 hour "fuzziness" window
           ie.intime - (60 * 2) AS starttime,
           wt.starttime         AS endtime,
           wt.weight,
           wt.weight_type
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN
         -- the below subquery returns one row for each unique stay_id
         -- the row contains: the first starttime and the corresponding weight
             (SELECT wt1.stay_id,
                     wt1.starttime,
                     wt1.weight,
                     weight_type,
                     ROW_NUMBER() OVER (
                         PARTITION BY wt1.stay_id ORDER BY wt1.starttime
                         ) AS rn
              FROM wt1) wt
         ON ie.stay_id = wt.stay_id
             AND wt.rn = 1
             AND ie.intime < wt.starttime
), wt AS (
    -- add the backfill rows to the main weight table
    SELECT wt1.stay_id,
           wt1.starttime,
           wt1.endtime,
           wt1.weight,
           wt1.weight_type
    FROM wt1
    UNION ALL
    SELECT wt_fix.stay_id,
           wt_fix.starttime,
           wt_fix.endtime,
           wt_fix.weight,
           wt_fix.weight_type
    FROM wt_fix
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       wt.starttime             AS start_ho,
       wt.endtime               AS end_ho,
       wt.starttime - ie.intime AS start_io,
       wt.endtime - ie.intime   AS end_io,
       wt.weight,
       wt.weight_type,
-- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       wt.starttime,
       wt.endtime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN wt
                    ON ie.stay_id = wt.stay_id
ORDER BY ie.subject_id, ie.hadm_id, wt.starttime;









