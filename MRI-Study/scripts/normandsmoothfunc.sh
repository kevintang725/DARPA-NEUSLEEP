#!/bin/csh
#
set subjdir = $1
set subj = `echo ${subjdir}|awk -F "sub-" '{print $2}'`
set funcsess = $2
set funcdata = $3
set funcprefix = `remove_ext ${funcdata}|awk -F "_brain" '{print $1}'`
set funcdir = "${subjdir}/ses-${funcsess}/func"
set anatsess = $4
set anatdata = $5
set anatprefix = `remove_ext ${anatdata}`
set anatdir = "${subjdir}/ses-${anatsess}/anat/reg"
set fwhm = $6
if (-e ${subjdir}/ses-${funcsess}/func/${funcdata}) then
echo "Found ${funcdata} for ${subj}"
echo "Applying MNI transform to ${funcdata} for ${subj}"
if (! -e ${funcdir}/${funcprefix}_brain_MNI.nii.gz) then
echo "applywarp -i ${funcdir}/${funcdata} -w ${anatdir}/${anatdata}_warp --premat=${funcdir}/reg/${funcprefix}_example_func2highres.mat -r $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -o ${funcdir}/${funcprefix}_brain_MNI -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil"
applywarp -i ${funcdir}/${funcdata} -w ${anatdir}/${anatdata}_warp --premat=${funcdir}/reg/${funcprefix}_example_func2highres.mat -r $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz -o ${funcdir}/${funcprefix}_brain_MNI -m $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil
else
echo "${subj} already has MNI-transformed ${funcdata}"
endif
echo "Smoothing ${funcdata} for ${subj} at a FWHM of ${fwhm}"
if (! -e ${funcdir}/${funcprefix}_brain_MNI+${fwhm}FWHM.nii.gz) then
echo "3dmerge -1blur_fwhm ${fwhm} -doall -prefix ${funcdir}/${funcprefix}_brain_MNI+${fwhm}FWHM.nii.gz ${funcdir}/${funcprefix}_brain_MNI.nii.gz"
3dmerge -1blur_fwhm ${fwhm} -doall -prefix ${funcdir}/${funcprefix}_brain_MNI+${fwhm}FWHM.nii.gz ${funcdir}/${funcprefix}_brain_MNI.nii.gz
else
echo "${subj} already has smoothed ${funcdata} at a FWHM of ${fwhm}"
endif
else
echo "Did not find ${funcdata} for ${subj}. Exiting..."
endif
