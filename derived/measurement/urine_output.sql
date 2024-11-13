
-- ====================================================================================================
-- Urine outcome
-- Version: 1.1
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- - Ankit Sakhuja (ToDo)
-- Purpose:
-- - The objective of this query is to retrieve urine output data. The primary contribution of this
--   query is its utilization of items that are frequently recorded on an hourly basis and are likely
--   to occur throughout a patient's stay in the Intensive Care Unit (ICU).
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/measurement/urine_output.sql
-- History:
-- - 1.0: Create new query.
-- - 1.1:
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.urine_output;
CREATE TABLE aims_eicu_crd_derived.urine_output AS
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       le.patientunitstayid,
       ie.intime_ho + le.chartoffset AS chart_ho,
       le.chartoffset                AS chart_io,
       le.urineoutput,
	   -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + le.chartoffset AS charttime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN physionet-data.eicu_crd_derived.pivoted_uo AS le
                    ON ie.patientunitstayid = le.patientunitstayid
ORDER BY ie.subject_id, ie.hadm_id, ie.intime_ho + le.chartoffset;









