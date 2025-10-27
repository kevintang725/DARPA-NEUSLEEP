# Wearable Focused Ultrasound Deep Brain Stimulation and Electrophysiological Recording Patch for REM Sleep Enhancement
## Author Information
Kai Wing Kevin Tang1,†, Benjamin Baird2,†, William D. Moscoso-Barrera1,†, Mengxia Yu1,†, Mengmeng Yao1, Jinmo Jeong1, Ilya Pyatnitskiy1, Anakaren Romero Lozano1, Jiachen Wang1, Ju-Chun Hsieh1, Tony Chae1, Daniel Song1, Julieta Garcia1, Rithvik Mittapalli1, Adam Bush1, Wynn Legon3, Vincent Mysliwiec4,*, Gregory A. Fonzo5,*, Huiliang Wang1,* 

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
The rise in sleep disease affecting the general population globally in the past decade has been detrimental to individually and socioeconomically. As of now, approaches often are temporary through medication, permanently using invasive implants with surgical complications or neuromodulation therapy. However, non-invasive, state-dependent neuromodulation during sleep is technically challenging, especially with the lack of flexibility, comfortability and robustness for sleep conditions. Here, we introduce a Non-invasive Electrophysiological Recording and Ultrasound Neuromodulation Sleep Patch (NEUSLeeP) in delivering focused ultrasound stimulation to the subthalamic nucleus (STN) overnight with simultaneous stable polysomnography recording. Our sleep patch integrates a custom eight-channel concentric ring transducer array with real-time electroencephalography (EEG), electrooculography (EOG), electromyography (EMG) recording, and individualized line-of-sight targeting to sonicate deep brain areas while preserving mobility. Our platform operated safely and comfortably across the two-night’s sleep study. Stimulation of the left STN was delivered every 90 minutes throughout the night and was associated with a 4.6% increase in REM (Rapid Eye Movement) sleep duration and a 43 minutes reduction in REM sleep latency compared to a sham night in a study of 26 subjects. Blood Oxygen Level Dependent (BOLD) signal attenuation in functional Magnetic Resonance Imaging (fMRI) was localized primarily to a left ipsilateral basal-ganglia-midbrain-temporal circuit, consistent with selective network modulation rather than global arousal changes. Overall, NEUSLeeP demonstrates feasibility by (i) a light weight and wearable ultrasound neuromodulation and sleep recording during natural sleep; (ii) establishing a potential mechanism relating targeted ultrasound stimulation of STN/sleep networks to REM enhancement.

## Competing Interest Statement

The authors K.W.K.T., M.M.Y., J.J. and H.W. declare the following competing financial interest(s): A patent application relating to this work has been filed. The remaining authors declare no competing interests.

## FUNDER INFORMATION DECLARED

Defense Advanced Research Projects Agency (DARPA) (REM-REST) grant

## Repository Description
1.) Code used for MRI, EEG, and materials analysis. 
2.) Scripts for Verasonics Vantage 64LE to control NEUSLeeP 
3.) MATLAB scripts for 3-axis motor system for acoustic field characterizations.
4.) MATLAB scripts for simulation.
5.) Details on design and parameters of NEUSLeeP

### System Requirements
### Operating System
Windows 10 or 11, Mac OS Monterey 12 or above.

### Software Dependencies
1.) Anaconda Environment

2.) Python 3.8.3

3.) AFNI 24.3.06

4.) FSL 6.0.7.15

5.) MATLAB 2024b

6.) eeglab

### Additional Hardwares
1.) Verasonics Vantage 64LE

2.) Arduino Uno

3.) 3-axis system controlled by Arduino Mega

4.) Oscilloscope with known USB address

## Installation Guide

### Instructions
## MRI Analysis 
1.) Open a terminal and navigate into _MRI-Study_ and create a folder for each subject with the following subdirectory structure
.
├── sub-001-1
│   └── ses-night
│       ├── anat
│       └── func
├── sub-001-2
│   └── ses-night
│       ├── anat
│       └── func


2.) Place your anatomical and functional scans to the corresponding _anat_ and _func_ folders
.
├── sub-001-1
│   └── ses-night
│       ├── anat
│           ├── sub-001-1_anat-ses-night_T1w_acq-0.8mmIso.json
│           └── sub-001-1_anat-ses-night_T1w_acq-0.8mmIso.nii.gz
│       └── func
│           ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-AP.nii.gz
│           ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-AP.json
│           ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-PA.nii.gz
│           ├── sub-001-1_func_ses-night_task-hariri_run-01_acq-PA.json
│           ├── sub-001-1_func_ses-night_task-rest_run-01_acq-AP.nii.gz
│           ├── sub-001-1_func_ses-night_task-rest_run-01_acq-AP.json
│           ├── sub-001-1_func_ses-night_task-rest_run-01_acq-PA.nii.gz
│           └── sub-001-1_func_ses-night_task-rest_run-01_acq-PA.json

3.) Open a terminal navigate to _MRI-Study/scripts_

4.) Run 1st level analysis on subjects _./NSSSAnalysisPipeline_Censor0.4_Hariri.sh <sub_#-session_#> <night> <session_#>_ (i.e. _./NSSSAnalysisPipeline_Censor0.4_Hariri.sh 001-1 night 1_)

5.) Analysis will take ~3 hours per subject session depending on hardware.

6.) When all subjects are completed, run group-level analysis using the _batch__ scripts (i.e. _batch_3dLME_hariri.sh_)

## Verasonics Vantage 64LE
1.) Navigate to NEUSleeP/Verasonics Vantage Script

2.) Refer to Verasonics Documentation for usage and use _DARPA_NEUSLEEP_Study.m_

## Others
Open and run directly.



