
DROP TABLE IF EXISTS aims_eicu_crd_derived.sepsis3;
CREATE TABLE aims_eicu_crd_derived.sepsis3 AS
WITH sofa AS (
    SELECT patientunitstayid,
           start_ho,
           end_ho,
           start_io,
           end_io,
           stay_id,
           starttime,
           endtime,
           respiration_24hours    AS respiration,
           coagulation_24hours    AS coagulation,
           liver_24hours          AS liver,
           cardiovascular_24hours AS cardiovascular,
           cns_24hours            AS cns,
           renal_24hours          AS renal,
           sofa_24hours           AS sofa_score
    FROM aims_eicu_crd_derived.sofa
    WHERE sofa_24hours >= 2
), s1 AS (
    SELECT soi.patientunitstayid,
           soi.subject_id,
           soi.stay_id,
           -- suspicion columns
           soi.ab_id,
           soi.antibiotic,
           soi.antibiotic_ho,
           soi.antibiotic_io,
           soi.suspected_infection,
           soi.suspected_infection_time,
           -- sofa columns
           start_ho, end_ho,
           start_io, end_io,
           starttime, endtime,
           respiration, coagulation, liver, cardiovascular, cns, renal,
           sofa_score,
           -- All rows have an associated suspicion of infection event
           -- Therefore, Sepsis-3 is defined as SOFA >= 2.
           -- Implicitly, the baseline SOFA score is assumed to be zero,
           -- as we do not know if the patient has preexisting
           -- (acute or chronic) organ dysfunction before the onset
           -- of infection.
           sofa_score >= 2 AND suspected_infection = 1 AS sepsis3,
           -- subselect to the earliest suspicion/antibiotic/SOFA row
           ROW_NUMBER() OVER
               (
               PARTITION BY soi.stay_id
               ORDER BY
                   suspected_infection_time, endtime
               )                                       AS rn_sus
    FROM aims_eicu_crd_derived.suspicion_of_infection AS soi
             INNER JOIN sofa
                        ON soi.stay_id = sofa.stay_id AND
                           sofa.endtime >= (soi.suspected_infection_time - 60 * 24) AND
                           sofa.endtime <= (soi.suspected_infection_time + 60 * 12)
    -- only include in-ICU rows
    WHERE soi.stay_id IS NOT NULL
)
SELECT patientunitstayid,
       subject_id, stay_id,
       -- note: there may be more than one antibiotic given at this time
       antibiotic_ho,
       antibiotic_io,
       -- culture times may be dates, rather than times
       suspected_infection_time,
       -- endtime is latest time at which the SOFA score is valid
       end_ho AS sofa_ho,
       end_io AS sofa_io,
       endtime AS sofa_time,
       LEAST(start_ho, end_ho) AS sepsis_ho,
       LEAST(start_io, end_io) AS sepsis_io,
       LEAST(start_ho, endtime) AS sepsis_time,
       sofa_score,
       respiration, coagulation, liver, cardiovascular, cns, renal,
       sepsis3
FROM s1
WHERE rn_sus = 1
ORDER BY subject_id, stay_id;









