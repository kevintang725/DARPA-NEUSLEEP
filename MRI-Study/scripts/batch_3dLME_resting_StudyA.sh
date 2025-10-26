#!/bin/tcsh

# === Set base directories ===
set root_dir = "/Volumes/Kevin-SSD/DARPA-REM-Sleep/Experiments/Clinical/StudyA_STN_Targeting_fMRI/STUDY_A_MRI"
set base_dir = "${root_dir}/IndivAnal/Resting"
set data_table_dir = "${base_dir}/3dLME_Input_Tables"
set output_dir = "${base_dir}/3dLME_Results"
set scripts_dir = "${root_dir}/scripts"

if (! -d $data_table_dir) mkdir -p $data_table_dir
if (! -d $output_dir) mkdir -p $output_dir

# === Path to subject information CSV ===
set subject_info_csv = "/Volumes/Kevin-SSD/DARPA-REM-Sleep/Experiments/Clinical/StudyA_STN_Targeting_fMRI/STUDY_A_MRI/Subject_Information.txt"  # Ensure tab-delimited

# === Path to brain mask ===
set brain_mask_template = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/MNI_Masks/MNI152_T1_1mm_brain.nii.gz"

# === List of contrasts ===
set contrast_list = ( FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz )

# === Initialize unified data table ===
set unified_table = ${data_table_dir}/UnifiedDataTable.txt
echo "Subj	Sex	Session	InputFile" > ${unified_table}

# === Build unified data table ===
foreach contrast (${contrast_list})
    set contrast_name = `basename ${contrast} .nii.gz`
    echo "Processing files for ${contrast_name}..."

    # Search for contrast files in both PreFUS and PostFUS folders
    set all_files = (`find ${base_dir} -type f -name "*${contrast}" -path "*sub-WANG_NEUSLEEP_STUDYA_*_ses-NEUSLEEP_resting_*.results/*"`)

    foreach this_file (${all_files})
        set parent_dir = `dirname ${this_file}`
        set folder_name = `basename ${parent_dir}`

        # Extract subject ID (e.g., 017)
        set subj_id = `echo ${folder_name} | sed -nE 's/.*STUDYA_([0-9]{3})_.*/\1/p'`

        if ("${folder_name}" =~ *PreFUS*) then
            set session_label = "Sham"
        else if ("${folder_name}" =~ *PostFUS*) then
            set session_label = "FUS"
        else
            echo "⚠️ Warning: Cannot determine session from ${folder_name}"
            continue
        endif


        # Lookup sex from subject info file
        set sex = `awk -F'\t' -v id="${subj_id}" 'NR>1 && $1==id {print $2}' ${subject_info_csv}`

        if ("${sex}" == "") then
            echo "⚠️ Warning: Subject ID ${subj_id} not found in CSV for file ${this_file}"
            continue
        endif

        echo "${subj_id}	${sex}	${session_label}	${this_file}" >> ${unified_table}
    end
end

echo "✅ Unified data table created: ${unified_table}"

# === Run 3dLME ===
set lme_output = ${output_dir}/3dLME_Unified
set log_file = ${output_dir}/log_3dLME_Unified.txt

# Extract example input file to resample mask
set example_input = `awk 'NR==2 {print $4}' ${unified_table}`

if ("${example_input}" == "") then
    echo "ERROR: Unified data table appears empty. Exiting..."
    exit
endif

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

echo "Running 3dLME model..." | tee ${log_file}

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
    -dataTable `cat ${unified_table}` |& tee -a ${log_file}

echo "✅ 3dLME complete."

# Convert AFNI to NIFTI for pTFCE input
3dAFNItoNIFTI -prefix ${lme_output}.nii.gz ${lme_output}+tlrc
3dAFNItoNIFTI -prefix ${lme_output}_resid.nii.gz ${lme_output}_resid+tlrc

# === Run pTFCE for each ROI mask ===
set mask_dir = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/pTFCE"
set mask_list = (`ls ${mask_dir}/*.nii.gz`)
set suffix = "rsFCa"
set reversesuffix = "rsFCb"
set lme_nii = ${lme_output}.nii.gz
set lme_resid = ${lme_output}_resid.nii.gz
set subbrik_list = 4  # Modify to loop multiple sub-briks if needed

foreach ptfce_mask (${mask_list})
    set ptfce_desc = `basename ${ptfce_mask} .nii.gz | sed 's/_mask//'`

    echo "📌 Running pTFCE for mask: ${ptfce_desc}"

    foreach subbrik (${subbrik_list})
        set glt_label_raw = `3dinfo -verb ${lme_nii} | grep "#${subbrik}" | awk -F"'" '{print $2}'`
        set glt_label_clean = `echo ${glt_label_raw} | sed 's/ /_/g' | sed 's/[^a-zA-Z0-9_]//g'`

        echo "▶ Running pTFCE on sub-brik ${subbrik} (${glt_label_raw}) in ROI ${ptfce_desc}"

        ${scripts_dir}/RunptfceR_LME.sh \
            ${output_dir} \
            ${lme_nii} \
            ${lme_resid} \
            ${subbrik} \
            ${ptfce_mask} \
            ${ptfce_desc} \
            "${suffix}_${glt_label_clean}" \
            "${reversesuffix}_${glt_label_clean}"
    end
end
