#!/bin/tcsh
#
set studydir = $3
set subj = $1
set sess = $2
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
set anatdir = "${studydir}/sub-${subj}/ses-${sess}/anat"
set behavdatadir = "${studydir}/behavdata/FUS-BOLD"
cd ${funcdir}/
rm ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
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
echo "afni_proc.py \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-subj_id ${subj} \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-script ${funcdir}/proc_${subj}_${sess}_fusbold_stimblocks.sh \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-out_dir ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-blocks scale regress \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-dsets ${run} \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-scr_overwrite \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_3dD_stop \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_reml_exec \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
#Stim types are FUS-On_Block1 FUS-On_Block2 FUS-On_Block3 FUS-On_Block4 FUS-On_Block5 FUS-On_Block6 FUS-On_Block7 FUS-On_Block8 FUS-On_Block9 FUS-On_Block10
echo "-regress_stim_labels FUS-On_Block1 FUS-On_Block2 FUS-On_Block3 FUS-On_Block4 FUS-On_Block5 FUS-On_Block6 FUS-On_Block7 FUS-On_Block8 FUS-On_Block9 FUS-On_Block10 \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_stim_times ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block1.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block2.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block3.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block4.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block5.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block6.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block7.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block8.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block9.1D ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times_Block10.1D \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_stim_types times times times times times times times times times times \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_basis 'BLOCK(30,1)' \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_censor_motion 0.4 \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_errts_prefix ${subj}_FUS-BOLD_StimBlocks_ErrorTS \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_no_fitts \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_motion_file ${runmotion1D} \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
# GLTs
#1 Second half vs. first half
#2 Block 10 vs. 1
#3 Block 5 vs. 1
#4 Block 10 vs. 5
#5 Linear Trend Decreasing
#6 Quadratic Trend Downward
#7 AllBlocks
echo "-regress_opts_3dD -noFDR -num_glt 7 -gltsym 'SYM: 0.2*FUS-On_Block10 0.2*FUS-On_Block9 0.2*FUS-On_Block8 0.2*FUS-On_Block7 0.2*FUS-On_Block6 -0.2*FUS-On_Block5 -0.2*FUS-On_Block4 -0.2*FUS-On_Block3 -0.2*FUS-On_Block2 -0.2*FUS-On_Block1' -glt_label 1 SecondHalfvsFirstHalf -gltsym 'SYM: 1*FUS-On_Block10 -1*FUS-On_Block1' -glt_label 2 Block10vs1 -gltsym 'SYM: 1*FUS-On_Block5 -1*FUS-On_Block1' -glt_label 3 Block5vs1 -gltsym 'SYM: 1*FUS-On_Block10 -1*FUS-On_Block5' -glt_label 4 Block10vs5 -gltsym 'SYM: 0.5*FUS-On_Block1 0.389*FUS-On_Block2 0.278*FUS-On_Block3 0.167*FUS-On_Block4 0.056*FUS-On_Block5 -0.056*FUS-On_Block6 -0.167*FUS-On_Block7 -0.278*FUS-On_Block8 -0.389*FUS-On_Block9 -0.5*FUS-On_Block10' -glt_label 5 LinearTrendDecreasing -gltsym 'SYM: 0.5*FUS-On_Block1 0.105*FUS-On_Block2 -0.191*FUS-On_Block3 -0.389*FUS-On_Block4 -0.488*FUS-On_Block5 -0.488*FUS-On_Block6 -0.389*FUS-On_Block7 -0.191*FUS-On_Block8 0.105*FUS-On_Block9 0.5*FUS-On_Block10' -glt_label 6 QuadraticTrendDecreasing -gltsym 'SYM: 0.1*FUS-On_Block1 0.1*FUS-On_Block2 0.1*FUS-On_Block3 0.1*FUS-On_Block4 0.1*FUS-On_Block5 0.1*FUS-On_Block6 0.1*FUS-On_Block7 0.1*FUS-On_Block8 0.1*FUS-On_Block9 0.1*FUS-On_Block10' -glt_label 7 AllBlocks \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_run_clustsim no \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_fout yes \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_polort 2 \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-regress_opts_reml -noFDR \" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
echo "-remove_preproc_files" >> ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
chmod 775 ${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
