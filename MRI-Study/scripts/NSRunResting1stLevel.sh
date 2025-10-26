#!/bin/csh
#
set studydir = $6
set scriptsdir = $7
set subj = $1
set sess = $2
set ROIfile = $3
set ROIdesc = $4
set fwhm = $5
set anatdir = "${studydir}/sub-${subj}/ses-${sess}/anat/struct"
set indivanaldir = "${studydir}/IndivAnal/Resting"
mkdir ${indivanaldir}/${ROIdesc}_timeseries

# Resample
rm ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz
3dresample -master ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor.nii.gz \
           -input ${studydir}/sub-${subj}/ses-${sess}/anat/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz \
           -prefix ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz
endif

cd ${scriptsdir}/
if (! -e ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz) then
./normanat.sh ${studydir}/sub-${subj}/ses-${sess} sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz highres2standard
mv ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_temp.nii.gz
echo "mv ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_temp.nii.gz"
echo "3dcalc -a ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_temp.nii.gz -expr '"'equals(a,1)*1'"' -prefix ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz"
3dcalc -a ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_temp.nii.gz -expr "equals(a,1)*1" -prefix ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz
rm ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_temp.nii.gz
echo "rm ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_temp.nii.gz"
endif
if (! -e ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN.nii.gz) then
echo "3dcalc -a ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz -b ${ROIfile} -expr '"'(ispositive(a)*1) - (ispositive(b)*1)'"' -prefix ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN.nii.gz"
3dcalc -a ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz -b ${ROIfile} -expr "(ispositive(a)*1) - (ispositive(b)*1)" -prefix ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN.nii.gz
endif

# Resample
if (! -e  ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN_resampled.nii.gz) then
rm ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN_resampled.nii.gz
3dresample -master ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor.nii.gz \
           -input ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN.nii.gz \
           -prefix ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN_resampled.nii.gz
endif

