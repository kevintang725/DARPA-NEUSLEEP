#!/bin/tcsh
#
set studydir = $3
set subj = $1
set sess = $2
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
set anatdir = "${studydir}/sub-${subj}/ses-${sess}/anat"
set behavdatadir = "${studydir}/behavdata/FUS-BOLD"
cd ${funcdir}/
rm ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
cd ${studydir}
foreach task (`more ${studydir}/Func_ImList_${sess}.txt`)
cd ${funcdir}
rm ${funcdir}/mc/sub-${subj}_${task}_mc.par.1D
set run = "${studydir}/sub-${subj}/ses-${sess}/func/sub-${subj}_${task}_mc_tu_brain_MNI+6.0FWHM.nii.gz"
cd ${funcdir}/
set runmotion = "${funcdir}/mc/sub-${subj}_${task}_mc.par.txt"
set runmotionprefix = `echo ${runmotion}|awk -F ".txt" '{print $1}'`
cp ${runmotion} ${runmotionprefix}.1D
set runmotion1D = "${runmotionprefix}.1D"
end
#set run = "${studydir}/sub-${subj}/ses-${sess}/func/sub-${subj}_func_ses-${sess}_task-fus_run-01_acq-AP_mc_tu_brain_MNI+6.0FWHM.nii.gz"
# cd ${funcdir}/
# set runmotion = "${funcdir}/mc/sub-${subj}_func_ses-${sess}_task-fus_run-01_acq-AP_mc.par.txt"
# set runmotionprefix = `echo ${runmotion}|awk -F ".txt" '{print $1}'`
# cp ${runmotion} ${runmotionprefix}.1D
# set runmotion1D = "${runmotionprefix}.1D"
echo "afni_proc.py \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-subj_id ${subj} \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-script ${funcdir}/proc_${subj}_${sess}_fusbold.sh \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-out_dir ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-blocks scale regress \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-dsets ${run} \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-scr_overwrite \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_3dD_stop \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_reml_exec \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
#Stim types are FUS-On
echo "-regress_stim_labels FUS-On \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_stim_times ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times.1D \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_stim_types times \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_basis 'BLOCK(30,1)' \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_censor_motion 0.4 \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_errts_prefix ${subj}_FUS-BOLD_ErrorTS \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_no_fitts \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_motion_file ${runmotion1D} \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_run_clustsim no \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_fout no \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_polort 2 \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-regress_opts_reml -noFDR \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
echo "-remove_preproc_files" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
chmod 775 ${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
