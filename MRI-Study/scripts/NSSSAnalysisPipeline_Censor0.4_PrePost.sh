#!/bin/tcsh
#

# Example for input arguments
# subj = <WANG_NEUSLEEP_STUDYA_001> for Study A, <001-1> for Study B & C
# sess = <NEUSLEEP> for Study A, <HaririTask> for Study B & C

source ~/.cshrc

set studydir = '/Volumes/Kevin-SSD/MRI-Study'
set scriptsdir = '/Volumes/Kevin-SSD/MRI-Study/scripts'
set subj = $1
set sess = $2
set anatsess = $3
set postsess = $4
cd ${scriptsdir}/
./SSRunMC.sh ${subj} ${sess} RunMC_Func_ImList_${sess}.txt
set funcdir = "${studydir}/sub-${subj}/ses-${sess}/func"
./ProbePE.sh ${funcdir}
cd ${scriptsdir}/
./SSRun_runtopup.sh ${studydir} ${subj} ${sess}
cd ${scriptsdir}/
./runstruct.sh ${studydir}/sub-${subj}/ses-${anatsess} ${studydir}
cd ${scriptsdir}/
foreach task (`more ${studydir}/Func_ImList_${sess}.txt`)
set funcimage = "sub-${subj}_${task}_mc_tu.nii.gz"
set anatimage = "sub-${subj}_ses-${anatsess}_T1w_acq-0.8mmIso.nii.gz"
cd ${scriptsdir}/
./runfunc2anat.sh ${studydir}/sub-${subj} ${studydir}/sub-${subj}/ses-${sess}/func ${studydir}/sub-${subj}/ses-${anatsess}/anat ${funcimage} ${anatimage} ${sess}
end
foreach task (`more ${studydir}/Func_ImList_${sess}.txt`)
set funcimage = "sub-${subj}_${task}_mc_tu.nii.gz"
set anatimage = "sub-${subj}_ses-${anatsess}_T1w_acq-0.8mmIso.nii.gz"
cd ${scriptsdir}/
./maskfunc.sh ${studydir}/sub-${subj}/ses-${sess} ${funcimage}
end
cd ${scriptsdir}/
./Run_normandsmoothfunc_thread1.sh ${studydir}/Func_ImList_${sess}_Thread1.txt ${subj} ${sess} ${anatsess} 6.0 ${studydir} ${scriptsdir} >> ${studydir}/logs/${subj}_normandsmoothfunc_${sess}_thread1_log.txt
#./Run_normandsmoothfunc_thread2.sh ${studydir}/Func_ImList_${sess}_Thread2.txt ${subj} ${sess} ${anatsess} 6.0 >> ${studydir}/logs/${subj}_normandsmoothfunc_${sess}_thread2_log.txt &
#./Run_normandsmoothfunc_thread3.sh ${studydir}/Func_ImList_${sess}_Thread3.txt ${subj} ${sess} ${anatsess} 6.0 >> ${studydir}/logs/${subj}_normandsmoothfunc_${sess}_thread3_log.txt &
#wait

