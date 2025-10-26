#!/bin/tcsh

# === Set base directories ===
set base_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/Resting"
set data_table_dir = "${base_dir}/3dMVM_Input_Tables"
set output_dir = "${base_dir}/3dMVM_Results"
set brain_mask = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/MNI_Masks/MNI152_T1_1mm_brain.nii.gz"

if (! -d $data_table_dir) mkdir -p $data_table_dir
if (! -d $output_dir) mkdir -p $output_dir

# === Path to subject information CSV ===
set subject_info_csv = "/Volumes/Kevin-SSD/MRI-Study/Subject_Information.txt"

# === Initialize unified data table ===
set unified_table = ${data_table_dir}/UnifiedDataTable.txt
echo "Subj	Sex	Session	InputFile" > ${unified_table}

# === Find statistical maps ===
echo "Searching for Fisher Z maps..."
set all_files = (`find ${base_dir} -type f -name "*errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz" | grep -v '/\._'`)

set fus_input = ""
set sham_input = ""

foreach this_file (${all_files})
    # Extract subject-session string
    set parent_dir = `dirname ${this_file} | xargs basename`
    set subj_sess = `echo ${parent_dir} | sed -nE 's/^sub-([0-9]{3}-[0-9])_ses-.*/\1/p'`

    set subj_id = `echo ${subj_sess} | sed -nE 's/([0-9]{3})-[0-9]/\1/p'`
    set session = `echo ${subj_sess} | sed -nE 's/[0-9]{3}-(1|2)/\1/p'`

    if ( ${session} == 1 ) then
        set session_label = "Sham"
        set sham_input = ( ${sham_input} "${subj_id} ${this_file}" )
    else if ( ${session} == 2 ) then
        set session_label = "FUS"
        set fus_input = ( ${fus_input} "${subj_id} ${this_file}" )
    else
        echo "⚠️  Warning: Unknown session for file ${this_file}"
        continue
    endif

    # Lookup sex from CSV
    set sex = `awk -F'\t' -v id="${subj_id}" 'NR>1 && $1==id {print $2}' ${subject_info_csv}`

    if ("${sex}" == "") then
        echo "⚠️  Warning: Subject ID ${subj_id} not found in CSV for file ${this_file}"
        continue
    endif

    # Write to unified table
    echo "${subj_id}	${sex}	${session_label}	${this_file}" >> ${unified_table}
end

echo "✅ Unified data table created: ${unified_table}"

# === Resample brain mask ===
set example_input = `awk 'NR==2 {print $4}' ${unified_table}`
if ("${example_input}" == "") then
    echo "ERROR: Example input file is missing. Unified table might be empty. Exiting..."
    exit
endif

set resampled_mask = ${output_dir}/resampled_brain_mask.nii.gz
if (! -e ${resampled_mask}) then
    echo "Resampling brain mask..."
    3dresample -master ${example_input} -inset ${brain_mask} -prefix ${resampled_mask}
    sleep 1
    3drefit -space TLRC ${resampled_mask}
endif

# === Run 3dMVM (Skip if exists) ===
set log_file = ${output_dir}/log_3dMVM_Unified.txt

if (-e ${output_dir}/wholebrain_MVM+tlrc.HEAD) then
    echo "✅ 3dMVM output already exists. Skipping 3dMVM step."
else
    echo "Running 3dMVM with unified table..." | tee ${log_file}

    3dMVM -prefix ${output_dir}/wholebrain_MVM \
          -jobs 4 \
          -mask ${resampled_mask} \
          -bsVars "Sex" \
          -wsVars "Session" \
          -num_glt 1 \
          -gltLabel 1 'FUS_vs_Sham' -gltCode 1 'Session : 1*FUS -1*Sham' \
          -dataTable @${unified_table} |& tee -a ${log_file}
endif

# === Run 3dttest++ with Clustsim ===
#echo "Running 3dttest++ with Clustsim..."

#cd ${output_dir}

#3dttest++ -prefix FUS_vs_Sham_ttest \
#          -mask ${resampled_mask} \
#          -setA FUS ${fus_input} \
#          -setB Sham ${sham_input} \
#          -Clustsim

#if ($status != 0) then
#    echo "❌ 3dttest++ failed. Exiting..."
#    exit 1
#endif

#cd -

#echo "✅ 3dttest++ completed successfully. Check ${output_dir}/FUS_vs_Sham_ttest.1D for cluster simulation results."

