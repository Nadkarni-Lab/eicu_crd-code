-- ------------------------------------------------------------------
-- Title: Sequential Organ Failure Assessment (SOFA)
-- This query extracts the sequential organ failure assessment
-- (formally: sepsis-related organ failure assessment).
-- This score is a measure of organ failure for patients in the ICU.
-- The score is calculated for **every hour** of the patient's ICU stay.
-- However, as the calculation window is 24 hours, care should be
-- taken when using the score before the end of the first day,
-- as the data window is limited.
-- ------------------------------------------------------------------

-- Reference for SOFA:
--    Jean-Louis Vincent, Rui Moreno, Jukka Takala, Sheila Willatts,
--    Arnaldo De Mendonça, Hajo Bruining, C. K. Reinhart,
--    Peter M Suter, and L. G. Thijs.
--    "The SOFA (Sepsis-related Organ Failure Assessment) score to
--     describe organ dysfunction/failure."
--    Intensive care medicine 22, no. 7 (1996): 707-710.

-- Variables used in SOFA:
--  GCS, MAP, FiO2, Ventilation status (chartevents)
--  Creatinine, Bilirubin, FiO2, PaO2, Platelets (labevents)
--  Dopamine, Dobutamine, Epinephrine, Norepinephrine (inputevents)
--  Urine output (outputevents)

