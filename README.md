# A wearable-bioadhesive patch enabling ultrasound neuromodulation and real-time electrophysiological monitoring for REM sleep enhancement
## Author Information
_Kai Wing Kevin Tang1,†_, Benjamin Baird2,†, William D. Moscoso-Barrera1,†, Mengxia Yu1,†, Mengmeng Yao1, Jinmo Jeong1, Ilya Pyatnitskiy1, Anakaren Romero Lozano1, Jiachen Wang1, Ju-Chun Hsieh1, Tony Chae1, Daniel Song1, Julieta Garcia1, Rithvik Mittapalli1, Adam Bush1, Wynn Legon3, Vincent Mysliwiec4,* Gregory A. Fonzo5,* Huiliang Wang1,*

BioRxiv Preprint: doi: https://doi.org/10.1101/2025.10.19.683337

## Affiliation
1. Department of Biomedical Engineering, Cockrell School of Engineering, The University of Texas at Austin, Austin, Texas 78712, United States.
2. Department of Psychology, The University of Texas at Austin, Austin, Texas 78712, United States.
3. Fralin Biomedical Research Institute, Virginia Polytechnic Institute, Blacksburg, Virginia 24061, United States.
4. Department of Psychiatry and Behavioral Sciences, The University of Texas Health Science at San Antonio, San Antonio, Texas 78229, United States.
5. Department of Psychiatry and Behavioral Sciences, Dell Medical School, The University of Texas at Austin, Austin, Texas 78712, United States.

†These authors contributed equally to this work. 

†First-Author: kevin.tang@utexas.edu

*Corresponding to: mysliwiec@uthscsa.edu; gfonzo@austin.utexas.edu; evanwang@utexas.edu

## Abstract
Wearable bioelectronic interfaces capable of simultaneous neural sensing and targeted deep brain modulation remain limited by the lack of non-invasive technologies with sufficient spatial precision and mechanical stability for continuous operation. Here we report NEUSLeeP, a flexible wearable-bioadhesive patch integrating electrophysiological sensing with transcranial focused ultrasound neuromodulation. The system incorporates a tunable concentric-ring ultrasound array, conformal hydrogel electrophysiological electrodes, and compliant interconnects within a soft substrate optimized for stable overnight operation. This integrated architecture enables spatially selective modulation and concurrent electrophysiological monitoring of deep brain structures, specifically the subthalamic nucleus during natural sleep. In a 28-participant study, NEUSLeeP demonstrated robust monitoring of sleep performance with precise-targeted neuromodulation of STN resulting in an increase in REM duration by 4.6% and reducing REM latency by 24%. This work establishes a wearable ultrasound bioelectronic platform for non-invasive, spatiotemporally precise modulation and monitoring of deep neural circuits for neuroscience and bioelectronic medicine. ClinicalTrials.gov identifier: NCT07190287

## Competing Interest Statement

The authors K.W.K.T., M.M.Y., J.J. and H.W. declare the following competing financial interest(s): A patent application relating to this work has been filed. The remaining authors declare no competing interests.

## Funding

Defense Advanced Research Projects Agency (DARPA) (REM-REST) grant

## Repository Description
```
1.) Code used for MRI, EEG, and materials analysis. 
2.) Scripts for Verasonics Vantage 64LE to control NEUSLeeP 
3.) MATLAB scripts for 3-axis motor system for acoustic field characterizations.
4.) MATLAB scripts for simulation.
5.) Details on design and parameters of NEUSLeeP
```

## System Requirements
### Operating System
```
Windows 10 or 11, Mac OS Monterey 12 or above.
```

### Software Dependencies
```
1.) Anaconda Environment
2.) Python 3.8.3
3.) AFNI 24.3.06
4.) FSL 6.0.7.15
5.) MATLAB 2024b
6.) eeglab
7.) COMSOL 6.0
```

### Additional Hardwares
```
1.) Verasonics Vantage 64LE
2.) Arduino Uno
3.) 3-axis system controlled by Arduino Mega
4.) Oscilloscope with known USB address
5.) 3T Primsa or 3T Vida Siemens
6.) BrainVision ExG EEG Amplifier (or any EEG amplifier)
7.) Torbal Force Gauge
```

## Installation Guide

### Root Tree Directory Structure

```bash
DARPA-NEUSLeeP/
├── MRI-Study/            (Directory for fMRI Analysis using AFNI and FSL)
├── NEUSLeeP/             (Directory for NEUSLeeP characterization)
├── Sleep-Study/          (Directory for Sleep Study analaysis)
└── NCT-071920287.csv/    (ClinicalTrials.gov details) 
```

## Instructions
### MRI Analysis 
1.) Open a terminal and navigate into _MRI-Study_ and create a folder for each subject with the following subdirectory structure

```
MRI-Study/
├── sub-001-1
│   └── ses-night
│       ├── anat
│       └── func
├── sub-001-2
│   └── ses-night
│       ├── anat
│       └── func
```

2.) Place your anatomical and functional scans to the corresponding _anat_ and _func_ folders

```
sub-001-1/
└── ses-night
    ├── anat
    │   ├── sub-001-1_anat-ses-night_T1w_acq-0.8mmIso.json
    │   └── sub-001-1_anat-ses-night_T1w_acq-0.8mmIso.nii.gz
    │
    └── func
        ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-AP.nii.gz
        ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-AP.json
        ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-PA.nii.gz
        ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-PA.json
        ├── sub-001-1_func_ses-night_task-rest_run-01_acq-AP.nii.gz
        ├── sub-001-1_func_ses-night_task-rest_run-01_acq-AP.json
        ├── sub-001-1_func_ses-night_task-rest_run-01_acq-PA.nii.gz
        └── sub-001-1_func_ses-night_task-rest_run-01_acq-PA.json
```

3.) Open a terminal navigate to _MRI-Study/scripts_

4.) Run 1st level analysis on subjects (i.e. ./NSSSAnalysisPipeline_Censor0.4_Hariri.sh 001-1 night 1)

```
sudo ./NSSSAnalysisPipeline_Censor0.4_Hariri.sh <sub_#-session_#> <night> <session_#> 
```

5.) Analysis will take ~3 hours per subject session depending on hardware.

6.) When all subjects are completed, run group-level analysis using the batch scripts
```
sudo ./batch_3dLME_hariri.sh
```

## Verasonics Vantage 64LE
1.) Navigate to NEUSleeP/Verasonics Vantage Script

2.) Refer to Verasonics Documentation for usage and use the matlab script for controlling NEUSLeeP for FUS (Set DelayParameter based on callibration curve for focal depth control)
```
MATLAB Terminal: activate -> VSX -> DARPA_NEUSLEEP_Study.m
```

## Others
Open and run directly.



