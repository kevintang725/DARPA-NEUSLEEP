#!/bin/csh
#
set subj = $1
set sess = $2
set tasklist = $3
set studydir = `pwd|awk -F "/scripts" '{print $1}'`
echo "Studydir is ${studydir}"
cd ${studydir}
set subjdir = "${studydir}/sub-${subj}/ses-${sess}"
cd ${subjdir}/func/
foreach task (`more ${studydir}/${tasklist}`)
if (-e ${subjdir}/func/sub-${subj}_${task}.nii.gz) then
echo "Found ${task} for ${subj} at session ${sess}"
if (! -e ${subjdir}/func/sub-${subj}_${task}_mc.nii.gz) then
echo "Running mcflirt on sub-${subj} for ${task} at session ${sess}"
echo "${studydir}/scripts/mcfunc.sh sub-${subj}_${task}.nii.gz ${subjdir}/func/"
${studydir}/scripts/mcfunc.sh sub-${subj}_${task}.nii.gz ${subjdir}/func/
else
echo "sub-${subj} already has motion-corrected image for ${task} at session ${sess}"
endif
else
echo "Did not find ${task} for ${subj} at session ${sess}.  Skipping..."
endif
end
cd ${studydir}
end
