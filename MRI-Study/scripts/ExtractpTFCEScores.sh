#!/bin/tcsh

# === Set study and contrast ===

set rootdir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal"
set studydir = "${rootdir}/Resting/3dLME_Results"
set source_maskpath = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates"
set out_dir = "${studydir}/ROI_pTFCE"

set contrastmap = "${studydir}/pTFCE_Z_rsFCa_FUS_vs_Sham_basalganglia_Thresh_4.9_4.134628_NoSigEffects.nii.gz"

# === Create output directory if needed ===
if (! -d ${out_dir}) mkdir -p ${out_dir}
cd ${studydir}

# === Loop through each ROI mask ===
foreach file (${source_maskpath}/*.nii.gz)
    echo "🔍 Extracting voxel values from: $file"

    # Clean filename
    set prefix = `basename $file .nii.gz`

    # Output filename
    set outfile = "${out_dir}/VoxelValues_${prefix}.txt"

    # Extract all voxel values within mask
    #3dmaskdump -nozero -mask $file ${contrastmap} > ${outfile}
    3dmaskdump  -noijk -nozero -mask $file ${contrastmap} > ${outfile}
    chmod 775 ${outfile}
end

echo "✅ Done extracting all voxel values within ROIs."
