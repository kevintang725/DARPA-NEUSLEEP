#!/bin/tcsh
#
set studydir = $3
set subj = $1
set sess = $2
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
set anatdir = "${studydir}/sub-${subj}/ses-${sess}/anat"


set subj_sess = `basename $subj`

# Extract X and Y from folder name using regex and awk
set X = `echo $subj_sess | awk -F'[-_]' '{print $2}' | cut -c3-`
set Y = `echo $subj_sess | awk -F'[-_]' '{print $3}'`

# Compute parity
@ x_mod = $X % 2
@ y_mod = $Y % 2

 # Logic to assign path
if ( $x_mod == 1 ) then
    if ( $y_mod == 1 ) then
        set behavdatadir = "/Volumes/Kevin-SSD/MRI-Study/behavdata/HARIRI/v1"
    else
        set behavdatadir = "/Volumes/Kevin-SSD/MRI-Study/behavdata/HARIRI/v2"
    endif
    else
    if ( $y_mod == 1 ) then
        set behavdatadir = "/Volumes/Kevin-SSD/MRI-Study/behavdata/HARIRI/v2"
    else
        set behavdatadir = "/Volumes/Kevin-SSD/MRI-Study/behavdata/HARIRI/v1"
    endif
endif

echo "$subj_sess → Assigned path: $behavdatadir"
# You can now use $path in your processing logic
#set behavdatadir = "${studydir}/behavdata/HARIRI"

cd ${funcdir}
rm -f ${subj}_${sess}_HaririTaskAFNIProcCommand_StimBlocks.sh

foreach task (`cat ${studydir}/Func_ImList_${sess}.txt`)
    cd ${funcdir}
    rm -f ${funcdir}/mc/sub-${subj}_${task}_mc.par.1D

    set run = "${studydir}/sub-${subj}/ses-${sess}/func/sub-${subj}_${task}_mc_tu_brain_MNI+6.0FWHM.nii.gz"
    set runmotion = "${funcdir}/mc/sub-${subj}_${task}_mc.par.txt"
    set runmotionprefix = `echo ${runmotion} | awk -F ".txt" '{print $1}'`
    cp ${runmotion} ${runmotionprefix}.1D
    set runmotion1D = "${runmotionprefix}.1D"
end

cat << EOF > ${subj}_${sess}_HaririTaskAFNIProcCommand_StimBlocks.sh
afni_proc.py \\
    -subj_id ${subj} \\
    -script ${funcdir}/proc_${subj}_${sess}_hariritask_stimblocks.sh \\
    -out_dir ${studydir}/IndivAnal/HARIRI/sub-${subj}_ses-${sess}_Hariri_StimBlocks.results \\
    -blocks scale regress \\
    -dsets ${run} \\
    -scr_overwrite \\
    -regress_3dD_stop \\
    -regress_reml_exec \\
    -regress_stim_labels angry fear happy neutral shape \\
    -regress_stim_times \\
        ${behavdatadir}/angry_stim_times.1D \\
        ${behavdatadir}/fear_stim_times.1D \\
        ${behavdatadir}/happy_stim_times.1D \\
        ${behavdatadir}/neutral_stim_times.1D \\
        ${behavdatadir}/shape_stim_times.1D \\
    -regress_stim_types times times times times times \\
    -regress_basis 'BLOCK(5,1)' \\
    -regress_censor_motion 0.4 \\
    -regress_errts_prefix ${subj}_HARIRI_StimBlocks_ErrorTS \\
    -regress_no_fitts \\
    -regress_motion_file ${runmotion1D} \\
    -regress_opts_3dD \\
        -noFDR \\
        -num_glt 8 \\
        -gltsym 'SYM: +angry -shape' -glt_label 1 Angry-Shape \\
        -gltsym 'SYM: +fear -shape' -glt_label 2 Fear-Shape \\
        -gltsym 'SYM: +happy -shape' -glt_label 3 Happy-Shape \\
        -gltsym 'SYM: +neutral -shape' -glt_label 4 Neutral-Shape \\
        -gltsym 'SYM: +angry -fear' -glt_label 5 Angry-Fear \\
        -gltsym 'SYM: +angry -neutral' -glt_label 6 Angry-Neutral \\
        -gltsym 'SYM: +fear -neutral' -glt_label 7 Fear-Neutral \\
        -gltsym 'SYM: +happy -neutral' -glt_label 8 Happy-Neutral \\
    -regress_run_clustsim no \\
    -regress_fout yes \\
    -regress_polort 2 \\
    -regress_opts_reml -noFDR \\
    -remove_preproc_files
EOF

chmod 775 ${subj}_${sess}_HaririTaskAFNIProcCommand_StimBlocks.sh
