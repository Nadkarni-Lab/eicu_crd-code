# eICU-CRD Concepts
This repository provides SQL scripts for preprocessing and generating concepts in the MIMIC-IV and eICU-CRD databases, facilitating the use of these datasets in machine learning pipelines with minimal modifications.


## Directory Structure
* [hosp](/hosp/): SQL queries to construct core tables related to admissions and patients in the MIMIC-IV dataset.
* [icu](/icu/): SQL queries to build the icustays table, which focuses on ICU-specific data in the MIMIC-IV dataset.
* [derived](/derived/): SQL queries to construct derived concepts, utilizing data from MIMIC-IV for analytical and ML applications.


## Offset (Timestamp) Encoding
The eICU-CRD data traditionally encodes timestamps relative to ICU admission. This approach is useful when the focus is on single ICU stays or events strictly within the ICU setting.
The timestamps (offsets) in this repository are encoded relative to hospital admission, rather than ICU admission. This approach is beneficial for analyses that involve multiple ICU stays during a single hospitalization, or investigations that encompass the full hospital admission and discharge period.

To ensure interoperability while preserving the eICU-CRD’s original data structure, we developed a clear naming convention for timestamp offsets:
* **Suffix** `_ho`: Encodes offset relative to hospital admission.
* **Suffix** `_io`: Encodes offset relative to ICU admission.
* **No suffix**: Default offset relative to hospital admission.


## Standardized Identifiers
To harmonize the identifiers across both databases, the following mappings are established:
* `subject_id`: Equivalent to `uniquepid`
* `hadm_id`: Equivalent to `patienthealthsystemstayid`
* `stay_id`: Equivalent to `patientunitstayid`


## Citation
If you find this SQL code helpful, please cite the following paper:
> Takkavatakarn K, Oh W, Chan L, Hofer I, Shawwa K, Kraft M, Shah N, Kohli-Seth R, Nadkarni GN, Sakhuja A. Machine learning derived serum creatinine trajectories in acute kidney injury in critically ill patients with sepsis. Critical Care. 2024 May 10;28(1):156.