-- use icustay_hourly to get a row for every hour the patient was in the ICU
-- all of our joins to data will use these times
-- to extract data pertinent to only that hour
CREATE TABLE eicu_crd_derived.sofa AS
WITH co AS (
    SELECT ih.patientunitstayid,
           ie.patienthealthsystemstayid,
           ih.hr,
           -- start/endtime can be used to filter to values within this hour
           ih.end_ho - 60 AS start_ho,
           ih.end_ho,
           ih.end_io - 60 AS start_io,
           ih.end_io,
           -- MIMIC style
           ie.hadm_id,
           ih.stay_id,
           ih.end_ho - 60 AS starttime,
           ih.endtime
    FROM eicu_crd_derived.icustay_hourly AS ih
             INNER JOIN eicu_crd_icu.icustays AS ie
                        ON ih.patientunitstayid = ie.patientunitstayid
), v1 as (
    --airway type from respcare (1=invasive) (by resp therapist!!)
    SELECT patientunitstayid,
           respcarestatusoffset AS chart_io,
           MAX(CASE
                   WHEN airwaytype in ('Oral ETT', 'Nasal ETT', 'Tracheostomy')
                       THEN 1
                   ELSE NULL
               END)             AS airway -- either invasive airway or NULL
    FROM `physionet-data.eicu_crd.respiratorycare`
    GROUP BY patientunitstayid, respcarestatusoffset
), v2 AS (
    --airway type from respcharting (1=invasive)
    SELECT patientunitstayid,
           respchartoffset AS chart_io,
           1 as ventilator
    FROM `physionet-data.eicu_crd.respiratorycharting`
    WHERE respchartvalue like '%ventilator%'
       OR respchartvalue like '%vent%'
       OR respchartvalue like '%bipap%'
       OR respchartvalue like '%840%'
       OR respchartvalue like '%cpap%'
       OR respchartvalue like '%drager%'
       OR respchartvalue like 'mv%'
       OR respchartvalue like '%servo%'
       OR respchartvalue like '%peep%'
    GROUP BY patientunitstayid, respchartoffset
), v3 as ( --airway type from treatment (1=invasive)
    SELECT patientunitstayid,
           treatmentoffset AS chart_io,
           max(CASE
                   WHEN treatmentstring IN
                        ('pulmonary|ventilation and oxygenation|mechanical ventilation',
                         'pulmonary|ventilation and oxygenation|tracheal suctioning',
                         'pulmonary|ventilation and oxygenation|ventilator weaning',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|assist controlled',
                         'pulmonary|radiologic procedures / bronchoscopy|endotracheal tube',
                         'pulmonary|ventilation and oxygenation|oxygen therapy (> 60%)',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|tidal volume 6-10 ml/kg',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|volume controlled',
                         'surgery|pulmonary therapies|mechanical ventilation',
                         'pulmonary|surgery / incision and drainage of thorax|tracheostomy',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|synchronized intermittent',
                         'pulmonary|surgery / incision and drainage of thorax|tracheostomy|performed during current admission for ventilatory support',
                         'pulmonary|ventilation and oxygenation|ventilator weaning|active',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|pressure controlled',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|pressure support',
                         'pulmonary|ventilation and oxygenation|ventilator weaning|slow',
                         'surgery|pulmonary therapies|ventilator weaning',
                         'surgery|pulmonary therapies|tracheal suctioning',
                         'pulmonary|radiologic procedures / bronchoscopy|reintubation',
                         'pulmonary|ventilation and oxygenation|lung recruitment maneuver',
                         'pulmonary|surgery / incision and drainage of thorax|tracheostomy|planned',
                         'surgery|pulmonary therapies|ventilator weaning|rapid',
                         'pulmonary|ventilation and oxygenation|prone position',
                         'pulmonary|surgery / incision and drainage of thorax|tracheostomy|conventional',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|permissive hypercapnea',
                         'surgery|pulmonary therapies|mechanical ventilation|synchronized intermittent',
                         'pulmonary|medications|neuromuscular blocking agent',
                         'surgery|pulmonary therapies|mechanical ventilation|assist controlled',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|volume assured',
                         'surgery|pulmonary therapies|mechanical ventilation|tidal volume 6-10 ml/kg',
                         'surgery|pulmonary therapies|mechanical ventilation|pressure support',
                         'pulmonary|ventilation and oxygenation|non-invasive ventilation',
                         'pulmonary|ventilation and oxygenation|non-invasive ventilation|face mask',
                         'pulmonary|ventilation and oxygenation|non-invasive ventilation|nasal mask',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation|face mask',
                         'surgery|pulmonary therapies|non-invasive ventilation',
                         'surgery|pulmonary therapies|non-invasive ventilation|face mask',
                         'pulmonary|ventilation and oxygenation|mechanical ventilation|non-invasive ventilation|nasal mask',
                         'surgery|pulmonary therapies|non-invasive ventilation|nasal mask',
                         'surgery|pulmonary therapies|mechanical ventilation|non-invasive ventilation',
                         'surgery|pulmonary therapies|mechanical ventilation|non-invasive ventilation|face mask'
                            )
                       THEN 1
                   ELSE NULL END) AS interface -- either ETT/NiV or NULL
    FROM `physionet-data.eicu_crd.treatment`
    GROUP BY patientunitstayid, treatmentoffset-- , treatmentoffset, interface
), vd_id AS (
    SELECT patientunitstayid, chart_io
    FROM v1
    UNION DISTINCT
    SELECT patientunitstayid, chart_io
    FROM v2
    UNION DISTINCT
    SELECT patientunitstayid, chart_io
    FROM v3
), vd AS (
    --Note from Michael
    --
    --Previously the below line was "case when t1.airway is not null or t2.ventilator is not null or t3.interface is not null or t4.interface is not null then 1 else null end as mechvent
    --
    --t4 doesn't have interface, removing
    SELECT id.patientunitstayid,
           ie.intime_ho + id.chart_io AS chart_ho,
           id.chart_io,
           CASE
               WHEN v1.airway IS NOT NULL OR
                    v2.ventilator IS NOT NULL OR
                    v3.interface IS NOT NULL
                   THEN 1
               END                       mechvent, --summarize
-- MIMIC style
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           ie.intime_ho + id.chart_io AS charttime
    FROM eicu_crd_icu.icustays AS ie
             INNER JOIN vd_id AS id
                        ON ie.patientunitstayid = id.patientunitstayid
             LEFT JOIN v1
                       ON id.patientunitstayid = v1.patientunitstayid
                           AND id.chart_io = v1.chart_io
             LEFT JOIN v2
                       ON id.patientunitstayid = v2.patientunitstayid
                           AND id.chart_io = v2.chart_io
             LEFT JOIN v3
                       ON id.patientunitstayid = v3.patientunitstayid
                           AND id.chart_io = v3.chart_io
    ORDER BY id.patientunitstayid, id.chart_io
), pafi AS (
    -- join blood gas to ventilation durations to determine if patient was vent
    SELECT ie.patientunitstayid,
           bg.chart_ho,
           bg.chart_io,
           -- because pafi has an interaction between vent/PaO2:FiO2,
           -- we need two columns for the score
           -- it can happen that the lowest unventilated PaO2/FiO2 is 68,
           -- but the lowest ventilated PaO2/FiO2 is 120
           -- in this case, the SOFA score is 3, *not* 4.
           CASE
               WHEN vd.stay_id IS NULL THEN pao2fio2ratio
               ELSE null
               END                       AS pao2fio2ratio_novent,
           CASE
               WHEN vd.stay_id IS NOT NULL THEN pao2fio2ratio
               ELSE null
               END                       AS pao2fio2ratio_vent,
           -- MIMIC style
           ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           bg.charttime
    FROM eicu_crd_icu.icustays AS ie
             INNER JOIN eicu_crd_derived.bg AS bg
                        ON ie.subject_id = bg.subject_id
             LEFT JOIN vd
                       ON ie.stay_id = vd.stay_id
                           AND bg.charttime >= vd.charttime
                           AND bg.charttime <= (vd.charttime + 60 * 24)
                           AND vd.mechvent IS NOT NULL
), vs AS (
    SELECT co.stay_id,
           co.hr,
           -- vitals
           MIN(vs.ibp_mean) AS meanbp_min
    FROM co
             LEFT JOIN eicu_crd_derived.vitalsign AS vs
                       ON co.stay_id = vs.stay_id
                           AND co.starttime < vs.charttime
                           AND co.endtime >= vs.charttime
    GROUP BY co.stay_id, co.hr
), gcs AS (
    SELECT co.stay_id,
           co.hr,
           -- gcs
           MIN(gcs.gcs) AS gcs_min
    FROM co
             LEFT JOIN eicu_crd_derived.gcs AS gcs
                       ON co.stay_id = gcs.stay_id
                           AND co.starttime < gcs.charttime
                           AND co.endtime >= gcs.charttime
    GROUP BY co.stay_id, co.hr
), bili AS (
    SELECT co.stay_id,
           co.hr,
           MAX(enz.bilirubin_total) AS bilirubin_max
    FROM co
             LEFT JOIN eicu_crd_derived.enzyme enz
                       ON co.hadm_id = enz.hadm_id
                           AND co.starttime < enz.charttime
                           AND co.endtime >= enz.charttime
    GROUP BY co.stay_id, co.hr
), cr AS (
    SELECT co.stay_id,
           co.hr,
           MAX(chem.creatinine) AS creatinine_max
    FROM co
             LEFT JOIN eicu_crd_derived.creatinine AS chem
                       ON co.hadm_id = chem.hadm_id
                           AND co.starttime < chem.charttime
                           AND co.endtime >= chem.charttime
    GROUP BY co.stay_id, co.hr
), plt AS (
    SELECT co.stay_id,
           co.hr
            ,
           MIN(cbc.platelet) AS platelet_min
    FROM co
             LEFT JOIN eicu_crd_derived.complete_blood_count AS cbc
                       ON co.hadm_id = cbc.hadm_id
                           AND co.starttime < cbc.charttime
                           AND co.endtime >= cbc.charttime
    GROUP BY co.stay_id, co.hr
), pf AS (
    SELECT co.stay_id, co.hr
        , MIN(pafi.pao2fio2ratio_novent) AS pao2fio2ratio_novent
        , MIN(pafi.pao2fio2ratio_vent) AS pao2fio2ratio_vent
    FROM co
    -- bring in blood gases that occurred during this hour
    LEFT JOIN pafi
        ON co.stay_id = pafi.stay_id
            AND co.starttime < pafi.charttime
            AND co.endtime >= pafi.charttime
    GROUP BY co.stay_id, co.hr
), uo AS (
    -- sum uo separately to prevent duplicating values
    SELECT co.stay_id,
           co.hr,
           -- uo
           MAX(CASE
                   WHEN uo.uo_tm_24hr >= 22 AND uo.uo_tm_24hr <= 30
                       THEN uo.urineoutput_24hr / uo.uo_tm_24hr * 24
               END) AS uo_24hr
    FROM co
             LEFT JOIN eicu_crd_derived.urine_output_rate AS uo
                       ON co.stay_id = uo.stay_id
                           AND co.starttime < uo.charttime
                           AND co.endtime >= uo.charttime
    GROUP BY co.stay_id, co.hr
)

