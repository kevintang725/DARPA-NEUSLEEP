#!/bin/csh
#
set studydir = $1
cd ${studydir}/
set subj = $2
set sessname = $3
if (${sessname} == "postFUSver1" || ${sessname} == "postFUSver2" || ${sessname} == "postFUSspecialver3" || ${sessname} == "postFUSspecialver4") then
set sess = "postFUS"
else
set sess = ${sessname}
endif
echo "Running topup for ${subj} for session ${sess}"
foreach task (`more ${studydir}/RunMC_Func_ImList_${sessname}.txt|grep "AP"`)
echo "Beginning with ${task}"
if (! -e ${studydir}/sub-${subj}/ses-${sess}/func/sub-${subj}_${task}_mc_tu.nii.gz) then
echo "Did not find existing topup correction for ${task}.  Running runtopup.sh"
set firstimage = "sub-${subj}_${task}_mc.nii.gz"
echo "First image is ${firstimage}"
set secondimage = `more ${studydir}/sub-${subj}/ses-${sess}/func/TopupFiles.txt|grep "Xsub-${subj}_${task}_mc.nii.gzX"|awk '{print $2}'`
echo "Second image is ${secondimage}"
set order = `more ${studydir}/sub-${subj}/ses-${sess}/func/TopupFiles.txt|grep "Xsub-${subj}_${task}_mc.nii.gzX"|awk '{print $3}'`
echo "Order is ${order}"
cd ${studydir}/scripts/
./runtopup.sh ${firstimage} ${secondimage} ${studydir}/sub-${subj}/ses-${sess}/func ${order}
cd ${studydir}
else
echo "Found existing topup correction for ${task}!  Not running topup again."
endif
end

