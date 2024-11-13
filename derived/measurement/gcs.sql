
CREATE TABLE aims_eicu_crd_derived.gcs AS
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       le.patientunitstayid,
       ie.intime_ho + le.chartoffset AS chart_ho,
       le.chartoffset AS chart_io,
       le.gcs,
       le.gcsmotor,
       le.gcsverbal,
       le.gcseyes,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.chartoffset AS charttime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN physionet-data.eicu_crd_derived.pivoted_gcs AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY ie.subject_id, ie.hadm_id, ie.intime_ho + le.chartoffset;