-- collapse vasopressors into 1 row per hour
-- also ensures only 1 row per chart time
, vaso AS (
    SELECT
        co.stay_id
        , co.hr
        , MAX(epi.vaso_rate) AS rate_epinephrine
        , MAX(nor.vaso_rate) AS rate_norepinephrine
        , MAX(dop.vaso_rate) AS rate_dopamine
        , MAX(dob.vaso_rate) AS rate_dobutamine
    FROM co
    LEFT JOIN eicu_crd_derived.epinephrine epi
        ON co.stay_id = epi.stay_id
            AND co.endtime > epi.starttime
            AND co.endtime <= (epi.starttime + 60)
    LEFT JOIN eicu_crd_derived.norepinephrine nor
        ON co.stay_id = nor.stay_id
            AND co.endtime > nor.starttime
            AND co.endtime <= (nor.starttime + 60)
    LEFT JOIN eicu_crd_derived.dopamine dop
        ON co.stay_id = dop.stay_id
            AND co.endtime > dop.starttime
            AND co.endtime <= (dop.starttime + 60)
    LEFT JOIN eicu_crd_derived.dobutamine dob
        ON co.stay_id = dob.stay_id
            AND co.endtime > dob.starttime
            AND co.endtime <= (dob.starttime + 60 * 5)
    WHERE epi.stay_id IS NOT NULL
        OR nor.stay_id IS NOT NULL
        OR dop.stay_id IS NOT NULL
        OR dob.stay_id IS NOT NULL
    GROUP BY co.stay_id, co.hr
-- SELECT -- PERCENTILE_CONT(DATETIME_DIFF(endtime, starttime, HOUR), 0.5) OVER() AS med
--        AVG(DATETIME_DIFF(endtime, starttime, HOUR))
-- FROM `physionet-data.mimiciv_derived.epinephrine`
-- -- 1
-- -- 2.7
--
-- SELECT -- PERCENTILE_CONT(DATETIME_DIFF(endtime, starttime, HOUR), 0.5) OVER() AS med
--        AVG(DATETIME_DIFF(endtime, starttime, HOUR))
-- FROM `physionet-data.mimiciv_derived.norepinephrine`
-- -- 1
-- -- 1.7
--
-- SELECT -- PERCENTILE_CONT(DATETIME_DIFF(endtime, starttime, HOUR), 0.5) OVER() AS med
--        AVG(DATETIME_DIFF(endtime, starttime, HOUR))
-- FROM `physionet-data.mimiciv_derived.dopamine`
-- -- 1
-- -- 2.6
--
-- SELECT PERCENTILE_CONT(DATETIME_DIFF(endtime, starttime, HOUR), 0.5) OVER() AS med
--        -- AVG(DATETIME_DIFF(endtime, starttime, HOUR))
-- FROM `physionet-data.mimiciv_derived.dobutamine`
-- -- 5
-- -- 6.3
)

