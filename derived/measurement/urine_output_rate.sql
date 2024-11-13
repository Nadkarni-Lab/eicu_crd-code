
-- attempt to calculate urine output per hour
-- rate/hour is the interpretable measure of kidney function
-- though it is difficult to estimate from aperiodic point measures
-- first we get the earliest heart rate documented for the stay
CREATE TABLE aims_eicu_crd_derived.urine_output_rate AS
WITH t1 AS
(
    SELECT ce.patientunitstayid,
           MIN(ie.intime_ho + ce.observationoffset) AS intime_hr_ho,
           MAX(ie.intime_ho + ce.observationoffset) AS outtime_hr_ho,
           MIN(ce.observationoffset)                AS intime_hr_io,
           MAX(ce.observationoffset)                AS outtime_hr_io,
           -- ToDo: nursecharting (eICU) and vitalperiodic (eICU) are two sources of HR.
           --       Need to confirm vitalperiodic (eICU) contains only data from the ICU setting.
           ce.patientunitstayid                     AS stay_id,
           MIN(ie.intime_ho + ce.observationoffset) AS intime_hr,
           MAX(ie.intime_ho + ce.observationoffset) AS outtime_hr
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd.vitalperiodic` AS ce
                        ON ie.patientunitstayid = ce.patientunitstayid
    -- only look at heart rate
    WHERE ce.heartrate IS NOT NULL
      AND 225 >= ce.heartrate
      AND ce.heartrate >= 25
    GROUP BY ce.patientunitstayid
), tm AS (
    SELECT *
    FROM t1
    WHERE outtime_hr_io > 0
), uo_tm AS (
    -- now calculate time since last UO measurement
    SELECT tm.patientunitstayid,
           tm.stay_id,
           CASE
               WHEN LAG(uo.charttime) OVER w IS NULL
                   THEN uo.charttime - tm.intime_hr
               ELSE uo.charttime - (LAG(uo.charttime) OVER w)
               END AS tm_since_last_uo,
           uo.chart_ho,
           uo.chart_io,
           uo.charttime,
           uo.urineoutput
    FROM tm
             INNER JOIN aims_eicu_crd_derived.urine_output AS uo
                        ON tm.stay_id = uo.stay_id
    WINDOW w AS (PARTITION BY tm.stay_id ORDER BY uo.charttime)
), ur_stg AS (
    SELECT MAX(io.patientunitstayid)          AS patientunitstayid,
           MAX(io.chart_ho)                   AS chart_ho,
           MAX(io.chart_io)                   AS chart_io,
           io.stay_id,
           io.charttime,
           -- we have joined each row to all rows preceding within 24 hours
           -- we can now sum these rows to get total UO over the last 24 hours
           -- we can use case statements to restrict it to only the last 6/12 hours
           -- therefore we have three sums:
           -- 1) over a 6 hour period
           -- 2) over a 12 hour period
           -- 3) over a 24 hour period
           SUM(DISTINCT io.urineoutput)       AS uo,
           -- note that we assume data charted at charttime corresponds
           -- to 1 hour of UO, therefore we use '5' and '11' to restrict the
           -- period, rather than 6/12 this assumption may overestimate UO rate
           -- when documentation is done less than hourly
           SUM(CASE
                   WHEN (io.charttime - iosum.charttime) / 60 <= 5
                       THEN iosum.urineoutput
                   ELSE null END)             AS urineoutput_6hr,
           SUM(CASE
                   WHEN (io.charttime - iosum.charttime) / 60 <= 5
                       THEN iosum.tm_since_last_uo
                   ELSE null END) / 60.0      AS uo_tm_6hr,
           SUM(CASE
                   WHEN (io.charttime - iosum.charttime) / 60 <= 11
                       THEN iosum.urineoutput
                   ELSE null END)             AS urineoutput_12hr,
           SUM(CASE
                   WHEN (io.charttime - iosum.charttime) / 60 <= 11
                       THEN iosum.tm_since_last_uo
                   ELSE null END) / 60.0      AS uo_tm_12hr,
           -- 24 hours
           SUM(iosum.urineoutput)             AS urineoutput_24hr,
           SUM(iosum.tm_since_last_uo) / 60.0 AS uo_tm_24hr
    FROM uo_tm io
             -- this join gives you all UO measurements over a 24 hour period
             LEFT JOIN uo_tm iosum
                       ON io.stay_id = iosum.stay_id
                           AND io.charttime >= iosum.charttime
                           AND io.charttime <= (iosum.charttime + (23 * 60))
    GROUP BY io.stay_id, io.charttime
)
SELECT ur.patientunitstayid,
       ur.chart_ho,
       ur.chart_io,
       wd.weight,
       ur.uo,
       ur.urineoutput_6hr,
       ur.urineoutput_12hr,
       ur.urineoutput_24hr,
       CASE
           WHEN uo_tm_6hr >= 6 THEN ROUND(CAST((ur.urineoutput_6hr / wd.weight / uo_tm_6hr) AS NUMERIC), 4)
           END                               AS uo_mlkghr_6hr,
       CASE
           WHEN uo_tm_12hr >= 12 THEN ROUND(CAST((ur.urineoutput_12hr / wd.weight / uo_tm_12hr) AS NUMERIC), 4)
           END                               AS uo_mlkghr_12hr,
       CASE
           WHEN uo_tm_24hr >= 24 THEN ROUND(CAST((ur.urineoutput_24hr / wd.weight / uo_tm_24hr) AS NUMERIC), 4)
           END                               AS uo_mlkghr_24hr,
       -- time of earliest UO measurement that was used to calculate the rate
       ROUND(CAST(uo_tm_6hr AS NUMERIC), 2)  AS uo_tm_6hr,
       ROUND(CAST(uo_tm_12hr AS NUMERIC), 2) AS uo_tm_12hr,
       ROUND(CAST(uo_tm_24hr AS NUMERIC), 2) AS uo_tm_24hr,
       ur.stay_id,
       ur.charttime
FROM ur_stg AS ur
         LEFT JOIN aims_eicu_crd_derived.weight_durations wd
                   ON ur.stay_id = wd.stay_id
                       AND ur.charttime > wd.starttime
                       AND ur.charttime <= wd.endtime
                       AND wd.weight > 0
ORDER BY ur.stay_id, ur.charttime;









