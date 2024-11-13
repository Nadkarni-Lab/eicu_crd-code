
-- ====================================================================================================
-- antibiotic
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- -
-- Reference:
-- - https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iv/concepts/medication/antibiotic.sql
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.antibiotic;
CREATE TABLE aims_eicu_crd_derived.antibiotic AS
WITH abx AS (
    SELECT DISTINCT drugname,
                    routeadmin,
                    CASE
                        WHEN LOWER(drugname) LIKE '%adoxa%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ala-tet%' THEN 1
                        WHEN LOWER(drugname) LIKE '%alodox%' THEN 1
                        WHEN LOWER(drugname) LIKE '%amikacin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%amikin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%amoxicill%' THEN 1
                        WHEN LOWER(drugname) LIKE '%amphotericin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%anidulafungin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ancef%' THEN 1
                        WHEN LOWER(drugname) LIKE '%clavulanate%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ampicillin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%augmentin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%avelox%' THEN 1
                        WHEN LOWER(drugname) LIKE '%avidoxy%' THEN 1
                        WHEN LOWER(drugname) LIKE '%azactam%' THEN 1
                        WHEN LOWER(drugname) LIKE '%azithromycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%aztreonam%' THEN 1
                        WHEN LOWER(drugname) LIKE '%axetil%' THEN 1
                        WHEN LOWER(drugname) LIKE '%bactocill%' THEN 1
                        WHEN LOWER(drugname) LIKE '%bactrim%' THEN 1
                        WHEN LOWER(drugname) LIKE '%bactroban%' THEN 1
                        WHEN LOWER(drugname) LIKE '%bethkis%' THEN 1
                        WHEN LOWER(drugname) LIKE '%biaxin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%bicillin l-a%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cayston%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefazolin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cedax%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefoxitin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ceftazidime%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefaclor%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefadroxil%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefdinir%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefditoren%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefepime%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefotan%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefotetan%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefotaxime%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ceftaroline%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefpodoxime%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefpirome%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefprozil%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ceftibuten%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ceftin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ceftriaxone%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cefuroxime%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cephalexin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cephalothin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cephapririn%' THEN 1
                        WHEN LOWER(drugname) LIKE '%chloramphenicol%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cipro%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ciprofloxacin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%claforan%' THEN 1
                        WHEN LOWER(drugname) LIKE '%clarithromycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cleocin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%clindamycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%cubicin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%dicloxacillin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%dirithromycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%doryx%' THEN 1
                        WHEN LOWER(drugname) LIKE '%doxycy%' THEN 1
                        WHEN LOWER(drugname) LIKE '%duricef%' THEN 1
                        WHEN LOWER(drugname) LIKE '%dynacin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ery-tab%' THEN 1
                        WHEN LOWER(drugname) LIKE '%eryped%' THEN 1
                        WHEN LOWER(drugname) LIKE '%eryc%' THEN 1
                        WHEN LOWER(drugname) LIKE '%erythrocin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%erythromycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%factive%' THEN 1
                        WHEN LOWER(drugname) LIKE '%flagyl%' THEN 1
                        WHEN LOWER(drugname) LIKE '%fortaz%' THEN 1
                        WHEN LOWER(drugname) LIKE '%furadantin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%garamycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%gentamicin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%kanamycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%keflex%' THEN 1
                        WHEN LOWER(drugname) LIKE '%kefzol%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ketek%' THEN 1
                        WHEN LOWER(drugname) LIKE '%levaquin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%levofloxacin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%lincocin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%linezolid%' THEN 1
                        WHEN LOWER(drugname) LIKE '%macrobid%' THEN 1
                        WHEN LOWER(drugname) LIKE '%macrodantin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%maxipime%' THEN 1
                        WHEN LOWER(drugname) LIKE '%mefoxin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%metronidazole%' THEN 1
                        WHEN LOWER(drugname) LIKE '%meropenem%' THEN 1
                        WHEN LOWER(drugname) LIKE '%methicillin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%minocin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%minocycline%' THEN 1
                        WHEN LOWER(drugname) LIKE '%monodox%' THEN 1
                        WHEN LOWER(drugname) LIKE '%monurol%' THEN 1
                        WHEN LOWER(drugname) LIKE '%morgidox%' THEN 1
                        WHEN LOWER(drugname) LIKE '%moxatag%' THEN 1
                        WHEN LOWER(drugname) LIKE '%moxifloxacin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%mupirocin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%myrac%' THEN 1
                        WHEN LOWER(drugname) LIKE '%nafcillin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%neomycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%nicazel doxy 30%' THEN 1
                        WHEN LOWER(drugname) LIKE '%nitrofurantoin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%norfloxacin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%noroxin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ocudox%' THEN 1
                        WHEN LOWER(drugname) LIKE '%ofloxacin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%omnicef%' THEN 1
                        WHEN LOWER(drugname) LIKE '%oracea%' THEN 1
                        WHEN LOWER(drugname) LIKE '%oraxyl%' THEN 1
                        WHEN LOWER(drugname) LIKE '%oxacillin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%pc pen vk%' THEN 1
                        WHEN LOWER(drugname) LIKE '%pce dispertab%' THEN 1
                        WHEN LOWER(drugname) LIKE '%panixine%' THEN 1
                        WHEN LOWER(drugname) LIKE '%pediazole%' THEN 1
                        WHEN LOWER(drugname) LIKE '%penicillin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%periostat%' THEN 1
                        WHEN LOWER(drugname) LIKE '%pfizerpen%' THEN 1
                        WHEN LOWER(drugname) LIKE '%piperacillin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%tazobactam%' THEN 1
                        WHEN LOWER(drugname) LIKE '%primsol%' THEN 1
                        WHEN LOWER(drugname) LIKE '%proquin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%raniclor%' THEN 1
                        WHEN LOWER(drugname) LIKE '%rifadin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%rifampin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%rocephin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%smz-tmp%' THEN 1
                        WHEN LOWER(drugname) LIKE '%septra%' THEN 1
                        WHEN LOWER(drugname) LIKE '%septra ds%' THEN 1
                        WHEN LOWER(drugname) LIKE '%septra%' THEN 1
                        WHEN LOWER(drugname) LIKE '%solodyn%' THEN 1
                        WHEN LOWER(drugname) LIKE '%spectracef%' THEN 1
                        WHEN LOWER(drugname) LIKE '%streptomycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%sulfadiazine%' THEN 1
                        WHEN LOWER(drugname) LIKE '%sulfamethoxazole%' THEN 1
                        WHEN LOWER(drugname) LIKE '%trimethoprim%' THEN 1
                        WHEN LOWER(drugname) LIKE '%sulfatrim%' THEN 1
                        WHEN LOWER(drugname) LIKE '%sulfisoxazole%' THEN 1
                        WHEN LOWER(drugname) LIKE '%suprax%' THEN 1
                        WHEN LOWER(drugname) LIKE '%synercid%' THEN 1
                        WHEN LOWER(drugname) LIKE '%tazicef%' THEN 1
                        WHEN LOWER(drugname) LIKE '%tetracycline%' THEN 1
                        WHEN LOWER(drugname) LIKE '%timentin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%tobramycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%trimethoprim%' THEN 1
                        WHEN LOWER(drugname) LIKE '%unasyn%' THEN 1
                        WHEN LOWER(drugname) LIKE '%vancocin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%vancomycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%vantin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%vibativ%' THEN 1
                        WHEN LOWER(drugname) LIKE '%vibra-tabs%' THEN 1
                        WHEN LOWER(drugname) LIKE '%vibramycin%' THEN 1
                        WHEN LOWER(drugname) LIKE '%zinacef%' THEN 1
                        WHEN LOWER(drugname) LIKE '%zithromax%' THEN 1
                        WHEN LOWER(drugname) LIKE '%zosyn%' THEN 1
                        WHEN LOWER(drugname) LIKE '%zyvox%' THEN 1
                        ELSE 0
                        END AS antibiotic
    FROM `physionet-data.eicu_crd.medication`
    WHERE UPPER(routeadmin) NOT IN ('OU', 'OS', 'OD', 'AU', 'AS', 'AD', 'TP')
      AND LOWER(routeadmin) NOT LIKE '%ear%'
      AND LOWER(routeadmin) NOT LIKE '%eye%'
      -- we exclude certain types of antibiotics: topical creams,
      -- gels, desens, etc
      AND LOWER(drugname) NOT LIKE '%cream%'
      AND LOWER(drugname) NOT LIKE '%desensitization%'
      AND LOWER(drugname) NOT LIKE '%ophth oint%'
      AND LOWER(drugname) NOT LIKE '%gel%'
)
SELECT pr.patientunitstayid,
       pr.drugname                       AS antibiotic,
       pr.routeadmin                     AS route,
       ie.intime_ho + pr.drugstartoffset AS start_ho,
       ie.intime_ho + pr.drugstopoffset  AS stop_ho,
       pr.drugstartoffset                AS start_io,
       pr.drugstopoffset                 AS stop_io,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       ie.intime_ho + pr.drugstartoffset AS starttime,
       ie.intime_ho + pr.drugstopoffset  AS stoptime,
FROM `physionet-data.eicu_crd.medication` AS pr
-- inner join to subselect to only antibiotic prescriptions
         INNER JOIN abx
                    ON pr.drugname = abx.drugname
                        -- route is never NULL for antibiotics
                        -- only ~4000 null rows in prescriptions total.
                        AND pr.routeadmin = abx.routeadmin
-- add in stay_id as we use this table for sepsis-3
         INNER JOIN aims_eicu_crd_icu.icustays AS ie
                    ON pr.patientunitstayid = ie.patientunitstayid
--                         AND (ie.intime_ho + pr.drugstartoffset) >= ie.intime_ho
--                         AND (ie.intime_ho + pr.drugstartoffset) < ie.intime_ho
WHERE abx.antibiotic = 1
ORDER BY subject_id, hadm_id, stay_id, ie.intime_ho + pr.drugstartoffset;









