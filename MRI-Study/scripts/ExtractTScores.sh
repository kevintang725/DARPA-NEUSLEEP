#!/bin/csh
#
#set contrastmap = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI/3dLME_Results/3dLME_Unified+tlrc"
#set studydir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI/3dLME_Results/"

set contrastmap = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/Resting/3dLME_Results/3dLME_Unified+tlrc"
set studydir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/Resting/3dLME_Results/"

#set source_maskpath = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/"
#set out_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI/3dLME_Results/ROI"

set source_maskpath = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/"
set out_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/Resting/3dLME_Results/ROI"

cd $studydir
mkdir "ROI"

foreach file (${source_maskpath}/*.nii.gz)
    echo "Calculating Fischer Z Scores in Mask: $file"
    set prefix = `basename $file`
    set prefix = `remove_ext $prefix`

  
    # Calculate FUS Effect T-scores in Masks
    echo "Calculating Pre-FUS ROI"
    echo "3dmaskave -mask $file -sigma $contrastmap'[7]' >> ${out_dir}/FUS_Effect_${prefix}.txt"
    3dROIstats -mask $file -sigma $contrastmap >> ${out_dir}/FUS_Effect_${prefix}.txt

    chmod 775 ${out_dir}/FUS_Effect_${prefix}.txt

end

