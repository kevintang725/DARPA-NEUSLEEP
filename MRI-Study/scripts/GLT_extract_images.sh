#!/bin/tcsh

# === Set directories ===
set base_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI"
set output_dir = "${base_dir}/3dLME_Images"
if (! -d ${output_dir}) mkdir -p ${output_dir}

# === Static Inputs ===
set underlay_path = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/MNI_Masks/MNI152_T1_1mm_brain.nii.gz"
set xyz_mm = "-21 -2 -18"
set lme_output = "${base_dir}/3dLME_Results/3dLME_Unified"

# === GLT contrast labels ===
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

# === Prepare working directory ===
cd ${output_dir}

# === Copy underlay locally if not present ===
if (! -e MNI152_T1_1mm_brain+tlrc.HEAD) then
    echo "Copying underlay to working directory..."
    3dcopy ${underlay_path} MNI152_T1_1mm_brain
endif

@ glt_index = 4

foreach glt (${glt_list})
    @ glt_index += 1
    @ index = ${glt_index} - 1

    echo "Processing ${glt}..."

    # Prepare overlay: Convert to local BRIK/HEAD if not already present
    set overlay_full = "${lme_output}+tlrc[${index}]"
    set overlay_copy = "${glt}"

    if (! -e ${overlay_copy}+tlrc.HEAD) then
        echo "Copying GLT sub-brick to local file..."
        3dbucket -prefix ${overlay_copy} ${overlay_full}
    else
        echo "Overlay already copied for ${glt}."
    endif

    set func_max = `3dBrickStat -max ${overlay_copy}+tlrc`
    if ("${func_max}" == "0") then
        echo "WARNING: ${glt} has max of 0 — skipping image generation."
        continue
    endif

    set thresh_val = 0.0001

    set coronal_out = "${output_dir}/${glt}_coronal.png"
    set transverse_out = "${output_dir}/${glt}_transverse.png"

    foreach file ( ${coronal_out} ${transverse_out} )
        if ( -e $file ) then
            echo "Removing existing file: $file"
            rm -f $file
        endif
    end

    # Save coronal image
    afni -no_detach \
        -com "SET_UNDERLAY A. MNI152_T1_1mm_brain" \
        -com "SET_OVERLAY A. ${overlay_copy}" \
        -com "SEE_OVERLAY A.+" \
        -com "SET_THRESHNEW A. ${thresh_val}" \
        -com "SET_FUNC_RANGE A. ${func_max}" \
        -com "SET_PBAR_SIGN A. +" \
        -com "OPEN_WINDOW A.coronalimage mont=1x1:orient=coronal:zoom=4:func_range=${func_max}:hide_ulay=no:hide_overlay=no" \
        -com "SET_DICOM_XYZ A. ${xyz_mm}" \
        -com "SET_CROSSHAIRS A.OFF" \
        -com "SAVE_PNG A.coronalimage ${coronal_out} dpi=1200" \
        -com "QUIT" &

    sleep 5

    # Save transverse image
    afni -no_detach \
        -com "SET_UNDERLAY A. MNI152_T1_1mm_brain" \
        -com "SET_OVERLAY A. ${overlay_copy}" \
        -com "SEE_OVERLAY A.+" \
        -com "SET_THRESHNEW A. ${thresh_val}" \
        -com "SET_FUNC_RANGE A. ${func_max}" \
        -com "SET_PBAR_SIGN A. +" \
        -com "OPEN_WINDOW A.axialimage mont=1x1:orient=axial:zoom=4:func_range=${func_max}:hide_ulay=no:hide_overlay=no" \
        -com "SET_DICOM_XYZ A. ${xyz_mm}" \
        -com "SET_CROSSHAIRS A.OFF" \
        -com "SAVE_PNG A.axialimage ${transverse_out} dpi=1200" \
        -com "QUIT" &

    sleep 5

end

echo "✅ Image generation complete for all GLT conditions."
