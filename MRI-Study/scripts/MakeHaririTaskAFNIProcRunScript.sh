#!/bin/tcsh

# === Inputs ===
set subj = $1
set sess = $2
set studydir = $3

# === Directories ===
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
set anatdir = "${studydir}/sub-${subj}/ses-${sess}/anat"
set behavdatadir = "${studydir}/behavdata/HARIRI"
set outscript = "${subj}_${sess}_HaririTaskAFNIProCommand.sh"

# === Cleanup old script ===
cd ${funcdir}
rm -f ${outscript}

# === Loop over functional tasks ===
foreach task (`cat ${studydir}/Func_ImList_${sess}.txt`)
    set run = "${funcdir}/sub-${subj}_${task}_mc_tu_brain_MNI+6.0FWHM.nii.gz"
    set runmotion = "${funcdir}/mc/sub-${subj}_${task}_mc.par.txt"
    set runmotionprefix = `echo ${runmotion} | awk -F ".txt" '{print $1}'`
    set runmotion1D = "${runmotionprefix}.1D"

    cp ${runmotion} ${runmotion1D}
end

# === Generate afni_proc.py script ===
echo "#!/bin/tcsh" > ${outscript}
echo "afni_proc.py \\" >> ${outscript}
echo "  -subj_id ${subj} \\" >> ${outscript}
echo "  -script ${funcdir}/proc_${subj}_${sess}_hariri.sh \\" >> ${outscript}
echo "  -out_dir ${studydir}/IndivAnal/HARIRI/sub-${subj}_ses-${sess}_HARIRI.results \\" >> ${outscript}
echo "  -blocks scale regress \\" >> ${outscript}
echo "  -dsets ${run} \\" >> ${outscript}
echo "  -scr_overwrite \\" >> ${outscript}
echo "  -regress_3dD_stop \\" >> ${outscript}
echo "  -regress_reml_exec \\" >> ${outscript}

# === Hariri task stimulus setup ===
echo "  -regress_stim_labels Fear Angry Shape \\" >> ${outscript}
echo "  -regress_stim_times \\" >> ${outscript}
echo "      ${behavdatadir}/angry_stim_times.1D \\" >> ${outscript}
echo "      ${behavdatadir}/fear_stim_times.1D \\" >> ${outscript}
echo "      ${behavdatadir}/happy_stim_times.1D \\" >> ${outscript}
echo "      ${behavdatadir}/neutral_stim_times.1D \\" >> ${outscript}
echo "      ${behavdatadir}/shape_stim_times.1D \\" >> ${outscript}

#!/bin/tcsh
#
set studydir = $4
set subj = $1
set sess = $2
set anatsess = $3
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
set anatdir = "${studydir}/sub-${subj}/ses-${anatsess}/anat"
set behavdatadir = "${studydir}/behavdata"
set outdir = "PreFUS"
# if (${sess} == "postFUS") then
# set outdir = "PostTx"
# else
# set outdir = "PreFUS"
# endif
cd ${funcdir}/
rm ${subj}_${sess}_HaririTaskAFNIProCommand.sh
rm ${funcdir}/mc/sub-${subj}_func_ses-${sess}_task-hariri_run-01_acq-AP_mc.par.1D
set run = "${studydir}/sub-${subj}/ses-${sess}/func/sub-${subj}_func_ses-${sess}_task-hariri_run-01_acq-AP_mc_tu_brain_MNI.nii.gz"
set anat = "${studydir}/sub-${subj}/ses-${anatsess}/anat/sub-${subj}_ses-${anatsess}_T1w_acq-0.8mmIso_brain_MNI.nii.gz"
set runmotion = "${funcdir}/mc/sub-${subj}_func_ses-${sess}_task-hariri_run-01_acq-AP_mc.par.txt"
set runmotionprefix = `echo ${runmotion}|awk -F ".txt" '{print $1}'`
cp ${runmotion} ${runmotionprefix}.1D
set runmotion1D = "${runmotionprefix}.1D"
echo "afni_proc.py \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-subj_id ${subj} \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-script ${funcdir}/proc_${subj}_${sess}_hariri.sh \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-out_dir ${studydir}/IndivAnal/HARIRI/sub-${subj}_ses-${sess}_hariri.results \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-blocks scale regress \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-dsets ${run} \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-scr_overwrite \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_3dD_stop \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_reml_exec \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
#Stim types are FUS-On
echo "-regress_stim_labels FUS-On \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
#
echo "-regress_stim_times ${behavdatadir}/AllSubj_fus_run-01_Row_LIFUOn_Times.1D \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_stim_types times \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_basis 'BLOCK(30,1)' \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_censor_motion 0.4 \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_errts_prefix ${subj}_FUS-BOLD_ErrorTS \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_no_fitts \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_motion_file ${runmotion1D} \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_run_clustsim no \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_fout no \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_polort 2 \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-regress_opts_reml -noFDR \" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
echo "-remove_preproc_files" >> ${subj}_${sess}_HaririTaskAFNIProCommand.sh
chmod 775 ${subj}_${sess}_HaririTaskAFNIProCommand.sh

