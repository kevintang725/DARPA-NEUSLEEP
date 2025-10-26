#!/bin/csh
#

set studydir = "/Volumes/Kevin-SSD/MRI-Study"
set source_maskpath = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/"

# Loop through all Pre-FUS Fisher Z maps
foreach Pre_fischerZmap (`find ${studydir}/IndivAnal/Resting -type f -name "*_resting_PreFUS_errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz"`)

    echo "Processing file: ${Pre_fischerZmap}"

    # Determine output directory for this subject
    set subj_dir = `dirname ${Pre_fischerZmap}`
    set out_dir = ${studydir}/IndivAnal/Resting/FisherZMap_ROI
    if (! -d ${out_dir}) mkdir -p ${out_dir}

    # Loop through all masks
    foreach file (${source_maskpath}/*.nii.gz)
        echo "Calculating Fisher Z Scores in Mask: $file"
        set prefix = `basename $file`
        set prefix = `remove_ext $prefix`

        # Calculate Fisher Z scores in Masks
        echo "Calculating Resting-State ROI for ${prefix}"
        3dmaskave -mask $file -sigma ${Pre_fischerZmap} >> ${out_dir}/Resting_${prefix}.txt

        chmod 775 ${out_dir}/Resting_${prefix}.txt
    end

end
