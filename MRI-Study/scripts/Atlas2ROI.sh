#!/bin/tcsh

set atlas = "/Volumes/Kevin-SSD/MRI-Study/Mask_Repositories/CIT168_Atlas/CIT168_T1w_MNI.nii"
set lut   = "/Volumes/Kevin-SSD/MRI-Study/Mask_Repositories/CIT168_Atlas/CIT168_Subcortical_LUT.txt"
set outdir = "/Volumes/Kevin-SSD/MRI-Study/Mask_Repositories/CIT168_Atlas/ROI"
if (! -d $outdir) mkdir -p $outdir

foreach line (`grep -v "^0" $lut`)
    set val  = `echo $line | awk '{print $1}'`
    set name = `echo $line | cut -f2- -d' ' | tr ' ' '_' | tr -cd '[:alnum:]_-'`

    # Count voxels for this label
    set count = `3dmaskdump -noijk -mask $atlas $atlas | awk -v v=$val '$1==v {c++} END {print c+0}'`

    if ($count > 0) then
        echo "Extracting label $val → $name (voxels: $count)"
        3dcalc -a $atlas -expr "equals(a,$val)" \
            -prefix "${outdir}/ROI_${name}.nii.gz" -overwrite
    else
        echo "Skipping label $val → $name (not found in atlas)"
    endif
end

echo "✅ Finished: Non-empty ROIs saved to $outdir"
