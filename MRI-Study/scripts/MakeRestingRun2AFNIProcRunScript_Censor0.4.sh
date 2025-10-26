#!/bin/tcsh
#
set studydir = $4
set subj = $1
set sess = $2
set anatsess = $3
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
set anatdir = "${studydir}/sub-${subj}/ses-${anatsess}/anat"
set behavdatadir = "${studydir}/behavdata"
set outdir = "PostFUS"
# if (${sess} == "postFUS") then
# set outdir = "PostTx"
# else
# set outdir = ostFUS"
# endif
echo "cd ${funcdir}/"
cd ${funcdir}/
rm ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
rm ${funcdir}/mc/sub-${subj}_func_ses-${sess}_task-rest_run-02_acq-AP_mc.par.1D
set run = "${studydir}/sub-${subj}/ses-${sess}/func/sub-${subj}_func_ses-${sess}_task-rest_run-02_acq-AP_mc_tu_brain_MNI.nii.gz"
set anat = "${studydir}/sub-${subj}/ses-${anatsess}/anat/sub-${subj}_ses-${anatsess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz"
set runmotion = "${funcdir}/mc/sub-${subj}_func_ses-${sess}_task-rest_run-02_acq-AP_mc.par.txt"
set runmotionprefix = `echo ${runmotion}|awk -F ".txt" '{print $1}'`
cp ${runmotion} ${runmotionprefix}.1D
set runmotion1D = "${runmotionprefix}.1D"
echo "afni_proc.py \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-subj_id ${subj} \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-script ${funcdir}/proc_${subj}_${sess}_resting_run-02_Censor0.4.sh \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-out_dir ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-blocks mask scale regress \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-anat_has_skull no \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-copy_anat ${anat} \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-dsets ${run} \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-scr_overwrite \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-mask_segment_anat yes \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-mask_rm_segsy no \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-mask_segment_erode yes \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-mask_import STN ${studydir}/Mask_Templates/Left_STN_mask.nii.gz \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-mask_intersect Svent CSFe STN \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-mask_epi_anat yes \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_ROI_PC STN 4 \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
# echo "-regress_ROI_PC WMe 4 \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_anaticor_fast \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_make_corr_vols WMe Svent \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_censor_motion 0.4 \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_censor_outliers 0.05 \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_bandpass 0.008 0.10 \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_apply_mot_types demean deriv \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_errts_prefix sub-${subj}_ses-${sess}_RestingPostFUS_CleanedTS \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_motion_file ${runmotion1D} \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_run_clustsim no \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_fout no \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-regress_polort 2 \" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
echo "-remove_preproc_files" >> ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
chmod 775 ${subj}_${sess}_RestingRun2AFNIProcCommand.sh
