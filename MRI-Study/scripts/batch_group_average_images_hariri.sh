#!/bin/tcsh

# === Set base directory where the results are stored ===
set base_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI"
set base_output_dir = ${base_dir}/Group_Averages
if (! -d $base_output_dir) mkdir -p $base_output_dir

# === Static Inputs ===
set underlay = /Volumes/Kevin-SSD/MRI-Study/Mask_Templates/MNI_Masks/MNI152_T1_1mm_brain.nii.gz
set left_mask = /Volumes/Kevin-SSD/MRI-Study/Mask_Templates/Left_Amygdala_mask.nii.gz
set right_mask = /Volumes/Kevin-SSD/MRI-Study/Mask_Templates/Right_Amygdala_mask.nii.gz
set xyz_mm = "-15 -2 -16"
set thresh_val = 0

# === Create bilateral ROI mask ===
set roi_mask = ${base_output_dir}/Bilateral_Amygdala_mask_bin.nii.gz
set resampled_roi = ${base_output_dir}/Bilateral_Amygdala_mask_resampled.nii.gz

if ( -e $roi_mask ) rm -f $roi_mask
if ( -e $resampled_roi ) rm -f $resampled_roi

3dcalc -a ${left_mask} -b ${right_mask} -expr 'step(step(a) + step(b))' -prefix ${roi_mask}

# Find a sample contrast image to use as the resampling master
set example_contrast = `find $base_dir -type f -name AngervsHappy_Coef.nii.gz | grep -E '\-1|\-2' | head -n 1`
if ( "${example_contrast}" == "" ) then
    echo "ERROR: Could not find an example contrast image to use for resampling."
    exit 1
endif

3dresample -master ${example_contrast} -inset ${roi_mask} -prefix ${resampled_roi}

# === List of contrasts ===
set contrast_list = ( \
    Anger_Coef.nii.gz \
    Neutral_Coef.nii.gz \
    Happy_Coef.nii.gz \
    Fear_Coef.nii.gz \
    Shapes_Coef.nii.gz \
    #AngervsHappy_Coef.nii.gz \
    #AngervsNeutral_Coef.nii.gz \
    #AngervsShapes_Coef.nii.gz \
    #FearvsAnger_Coef.nii.gz \
    #FearvsHappy_Coef.nii.gz \
    #FearvsNeutral_Coef.nii.gz \
    #FearvsShapes_Coef.nii.gz \
    #HappyvsNeutral_Coef.nii.gz \
    #HappyvsShapes_Coef.nii.gz \
    #NeutralvsShapes_Coef.nii.gz \
    #NegFacesvsHappy_Coef.nii.gz \
    #NegFacesvsShapes_Coef.nii.gz \
    #NegFacesvsNeutral_Coef.nii.gz \
    #AllFacesvsShapes_Coef.nii.gz \
    #AllEmotionvsShapes_Coef.nii.gz\
     )

