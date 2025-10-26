#!/bin/csh
#
source ~/.cshrc

set source_maskpath = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/Bilateral_Masks"
set out_dir = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates"

mkdir ${out_dir}/Unilateral_Masks

foreach file (${source_maskpath}/*.nii.gz)
    echo "Creating Masks: $file"
    set prefix = `basename $file`
    set prefix = `remove_ext $prefix`
    # Create Left Mask
    3dcalc -a $file -expr 'step(a)*step(x)' -prefix "${out_dir}/Unilateral_Masks/Left_${prefix}_mask.nii.gz"
    3dresample -master "/Users/kevintang/Desktop/DARPA-REMSLEEP/Mask_Templates/Left_STN_mask.nii.gz" \
           -input ${out_dir}/Unilateral_Masks/Left_${prefix}_mask.nii.gz \
           -prefix "${out_dir}/Left_${prefix}_mask.nii.gz"
    # Create Right Mask
    3dcalc -a $file -expr 'step(a)*step(-x)' -prefix "${out_dir}/Unilateral_Masks/Right_${prefix}_mask.nii.gz"
    3dresample -master "/Users/kevintang/Desktop/DARPA-REMSLEEP/Mask_Templates/Left_STN_mask.nii.gz" \
           -input ${out_dir}/Unilateral_Masks/Right_${prefix}_mask.nii.gz \
           -prefix "${out_dir}/Right_${prefix}_mask.nii.gz"
end
