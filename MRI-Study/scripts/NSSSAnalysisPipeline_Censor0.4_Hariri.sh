#!/bin/tcsh
#

# Example for input arguments
# subj = <WANG_NEUSLEEP_STUDYA_001> for Study A, <001-1> for Study B & C
# sess = <NEUSLEEP> for Study A, <HaririTask> for Study B & C

source ~/.cshrc

if ($#argv < 3) then
	echo "Try again...."
	echo "Usage: ./NSSSAnalysisPipeline_Censor0.4_Hariri.sh [subject, e.g., 001-1] [session, e.g., night] [Hariri Task version, e.g., 1 or 2]"
	exit
endif
set studydir = '/Volumes/Kevin-SSD/MRI-Study'
set scriptsdir = '/Volumes/Kevin-SSD/MRI-Study/scripts'
set subj = $1
set sess = $2
set anatsess = ${sess}
set hariritaskver = $3
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
# Odd Subjects (1->2)
# Even Subjects (2->1)
set behavdatadir = "${studydir}/HaririTask"
echo "Extracting behavioral data and creating regressors for ${subj} at session ${sess} for hariri version ${hariritaskver}"
set shortsubj = `echo ${subj}|awk -F "-" '{print $1}'`
if (${hariritaskver} == "1") then
./ExtractBehavData_Hariri_Ver1.sh ${shortsubj} ${sess} ${behavdatadir}
echo "✅ Behavioral data and regressor extracted successfully for ${subj}"
endif
if (${hariritaskver} == "2") then
./ExtractBehavData_Hariri_Ver2.sh ${shortsubj} ${sess} ${behavdatadir}
echo "✅ Behavioral data and regressor extracted successfully for ${subj}"
endif
if ( ! -d ${studydir}/IndivAnal/Hariri ) then
	echo "mkdir -p ${studydir}/IndivAnal/Hariri/"
	mkdir -p ${studydir}/IndivAnal/Hariri/
endif
#Start making AFNI run files for A or B pad session
echo "Making AFNI Proc Run Script for Resting State Run 1 for ${subj} at session ${sess}"
echo "./MakeRestingRun1AFNIProcRunScript_Censor0.4.sh ${subj} ${sess}"
./MakeRestingRun1AFNIProcRunScript_Censor0.4.sh ${subj} ${sess} ${sess} ${studydir}
echo "Making AFNI Proc Run Script for Hariri Version ${hariritaskver} for ${subj} at session ${sess}"
echo "./MakeHaririAFNIProcRunScript.sh ${subj} ${sess} ${hariritaskver}"
./MakeHaririAFNIProcRunScript.sh ${subj} ${sess} ${hariritaskver}

# Start AFNI Processing
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
echo "Now running Hariri Ver ${hariritaskver} AFNI Proc run script for ${subj} at session ${sess}"
echo "${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_HaririAFNIProcCommand.sh"
set run = `ls ${studydir}/sub-${subj}/ses-${sess}/func/|grep "hariri"|grep "acq-AP"|grep ".json"|awk -F "run-" '{print $2}'|awk -F "_" '{print $1}'`
${studydir}/sub-${subj}/ses-${sess}/func/${subj}_${sess}_HaririAFNIProcCommand.sh
if (! -e ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/stats.${subj}_REML.nii.gz) then
echo "Now running Hariri Ver ${hariritaskver} individual-level analysis for ${subj} at session ${sess}!"
echo "tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_hariri.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_hariri.sh"
tcsh -xef ${studydir}/sub-${subj}/ses-${sess}/func/proc_${subj}_${sess}_hariri.sh |& tee ${studydir}/sub-${subj}/ses-${sess}/func/output.proc_${subj}_${sess}_hariri.sh
echo "Now cleaning up output files for Hariri Ver ${hariritaskver} analysis for ${subj} at session ${sess}"
foreach file (`ls ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/|grep "+tlrc.HEAD"`)
set shortprefix = `echo ${file}|awk -F "tlrc" '{print $1}'|sed 's/+//'`
set longprefix = `echo ${file}|awk -F ".HEAD" '{print $1}'`
echo "Connverting ${longprefix} to ${shortprefix}.nii.gz"
echo "3dcopy ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/${longprefix} ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/${shortprefix}.nii.gz"
3dcopy ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/${longprefix} ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/${shortprefix}.nii.gz
echo "Removing old unzipped file ${longprefix}"
echo "rm ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/${longprefix}*"
rm ${studydir}/IndivAnal/Hariri/sub-${subj}_ses-${sess}_hariri_run-${run}.results/${longprefix}*
end
echo "Done cleaning up output files for Hariri Ver ${hariritaskver} analysis for ${subj} at session ${sess}!"
else
echo "${subj} already has first-level analysis output for Hariri Ver ${hariritaskver} at session ${sess}!  Not re-running..."
endif


echo "Now running Functional Resting State 1st Level Analysis"
./Run_NSRunResting1stLevel.sh

# Extract Fizher Z for Resting State in STN
echo "Now Extract Fischer Z Map from ROI Masks"
mkdir ${studydir}/IndivAnal/Resting/FisherZMap_ROI
echo "./Compute_maskvalues.sh ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz  ${studydir}"
./Compute_maskvalues.sh ${studydir}/IndivAnal/Resting/sub-${subj}_ses-${sess}_resting_PreFUS.results/sub-${subj}_ses-${sess}_resting_PreFUS_errts.fanaticor_FWHM6.0_LeftSTN_CorrMap_FisherZ.nii.gz ${studydir}

# Extract Beta Coefficients for HARIRI in Amygdala
#echo "Now Extract Beta Coefficients from ROI Masks"
#mkdir ${studydir}/IndivAnal/HARIRI/BetaCoefficients
#echo "./Compute_maskBeta.sh ${subj} ${sess} ${studydir}"
#./Compute_maskBeta.sh ${subj} ${sess} ${studydir}

# Extract Images for HARIRI from Amygdala ROI 
#echo "Now Extract Images for Amygdala HARIRI"
#./extract_image.sh ${subj}

echo "✅✅✅✅✅ Finished Analysis for ${subj} ✅✅✅✅✅"