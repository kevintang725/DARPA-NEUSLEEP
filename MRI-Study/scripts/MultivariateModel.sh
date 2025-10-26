#!/bin/csh
#
source ~/.cshrc

cd "/Volumes/Kevin-SSD/DARPA-REM-Sleep/Experiments/Clinical/StudyA_STN_Targeting_fMRI/STUDY_A_MRI/MVM_LME"

3dMVM -prefix MVM_results -jobs 4   \
         -resid 3dLME_Unified_results \
         -bsVars 'Group+Sex'              \
         -wsVars 'Condition'  \
         -qVars 'Age' \
         -num_glt 3               \
         -gltLabel 1 FUSEffect -gltCode 1 'Condition: 1*PostFUS -1*PreFUS' \
         -gltLabel 2 FUS_vs_Age -gltCode 2 'Condition: 1*PostFUS -1*PreFUS Group: 1*Young -1*Old' \
         -gltLabel 3 FUS_vs_Sex -gltCode 3 'Condition: 1*PostFUS -1*PreFUS Sex: 1*M -1*F' \
         -dataTable @MultivariateModel_dataTable.txt