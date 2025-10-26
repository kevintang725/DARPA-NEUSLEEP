#!/bin/csh
#
set Pre_fischerZmap = $1
set Post_fischerZmap = $2
set studydir = $3

set source_maskpath = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/"
set out_dir = "${studydir}/IndivAnal/Resting/FisherZMap_ROI"

foreach file (${source_maskpath}/*.nii.gz)
    echo "Calculating Fischer Z Scores in Mask: $file"
    set prefix = `basename $file`
    set prefix = `remove_ext $prefix`

  
    # Calculate Fisher Z scores in Masks
    echo "Calculating Pre-FUS ROI"
    echo "3dmaskave -mask $file -sigma $1 >> ${out_dir}/PreFUS_${prefix}.txt"
    3dmaskave -mask $file -sigma $1 >> ${out_dir}/PreFUS_${prefix}.txt

    chmod 775 ${out_dir}/PreFUS_${prefix}.txt

    echo "Calculating Post-FUS ROI"
    echo "3dmaskave -mask $file -sigma $2 >> ${out_dir}/PostFUS_${prefix}.txt"
    3dmaskave -mask $file -sigma $2 >> ${out_dir}/PostFUS_${prefix}.txt

    chmod 775 ${out_dir}/PostFUS_${prefix}.txt
end

