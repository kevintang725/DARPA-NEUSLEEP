#!/bin/csh
#
set subjdir = $1
set subj = `echo ${subjdir}|awk -F "sub-" '{print $2}'|awk -F "_ses" '{print $1}'`
set funcdata = $2
set funcprefix = `echo ${funcdata}|awk -F "_brain.nii.gz" '{print $1}'`
set funcdir = "${subjdir}/anat"
set anatdata = $3
set anatprefix = `remove_ext ${anatdata}`
set anatdir = "${subjdir}/anat/reg"
echo "Applying MNI transform to ${funcdata} for ${subj}"
if (! -e ${funcdir}/${funcprefix}_brain_MNI.nii.gz) then
echo "applywarp -i ${funcdir}/${funcdata} -w ${anatdir}/${anatdata}_warp -r $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -o ${funcdir}/${funcprefix}_brain_MNI -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil"
applywarp -i ${funcdir}/${funcdata} -w ${anatdir}/${anatdata}_warp -r $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -o ${funcdir}/${funcprefix}_brain_MNI -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil
else
echo "${subj} already has MNI-transformed ${funcdata}"
endif

