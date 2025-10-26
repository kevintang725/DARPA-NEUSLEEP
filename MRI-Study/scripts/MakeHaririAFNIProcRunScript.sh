#!/bin/tcsh
#
set studydir = "/Volumes/Kevin-SSD/MRI-Study"
set subj = $1
set shortsubj = `echo ${subj}|awk -F "-" '{print $1}'`
set sess = $2
set hariritaskver = $3
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
set anatdir = "${studydir}/sub-${subj}/ses-${sess}/anat"
set subjbehavdatadir = "${studydir}/HaririTask/data"
cd ${funcdir}/
rm ${subj}_${sess}_HaririAFNIProcCommand.sh
set runnumber = "01"
rm ${funcdir}/mc/sub-${subj}_func_ses-night_task-hariri_run-${runnumber}_acq-AP_mc.par.1D
set run = "${studydir}/sub-${subj}/ses-${sess}/func/sub-${subj}_func_ses-night_task-hariri_run-${runnumber}_acq-AP_mc_tu_brain_MNI+6.0FWHM.nii.gz"
set runmotion = "${funcdir}/mc/sub-${subj}_func_ses-${sess}_task-hariri_run-${runnumber}_acq-AP_mc.par.txt"
set runmotionprefix = `echo ${runmotion}|awk -F ".txt" '{print $1}'`
cp ${runmotion} ${runmotionprefix}.1D
set runmotion1D = "${runmotionprefix}.1D"
echo "afni_proc.py \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-subj_id ${subj} \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-script ${funcdir}/proc_${subj}_${sess}_hariri.sh \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-out_dir ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${runnumber}.results \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-blocks scale regress \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-dsets ${run} \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-scr_overwrite \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_3dD_stop \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_reml_exec \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
#Stim types are Anger Fear Happy Neutral Shapes
echo "-regress_stim_labels Anger Fear Happy Neutral Shapes \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_stim_times ${subjbehavdatadir}/sub${shortsubj}_${sess}_Ver${hariritaskver}_AngerTimes_Row.1D ${subjbehavdatadir}/sub${shortsubj}_${sess}_Ver${hariritaskver}_FearTimes_Row.1D ${subjbehavdatadir}/sub${shortsubj}_${sess}_Ver${hariritaskver}_HappyTimes_Row.1D ${subjbehavdatadir}/sub${shortsubj}_${sess}_Ver${hariritaskver}_NeutralTimes_Row.1D ${subjbehavdatadir}/sub${shortsubj}_${sess}_Ver${hariritaskver}_ShapeTimes_Row.1D \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_stim_types times times times times times \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_basis_multi 'BLOCK(40,1)' 'BLOCK(40,1)' 'BLOCK(40,1)' 'BLOCK(40,1)' 'BLOCK(40,1)' \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_censor_motion 0.4 \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_errts_prefix ${subj}_hariri_ver${hariritaskver}_run-${runnumber}_ErrorTS \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_no_fitts \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_motion_file ${runmotion1D} \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
#GLTs
#1 Anger vs. Shapes
#2 Anger vs. Neutral
#3 Fear vs. Shapes
#4 Fear vs. Neutral
#5 Happy vs. Shapes
#6 Happy vs. Neutral
#7 Anger vs. Happy
#8 Fear vs. Happy
#9 Fear vs. Anger
#10 AllFaces vs. Shapes
#11 AllEmotion vs. Shapes
#12 NegFaces vs. Shapes
#13 NegFaces vs. Neutral
#14 NegFaces vs. Happy
#15 Neutral vs. Shapes
echo "-regress_opts_3dD -noFDR -num_glt 15 -gltsym 'SYM: 1*Anger -1*Shapes' -glt_label 1 AngervsShapes -gltsym 'SYM: 1*Anger -1*Neutral' -glt_label 2 AngervsNeutral -gltsym 'SYM: 1*Fear -1*Shapes' -glt_label 3 FearvsShapes -gltsym 'SYM: 1*Fear -1*Neutral' -glt_label 4 FearvsNeutral -gltsym 'SYM: 1*Happy -1*Shapes' -glt_label 5 HappyvsShapes -gltsym 'SYM: 1*Happy -1*Neutral' -glt_label 6 HappyvsNeutral -gltsym 'SYM: 1*Anger -1*Happy' -glt_label 7 AngervsHappy -gltsym 'SYM: 1*Fear -1*Happy' -glt_label 8 FearvsHappy -gltsym 'SYM: 1*Fear -1*Anger' -glt_label 9 FearvsAnger -gltsym 'SYM: 0.25*Anger 0.25*Fear 0.25*Happy 0.25*Neutral  -1*Shapes' -glt_label 10 AllFacesvsShapes -gltsym 'SYM: 0.33*Anger 0.33*Fear 0.33*Happy -0.99*Shapes' -glt_label 11 AllEmotionvsShapes -gltsym 'SYM: 0.5*Fear 0.5*Anger -1*Shapes' -glt_label 12 NegFacesvsShapes -gltsym 'SYM: 0.5*Fear 0.5*Anger -1*Neutral' -glt_label 13 NegFacesvsNeutral -gltsym 'SYM: 0.5*Fear 0.5*Anger -1*Happy' -glt_label 14 NegFacesvsHappy -gltsym 'SYM: 1*Neutral -1*Shapes' -glt_label 15 NeutralvsShapes \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_run_clustsim no \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_fout no \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-regress_opts_reml -noFDR \" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
echo "-remove_preproc_files" >> ${subj}_${sess}_HaririAFNIProcCommand.sh
chmod 775 ${subj}_${sess}_HaririAFNIProcCommand.sh
