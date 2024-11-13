
-- The aim of this query is to pivot entries related to blood gases
-- which were found in LABEVENTS
CREATE TABLE aims_eicu_crd_derived.bg AS
WITH bg0 AS (
    SELECT le.patientunitstayid,
           ie.intime_ho + le.labresultoffset AS chart_ho,
           le.labresultoffset                AS chart_io,
           NULL                              AS store_ho,
           NULL                              AS store_io,
           le.labid,
           NULL                              AS specimen,
           NULL                              AS aado2,
           CASE
               WHEN le.labname = 'Base Excess' AND
                    le.labresult >= -100 AND le.labresult <= 100
                   THEN le.labresult
               END                           AS baseexcess,
           CASE
               WHEN le.labname = 'bicarbonate'
                   THEN le.labresult
               END                           AS bicarbonate,
           CASE
               WHEN le.labname = 'Total CO2'
                   THEN le.labresult
               END                           AS totalco2,
           CASE
               WHEN le.labname = 'Carboxyhemoglobin'
                   THEN le.labresult
               END                           AS carboxyhemoglobin,
           CASE
               WHEN le.labname = 'chloride'
                   THEN le.labresult
               END                           AS chloride,
           CASE
               WHEN le.labname = 'calcium'
                   THEN le.labresult
               END                           AS calcium,
           CASE
               WHEN le.labname = 'glucose' AND
                    le.labresult <= 10000
                   THEN le.labresult
               END                           AS glucose,
           CASE
               WHEN le.labname = 'Hct' AND
                    le.labresult <= 100
                   THEN le.labresult
               END                           AS hematocrit,
           CASE
               WHEN le.labname = 'Hgb'
                   THEN le.labresult
               END                           AS hemoglobin,
           CASE
               WHEN le.labname = 'lactate' AND
                    le.labresult <= 10000
                   THEN le.labresult
               END                           AS lactate,
           CASE
               WHEN le.labname = 'Methemoglobin'
                   THEN le.labresult
               END                           AS methemoglobin,
           NULL                              AS o2flow,
           -- fix a common unit conversion error for fio2
           -- atmospheric o2 is 20.89%, so any value <= 20 is unphysiologic
           -- usually this is a misplaced O2 flow measurement           CASE
           CASE
               WHEN le.labname = 'FiO2' THEN
                   CASE
                       WHEN le.labresult > 20 AND
                            le.labresult <= 100 THEN le.labresult
                       WHEN
                                   le.labresult > 0.2 AND
                                   le.labresult <= 1.0 THEN le.labresult * 100.0
                       END
               END                           AS fio2,
           CASE
               WHEN le.labname = 'O2 Sat (%)' AND
                    le.labresult <= 100
                   THEN le.labresult
               END                           AS so2,
           CASE
               WHEN le.labname = 'paCO2' AND
                    le.labresult >= 5 AND le.labresult <= 250
                   THEN le.labresult
               END                           AS pco2,
           CASE
               WHEN le.labname = 'PEEP' AND
                    le.labresult >= 0 AND le.labresult <= 60
                   THEN le.labresult END     AS peep,
           CASE
               WHEN le.labname = 'pH' AND
                    le.labresult >= 6.5 AND le.labresult <= 8.5
                   THEN le.labresult END     AS ph,
           CASE
               WHEN le.labname = 'paO2' AND
                    le.labresult >= 15 AND le.labresult <= 720
                   THEN le.labresult
               END                           AS po2,
           CASE
               WHEN le.labname = 'potassium'
                   THEN le.labresult
               END                           AS potassium,
           NULL                              AS requiredo2,
           CASE
               WHEN le.labname = 'sodium'
                   THEN le.labresult
               END                           AS sodium,
           CASE
               WHEN le.labname = 'Temperature'
                   THEN le.labresult
               END                           AS temperature,
           NULL                              AS comments,
           -- MIMIC style
           ie.subject_id                     AS subject_id,
           ie.hadm_id                        AS hadm_id,
           ie.stay_id                        AS stay_id,
           ie.intime_ho + le.labresultoffset AS charttime,
           NULL                              AS storetime,
           le.labid                          AS specimen_id
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd.lab` AS le
                        ON ie.patientunitstayid = le.patientunitstayid
    WHERE le.labname IN
          (
              -- aado2
           'Base Excess',
           'bicarbonate',
           'Total CO2',
           'Carboxyhemoglobin',
           'chloride',
           'calcium',
           'glucose',
           'Hct',
           'Hgb',
           'lactate',
           'Methemoglobin',
              -- O2 Flow
           'FiO2',
           'O2 Sat (%)',
           'paCO2',
           'PEEP',
           'pH',
           'paO2',
           'potassium',
              -- Required O2
           'sodium',
           'Temperature'
              )
), bg AS (
    SELECT MAX(patientunitstayid) AS patientunitstayid,
           MAX(chart_ho)          AS chart_ho,
           MAX(chart_io)          AS chart_io,
           MAX(store_ho)          AS store_ho,
           MAX(store_io)          AS store_io,
           MAX(specimen)          AS specimen,
           MAX(labid)             AS labid,
           MAX(aado2)             AS aado2,
           MAX(baseexcess)        AS baseexcess,
           MAX(bicarbonate)       AS bicarbonate,
           MAX(totalco2)          AS totalco2,
           MAX(carboxyhemoglobin) AS carboxyhemoglobin,
           MAX(chloride)          AS chloride,
           MAX(calcium)           AS calcium,
           MAX(glucose)           AS glucose,
           MAX(hematocrit)        AS hematocrit,
           MAX(hemoglobin)        AS hemoglobin,
           MAX(lactate)           AS lactate,
           MAX(methemoglobin)     AS methemoglobin,
           MAX(o2flow)            AS o2flow,
           MAX(fio2)              AS fio2,
           MAX(so2)               AS so2,
           MAX(pco2)              AS pco2,
           MAX(peep)              AS peep,
           MAX(ph)                AS ph,
           MAX(po2)               AS po2,
           MAX(potassium)         AS potassium,
           MAX(requiredo2)        AS requiredo2,
           MAX(sodium)            AS sodium,
           MAX(temperature)       AS temperature,
           MAX(comments)          AS comments,
           subject_id,
           hadm_id,
           stay_id,
           charttime,
           MAX(storetime)         AS storetime,
           MAX(specimen_id)       AS specimen_id
    FROM bg0
    WHERE specimen IS NOT NULL
       OR aado2 IS NOT NULL
       OR baseexcess IS NOT NULL
       OR bicarbonate IS NOT NULL
       OR totalco2 IS NOT NULL
       OR carboxyhemoglobin IS NOT NULL
       OR chloride IS NOT NULL
       OR calcium IS NOT NULL
       OR glucose IS NOT NULL
       OR hematocrit IS NOT NULL
       OR hemoglobin IS NOT NULL
       OR lactate IS NOT NULL
       OR methemoglobin IS NOT NULL
       OR o2flow IS NOT NULL
       OR fio2 IS NOT NULL
       OR so2 IS NOT NULL
       OR pco2 IS NOT NULL
       OR peep IS NOT NULL
       OR ph IS NOT NULL
       OR po2 IS NOT NULL
       OR potassium IS NOT NULL
       OR requiredo2 IS NOT NULL
       OR sodium IS NOT NULL
       OR temperature IS NOT NULL
       OR comments IS NOT NULL
    GROUP BY subject_id, hadm_id, stay_id, charttime
), stg_spo20 AS (
    SELECT MAX(ce.patientunitstayid)                 AS patientunitstayid,
           MAX(ie.intime_ho + ce.respchartoffset)    AS chart_ho,
           MAX(ce.respchartoffset)                   AS chart_io,
           AVG(SAFE_CAST(respchartvalue AS NUMERIC)) AS spo2,
           -- MIMIC style
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           MAX(ie.intime_ho + ce.respchartoffset)        AS charttime,
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd.respiratorycharting` AS ce
                        ON ie.patientunitstayid = ce.patientunitstayid
    WHERE lower(ce.respchartvaluelabel) LIKE '%spo2%'
      AND SAFE_CAST(respchartvalue AS NUMERIC) > 0
      AND SAFE_CAST(respchartvalue AS NUMERIC) <= 100
    GROUP BY ie.subject_id, ie.hadm_id, ie.stay_id, ie.intime_ho + ce.respchartoffset
), stg_spo2 AS (
    SELECT *
    FROM stg_spo20
    WHERE spo2 IS NOT NULL
), stg_fio20 AS (
    SELECT MAX(ce.patientunitstayid)                 AS patientunitstayid,
           MAX(ie.intime_ho + ce.respchartoffset) AS chart_ho,
           MAX(ce.respchartoffset)                AS chart_io,
           MAX(CASE
                   WHEN SAFE_CAST(respchartvalue AS NUMERIC) > 0.2 AND
                        SAFE_CAST(respchartvalue AS NUMERIC) <= 1
                       THEN SAFE_CAST(respchartvalue AS NUMERIC) * 100
               -- improperly input data - looks like O2 flow in litres
                   WHEN SAFE_CAST(respchartvalue AS NUMERIC) > 1 AND
                        SAFE_CAST(respchartvalue AS NUMERIC) < 20
                       THEN NULL
                   WHEN SAFE_CAST(respchartvalue AS NUMERIC) >= 20 AND
                        SAFE_CAST(respchartvalue AS NUMERIC) <= 100
                       THEN SAFE_CAST(respchartvalue AS NUMERIC)
                   ELSE NULL END
               )                                  AS fio2_chartevents,
           -- MIMIC style
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           MAX(ie.intime_ho + ce.respchartoffset) AS charttime,
    FROM aims_eicu_crd_icu.icustays AS ie
             INNER JOIN `physionet-data.eicu_crd.respiratorycharting` AS ce
                        ON ie.patientunitstayid = ce.patientunitstayid
    WHERE lower(ce.respchartvaluelabel) LIKE '%fio2%'
      AND SAFE_CAST(respchartvalue AS NUMERIC) > 0
      AND SAFE_CAST(respchartvalue AS NUMERIC) <= 100
    GROUP BY ie.subject_id, ie.hadm_id, ie.stay_id, ie.intime_ho + ce.respchartoffset
), stg_fio2 AS (
    SELECT *
    FROM stg_fio20
    WHERE fio2_chartevents IS NOT NULL
), stg2 AS (
    SELECT bg.*,
           ROW_NUMBER() OVER (
               PARTITION BY bg.subject_id, bg.charttime ORDER BY s1.charttime DESC
               ) AS lastrowspo2,
           s1.spo2
    FROM bg
             LEFT JOIN stg_spo2 s1
        -- same hospitalization
                       ON bg.subject_id = s1.subject_id
                           -- spo2 occurred at most 2 hours before this blood gas
                           AND s1.charttime BETWEEN bg.charttime - (60 * 2) AND bg.charttime
    WHERE bg.po2 IS NOT NULL
), stg3 AS (
    SELECT bg.*,
           ROW_NUMBER() OVER (
            PARTITION BY bg.subject_id, bg.charttime ORDER BY s2.charttime DESC
        ) AS lastrowfio2,
        s2.fio2_chartevents
    FROM stg2 bg
    LEFT JOIN stg_fio2 s2
        -- same patient
        ON bg.subject_id = s2.subject_id
            -- fio2 occurred at most 4 hours before this blood gas
            AND s2.charttime >= bg.charttime - (60 * 4)
            AND s2.charttime <= bg.charttime
            AND s2.fio2_chartevents > 0
    -- only the row with the most recent SpO2 (if no SpO2 found lastRowSpO2 = 1)
    WHERE bg.lastrowspo2 = 1
)
SELECT stg3.patientunitstayid,
       stg3.chart_ho,
       stg3.chart_io,
       -- drop down text indicating the specimen type
       specimen,
       -- oxygen related parameters
       so2,
       po2,
       pco2,
       fio2_chartevents,
       fio2,
       aado2,
       -- also calculate AADO2
       CASE
           WHEN po2 IS NULL
               OR pco2 IS NULL
               THEN NULL
           WHEN fio2 IS NOT NULL
               -- multiple by 100 because fio2 is in a % but should be a fraction
               THEN (fio2 / 100) * (760 - 47) - (pco2 / 0.8) - po2
           WHEN fio2_chartevents IS NOT NULL
               THEN (fio2_chartevents / 100) * (760 - 47) - (pco2 / 0.8) - po2
           ELSE NULL
           END AS aado2_calc,
       CASE
           WHEN po2 IS NULL
               THEN NULL
           WHEN fio2 IS NOT NULL
               -- multiply by 100 because fio2 is in a % but should be a fraction
               THEN 100 * po2 / fio2
           WHEN fio2_chartevents IS NOT NULL
               -- multiply by 100 because fio2 is in a % but should be a fraction
               THEN 100 * po2 / fio2_chartevents
           ELSE NULL
           END AS pao2fio2ratio,
       -- acid-base parameters
       ph,
       baseexcess,
       bicarbonate,
       totalco2,

       -- blood count parameters
       hematocrit,
       hemoglobin,
       carboxyhemoglobin,
       methemoglobin,

       -- chemistry
       chloride,
       calcium,
       temperature,
       potassium,
       sodium,
       lactate,
       glucose,
       stg3.subject_id,
       stg3.hadm_id,
       stg3.stay_id,
       stg3.charttime

-- ventilation stuff that's sometimes input
-- , intubated, tidalvolume, ventilationrate, ventilator
-- , peep, o2flow
-- , requiredo2
FROM stg3
WHERE lastrowfio2 = 1
ORDER BY subject_id, hadm_id, charttime; -- only the most recent FiO2