, scorecomp AS (
    SELECT
        co.stay_id
        , co.hr
        , co.starttime, co.endtime
        , pf.pao2fio2ratio_novent
        , pf.pao2fio2ratio_vent
        , vaso.rate_epinephrine
        , vaso.rate_norepinephrine
        , vaso.rate_dopamine
        , vaso.rate_dobutamine
        , vs.meanbp_min
        , gcs.gcs_min
        -- uo
        , uo.uo_24hr
        -- labs
        , bili.bilirubin_max
        , cr.creatinine_max
        , plt.platelet_min
    FROM co
    LEFT JOIN vs
        ON co.stay_id = vs.stay_id
            AND co.hr = vs.hr
    LEFT JOIN gcs
        ON co.stay_id = gcs.stay_id
            AND co.hr = gcs.hr
    LEFT JOIN bili
        ON co.stay_id = bili.stay_id
            AND co.hr = bili.hr
    LEFT JOIN cr
        ON co.stay_id = cr.stay_id
            AND co.hr = cr.hr
    LEFT JOIN plt
        ON co.stay_id = plt.stay_id
            AND co.hr = plt.hr
    LEFT JOIN pf
        ON co.stay_id = pf.stay_id
            AND co.hr = pf.hr
    LEFT JOIN uo
        ON co.stay_id = uo.stay_id
            AND co.hr = uo.hr
    LEFT JOIN vaso
        ON co.stay_id = vaso.stay_id
            AND co.hr = vaso.hr
)

