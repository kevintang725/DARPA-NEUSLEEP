#!/bin/csh
#
source ~/.cshrc

set timeseriesdir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/Resting/LeftSTN_timeseries"

mkdir "${timeseriesdir}/ALFF"
mkdir "${timeseriesdir}/TimeSeries"
foreach subj (`ls ${timeseriesdir}|grep ".1D"|sort -u`)

cat ${timeseriesdir}/${subj} | tr '\t' ' ' | tr -s ' ' > ${timeseriesdir}/TimeSeries/${subj}

3dPeriodogram -prefix  ${timeseriesdir}/ALFF/${subj} ${timeseriesdir}/TimeSeries/${subj}

1dcat  ${timeseriesdir}/ALFF/${subj}| 1d_tool.py -show_mmms

end