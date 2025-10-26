#!/bin/csh
#
source ~/.cshrc

set studydir = '/Volumes/Kevin-SSD/MRI-Study'
set scriptsdir = '/Volumes/Kevin-SSD/MRI-Study/scripts'
set ROIdesc = "LeftSTN"
set ROIfile = "${studydir}/Mask_Templates/Left_STN_mask.nii.gz"
set fwhm = 6.0
foreach subj (`ls ${studydir}/IndivAnal/Resting/|grep ".results"|awk -F "sub-" '{print $2}'|awk -F "_ses" '{print $1}'|sort -u`)
foreach sess (`ls ${studydir}/IndivAnal/Resting/|grep ".results"|awk -F "ses-" '{print $2}'|awk -F "_" '{print $1}'|sort -u`)
cd ${scriptsdir}/
echo "Running NSRunResting1stLevel.sh for ${subj} at session ${sess} with seed ${ROIdesc} at FWHM ${fwhm}"
./NSRunResting1stLevel.sh ${subj} ${sess} ${ROIfile} ${ROIdesc} ${fwhm} ${studydir} ${scriptsdir}
echo "Done w/ resting 1st level analysis for ${subj} at session ${sess} with seed ${ROIdesc} at FWHM ${fwhm}!"
end
end