, scorecalc AS (
    -- Calculate the final score
    -- note that if the underlying data is missing,
    -- the component is null
    -- eventually these are treated as 0 (normal),
    -- but knowing when data is missing is useful for debugging
    SELECT scorecomp.*
        -- Respiration
        , CASE
            WHEN pao2fio2ratio_vent < 100 THEN 4
            WHEN pao2fio2ratio_vent < 200 THEN 3
            WHEN pao2fio2ratio_novent < 300 THEN 2
            WHEN pao2fio2ratio_vent < 300 THEN 2
            WHEN pao2fio2ratio_novent < 400 THEN 1
            WHEN pao2fio2ratio_vent < 400 THEN 1
            WHEN
                COALESCE(
                    pao2fio2ratio_vent, pao2fio2ratio_novent
                ) IS NULL THEN null
            ELSE 0
        END AS respiration

        -- Coagulation
        , CASE
            WHEN platelet_min < 20 THEN 4
            WHEN platelet_min < 50 THEN 3
            WHEN platelet_min < 100 THEN 2
            WHEN platelet_min < 150 THEN 1
            WHEN platelet_min IS NULL THEN null
            ELSE 0
        END AS coagulation

        -- Liver
        , CASE
            -- Bilirubin checks in mg/dL
            WHEN bilirubin_max >= 12.0 THEN 4
            WHEN bilirubin_max >= 6.0 THEN 3
            WHEN bilirubin_max >= 2.0 THEN 2
            WHEN bilirubin_max >= 1.2 THEN 1
            WHEN bilirubin_max IS NULL THEN null
            ELSE 0
        END AS liver

        -- Cardiovascular
        , CASE
            WHEN rate_dopamine > 15
                OR rate_epinephrine > 0.1
                OR rate_norepinephrine > 0.1
                THEN 4
            WHEN rate_dopamine > 5
                OR rate_epinephrine <= 0.1
                OR rate_norepinephrine <= 0.1
                THEN 3
            WHEN rate_dopamine > 0
                OR rate_dobutamine > 0
                THEN 2
            WHEN meanbp_min < 70 THEN 1
            WHEN
                COALESCE(
                    meanbp_min
                    , rate_dopamine
                    , rate_dobutamine
                    , rate_epinephrine
                    , rate_norepinephrine
                ) IS NULL THEN null
            ELSE 0
        END AS cardiovascular

        -- Neurological failure (GCS)
        , CASE
            WHEN (gcs_min >= 13 AND gcs_min <= 14) THEN 1
            WHEN (gcs_min >= 10 AND gcs_min <= 12) THEN 2
            WHEN (gcs_min >= 6 AND gcs_min <= 9) THEN 3
            WHEN gcs_min < 6 THEN 4
            WHEN gcs_min IS NULL THEN null
            ELSE 0
        END AS cns

        -- Renal failure - high creatinine or low urine output
        , CASE
            WHEN (creatinine_max >= 5.0) THEN 4
            WHEN uo_24hr < 200 THEN 4
            WHEN (creatinine_max >= 3.5 AND creatinine_max < 5.0) THEN 3
            WHEN uo_24hr < 500 THEN 3
            WHEN (creatinine_max >= 2.0 AND creatinine_max < 3.5) THEN 2
            WHEN (creatinine_max >= 1.2 AND creatinine_max < 2.0) THEN 1
            WHEN COALESCE(uo_24hr, creatinine_max) IS NULL THEN null
            ELSE 0
        END AS renal
    FROM scorecomp
)

