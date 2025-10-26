#!/bin/tcsh

set subj = $1

# === Step 0: Setup working directory
cd /Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI/sub-${subj}_ses-night_hariri_run-01.results

# === Create base output directory
set base_output_dir = /Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI/Images
if (! -d $base_output_dir) mkdir $base_output_dir

# === Copy underlay if not already present
if (! -e MNI152_T1_1mm_brain.nii.gz) then
    cp /Volumes/Kevin-SSD/MRI-Study/Mask_Templates/MNI_Masks/MNI152_T1_1mm_brain.nii.gz .
endif

# === Static Inputs ===
set underlay = MNI152_T1_1mm_brain.nii.gz
set left_mask = /Volumes/Kevin-SSD/MRI-Study/Mask_Templates/Left_Amygdala_mask.nii.gz
set right_mask = /Volumes/Kevin-SSD/MRI-Study/Mask_Templates/Right_Amygdala_mask.nii.gz
set xyz_mm = "-21 -2 -18" #Amygdala Coordinates
set thresh_val = 0 # 

# === Create Bilateral Amygdala ROI mask ===
set roi_mask = Bilateral_Amygdala_mask_bin.nii.gz
set resampled_roi = Bilateral_Amygdala_mask_resampled.nii.gz

if ( -e $roi_mask ) rm -f $roi_mask
if ( -e $resampled_roi ) rm -f $resampled_roi

3dcalc -a ${left_mask} -b ${right_mask} \
       -expr 'step(step(a) + step(b))' \
       -prefix ${roi_mask}

3dresample -master ${underlay} \
           -inset ${roi_mask} \
           -prefix ${resampled_roi}

# === List of contrasts ===
set contrast_list = ( \
    Anger_Coef.nii.gz \
    Neutral_Coef.nii.gz \
    Happy_Coef.nii.gz \
    Fear_Coef.nii.gz \
    Shapes_Coef.nii.gz \
    AngervsHappy_Coef.nii.gz \
    AngervsNeutral_Coef.nii.gz \
    AngervsShapes_Coef.nii.gz \
    FearvsAnger_Coef.nii.gz \
    FearvsHappy_Coef.nii.gz \
    FearvsNeutral_Coef.nii.gz \
    FearvsShapes_Coef.nii.gz \
    HappyvsNeutral_Coef.nii.gz \
    HappyvsShapes_Coef.nii.gz \
    NeutralvsShapes_Coef.nii.gz \
    NegFacesvsHappy_Coef.nii.gz \
    NegFacesvsShapes_Coef.nii.gz \
    NegFacesvsNeutral_Coef.nii.gz \
    AllFacesvsShapes_Coef.nii.gz \
    AllEmotionvsShapes_Coef.nii.gz )

foreach raw_overlay (${contrast_list})

    # Get prefix from filename
    set prefix = `basename $raw_overlay .nii.gz`

    # Create output subfolder
    set output_dir = ${base_output_dir}/${prefix}
    if (! -d $output_dir) mkdir -p $output_dir

    # Define intermediate filenames
    set resampled_overlay = ${prefix}_resampled.nii.gz
    set brain_masked_overlay = ${prefix}_masked.nii.gz
    set roi_masked_overlay = ${prefix}_amygdala_masked.nii.gz
    set brain_out_image = ${output_dir}/sub-${subj}_${prefix}_brain.png
    set roi_out_image = ${output_dir}/sub-${subj}_${prefix}_amygdala.png
    set roi_out_image = ${output_dir}/sub-${subj}_${prefix}_amygdala_coronal.png
    set roi_out_image_transverse = ${output_dir}/sub-${subj}_${prefix}_amygdala_transverse.png

    # Clean up any old files
    foreach file ( $resampled_overlay $brain_masked_overlay $roi_masked_overlay $brain_out_image $roi_out_image )
        if ( -e $file ) then
            echo "Removing existing file: $file"
            rm -f $file
        endif
    end

    # Resample overlay
    3dresample -master ${underlay} \
               -inset ${raw_overlay} \
               -prefix ${resampled_overlay}

    # Mask overlay with whole brain
    3dcalc -a ${resampled_overlay} -b ${underlay} \
           -expr 'a*step(b)' \
           -datum float \
           -prefix ${brain_masked_overlay}

    # Mask overlay with amygdala ROI
    3dcalc -a ${resampled_overlay} -b ${resampled_roi} \
           -expr 'a*step(b)' \
           -datum float \
           -prefix ${roi_masked_overlay}

    # Get functional ranges
    set func_max = `3dBrickStat -max ${resampled_overlay}`
    #set func_max_amygdala = `3dBrickStat -max ${roi_masked_overlay}`
    set func_max_amygdala = 1

    # Save amydala-masked transverse image
    afni -no_detach \
         -com "SET_UNDERLAY A. ${underlay}" \
         -com "SET_OVERLAY A.${roi_masked_overlay}" \
         -com "SEE_OVERLAY A.+1" \
         -com "SET_THRESHNEW A.${thresh_val}" \
         -com "SET_FUNC_RANGE A. ${func_max_amygdala}" \
         -com "SET_PBAR_SIGN A. +" \
         -com "OPEN_WINDOW A.coronalimage mont=1x1:orient=coronal:zoom=4:func_range=${func_max_amygdala}:hide_ulay=no:hide_overlay=no" \
         -com "SET_DICOM_XYZ A. ${xyz_mm}" \
         -com "SET_CROSSHAIRS A.OFF" \
         -com "SAVE_PNG A.coronalimage ${roi_out_image} dpi=1200" \
         -com "QUIT" &

    sleep 5        

    # Save amygdala-masked coronal image
    afni -no_detach \
         -com "SET_UNDERLAY A. ${underlay}" \
         -com "SET_OVERLAY A.${roi_masked_overlay}" \
         -com "SEE_OVERLAY A.+1" \
         -com "SET_THRESHNEW A.${thresh_val}" \
         -com "SET_FUNC_RANGE A. ${func_max_amygdala}" \
         -com "SET_PBAR_SIGN A. +" \
         -com "OPEN_WINDOW A.coronalimage mont=1x1:orient=coronal:zoom=4:func_range=${func_max_amygdala}:hide_ulay=no:hide_overlay=no" \
         -com "SET_DICOM_XYZ A. ${xyz_mm}" \
         -com "SET_CROSSHAIRS A.OFF" \
         -com "SAVE_PNG A.coronalimage ${roi_out_image} dpi=1200" \
         -com "QUIT" &

    sleep 5

end
