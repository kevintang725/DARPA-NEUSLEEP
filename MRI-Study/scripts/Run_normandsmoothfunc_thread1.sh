#!/bin/csh
#
set tasklist = $1
set subj = $2
set sess = $3
set anatsess = $4
set fwhm = $5
set studydir = $6
set scriptsdir = $7
foreach task (`more ${tasklist}`)
set funcimage = "sub-${subj}_${task}_mc_tu_brain.nii.gz"
set anatimage = "highres2standard"
cd ${scriptsdir}/
./normandsmoothfunc.sh ${studydir}/sub-${subj} ${sess} ${funcimage} ${anatsess} ${anatimage} ${fwhm}
end
