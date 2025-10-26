#!/bin/tcsh

# === Set base directories ===
set root_dir = "/Volumes/Kevin-SSD/MRI-Study/"
set base_dir = "${root_dir}/IndivAnal/Resting"
set data_table_dir = "${base_dir}/3dLME_Input_Tables"
set output_dir = "${base_dir}/3dLME_Results"
set scripts_dir = "${root_dir}/scripts"

if (! -d $data_table_dir) mkdir -p $data_table_dir
if (! -d $output_dir) mkdir -p $output_dir

# === Path to brain mask ===
set brain_mask_template = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/MNI_Masks/MNI152_T1_1mm_brain.nii.gz"

# === List of contrasts ===
set contrast_list = ( \
    Anger_Coef.nii.gz \
    Neutral_Coef.nii.gz \
    Happy_Coef.nii.gz \
    Fear_Coef.nii.gz \
    Shapes_Coef.nii.gz )

# === Initialize unified data table ===
set unified_table = ${data_table_dir}/UnifiedDataTable.txt
echo "Subj	Session	Condition	InputFile" > ${unified_table}

# === Build unified data table ===
foreach contrast (${contrast_list})

    set contrast_name = `basename ${contrast} .nii.gz`

    echo "Processing files for ${contrast_name}..."

    # Find all -1 (Sham) files (only one level down)
    set sham_files = (`find ${base_dir} -mindepth 2 -maxdepth 2 -type f -name ${contrast} | grep '\-1'`)
    foreach sham_file (${sham_files})
        set subj_id = `echo ${sham_file} | sed -nE 's/.*sub-([0-9]+)-1.*/\1/p'`
        echo "${subj_id}	Sham	${contrast_name}	${sham_file}" >> ${unified_table}
    end

    # Find all -2 (FUS) files (only one level down)
    set fus_files = (`find ${base_dir} -mindepth 2 -maxdepth 2 -type f -name ${contrast} | grep '\-2'`)
    foreach fus_file (${fus_files})
        set subj_id = `echo ${fus_file} | sed -nE 's/.*sub-([0-9]+)-2.*/\1/p'`
        echo "${subj_id}	FUS	${contrast_name}	${fus_file}" >> ${unified_table}
    end

end


echo "✅ Unified data table created: ${unified_table}"

# === Run 3dLME ===
set lme_output = ${output_dir}/3dLME_Unified
set log_file = ${output_dir}/log_3dLME_Unified.txt

# === Resample mask to match grid of first input file ===
set example_input = `awk 'NR==2 {print $4}' ${unified_table}`

set resampled_mask = ${output_dir}/resampled_brain_mask.nii.gz

if (! -e ${resampled_mask}) then
    echo "Resampling brain mask..."
    3dresample -master ${example_input} -inset ${brain_mask_template} -prefix ${resampled_mask}
    sleep 2
    3drefit -space TLRC ${resampled_mask}

    if (! -e ${resampled_mask}) then
        echo "ERROR: Resampled mask was not created correctly. Exiting..."
        exit
    endif

    echo "Resampled mask saved to ${resampled_mask}"
else
    echo "Resampled mask already exists. Skipping resampling."
endif

# === Run 3dLME model with Session and Condition ===
echo "Running 3dLME with unified table..." | tee ${log_file}

3dLME -prefix ${lme_output} \
    -resid ${lme_output}_resid \
    -jobs 4 \
    -model "Sex*Session" \
    -ranEff "~1" \
    -mask ${resampled_mask} \
    -SS_type 3 \
    -num_glt 5 \
    -gltLabel 1 "FUS_vs_Sham"                 -gltCode 1 'Session : 1*FUS -1*Sham' \
    -gltLabel 2 "SessionXMale"              -gltCode 2 'Session : 1*FUS -1*Sham Sex : 1*Male' \
    -gltLabel 3 "SessionXFemale"            -gltCode 3 'Session : 1*FUS -1*Sham Sex : 1*Female' \
    -gltLabel 4 "MaleXFemale"              -gltCode 4 'Sex : 1*Male -1*Female' \
    -gltLabel 5 "SessionXMale-Female"   -gltCode 5 'Session : 1*FUS -1*Sham Sex : 1*Male -1*Female' \
    -dataTable `cat ${unified_table}` |& tee -a ${log_file}

echo "✅ 3dLME complete."

echo "Converting Output to NIFTI for pTFCE use later..."
3dAFNItoNIFTI -prefix ${lme_output}.nii.gz ${lme_output}+tlrc

echo "Converting Residuals to NIFTI for pTFCE use later..."
3dAFNItoNIFTI -prefix ${lme_output}_resid.nii.gz ${lme_output}_resid+tlrc

# === Loop through all masks in the Mask_Templates directory ===
set mask_dir = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/pTFCE"
set mask_list = (`ls ${mask_dir}/*.nii.gz`)
set suffix = "HARIRIa"
set reversesuffix = "HARIRIb"
set lme_nii = ${lme_output}.nii.gz
set lme_resid = ${lme_output}_resid.nii.gz
#set subbrik_list = 4
set subbrik_list = (4 14 16 18 20 22)

foreach ptfce_mask (${mask_list})
    set ptfce_desc = `basename ${ptfce_mask} .nii.gz | sed 's/_mask//'`

    echo "📌 Running pTFCE for mask: ${ptfce_desc}"

    foreach subbrik (${subbrik_list})
        # Extract GLT label (e.g., 'FUS_vs_Sham Z') from header
        set glt_label_raw = `3dinfo -verb ${lme_nii} | grep "#${subbrik}" | awk -F"'" '{print $2}'`

        # Replace spaces and symbols for filename-safe suffix
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
