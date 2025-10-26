#!/bin/csh
#
set datadir = $1
set subj = `echo ${datadir}|awk -F "sub-" '{print $2}'|awk -F "/" '{print $1}'`
set sess = `echo ${datadir}|awk -F "ses-" '{print $2}'`
set anatdir = "${datadir}/anat"
set ANALYSIS_PIPE_DIR = $2

cd ${anatdir}/
echo "Creating struct directory within ${anatdir}/"
if (! -e ${anatdir}/struct/first_flirt_cort.mat) then
mkdir ${anatdir}/struct
else
echo "${subj} already has a struct directory."
endif
echo "Running first_flirt on ${subj}"
if (! -e ${anatdir}/struct/first_flirt_cort.mat) then
echo "first_flirt ${anatdir}/sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso.nii.gz ${anatdir}/struct/first_flirt -cort"
first_flirt ${anatdir}/sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso.nii.gz ${anatdir}/struct/first_flirt -cort
echo "Removing temporary files"
echo "imrm ${anatdir}/struct/first_flirt*stage*"
imrm ${anatdir}/struct/first_flirt*stage*
else
echo "${subj} already has first_flirt outputs"
endif
echo "Creating inverse warp matrix"
if (! -e ${anatdir}/struct/first_flirt_cort_inv.mat) then
echo "convert_xfm -omat ${anatdir}/struct/first_flirt_cort_inv.mat -inverse ${anatdir}/struct/first_flirt_cort.mat"
convert_xfm -omat ${anatdir}/struct/first_flirt_cort_inv.mat -inverse ${anatdir}/struct/first_flirt_cort.mat
else
echo "${subj} already has inverse warp matrix: first_flirt_cort_inv.mat"
endif
echo "Warping MNI Brain Mask to subject native space to create subject-specific brain mask"
if (! -e ${anatdir}/struct/brain_mask.nii.gz) then
echo "flirt -in ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -ref sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -out ${anatdir}/struct/brain_mask -applyxfm -init ${anatdir}/struct/first_flirt_cort_inv.mat"
flirt -in ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -ref sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -out ${anatdir}/struct/brain_mask -applyxfm -init ${anatdir}/struct/first_flirt_cort_inv.mat
else
echo "${subj} already has brain mask in native space"
endif
echo "Applying brain mask to sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso to create skull-stripped brain image"
if (! -e ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz) then
echo "fslmaths sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -mas ${anatdir}/struct/brain_mask ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz"
fslmaths sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -mas ${anatdir}/struct/brain_mask ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz
cp ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz ${anatdir}/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz
else
echo "${subj} already has skull-stripped brain image"
endif
echo "Creating first directory for subcortical segmentation"
echo "mkdir ${anatdir}/struct/first/"
mkdir ${anatdir}/struct/first/
echo "Running FIRST for subcortical segmentation"
if (! -e ${anatdir}/struct/first_all_fast_firstseg.nii.gz) then
echo "run_first_all -v -a ${anatdir}/struct/first_flirt.mat -i sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -o ${anatdir}/struct/first/first -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal,R_Amyg -m auto"
run_first_all -v -a ${anatdir}/struct/first_flirt.mat -i sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -o ${anatdir}/struct/first/first -s L_Accu,L_Amyg,L_Caud,L_Hipp,L_Pall,L_Puta,L_Thal,R_Accu,R_Caud,R_Hipp,R_Pall,R_Puta,R_Thal,R_Amyg -m auto
echo "Moving FIRST files up a directory"
echo "immv ${anatdir}/struct/first/first_all_fast_firstseg ${anatdir}/struct/"
immv ${anatdir}/struct/first/first_all_fast_firstseg ${anatdir}/struct/
else
echo "${subj} already has FIRST subcortical segmentations"
endif
echo "Creating reg directory in ${anatdir}"
echo "mkdir ${anatdir}/reg/"
mkdir ${anatdir}/reg/
echo "Now beginning structural normalization to MNI Template"
echo "Running FLIRT on sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz"
if (! -e ${anatdir}/reg/highres2standard.nii.gz) then
echo "flirt -ref ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -in sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz -out ${anatdir}/reg/highres2standard -omat ${anatdir}/reg/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -interp trilinear"
flirt -ref ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -in sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz -out ${anatdir}/reg/highres2standard -omat ${anatdir}/reg/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -interp trilinear
else
echo "${subj} already has native space anatomical flirted to MNI template"
endif
echo "Creating inverse transformation matrix"
if (! -e ${anatdir}/reg/standard2highres.mat) then
echo "convert_xfm -omat ${anatdir}/reg/standard2highres.mat -inverse ${anatdir}/reg/highres2standard.mat"
convert_xfm -omat ${anatdir}/reg/standard2highres.mat -inverse ${anatdir}/reg/highres2standard.mat
else
echo "${subj} already has inverse transformation matrix: standard2highres.mat"
endif
echo "Running FNIRT on sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso"
if (! -e ${anatdir}/reg/highres2standard_warped.nii.gz) then
echo "Beginning with first FNIRT pass"
echo "fnirt --in=sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso --ref=MNI152_T1_1mm.nii.gz --config=$ANALYSIS_PIPE_DIR/fnirt_fine_config/T1_2_MNI152_1mm.cnf --aff=${anatdir}/reg/highres2standard.mat --cout=${anatdir}/reg/highres2standard_warp1 --intout=${anatdir}/reg/highres2standard_intensities --iout=${anatdir}/reg/highres2standard_warped1"
fnirt --in=sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso --ref=MNI152_T1_1mm.nii.gz --config=$ANALYSIS_PIPE_DIR/fnirt_fine_config/T1_2_MNI152_1mm.cnf --aff=${anatdir}/reg/highres2standard.mat --cout=${anatdir}/reg/highres2standard_warp1 --intout=${anatdir}/reg/highres2standard_intensities --iout=${anatdir}/reg/highres2standard_warped1
echo "Beginning with second FNIRT pass"
echo "fnirt --in=sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso --ref=MNI152_T1_1mm.nii.gz --config=$ANALYSIS_PIPE_DIR/fnirt_fine_config/T1_2_MNI152_level2.cnf --inwarp=${anatdir}/reg/highres2standard_warp1 --intout=${anatdir}/reg/highres2standard_intensities --cout=${anatdir}/reg/highres2standard_warp2 --iout=${anatdir}/reg/highres2standard_warped2"
fnirt --in=sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso --ref=MNI152_T1_1mm.nii.gz --config=$ANALYSIS_PIPE_DIR/fnirt_fine_config/T1_2_MNI152_level2.cnf --inwarp=${anatdir}/reg/highres2standard_warp1 --intout=${anatdir}/reg/highres2standard_intensities --cout=${anatdir}/reg/highres2standard_warp2 --iout=${anatdir}/reg/highres2standard_warped2
echo "Beginning with third FNIRT pass"
fnirt --in=sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso --ref=MNI152_T1_1mm.nii.gz --config=$ANALYSIS_PIPE_DIR/fnirt_fine_config/T1_2_MNI152_level3.cnf --inwarp=${anatdir}/reg/highres2standard_warp2 --intout=${anatdir}/reg/highres2standard_intensities --cout=${anatdir}/reg/highres2standard_warp3 --iout=${anatdir}/reg/highres2standard_warped3
echo "Cleaning up intermediate files"
echo "immv ${anatdir}/reg/highres2standard_warped3 ${anatdir}/reg/highres2standard_warped"
immv ${anatdir}/reg/highres2standard_warped3 ${anatdir}/reg/highres2standard_warped
echo "immv ${anatdir}/reg/highres2standard_warp3 ${anatdir}/reg/highres2standard_warp"
immv ${anatdir}/reg/highres2standard_warp3 ${anatdir}/reg/highres2standard_warp
imcp ${anatdir}/reg/highres2standard_warped.nii.gz ${anatdir}/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_MNI.nii.gz
echo "imrm ${anatdir}/reg/highres2standard_warp2 ${anatdir}/reg/highres2standard_warped2 ${anatdir}/reg/highres2standard_intensities ${anatdir}/reg/highres2standard_warp1 ${anatdir}/reg/highres2standard_warped1"
imrm ${anatdir}/reg/highres2standard_warp2 ${anatdir}/reg/highres2standard_warped2 ${anatdir}/reg/highres2standard_intensities ${anatdir}/reg/highres2standard_warp1 ${anatdir}/reg/highres2standard_warped1
else
echo "${subj} already has MNI-normalized anatomical image"
endif
echo "Inverting Warp Field"
if (! -e ${anatdir}/reg/standard2highres_warp.nii.gz) then
echo "invwarp -w ${anatdir}/reg/highres2standard_warp -r ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz -o ${anatdir}/reg/standard2highres_warp"
invwarp -w ${anatdir}/reg/highres2standard_warp -r ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz -o ${anatdir}/reg/standard2highres_warp
else
echo "${subj} already has inverse warp field: standard2highres_warp.nii.gz"
endif
echo "Inverting transformation matrix"
if (! -e ${anatdir}/reg/standard2highres.mat) then
echo "convert_xfm -omat ${anatdir}/reg/standard2highres.mat -inverse ${anatdir}/reg/highres2standard.mat"
convert_xfm -omat ${anatdir}/reg/standard2highres.mat -inverse ${anatdir}/reg/highres2standard.mat
else
echo "${subj} already has inverse warp matrix: standard2highres.mat"
endif
echo "Creating brain mask from FNIRT inverse transform for native space image"
if (! -e ${anatdir}/struct/brain_fnirt_mask.nii.gz) then
echo "applywarp -w ${anatdir}/reg/standard2highres_warp -i ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -r ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz -o ${anatdir}/struct/brain_fnirt_mask -d float"
applywarp -w ${anatdir}/reg/standard2highres_warp -i ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -r ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz -o ${anatdir}/struct/brain_fnirt_mask -d float
echo "fslmaths ${anatdir}/struct/brain_fnirt_mask -thr 0.0 -bin ${anatdir}/struct/brain_fnirt_mask -odt short"
fslmaths ${anatdir}/struct/brain_fnirt_mask -thr 0.0 -bin ${anatdir}/struct/brain_fnirt_mask -odt short
else
echo "${subj} already has brain mask obtain from inverse of FNIRT normalization: brain_fnirt_mask.nii.gz"
endif
echo "Applying brain mask to structural image to extract brain."
if (! -e ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz) then
echo "NOTE: Can compare output in ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz with ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain.nii.gz"
echo "fslmaths sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -mas ${anatdir}/struct/brain_fnirt_mask ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt"
fslmaths sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso -mas ${anatdir}/struct/brain_fnirt_mask ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz
cp ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz ${anatdir}/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz
else
echo "${subj} already has brain extraction based on FNIRT: sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz"
endif
if (! -e ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz) then
echo "Applying MNI normalization to skull-stripped image"
echo "applywarp -w ${anatdir}/reg/highres2standard_warp -i ${anatdir}/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -o ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz -d float"
applywarp -w ${anatdir}/reg/highres2standard_warp -i ${anatdir}/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_fnirt.nii.gz -r ${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz -o ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz -d float
imcp ${anatdir}/struct/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz ${anatdir}/sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz
else
echo "${subj} already has MNI-normalized skull-stripped image for session ${sess}: sub-${subj}_ses-${sess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz"
endif
echo "Done with structural processing for ${subj} for session ${sess}!"
