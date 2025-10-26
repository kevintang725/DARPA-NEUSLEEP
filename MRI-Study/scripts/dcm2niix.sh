#!/bin/tcsh

# Set root and output directories
set root_dir = "/Volumes/Kevin-SSD/MRI-Study/STUDYB-MRI-SCANS"
set output_root = "/Volumes/Kevin-SSD/MRI-Study/STUDYB-MRI-SCANS"

# Loop through each subject folder
foreach sub_dir (`ls -d ${root_dir}/*`)
    set sub_name = `basename ${sub_dir}`
    set dicom_dir = "${sub_dir}"
    set output_dir = "${output_root}/${sub_name}"

    # Ensure output directory exists
    if (! -d ${output_dir}) then
        mkdir -p ${output_dir}
    endif

    # === List of required files ===
    set files = ( \
        "${output_dir}/sub-${sub_name}_anat-ses-night_T1w_acq-0.8mmIso.json" \
        "${output_dir}/sub-${sub_name}_anat-ses-night_T1w_acq-0.8mmIso.nii.gz" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-hariri_run-01_acq-AP.nii.gz" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-hariri_run-01_acq-AP.json" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-hariri_run-01_acq-PA_distmap.json" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-hariri_run-01_acq-PA_distmap.nii.gz" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-rest_run-01_acq-AP.json" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-rest_run-01_acq-AP.nii.gz" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-rest_run-01_acq-PA_distmap.nii.gz" \
        "${output_dir}/sub-${sub_name}_func_ses-night_task-rest_run-01_acq-PA_distmap.json" \
    )

    # === Check if all files exist ===
    set all_exist = 1
    foreach f ($files)
        if (! -e $f) then
            set all_exist = 0
            break
        endif
    end

    if ($all_exist) then
        echo "Skipping ${sub_name}: All required NIfTI/JSON files exist."
        continue
    endif

    echo "Converting ${sub_name}..."

    # Run dcm2niix conversion
    dcm2niix -z y -o ${output_dir} -f "sub-${sub_name}_%p" ${dicom_dir}
end
