#!/bin/csh
#
set subjdir = $1
set subj = `echo ${subjdir}|awk -F "sub-" '{print $2}'|awk -F "/" '{print $1}'`
set sess = `echo ${subjdir}|awk -F "ses-" '{print $2}'`
set funcdata = $2
set funcprefix = `remove_ext ${funcdata}`
echo "Beginning masking process of functional data"
if (-e ${subjdir}/func/${funcprefix}.nii.gz) then
echo "Found ${funcdata} for ${subj} at ses-${sess}"
if (! -e ${subjdir}/func/${funcprefix}_mean_func.nii.gz) then
echo "Creating mean time-series functional image for ${funcdata} at ses-${sess}"
echo "fslmaths ${subjdir}/func/${funcdata} -Tmean ${subjdir}/func/${funcprefix}_mean_func.nii.gz"
fslmaths ${subjdir}/func/${funcdata} -Tmean ${subjdir}/func/${funcprefix}_mean_func.nii.gz
else
echo "${subj} already has mean time-series functional image for ${funcdata} at ses-${sess}"
endif
echo "Using bet2 to create initial brain mask for ${funcdata} at ses-${sess}"
if (! -e ${subjdir}/func/${funcprefix}_initialmask.nii.gz) then
echo "bet2 ${subjdir}/func/${funcprefix}_mean_func ${subjdir}/func/${funcprefix}_initialmask -f 0.3 -n -m"
bet2 ${subjdir}/func/${funcprefix}_mean_func ${subjdir}/func/${funcprefix}_initialmask -f 0.3 -n -m
immv ${subjdir}/func/${funcprefix}_initialmask_mask ${subjdir}/func/${funcprefix}_initialmask
else
echo "${subj} already has initial brain mask for ${funcdata} at ses-${sess}"
endif
echo "Applying first brain mask to functional data"
if (! -e ${subjdir}/func/${funcprefix}_bet.nii.gz) then
echo "fslmaths ${subjdir}/func/${funcdata} -mas ${subjdir}/func/${funcprefix}_initialmask ${subjdir}/func/${funcprefix}_bet"
fslmaths ${subjdir}/func/${funcdata} -mas ${subjdir}/func/${funcprefix}_initialmask ${subjdir}/func/${funcprefix}_bet
else
echo "${subj} already has initial brain mask applied to ${funcdata} at ses-${sess}"
endif
if (! -e ${subjdir}/func/${funcprefix}_mask.nii.gz) then
echo "Calculating upper threshold of functional data intensity for refined brain mask"
set upper_thresh = `fslstats ${subjdir}/func/${funcprefix}_bet -p 2 -p 98 | awk '{print $2}'`
set upper_thresh = `echo "scale=7; ${upper_thresh}*0.1" | bc -l`
echo "Upper threshold is $upper_thresh"
echo "Refining initial brain mask based on upper threshold intensity"
echo "fslmaths ${subjdir}/func/${funcprefix}_bet -thr $upper_thresh -Tmin -bin ${subjdir}/func/${funcprefix}_mask -odt char"
fslmaths ${subjdir}/func/${funcprefix}_bet -thr $upper_thresh -Tmin -bin ${subjdir}/func/${funcprefix}_initialmask -odt char
echo "fslmaths ${subjdir}/func/${funcprefix}_initialmask -dilF ${subjdir}/func/${funcprefix}_mask"
fslmaths ${subjdir}/func/${funcprefix}_initialmask -dilF ${subjdir}/func/${funcprefix}_mask
else
echo "${subj} already has refined brain mask based on upper threshold intensity for ${funcdata} at ses-${sess}"
endif
echo "Masking functional data with refined brain mask"
if (! -e ${subjdir}/func/${funcprefix}_brain.nii.gz) then
echo "fslmaths ${subjdir}/func/${funcdata} -mas ${subjdir}/func/${funcprefix}_mask ${subjdir}/func/${funcprefix}_brain -odt float"
fslmaths ${subjdir}/func/${funcdata} -mas ${subjdir}/func/${funcprefix}_mask ${subjdir}/func/${funcprefix}_brain -odt float
else
echo "${subj} already has refined brain-masked functional data for ${funcdata} at ses-${sess}"
endif
echo "Done with applying functional brain mask to ${funcdata} for ${subj} at ses-${sess}"
else
echo "Did not find ${funcdata} for ${subj} at ses-${sess}.  Exiting...."
endif
