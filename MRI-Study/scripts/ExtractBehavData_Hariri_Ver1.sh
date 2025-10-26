#!/bin/csh
#
set subj = $1
set sessname = $2
set behavdatadir = $3
set sess = "${sessname}"
cd ${behavdatadir}/data/
if (! -e ${behavdatadir}/data/sub${subj}_${sess}_Ver1_ShapeTimes_Row.1D) then
echo "Starting behavioral data extraction for ${subj} at sess ${sess} in ${behavdatadir}/data for Hariri Version 1"
set behavdata = `ls|grep "sub${subj}"|grep "HaririTask_Ver1"|grep "trials.csv"`
set blockonsetposition = `more ${behavdata}|head -n1|awk -F "GCFaceStartTime_mean" '{print $1}'|sed 's/,/ /g'|wc|awk '{print $2}'`
set newblockonsetposition = `expr ${blockonsetposition} + 1`
set blockoffsetposition =  `more ${behavdata}|head -n1|awk -F "GCPostFaceFixationEndTime_mean" '{print $1}'|sed 's/,/ /g'|wc|awk '{print $2}'`
set newblockoffsetposition = `expr ${blockoffsetposition} + 1`
set anger1blockstart = `more ${behavdata}|grep "Anger"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n1`
set anger1blockend = `more ${behavdata}|grep "Anger"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n10|tail -n1`
set anger1blockduration = `echo "${anger1blockend}-${anger1blockstart}"|bc`
set anger2blockstart = `more ${behavdata}|grep "Anger"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n11|tail -n1`
set anger2blockend = `more ${behavdata}|grep "Anger"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n20|tail -n1`
set anger2blockduration = `echo "${anger2blockend}-${anger2blockstart}"|bc`
echo "${anger1blockstart} ${anger2blockstart}" >> ${behavdatadir}/data/sub${subj}_${sess}_Ver1_AngerTimes_Row.1D
set fear1blockstart = `more ${behavdata}|grep "Fear"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n1`
set fear1blockend = `more ${behavdata}|grep "Fear"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n10|tail -n1`
set fear1blockduration = `echo "${fear1blockend}-${fear1blockstart}"|bc`
set fear2blockstart = `more ${behavdata}|grep "Fear"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n11|tail -n1`
set fear2blockend = `more ${behavdata}|grep "Fear"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n20|tail -n1`
set fear2blockduration = `echo "${fear2blockend}-${fear2blockstart}"|bc`
echo "${fear1blockstart} ${fear2blockstart}" >> ${behavdatadir}/data/sub${subj}_${sess}_Ver1_FearTimes_Row.1D
set happy1blockstart = `more ${behavdata}|grep "Happy"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n1`
set happy1blockend = `more ${behavdata}|grep "Happy"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n10|tail -n1`
set happy1blockduration = `echo "${happy1blockend}-${happy1blockstart}"|bc`
set happy2blockstart = `more ${behavdata}|grep "Happy"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n11|tail -n1`
set happy2blockend = `more ${behavdata}|grep "Happy"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n20|tail -n1`
set happy2blockduration = `echo "${happy2blockend}-${happy2blockstart}"|bc`
echo "${happy1blockstart} ${happy2blockstart}" >> ${behavdatadir}/data/sub${subj}_${sess}_Ver1_HappyTimes_Row.1D
set neutral1blockstart = `more ${behavdata}|grep "Neutral"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n1`
set neutral1blockend = `more ${behavdata}|grep "Neutral"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n10|tail -n1`
set neutral1blockduration = `echo "${neutral1blockend}-${neutral1blockstart}"|bc`
set neutral2blockstart = `more ${behavdata}|grep "Neutral"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n11|tail -n1`
set neutral2blockend = `more ${behavdata}|grep "Neutral"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n20|tail -n1`
set neutral2blockduration = `echo "${neutral2blockend}-${neutral2blockstart}"|bc`
echo "${neutral1blockstart} ${neutral2blockstart}" >> ${behavdatadir}/data/sub${subj}_${sess}_Ver1_NeutralTimes_Row.1D
set shape1blockstart = `more ${behavdata}|grep "Shape"|grep -v "MatchShape"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n1`
set shape1blockend = `more ${behavdata}|grep "Shape"|grep -v "MatchShape"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n10|tail -n1`
set shape1blockduration = `echo "${shape1blockend}-${shape1blockstart}"|bc`
set shape2blockstart = `more ${behavdata}|grep "Shape"|grep -v "MatchShape"|awk -F "," '{print $'${newblockonsetposition}'}'|head -n11|tail -n1`
set shape2blockend = `more ${behavdata}|grep "Shape"|grep -v "MatchShape"|awk -F "," '{print $'${newblockoffsetposition}'}'|head -n20|tail -n1`
set shape2blockduration = `echo "${shape2blockend}-${shape2blockstart}"|bc`
echo "${shape1blockstart} ${shape2blockstart}" >> ${behavdatadir}/data/sub${subj}_${sess}_Ver1_ShapeTimes_Row.1D
else
echo "Already found behavioral data extraction for ${subj} at sess ${sess} in ${behavdatadir}/data for Hariri Version 1.  Not re-running..."
endif
