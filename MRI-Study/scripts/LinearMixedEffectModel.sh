#!/bin/csh
#
source ~/.cshrc

cd "/Volumes/Kevin-SSD/DARPA-REM-Sleep/Experiments/Clinical/StudyA_STN_Targeting_fMRI/STUDY_A_MRI/MVM_LME"

# === Set base directories ===
set root_dir = "/Volumes/Kevin-SSD/DARPA-REM-Sleep/Experiments/Clinical/StudyA_STN_Targeting_fMRI/STUDY_A_MRI"
set base_dir = "${root_dir}/IndivAnal/Resting"
set data_table_dir = "${base_dir}/3dLME_Input_Tables"
set output_dir = "${base_dir}/3dLME_Results"
set scripts_dir = "${root_dir}/scripts"

# === Run 3dLME ===
set lme_output = ${output_dir}/3dLME_Unified
set log_file = ${output_dir}/log_3dLME_Unified.txt

# Resample brain mask to example file
set resampled_mask = ${output_dir}/resampled_brain_mask.nii.gz

if (! -e ${resampled_mask}) then
    echo "Resampling brain mask..."
    3dresample -master ${example_input} -inset ${brain_mask_template} -prefix ${resampled_mask}
    sleep 2
    3drefit -space TLRC ${resampled_mask}
    if (! -e ${resampled_mask}) then
        echo "ERROR: Mask resampling failed. Exiting..."
        exit
    endif
endif

3dLME -prefix ${lme_output} \
    -resid ${lme_output}_resid \
    -jobs 4 \
    -model "Sex*Session" \
    -ranEff "~1" \
    -mask ${resampled_mask} \
    -SS_type 3 \
    -num_glt 5 \
    -gltLabel 1 "FUS_vs_Sham"               -gltCode 1 'Session : 1*FUS -1*Sham' \
    -gltLabel 2 "SessionXMale"              -gltCode 2 'Session : 1*FUS -1*Sham Sex : 1*Male' \
    -gltLabel 3 "SessionXFemale"            -gltCode 3 'Session : 1*FUS -1*Sham Sex : 1*Female' \
    -gltLabel 4 "MaleXFemale"               -gltCode 4 'Sex : 1*Male -1*Female' \
    -gltLabel 5 "SessionXMale-Female"       -gltCode 5 'Session : 1*FUS -1*Sham Sex : 1*Male -1*Female' \
    -dataTable @/Volumes/Kevin-SSD/DARPA-REM-Sleep/Experiments/Clinical/StudyA_STN_Targeting_fMRI/STUDY_A_MRI/MVM_LME/UnifiedDataTable.txt |& tee -a ${log_file}

echo "✅ 3dLME complete."