cd ${scriptsdir}
#Extract behavioral data from hariri and colorID and make regressor files for A and B pads
set behavdatadir = "${studydir}/behavdata"
#Start making AFNI run files for A or B pad session
echo "Making AFNI Proc Run Script for Resting State Run 1 for ${subj} at session ${sess}"
echo "./MakeRestingRun1AFNIProcRunScript_Censor0.4.sh ${subj} ${sess}"
./MakeRestingRun1AFNIProcRunScript_Censor0.4.sh ${subj} ${sess} ${sess} ${studydir}
echo "Making AFNI Proc Run Script for Resting State Run 2 for ${subj} at session ${sess}"
echo "./MakeRestingRun2AFNIProcRunScript_Censor0.4.sh ${subj} ${sess}"
./MakeRestingRun2AFNIProcRunScript_Censor0.4.sh ${subj} ${sess} ${sess} ${studydir}
echo "Making AFNI Proc Run Script for FUS-BOLD for ${subj} at session ${sess}"
echo "./MakeFUS-BOLDAFNIProcRunScript.sh ${subj} ${sess}"
./MakeFUS-BOLDAFNIProcRunScript.sh ${subj} ${sess} ${studydir}
echo "Making AFNI Proc Run Script for FUS-BOLD Stim Blocks for ${subj} at session ${sess}"
echo "./MakeFUS-BOLDAFNIProcRunScript_StimBlocks.sh ${subj} ${sess}"
./MakeFUS-BOLDAFNIProcRunScript_StimBlocks.sh ${subj} ${sess} ${studydir}
#Start running individual-level analyses for A or B pad session
echo "Now running Resting State Run 1 AFNI Proc run script for ${subj} at session ${sess}"
echo "${studydir}/sub-${subj}/ses-${sess}/func/${subj}_RestingRun1AFNIProcCommand.sh"
${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_RestingRun1AFNIProcCommand.sh
if (! -e ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/errts.${subj}.fanaticor.nii.gz) then
echo "Now running Resting Run 1 individual-level analysis for ${subj} at session ${sess}!"
echo "tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_resting_run-01_Censor0.4.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_resting_run-01_Censor0.4.sh"
tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_resting_run-01_Censor0.4.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_resting_run-01_Censor0.4.sh
echo "Now cleaning up output files for Resting Run 1 analysis for ${subj} at session ${sess}"
foreach file (`ls ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/|grep "+tlrc.HEAD"`)
set shortprefix = `echo ${file}|awk -F "tlrc" '{print $1}'|sed 's/+//'`
set longprefix = `echo ${file}|awk -F ".HEAD" '{print $1}'`
echo "Connverting ${longprefix} to ${shortprefix}.nii.gz"
echo "3dcopy ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/${longprefix} ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/${shortprefix}.nii.gz"
3dcopy ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/${longprefix} ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/${shortprefix}.nii.gz
echo "Removing old unzipped file ${longprefix}"
echo "rm ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/${longprefix}*"
rm ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/${longprefix}*
end
echo "Done cleaning up output files for Resting Run1 analysis for ${subj} at session ${sess}!"
else
echo "${subj} already has first-level analysis output for Resting Run 1 task at session ${sess}!  Not re-running..."
endif
echo "Now running Resting Run 2 AFNI Proc run script for ${subj} at session ${sess}"
echo "${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_RestingRun2AFNIProcCommand.sh"
${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_RestingRun2AFNIProcCommand.sh
if (! -e ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/errts.${subj}.fanaticor.nii.gz) then
echo "Now running Resting Run 2 individual-level analysis for ${subj} at session ${sess}!"
echo "tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_resting_run-02_Censor0.4.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_resting_run-02_Censor0.4.sh"
tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_resting_run-02_Censor0.4.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_resting_run-02_Censor0.4.sh
echo "Now cleaning up output files for Resting Run 2 analysis for ${subj} at session ${sess}"
foreach file (`ls ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/|grep "+tlrc.HEAD"`)
set shortprefix = `echo ${file}|awk -F "tlrc" '{print $1}'|sed 's/+//'`
set longprefix = `echo ${file}|awk -F ".HEAD" '{print $1}'`
echo "Connverting ${longprefix} to ${shortprefix}.nii.gz"
echo "3dcopy ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/${longprefix} ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/${shortprefix}.nii.gz"
3dcopy ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/${longprefix} ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/${shortprefix}.nii.gz
echo "Removing old unzipped file ${longprefix}"
echo "rm ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/${longprefix}*"
rm ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/${longprefix}*
end
echo "Done cleaning up output files for Resting Run 2 analysis for ${subj} at session ${sess}!"
else
echo "${subj} already has first-level analysis output for Resting Run 2 at session ${sess}!  Not re-running..."
endif

# echo "Now running FUS-BOLD AFNI Proc run script for ${subj} at session ${sess}"
# echo "${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh"
# ${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_FUS-BOLDAFNIProcCommand.sh
# if (! -e ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/stats.${subj}_REML.nii.gz) then
# echo "Now running FUS-BOLD individual-level analysis for ${subj} at session ${sess}!"
# echo "tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_fusbold.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_fusbold.sh"
# tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_fusbold.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_fusbold.sh
# echo "Now cleaning up output files for FUS-BOLD analysis for ${subj} at session ${sess}"
# foreach file (`ls ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/|grep "+tlrc.HEAD"`)
# set shortprefix = `echo ${file}|awk -F "tlrc" '{print $1}'|sed 's/+//'`
# set longprefix = `echo ${file}|awk -F ".HEAD" '{print $1}'`
# echo "Connverting ${longprefix} to ${shortprefix}.nii.gz"
# echo "3dcopy ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/${longprefix} ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/${shortprefix}.nii.gz"
# 3dcopy ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/${longprefix} ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/${shortprefix}.nii.gz
# echo "Removing old unzipped file ${longprefix}"
# echo "rm ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/${longprefix}*"
# rm ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD.results/${longprefix}*
# end
# echo "Done cleaning up output files for FUS-BOLD analysis for ${subj} at session ${sess}!"
# else
# echo "${subj} already has first-level analysis output for FUS-BOLD at session ${sess}!  Not re-running..."
# endif
# echo "Now running FUS-BOLD Stim Blocks AFNI Proc run script for ${subj} at session ${sess}"
# echo "${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh"
# ${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_FUS-BOLDAFNIProcCommand_StimBlocks.sh
# if (! -e ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/stats.${subj}_REML.nii.gz) then
# echo "Now running FUS-BOLD Stim Blocks individual-level analysis for ${subj} at session ${sess}!"
# echo "tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_fusbold_stimblocks.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_fusbold_stimblocks.sh"
# tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_fusbold_stimblocks.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_fusbold_stimblocks.sh
# echo "Now cleaning up output files for FUS-BOLD Stim Blocks analysis for ${subj} at session ${sess}"
# foreach file (`ls ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/|grep "+tlrc.HEAD"`)
# set shortprefix = `echo ${file}|awk -F "tlrc" '{print $1}'|sed 's/+//'`
# set longprefix = `echo ${file}|awk -F ".HEAD" '{print $1}'`
# echo "Connverting ${longprefix} to ${shortprefix}.nii.gz"
# echo "3dcopy ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/${longprefix} ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/${shortprefix}.nii.gz"
# 3dcopy ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/${longprefix} ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/${shortprefix}.nii.gz
# echo "Removing old unzipped file ${longprefix}"
# echo "rm ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/${longprefix}*"
# rm ${studydir}/IndivAnal/FUS-BOLD/sub-${subj}_ses-${sess}_FUS-BOLD_StimBlocks.results/${longprefix}*
# end
# echo "Done cleaning up output files for FUS-BOLD Stim Blocks analysis for ${subj} at session ${sess}!"
# else
# echo "${subj} already has first-level analysis output for FUS-BOLD Stim Blocks at session ${sess}!  Not re-running..."
# endif


echo "Now running Functional Resting State 1st Level Analysis"
./Run_NSRunResting1stLevel.sh

echo "Now computing Fischer Z Map from ROI Masks"
mkdir ${studydir}/IndivAnal/Resting/FisherZMap_ROI
echo "./Compute_maskfisherZ.sh ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz ${studydir}"
./Compute_maskfisherZ.sh ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PostFUS.results/sub-${subj}_ses-${sess}_resting_PostFUS_errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz ${studydir}