, score_final AS (
    SELECT s.*
        -- Combine all the scores to get SOFA
        -- Impute 0 if the score is missing
        -- the window function takes the max over the last 24 hours
        , COALESCE(
            MAX(respiration) OVER w
            , 0) AS respiration_24hours
        , COALESCE(
            MAX(coagulation) OVER w
            , 0) AS coagulation_24hours
        , COALESCE(
            MAX(liver) OVER w
            , 0) AS liver_24hours
        , COALESCE(
            MAX(cardiovascular) OVER w
            , 0) AS cardiovascular_24hours
        , COALESCE(
            MAX(cns) OVER w
            , 0) AS cns_24hours
        , COALESCE(
            MAX(renal) OVER w
            , 0) AS renal_24hours

        -- sum together data for final SOFA
        , COALESCE(
            MAX(respiration) OVER w
            , 0)
        + COALESCE(
            MAX(coagulation) OVER w
            , 0)
        + COALESCE(
            MAX(liver) OVER w
            , 0)
        + COALESCE(
            MAX(cardiovascular) OVER w
            , 0)
        + COALESCE(
            MAX(cns) OVER w
            , 0)
        + COALESCE(
            MAX(renal) OVER w
            , 0)
        AS sofa_24hours
    FROM scorecalc s
    WINDOW w AS
        (
            PARTITION BY stay_id
            ORDER BY hr
            ROWS BETWEEN 23 PRECEDING AND 0 FOLLOWING
        )
)
SELECT ie.patientunitstayid,
       sc.hr,
       sc.starttime                AS start_ho,
       sc.endtime                  AS end_ho,
       sc.starttime - ie.intime_ho AS start_io,
       sc.endtime - ie.intime_ho   AS end_io,
       sc.pao2fio2ratio_novent,
       sc.pao2fio2ratio_vent,
       sc.rate_epinephrine,
       sc.rate_norepinephrine,
       sc.rate_dopamine,
       sc.rate_dobutamine,
       sc.meanbp_min,
       sc.gcs_min,
       sc.uo_24hr,
       sc.bilirubin_max,
       sc.creatinine_max,
       sc.platelet_min,
       sc.respiration,
       sc.coagulation,
       sc.liver,
       sc.cardiovascular,
       sc.cns,
       sc.renal,
       sc.respiration_24hours,
       sc.coagulation_24hours,
       sc.liver_24hours,
       sc.cardiovascular_24hours,
       sc.cns_24hours,
       sc.renal_24hours,
       sc.sofa_24hours,
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       sc.starttime,
       sc.endtime
FROM eicu_crd_icu.icustays AS ie
         INNER JOIN score_final AS sc
                    ON ie.stay_id = sc.stay_id
WHERE sc.hr >= 0
ORDER BY ie.subject_id, ie.hadm_id, sc.starttime;









