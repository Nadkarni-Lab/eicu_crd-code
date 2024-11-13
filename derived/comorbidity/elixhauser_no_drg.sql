
-- ====================================================================================================
-- Elixhauser comorbidities
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- - This code is designed to extract Elixhauser comorbidities.
-- Reference:
-- - http://mchp-appserv.cpe.umanitoba.ca/viewConcept.php?printer=Y&conceptID=1436
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.elixhauser_no_drg;
CREATE TABLE aims_eicu_crd_derived.elixhauser_no_drg AS
WITH hx AS (
    SELECT ie.subject_id,
           ie.hadm_id,
           ie.stay_id,
           ad.dischyear AS disch_yr,
           -- Congestive heart failure
           CASE
               WHEN (SUBSTRING(icd9code, 1, 5) = '39891') OR
                    (SUBSTRING(icd9code, 1, 5) = '40201') OR
                    (SUBSTRING(icd9code, 1, 5) = '40211') OR
                    (SUBSTRING(icd9code, 1, 5) = '40291') OR
                    (SUBSTRING(icd9code, 1, 5) = '40401') OR
                    (SUBSTRING(icd9code, 1, 5) = '40403') OR
                    (SUBSTRING(icd9code, 1, 5) = '40411') OR
                    (SUBSTRING(icd9code, 1, 5) = '40413') OR
                    (SUBSTRING(icd9code, 1, 5) = '40491') OR
                    (SUBSTRING(icd9code, 1, 5) = '40493') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '4254' AND '4259') OR
                    (SUBSTRING(icd9code, 1, 3) = '428')
                   THEN 1
               ELSE 0
               END AS chf,
           -- Cardiac arrhythmias
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '4260') OR
                    (SUBSTRING(icd9code, 1, 5) = '42613') OR
                    (SUBSTRING(icd9code, 1, 4) = '4267') OR
                    (SUBSTRING(icd9code, 1, 4) = '4269') OR
                    (SUBSTRING(icd9code, 1, 5) = '42610') OR
                    (SUBSTRING(icd9code, 1, 5) = '42612') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '4270' AND '4274') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '4276' AND '4279') OR
                    (SUBSTRING(icd9code, 1, 4) = '7850') OR
                    (SUBSTRING(icd9code, 1, 5) = '99601') OR
                    (SUBSTRING(icd9code, 1, 5) = '99604') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V450') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V533')
                   THEN 1
               ELSE 0
               END AS arythm,
           -- Valvular disease
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '0932') OR
                    (SUBSTRING(icd9code, 1, 3) BETWEEN '394' AND '397') OR
                    (SUBSTRING(icd9code, 1, 3) = '424') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '7463' AND '7466') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V422') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V433')
                   THEN 1
               ELSE 0
               END AS valve,
           -- Pulmonary circulation disorders
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '4150') OR
                    (SUBSTRING(icd9code, 1, 4) = '4151') OR
                    (SUBSTRING(icd9code, 1, 3) = '416') OR
                    (SUBSTRING(icd9code, 1, 4) = '4170') OR
                    (SUBSTRING(icd9code, 1, 4) = '4178') OR
                    (SUBSTRING(icd9code, 1, 4) = '4179')
                   THEN 1
               ELSE 0
               END AS pulmcirc,
           -- Peripheral vascular disorders
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '0930') OR
                    (SUBSTRING(icd9code, 1, 4) = '4373') OR
                    (SUBSTRING(icd9code, 1, 3) = '440') OR
                    (SUBSTRING(icd9code, 1, 3) = '441') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '4431' AND '4439') OR
                    (SUBSTRING(icd9code, 1, 4) = '4471') OR
                    (SUBSTRING(icd9code, 1, 4) = '5571') OR
                    (SUBSTRING(icd9code, 1, 4) = '5579') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V434')
                   THEN 1
               ELSE 0
               END AS perivasc,
           -- Hypertension, uncomplicated
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) = '401')
                   THEN 1
               ELSE 0
               END AS htn,
           -- Hypertension, complicated
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) BETWEEN '402' AND '405')
                   THEN 1
               ELSE 0
               END AS htncx,
           -- Paralysis
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '3341') OR
                    (SUBSTRING(icd9code, 1, 3) = '342') OR
                    (SUBSTRING(icd9code, 1, 3) = '343') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '3440' AND '3446') OR
                    (SUBSTRING(icd9code, 1, 4) = '3449')
                   THEN 1
               ELSE 0
               END AS para,
           -- Other neurological disorders
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '3319') OR
                    (SUBSTRING(icd9code, 1, 4) = '3320') OR
                    (SUBSTRING(icd9code, 1, 4) = '3321') OR
                    (SUBSTRING(icd9code, 1, 4) = '3334') OR
                    (SUBSTRING(icd9code, 1, 4) = '3335') OR
                    (SUBSTRING(icd9code, 1, 5) = '33392') OR
                    (SUBSTRING(icd9code, 1, 3) BETWEEN '334' AND '335') OR
                    (SUBSTRING(icd9code, 1, 4) = '3362') OR
                    (SUBSTRING(icd9code, 1, 3) = '340') OR
                    (SUBSTRING(icd9code, 1, 3) = '341') OR
                    (SUBSTRING(icd9code, 1, 3) = '345') OR
                    (SUBSTRING(icd9code, 1, 4) = '3481') OR
                    (SUBSTRING(icd9code, 1, 4) = '3483') OR
                    (SUBSTRING(icd9code, 1, 4) = '7803') OR
                    (SUBSTRING(icd9code, 1, 4) = '7843')
                   THEN 1
               ELSE 0
               END AS neuro,
           -- Chronic pulmonary disease
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '4168') OR
                    (SUBSTRING(icd9code, 1, 4) = '4169') OR
                    (SUBSTRING(icd9code, 1, 3) BETWEEN '490' AND '505') OR
                    (SUBSTRING(icd9code, 1, 4) = '5064') OR
                    (SUBSTRING(icd9code, 1, 4) = '5081') OR
                    (SUBSTRING(icd9code, 1, 4) = '5088')
                   THEN 1
               ELSE 0
               END AS chrnlung,
           -- Diabetes, uncomplicated
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) BETWEEN '2500' AND '2503')
                   THEN 1
               ELSE 0
               END AS dm,
           -- Diabetes, complicated
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) BETWEEN '2504' AND '2509')
                   THEN 1
               ELSE 0
               END AS dmcx,
           -- Hypothyroidism
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '2409') OR
                    (SUBSTRING(icd9code, 1, 3) = '243') OR
                    (SUBSTRING(icd9code, 1, 3) = '244') OR
                    (SUBSTRING(icd9code, 1, 4) = '2461') OR
                    (SUBSTRING(icd9code, 1, 4) = '2468')
                   THEN 1
               ELSE 0
               END AS hypothy,
           -- Renal failure
           CASE
               WHEN (SUBSTRING(icd9code, 1, 5) = '40301') OR
                    (SUBSTRING(icd9code, 1, 5) = '40311') OR
                    (SUBSTRING(icd9code, 1, 5) = '40391') OR
                    (SUBSTRING(icd9code, 1, 5) = '40402') OR
                    (SUBSTRING(icd9code, 1, 5) = '40403') OR
                    (SUBSTRING(icd9code, 1, 5) = '40412') OR
                    (SUBSTRING(icd9code, 1, 5) = '40413') OR
                    (SUBSTRING(icd9code, 1, 5) = '40492') OR
                    (SUBSTRING(icd9code, 1, 5) = '40493') OR
                    (SUBSTRING(icd9code, 1, 3) = '585') OR
                    (SUBSTRING(icd9code, 1, 3) = '586') OR
                    (SUBSTRING(icd9code, 1, 4) = '5880') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V420') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V451') OR
                    (SUBSTRING(icd9code, 1, 3) = 'V56')
                   THEN 1
               ELSE 0
               END AS renlfail,
           -- Liver disease
           CASE
               WHEN (SUBSTRING(icd9code, 1, 5) = '07022') OR
                    (SUBSTRING(icd9code, 1, 5) = '07023') OR
                    (SUBSTRING(icd9code, 1, 5) = '07032') OR
                    (SUBSTRING(icd9code, 1, 5) = '07033') OR
                    (SUBSTRING(icd9code, 1, 5) = '07044') OR
                    (SUBSTRING(icd9code, 1, 5) = '07054') OR
                    (SUBSTRING(icd9code, 1, 4) = '0706') OR
                    (SUBSTRING(icd9code, 1, 4) = '0709') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '4560' AND '4562') OR
                    (SUBSTRING(icd9code, 1, 3) = '570') OR
                    (SUBSTRING(icd9code, 1, 3) = '571') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '5722' AND '5728') OR
                    (SUBSTRING(icd9code, 1, 4) = '5733') OR
                    (SUBSTRING(icd9code, 1, 4) = '5734') OR
                    (SUBSTRING(icd9code, 1, 4) = '5738') OR
                    (SUBSTRING(icd9code, 1, 4) = '5739') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V427')
                   THEN 1
               ELSE 0
               END AS liver,
           -- Peptic ulcer disease excluding bleeding
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '5317') OR
                    (SUBSTRING(icd9code, 1, 4) = '5319') OR
                    (SUBSTRING(icd9code, 1, 4) = '5327') OR
                    (SUBSTRING(icd9code, 1, 4) = '5329') OR
                    (SUBSTRING(icd9code, 1, 4) = '5337') OR
                    (SUBSTRING(icd9code, 1, 4) = '5339') OR
                    (SUBSTRING(icd9code, 1, 4) = '5347') OR
                    (SUBSTRING(icd9code, 1, 4) = '5349')
                   THEN 1
               ELSE 0
               END AS ulcer,
           -- AIDS/H1V
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) BETWEEN '042' AND '044')
                   THEN 1
               ELSE 0
               END AS aids,
           -- Lymphoma
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) BETWEEN '200' AND '202') OR
                    (SUBSTRING(icd9code, 1, 4) = '2030') OR
                    (SUBSTRING(icd9code, 1, 4) = '2386')
                   THEN 1
               ELSE 0
               END AS lymph,
           -- Metastatic cancer
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) BETWEEN '196' AND '199')
                   THEN 1
               ELSE 0
               END AS mets,
           -- Solid tumor without metastasis
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) BETWEEN '140' AND '172') OR
                    (SUBSTRING(icd9code, 1, 3) BETWEEN '174' AND '195')
                   THEN 1
               ELSE 0
               END AS tumor,
           -- Rheumatoid arthritis/collagen vascular diseases
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) = '446') OR
                    (SUBSTRING(icd9code, 1, 4) = '7010') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '7100' AND '7104') OR
                    (SUBSTRING(icd9code, 1, 4) = '7108') OR
                    (SUBSTRING(icd9code, 1, 4) = '7109') OR
                    (SUBSTRING(icd9code, 1, 4) = '7112') OR
                    (SUBSTRING(icd9code, 1, 3) = '714') OR
                    (SUBSTRING(icd9code, 1, 4) = '7193') OR
                    (SUBSTRING(icd9code, 1, 3) = '720') OR
                    (SUBSTRING(icd9code, 1, 3) = '725') OR
                    (SUBSTRING(icd9code, 1, 4) = '7285') OR
                    (SUBSTRING(icd9code, 1, 5) = '72889') OR
                    (SUBSTRING(icd9code, 1, 5) = '72930')
                   THEN 1
               ELSE 0
               END AS arth,
           -- Coagulopathy
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) = '286') OR
                    (SUBSTRING(icd9code, 1, 4) = '2871') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '2873' AND '2875')
                   THEN 1
               ELSE 0
               END AS coag,
           -- Obesity
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '2780')
                   THEN 1
               ELSE 0
               END AS obese,
           -- Weight loss
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) BETWEEN '260' AND '263') OR
                    (SUBSTRING(icd9code, 1, 4) = '7832') OR
                    (SUBSTRING(icd9code, 1, 4) = '7994')
                   THEN 1
               ELSE 0
               END AS wghtloss,
           -- Fluid and electrolyte disorders
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '2536') OR
                    (SUBSTRING(icd9code, 1, 3) = '276')
                   THEN 1
               ELSE 0
               END AS lytes,
           -- Blood loss anemia
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '2800')
                   THEN 1
               ELSE 0
               END AS bldloss,
           -- Deficiency anemia
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) BETWEEN '2801' AND '2809') OR
                    (SUBSTRING(icd9code, 1, 3) = '281')
                   THEN 1
               ELSE 0
               END AS anemdef,
           -- Alcohol abuse
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '2652') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '2911' AND '2913') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '2915' AND '2919') OR
                    (SUBSTRING(icd9code, 1, 4) = '3030') OR
                    (SUBSTRING(icd9code, 1, 4) = '3039') OR
                    (SUBSTRING(icd9code, 1, 4) = '3050') OR
                    (SUBSTRING(icd9code, 1, 4) = '3575') OR
                    (SUBSTRING(icd9code, 1, 4) = '4255') OR
                    (SUBSTRING(icd9code, 1, 4) = '5353') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '5710' AND '5713') OR
                    (SUBSTRING(icd9code, 1, 3) = '980') OR
                    (SUBSTRING(icd9code, 1, 4) = 'V113')
                   THEN 1
               ELSE 0
               END AS alcohol,
           -- Drug abuse
           CASE
               WHEN (SUBSTRING(icd9code, 1, 3) = '292') OR
                    (SUBSTRING(icd9code, 1, 3) = '304') OR
                    (SUBSTRING(icd9code, 1, 4) BETWEEN '3052' AND '3059') OR
                    (SUBSTRING(icd9code, 1, 5) = 'V6542')
                   THEN 1
               ELSE 0
               END AS drug,
           -- Psychoses
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '2938') OR
                    (SUBSTRING(icd9code, 1, 3) = '295') OR
                    (SUBSTRING(icd9code, 1, 5) = '29604') OR
                    (SUBSTRING(icd9code, 1, 5) = '29614') OR
                    (SUBSTRING(icd9code, 1, 5) = '29644') OR
                    (SUBSTRING(icd9code, 1, 5) = '29654') OR
                    (SUBSTRING(icd9code, 1, 3) = '297') OR
                    (SUBSTRING(icd9code, 1, 3) = '298')
                   THEN 1
               ELSE 0
               END AS psych,
           -- Depression
           CASE
               WHEN (SUBSTRING(icd9code, 1, 4) = '2962') OR
                    (SUBSTRING(icd9code, 1, 4) = '2963') OR
                    (SUBSTRING(icd9code, 1, 4) = '2965') OR
                    (SUBSTRING(icd9code, 1, 4) = '3004') OR
                    (SUBSTRING(icd9code, 1, 3) = '309') OR
                    (SUBSTRING(icd9code, 1, 3) = '311')
                   THEN 1
               ELSE 0
               END AS depress
           --
    FROM aims_eicu_crd_hosp.admissions AS ad
             INNER JOIN aims_eicu_crd_icu.icustays AS ie
                        ON ad.subject_id = ie.subject_id AND
                           ad.hadm_id = ie.hadm_id
             LEFT JOIN physionet-data.eicu_crd.diagnosis AS hx
                       ON ie.stay_id = hx.patientunitstayid
	WHERE diagnosisoffset <= 0
)
SELECT subject_id,
       hadm_id,
       stay_id,
       MAX(chf)      AS chf,
       MAX(arythm)   AS arythm,
       MAX(valve)    AS valve,
       MAX(pulmcirc) AS pulmcirc,
       MAX(perivasc) AS perivasc,
       MAX(htn)      AS htn,
       MAX(htncx)    AS htncx,
       MAX(para)     AS para,
       MAX(neuro)    AS neuro,
       MAX(chrnlung) AS chrnlung,
       MAX(dm)       AS dm,
       MAX(dmcx)     AS dmcx,
       MAX(hypothy)  AS hypothy,
       MAX(renlfail) AS renlfail,
       MAX(liver)    AS liver,
       MAX(ulcer)    AS ulcer,
       MAX(aids)     AS aids,
       MAX(lymph)    AS lymph,
       MAX(mets)     AS mets,
       MAX(tumor)    AS tumor,
       MAX(arth)     AS arth,
       MAX(coag)     AS coag,
       MAX(obese)    AS obese,
       MAX(wghtloss) AS wghtloss,
       MAX(lytes)    AS lytes,
       MAX(bldloss)  AS bldloss,
       MAX(anemdef)  AS anemdef,
       MAX(alcohol)  AS alcohol,
       MAX(drug)     AS drug,
       MAX(psych)    AS psych,
       MAX(depress)  AS depress,
FROM hx
GROUP BY subject_id, hadm_id, stay_id, disch_yr
ORDER BY subject_id, hadm_id, stay_id, disch_yr;









