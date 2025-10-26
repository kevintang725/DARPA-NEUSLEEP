#!/bin/tcsh

# === Set directories ===
set base_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI"
set output_dir = "${base_dir}/3dLME_Results"
set summary_dir = "${base_dir}/3dLME_Summary"

if (! -d ${summary_dir}) mkdir -p ${summary_dir}

# === Define inputs ===
set lme_output = "${output_dir}/3dLME_Unified"

# === GLT Labels ===
set glt_list = ( \
    "FUS_vs_Sham" \
    "Anger_vs_Shapes" \
    "Happy_vs_Shapes" \
    "Neutral_vs_Shapes" \
    "Fear_vs_Shapes" \
    "SessionXAnger" \
    "SessionXHappy" \
    "SessionXNeutral" \
    "SessionXFear" \
    "SessionXShapes" )

set summary_file = "${summary_dir}/GLT_Summary.txt"
echo "GLT_Label	Mean_Beta	Significant_Voxel_Count" > ${summary_file}

# === Set threshold for significant voxels ===
set threshold = 0.5  # adjust based on your study

@ glt_index = 0

foreach glt (${glt_list})
    @ glt_index += 1

    echo "Processing ${glt}..."

    set glt_brick = "${lme_output}+tlrc[${glt_index}]"

    # Extract significant voxels (threshold applied)
    set mask_file = "${summary_dir}/${glt}_sigmask.nii.gz"
    3dcalc -a ${glt_brick} -expr "ispositive(a - ${threshold})" -prefix ${mask_file}

    # Count significant voxels
    set voxel_count = `3dBrickStat -count -non-zero ${mask_file}`

    if ("${voxel_count}" == "0") then
        echo "${glt}	0	0" >> ${summary_file}
        echo "No significant voxels for ${glt}, skipping mean calculation."
        continue
    endif

    # Calculate mean beta within significant voxels
    set mean_beta = `3dmaskave -mask ${mask_file} ${glt_brick}`

    echo "${glt}	${mean_beta}	${voxel_count}" >> ${summary_file}
end

echo "Summary saved to ${summary_file}"