# === Average each contrast across subjects with -1 (Sham) and -2 (FUS) ===
foreach contrast (${contrast_list})
    echo "Processing contrast: $contrast"

    set contrast_name = `basename ${contrast} .nii.gz`
    set contrast_dir = ${base_output_dir}/${contrast_name}
    if (! -d ${contrast_dir}) mkdir -p ${contrast_dir}

    # Find files for -1 (Sham) and -2 (FUS)
    set sham_contrasts = (`find $base_dir -type f -name $contrast | grep '\-1'`)
    set fus_contrasts = (`find $base_dir -type f -name $contrast | grep '\-2'`)

    # ============================
    # === Process Sham Group ====
    if ( $#sham_contrasts > 0 ) then
        set sham_dir = ${contrast_dir}/Sham
        if (! -d $sham_dir) mkdir -p $sham_dir

        set group_avg_sham = ${sham_dir}/Group_Sham_${contrast}
        3dMean -prefix ${group_avg_sham} $sham_contrasts

        set amygdala_masked_sham = ${sham_dir}/Group_Sham_${contrast_name}_amygdala_masked.nii.gz
        3dcalc -a ${group_avg_sham} -b ${resampled_roi} -expr 'a*step(b)' -datum float -prefix ${amygdala_masked_sham}

        cd ${sham_dir}
        set underlay_file = `basename ${underlay}`
        if (! -e ${underlay_file}) then
            cp ${underlay} ${underlay_file}
        endif

        set overlay_file = `basename ${amygdala_masked_sham}`
        #set func_max = `3dBrickStat -max ${overlay_file}`
        set func_max = 1

        set coronal_out = Group_Sham_${contrast_name}_amygdala_coronal.png
        set transverse_out = Group_Sham_${contrast_name}_amygdala_transverse.png

        # Coronal view for Sham
        afni -no_detach \
            -com "SET_UNDERLAY A. ${underlay_file}" \
            -com "SET_OVERLAY A.${overlay_file}" \
            -com "SEE_OVERLAY A.+1" \
            -com "SET_THRESHNEW A.${thresh_val}" \
            -com "SET_FUNC_RANGE A. ${func_max}" \
            -com "SET_PBAR_SIGN A. +" \
            -com "OPEN_WINDOW A.coronalimage mont=1x1:orient=coronal:zoom=4:func_range=${func_max}:hide_ulay=no:hide_overlay=no" \
            -com "SET_DICOM_XYZ A. ${xyz_mm}" \
            -com "SET_CROSSHAIRS A.OFF" \
            -com "SAVE_PNG A.coronalimage ${coronal_out} dpi=1200" \
            -com "QUIT" &

        sleep 5

        # Transverse view for Sham
        afni -no_detach \
            -com "SET_UNDERLAY A. ${underlay_file}" \
            -com "SET_OVERLAY A.${overlay_file}" \
            -com "SEE_OVERLAY A.+1" \
            -com "SET_THRESHNEW A.${thresh_val}" \
            -com "SET_FUNC_RANGE A. ${func_max}" \
            -com "SET_PBAR_SIGN A. +" \
            -com "OPEN_WINDOW A.axialimage mont=1x1:orient=axial:zoom=4:func_range=${func_max}:hide_ulay=no:hide_overlay=no" \
            -com "SET_DICOM_XYZ A. ${xyz_mm}" \
            -com "SET_CROSSHAIRS A.OFF" \
            -com "SAVE_PNG A.axialimage ${transverse_out} dpi=1200" \
            -com "QUIT" &

        sleep 5
    else
        echo "No Sham files found for $contrast"
    endif

    # ==========================
    # === Process FUS Group ====
    if ( $#fus_contrasts > 0 ) then
        set fus_dir = ${contrast_dir}/FUS
        if (! -d $fus_dir) mkdir -p $fus_dir

        set group_avg_fus = ${fus_dir}/Group_FUS_${contrast}
        3dMean -prefix ${group_avg_fus} $fus_contrasts

        set amygdala_masked_fus = ${fus_dir}/Group_FUS_${contrast_name}_amygdala_masked.nii.gz
        3dcalc -a ${group_avg_fus} -b ${resampled_roi} -expr 'a*step(b)' -datum float -prefix ${amygdala_masked_fus}

        cd ${fus_dir}
        set underlay_file = `basename ${underlay}`
        if (! -e ${underlay_file}) then
            cp ${underlay} ${underlay_file}
        endif

        set overlay_file = `basename ${amygdala_masked_fus}`
        set func_max = `3dBrickStat -max ${overlay_file}`
        #set func_max = 1

        set coronal_out = Group_FUS_${contrast_name}_amygdala_coronal.png
        set transverse_out = Group_FUS_${contrast_name}_amygdala_transverse.png

        # Coronal view for FUS
        afni -no_detach \
            -com "SET_UNDERLAY A. ${underlay_file}" \
            -com "SET_OVERLAY A.${overlay_file}" \
            -com "SEE_OVERLAY A.+1" \
            -com "SET_THRESHNEW A.${thresh_val}" \
            -com "SET_FUNC_RANGE A. ${func_max}" \
            -com "SET_PBAR_SIGN A. +" \
            -com "OPEN_WINDOW A.coronalimage mont=1x1:orient=coronal:zoom=4:func_range=${func_max}:hide_ulay=no:hide_overlay=no" \
            -com "SET_DICOM_XYZ A. ${xyz_mm}" \
            -com "SET_CROSSHAIRS A.OFF" \
            -com "SAVE_PNG A.coronalimage ${coronal_out} dpi=1200" \
            -com "QUIT" &

        sleep 5

        # Transverse view for FUS
        afni -no_detach \
            -com "SET_UNDERLAY A. ${underlay_file}" \
            -com "SET_OVERLAY A.${overlay_file}" \
            -com "SEE_OVERLAY A.+1" \
            -com "SET_THRESHNEW A.${thresh_val}" \
            -com "SET_FUNC_RANGE A. ${func_max}" \
            -com "SET_PBAR_SIGN A. +" \
            -com "OPEN_WINDOW A.axialimage mont=1x1:orient=axial:zoom=4:func_range=${func_max}:hide_ulay=no:hide_overlay=no" \
            -com "SET_DICOM_XYZ A. ${xyz_mm}" \
            -com "SET_CROSSHAIRS A.OFF" \
            -com "SAVE_PNG A.axialimage ${transverse_out} dpi=1200" \
            -com "QUIT" &

        sleep 5
    else
        echo "No FUS files found for $contrast"
    endif

end
