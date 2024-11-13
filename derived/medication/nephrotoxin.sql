
-- ====================================================================================================
-- nephrotoxin
-- Version: 1.0
-- Moderator:
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Contributors:
-- - Kullaya Takkavatakarn (kullaya.takkavatakarn@mssm.edu)
-- - Wonsuk Oh (wonsuk.oh@mssm.edu)
-- Purpose:
-- - The objective of this query is to extract nephrotoxic medication.
-- Reference:
-- - https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7170726/
-- History:
-- - 1.0: Create new query.
-- ====================================================================================================

DROP TABLE IF EXISTS aims_eicu_crd_derived.nephrotoxin;
CREATE TABLE aims_eicu_crd_derived.nephrotoxin AS
SELECT rx.patientunitstayid,
       rx.drugstartoffset,
       rx.drugname,
       rx.drughiclseqno,
       rx.routeadmin,
       -- MIMIC style
       ie.subject_id,
       ie.hadm_id,
       ie.stay_id,
       (ie.intime + rx.drugstartoffset) AS charttime,
       rx.drugname                      AS medication,
       rx.routeadmin                    AS route
FROM aims_eicu_crd_icu.icustays AS ie
         INNER JOIN `physionet-data.eicu_crd.medication` AS rx
                    ON ie.patientunitstayid = rx.patientunitstayid
WHERE (LOWER(drugname) LIKE '%cyclovir%' OR
       LOWER(drugname) LIKE '%mikacin%' OR
       LOWER(drugname) LIKE '%mphotericin%' OR
       LOWER(drugname) LIKE '%spirin%' OR
       LOWER(drugname) LIKE '%aptopril%' OR
       LOWER(drugname) LIKE '%arboplatin%' OR
       LOWER(drugname) LIKE '%idofovir%' OR
       LOWER(drugname) LIKE '%olisti%' OR
       LOWER(drugname) LIKE '%eferasirox%' OR
       LOWER(drugname) LIKE '%nalaprilat%' OR
       LOWER(drugname) LIKE '%nalapril%' OR
       LOWER(drugname) LIKE '%oscarnet%' OR
       LOWER(drugname) LIKE '%anciclovir%' OR
       LOWER(drugname) LIKE '%entamicin%' OR
       LOWER(drugname) LIKE '%buprofen%' OR
       LOWER(drugname) LIKE '%fosfamide%' OR
       LOWER(drugname) LIKE '%ndomethacin%' OR
       LOWER(drugname) LIKE '%isinopril%' OR
       LOWER(drugname) LIKE '%osartan%' OR
       LOWER(drugname) LIKE '%ithium%' OR
       LOWER(drugname) LIKE '%esalamine%' OR
       LOWER(drugname) LIKE '%ethotrexate%' OR
       LOWER(drugname) LIKE '%itomycin%' OR
       LOWER(drugname) LIKE '%aproxen%' OR
       LOWER(drugname) LIKE '%afcillin%' OR
       LOWER(drugname) LIKE '%amidronate%' OR
       LOWER(drugname) LIKE '%entamidine%' OR
       LOWER(drugname) LIKE '%iperacillin%' OR
       LOWER(drugname) LIKE '%olymixin B%' OR
       LOWER(drugname) LIKE '%ulfasalazine%' OR
       LOWER(drugname) LIKE '%irolimus%' OR
       LOWER(drugname) LIKE '%acrolimus%' OR
       LOWER(drugname) LIKE '%enofovir%' OR
       LOWER(drugname) LIKE '%icarcillin/clavulanic acid%' OR
       LOWER(drugname) LIKE '%obramycin%' OR
       LOWER(drugname) LIKE '%opiramate%' OR
       LOWER(drugname) LIKE '%alacyclovir%' OR
       LOWER(drugname) LIKE '%alsartan%' OR
       LOWER(drugname) LIKE '%ancomycin%' OR
       LOWER(drugname) LIKE '%onisamide%' OR
       LOWER(drugname) LIKE '%oledronic acid%' OR
       LOWER(drugname) LIKE '%odixanol%' OR
       LOWER(drugname) LIKE '%ohexol%' OR
       LOWER(drugname) LIKE '%opamidol%' OR
       LOWER(drugname) LIKE '%opromide%' OR
       LOWER(drugname) LIKE '%oversol%' OR
       LOWER(drugname) LIKE '%iatrizoate meglumine%' OR
       LOWER(drugname) LIKE '%iatrizoate sodium%' OR
       LOWER(drugname) LIKE '%oxaglate sodium%' OR
       LOWER(drugname) LIKE '%oxilan%') AND
           LOWER(routeadmin) NOT LIKE '%ear%' AND
           LOWER(routeadmin) NOT LIKE '%eye%' AND
           LOWER(routeadmin) NOT LIKE '%opth%' AND
           LOWER(routeadmin) NOT LIKE '%nostril%' AND
           LOWER(routeadmin) NOT LIKE '%topical%' AND
           LOWER(routeadmin) NOT LIKE '%transderm%'
ORDER BY ie.subject_id, ie.hadm_id, ie.stay_id, ie.intime + rx.drugstartoffset;