if (! -e ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PreFUS_${ROIdesc}_ts.1D) then
echo "Extracting time series for ${subj} at session ${sess} for ${ROIdesc} for Pre FUS"
echo "3dROIstats -mask ${ROIfile} -quiet -mask_f2short ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor.nii.gz >> ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PreFUS_${ROIdesc}_ts.1D"
3dROIstats -mask ${ROIfile} -quiet -mask_f2short ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor.nii.gz >> ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PreFUS_${ROIdesc}_ts.1D
else
echo "${subj} already has extracted time series at session ${sess} for ${ROIdesc} at PreFUS!  Not re-running...."
endif
#if (! -e ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PostFUS_${ROIdesc}_ts.1D) then
#echo "Extracting time series for ${subj} at session ${sess} for ${ROIdesc} for Post FUS"
#echo "3dROIstats -mask ${ROIfile} -quiet -mask_f2short ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor.nii.gz >> ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PostFUS_${ROIdesc}_ts.1D"
#3dROIstats -mask ${ROIfile} -quiet -mask_f2short ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor.nii.gz >> ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PostFUS_${ROIdesc}_ts.1D
#else
#echo "${subj} already has extracted time series at session ${sess} for ${ROIdesc} at PostFUS!  Not re-running...."
#endif
if (! -e ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz) then
echo "Smoothing residual time series for ${subj} at session ${sess} for ${ROIdesc} for PreFUS run"
echo "3dmerge -1blur_fwhm ${fwhm} -doall -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor.nii.gz"
3dmerge -1blur_fwhm ${fwhm} -doall -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor.nii.gz
else
echo "${subj} already has smoothed time series at ${fwhm} FWHM at session ${sess} for ${ROIdesc} for PreFUS run.  Not re-running..."
endif
if (! -e  ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz) then
echo "Now computing 1st level R2 maps for ${subj} at session ${sess} for ${ROIdesc} for PreFUS run"
echo "3dDeconvolve -input ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz -mask ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN_resampled.nii.gz -censor ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/censor_${subj}_combined_2.1D -polort -1 -num_stimts 1 -stim_file 1 ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PreFUS_${ROIdesc}_ts.1D -stim_label 1 ${ROIdesc}_ts -rout -tout -bucket ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz"
3dDeconvolve -input ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz -mask ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN_resampled.nii.gz -censor ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/censor_${subj}_combined_2.1D -polort -1 -num_stimts 1 -stim_file 1 ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PreFUS_${ROIdesc}_ts.1D -stim_label 1 ${ROIdesc}_ts -rout -tout -bucket ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz
else
echo "${subj} already has R2 Map at FWHM ${fwhm} at session ${sess} for ${ROIdesc} at PreFUS!  Not re-running...."
endif
if (! -e ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz) then
echo "Calculating CorrMap from R2 Map for ${subj} at session ${sess} for ${ROIdesc} with FWHM ${fwhm} at PreFUS"
echo "3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['4']' -b ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['2']' -expr '"'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)'"' -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz"
3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['4']' -b ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['2']' -expr "ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)" -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz
else
echo "${subj} already has Corr Map at FWHM ${fwhm} at session ${sess} for ${ROIdesc} at PreFUS!  Not re-running...."
endif
if (! -e ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap_FisherZ.nii.gz) then
echo "Calculating Fisher Z map for ${subj} at session ${sess} for ${ROIdesc} for PreFUS run"
echo "3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz -expr '"'atanh(a)'"' -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap_FisherZ.nii.gz"
3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz -expr "atanh(a)" -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap_FisherZ.nii.gz
else
echo "${subj} already has Fisher Z Map at FWHM ${fwhm} at session ${sess} for ${ROIdesc} at PreFUS!  Not re-running...."
endif
#if (! -e ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz) then
#echo "Smoothing residual time series for ${subj} at session ${sess} for ${ROIdesc} for PostFUS run"
#echo "3dmerge -1blur_fwhm ${fwhm} -doall -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor.nii.gz"
#3dmerge -1blur_fwhm ${fwhm} -doall -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor.nii.gz
#else
#echo "${subj} already has smoothed time series at ${fwhm} FWHM at session ${sess} for ${ROIdesc} for PostFUS run.  Not re-running..."
#endif
#if (! -e  ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz) then
#echo "Now computing 1st level R2 maps for ${subj} at session ${sess} for ${ROIdesc} for PostFUS run"
#echo "3dDeconvolve -input ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz -mask ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN_resampled.nii.gz -censor ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/censor_${subj}_combined_2.1D -polort -1 -num_stimts 1 -stim_file 1 ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PostFUS_${ROIdesc}_ts.1D -stim_label 1 ${ROIdesc}_ts -rout -tout -bucket ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz"
#3dDeconvolve -input ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor_FWHM${fwhm}.nii.gz -mask ${studydir}/sub-${subj}/ses-${sess}/anat/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI_NoROI_LSTN_resampled.nii.gz -censor ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/censor_${subj}_combined_2.1D -polort -1 -num_stimts 1 -stim_file 1 ${indivanaldir}/${ROIdesc}_timeseries/sub-${subj}_ses-${sess}_resting_PostFUS_${ROIdesc}_ts.1D -stim_label 1 ${ROIdesc}_ts -rout -tout -bucket ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz
#else
#echo "${subj} already has R2 Map at FWHM ${fwhm} at session ${sess} for ${ROIdesc} at PostFUS!  Not re-running...."
#endif
#if (! -e ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz) then
#echo "Calculating CorrMap from R2 Map for ${subj} at session ${sess} for ${ROIdesc} with FWHM ${fwhm} at PostFUS"
#echo "3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['4']' -b ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['2']' -expr '"'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)'"' -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz"
#3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['4']' -b ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_R2Map.nii.gz'['2']' -expr "ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)" -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz
#else
#echo "${subj} already has Corr Map at FWHM ${fwhm} at session ${sess} for ${ROIdesc} at PostFUS!  Not re-running...."
#endif
#if (! -e ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap_FisherZ.nii.gz) then
#echo "Calculating Fisher Z map for ${subj} at session ${sess} for ${ROIdesc} for PostFUS run"
#echo "3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz -expr '"'atanh(a)'"' -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap_FisherZ.nii.gz"
#3dcalc -a ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap.nii.gz -expr "atanh(a)" -prefix ${indivanaldir}/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM${fwhm}_${ROIdesc}_CorrMap_FisherZ.nii.gz
#else
#echo "${subj} already has Fisher Z Map at FWHM ${fwhm} at session ${sess} for ${ROIdesc} at PostFUS!  Not re-running...."
endif

# Remove Files
cd ${indivanaldir}/Resting
rm "sub-${subj}_ses-${sess}_resting_PreFUS.REML_cmd"
rm "sub-${subj}_ses-${sess}_resting_PreFUS.xmat.1D"
#rm "sub-${subj}_ses-${sess}_resting_PostFUS.REML_cmd"
#rm "sub-${subj}_ses-${sess}_resting_PostFUS.xmat.1D"

cd ${studydir}
