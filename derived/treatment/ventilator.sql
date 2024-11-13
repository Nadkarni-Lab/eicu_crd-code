
-- ====================================================================================================
-- ventilator
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- - 
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.ventilator;
CREATE TABLE aims_eicu_crd_derived.ventilator AS
WITH v1 as (
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
), vd1 AS (
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
           ie.intime_ho + id.chart_io AS charttime,
           -- endtime imputation purpose
           ie.intime_ho,
           ie.intime_io,
           ie.intime,
           ie.outtime_ho,
           ie.outtime_io,
           ie.outtime
    FROM aims_eicu_crd_icu.icustays AS ie
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
), vd2 AS (
    SELECT patientunitstayid,
           chart_ho AS start_ho,
           chart_io AS start_io,
           LEAD(chart_ho) OVER (
               PARTITION BY stay_id
               ORDER BY charttime
               ) AS end_ho,
           LEAD(chart_io) OVER (
               PARTITION BY stay_id
               ORDER BY charttime
               ) AS end_io,
           mechvent,
           -- MIMIC style
           subject_id,
           hadm_id,
           stay_id,
           charttime AS starttime,
           LEAD(charttime) OVER (
               PARTITION BY stay_id
               ORDER BY charttime
               ) AS endtime,
           -- endtime imputation purpose
           intime_ho,
           intime_io,
           intime,
           outtime_ho,
           outtime_io,
           outtime
    FROM vd1
    ORDER BY subject_id, hadm_id, stay_id, charttime
)
SELECT patientunitstayid,
       start_ho,
       start_io,
       CASE
           WHEN end_ho IS NULL
               THEN LEAST(start_ho + 60 * 24 * 4, outtime_ho)
           ELSE LEAST(start_ho + 60 * 24 * 4, end_ho)
           END AS end_ho,
       CASE
           WHEN end_io IS NULL
               THEN LEAST(start_io + 60 * 24 * 4, outtime_io)
           ELSE LEAST(start_io + 60 * 24 * 4, end_io)
           END AS end_io,
       mechvent,
       subject_id,
       hadm_id,
       stay_id,
       starttime,
       CASE
           WHEN endtime IS NULL
               THEN LEAST(starttime + 60 * 24 * 4, outtime)
           ELSE LEAST(starttime + 60 * 24 * 4, endtime)
           END AS endtime
FROM vd2
ORDER BY subject_id, hadm_id, stay_id, starttime









