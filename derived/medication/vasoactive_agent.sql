
-- ====================================================================================================
-- vasoactive agent
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/medication/vasoactive_agent.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

-- This query creates a single table with ongoing doses of vasoactive agents.
-- TBD: rarely angiotensin II, methylene blue, and
-- isoprenaline/isoproterenol are used. These are not in the query currently
-- as they are not documented in MetaVision. However, they could
-- be documented in other hospital wide systems.

-- collect all vasopressor administration times
-- create a single table with these as start/stop times
DROP TABLE IF EXISTS aims_eicu_crd_derived.vasoactive_agent;
CREATE TABLE aims_eicu_crd_derived.vasoactive_agent AS
WITH tm AS (
    SELECT stay_id, starttime AS vasotime
    FROM aims_eicu_crd_derived.dobutamine
    UNION DISTINCT
    SELECT stay_id, starttime AS vasotime
    FROM aims_eicu_crd_derived.dopamine
    UNION DISTINCT
    SELECT stay_id, starttime AS vasotime
    FROM aims_eicu_crd_derived.epinephrine
    UNION DISTINCT
    SELECT stay_id, starttime AS vasotime
    FROM aims_eicu_crd_derived.norepinephrine
    UNION DISTINCT
    SELECT stay_id, starttime AS vasotime
    FROM aims_eicu_crd_derived.phenylephrine
    UNION DISTINCT
    SELECT stay_id, starttime AS vasotime
    FROM aims_eicu_crd_derived.vasopressin
    UNION DISTINCT
    -- combine end times from the same tables
    SELECT stay_id, endtime AS vasotime
    FROM aims_eicu_crd_derived.dobutamine
    UNION DISTINCT
    SELECT stay_id, endtime AS vasotime
    FROM aims_eicu_crd_derived.dopamine
    UNION DISTINCT
    SELECT stay_id, endtime AS vasotime
    FROM aims_eicu_crd_derived.epinephrine
    UNION DISTINCT
    SELECT stay_id, endtime AS vasotime
    FROM aims_eicu_crd_derived.norepinephrine
    UNION DISTINCT
    SELECT stay_id, endtime AS vasotime
    FROM aims_eicu_crd_derived.phenylephrine
    UNION DISTINCT
    SELECT stay_id, endtime AS vasotime
    FROM aims_eicu_crd_derived.vasopressin
),
-- create starttime/endtime from all possible times collected
tm_lag AS (
    SELECT stay_id,
           vasotime                                            AS starttime,
           -- note: the last row for each partition (stay_id) will have
           -- a NULL endtime. we can drop this row later, as we know that no
           -- vasopressor will start at this time (otherwise, we would have
           -- a later end time, which would mean it's not the last row!)
           LEAD(
                   vasotime, 1
               ) OVER (PARTITION BY stay_id ORDER BY vasotime) AS endtime
    FROM tm
), rx AS (
    -- left join to raw data tables to combine doses
    SELECT t.stay_id,
           t.starttime,
           t.endtime,
           -- inopressors/vasopressors
           dop.vaso_rate AS dopamine,       -- mcg/kg/min
           epi.vaso_rate AS epinephrine,    -- mcg/kg/min
           nor.vaso_rate AS norepinephrine, -- mcg/kg/min
           phe.vaso_rate AS phenylephrine,  -- mcg/kg/min
           vas.vaso_rate AS vasopressin,     -- units/hour
           -- inodialators
           dob.vaso_rate AS dobutamine -- mcg/kg/min
           -- isoproterenol is used in CCU/CVICU but not in metavision
           -- other drugs not included here but (rarely) used in the BIDMC:
           -- angiotensin II, methylene blue
    FROM tm_lag AS t
             LEFT JOIN aims_eicu_crd_derived.dobutamine AS dob
                       ON t.stay_id = dob.stay_id
                           AND t.starttime >= dob.starttime
                           AND t.endtime <= dob.endtime
             LEFT JOIN aims_eicu_crd_derived.dopamine AS dop
                       ON t.stay_id = dop.stay_id
                           AND t.starttime >= dop.starttime
                           AND t.endtime <= dop.endtime
             LEFT JOIN aims_eicu_crd_derived.epinephrine AS epi
                       ON t.stay_id = epi.stay_id
                           AND t.starttime >= epi.starttime
                           AND t.endtime <= epi.endtime
             LEFT JOIN aims_eicu_crd_derived.norepinephrine AS nor
                       ON t.stay_id = nor.stay_id
                           AND t.starttime >= nor.starttime
                           AND t.endtime <= nor.endtime
             LEFT JOIN aims_eicu_crd_derived.phenylephrine AS phe
                       ON t.stay_id = phe.stay_id
                           AND t.starttime >= phe.starttime
                           AND t.endtime <= phe.endtime
             LEFT JOIN aims_eicu_crd_derived.vasopressin AS vas
                       ON t.stay_id = vas.stay_id
                           AND t.starttime >= vas.starttime
                           AND t.endtime <= vas.endtime
    -- remove the final row for each stay_id
    -- it will not have any infusions associated with it
    WHERE t.endtime IS NOT NULL
)
SELECT ie.uniquepid,
       ie.patienthealthsystemstayid,
       ie.patientunitstayid,
       rx.starttime                AS start_ho,
       rx.starttime - ie.intime_ho AS start_io,
       rx.endtime                  AS end_ho,
       rx.endtime - ie.intime_ho   AS end_io,
       rx.dopamine,
       rx.epinephrine,
       rx.norepinephrine,
       rx.phenylephrine,
       rx.vasopressin,
       rx.dobutamine,
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       rx.starttime,
       rx.endtime
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN rx
                    ON ie.stay_id = rx.stay_id
WHERE rx.dopamine IS NOT NULL
   OR rx.epinephrine IS NOT NULL
   OR rx.norepinephrine IS NOT NULL
   OR rx.phenylephrine IS NOT NULL
   OR rx.vasopressin IS NOT NULL
   OR rx.dobutamine IS NOT NULL
ORDER BY ie.subject_id, ie.hadm_id, ie.stay_id, rx.starttime;









