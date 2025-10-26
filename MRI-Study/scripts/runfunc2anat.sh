#!/bin/csh
#
set subjdir = $1
set funcdir = $2
set anatdir = $3
set func = $4
set funcprefix = `remove_ext ${func}`
set anat = $5
set anatprefix = `remove_ext ${anat}`
set subj = `echo ${subjdir}|awk -F "sub-" '{print $2}'`
set sess = $6

if (-e ${funcdir}/${funcprefix}.nii.gz) then
echo "Found ${func} for ${subj}"
echo "Beginning functional to structural registration"
echo "Aligning ${func} to ${anat} for ${subj}"
cd ${funcdir}/
mkdir reg
set nvols = `fslnvols ${func}`
set refvol = `echo "$nvols / 2" | bc`
echo "For ${func} for ${subj}"
echo "Total Number of Volumes: $nvols, Reference Volume: $refvol"
echo "Creating example_func for registration"
if (! -e ${funcdir}/${funcprefix}_example_func.nii.gz) then
echo "fslroi ${funcdir}/${func} ${funcdir}/${funcprefix}_example_func $refvol 1"
fslroi ${funcdir}/${func} ${funcdir}/${funcprefix}_example_func $refvol 1
else
echo "Already found ${funcprefix}_example_func for ${subj} in ${funcdir}.  Not re-creating."
endif
echo "Doing BBR Registration for ${func} --> ${anat} for ${subj}"
set brainim = ${anatdir}/${anatprefix}_brain.nii.gz
set T1im = ${anatdir}/${anat}
set T1 = ${anatdir}/sub-${subj}_anat-ses-${sess}_T1w_acq-0.8mmIso.nii.gz
if (! -e ${funcdir}/reg/${funcprefix}_example_func2highres.nii.gz) then
set wmtest = `ls ${funcdir}/reg/*wmseg.nii.gz|head -n1|awk -F "fast_wmseg." '{print $2}'`
if ("${wmtest}_" == "_") then
echo "No existing wmseg image in reg directory"
echo "epi_reg --epi=${funcdir}/${funcprefix}_example_func --t1=${T1} --t1brain=${brainim} --out=${funcdir}/reg/${funcprefix}_example_func2highres"
epi_reg --epi=${funcdir}/${funcprefix}_example_func --t1=${T1} --t1brain=${brainim} --out=${funcdir}/reg/${funcprefix}_example_func2highres
else
echo "Found existing wmseg image in reg directory"
set wmsegim = `ls ${funcdir}/reg/*wmseg.nii.gz|head -n1|grep ".nii.gz"`
echo "epi_reg --epi=${funcdir}/${funcprefix}_example_func --t1=${T1} --t1brain=${brainim} --wmseg=${wmsegim} --out=${funcdir}/reg/${funcprefix}_example_func2highres"
epi_reg --epi=${funcdir}/${funcprefix}_example_func --t1=${T1} --t1brain=${brainim} --wmseg=${wmsegim} --out=${funcdir}/reg/${funcprefix}_example_func2highres
endif
else
echo "Already found ${funcprefix}_example_func2highres for ${subj} in ${funcdir}.  Not re-creating."
endif
echo "Creating inverse of transformation matrix: i.e. anatomical --> functional"
if (! -e ${funcdir}/reg/${funcprefix}_highres2example_func.mat) then
echo "convert_xfm -omat ${funcdir}/reg/${funcprefix}_highres2example_func.mat -inverse ${funcdir}/reg/${funcprefix}_example_func2highres.mat"
convert_xfm -omat ${funcdir}/reg/${funcprefix}_highres2example_func.mat -inverse ${funcdir}/reg/${funcprefix}_example_func2highres.mat
else
echo "Already found ${funcprefix}_highres2example_func.mat for ${subj} in ${funcdir}.  Not re-creating."
endif
echo "Done with ${func} --> ${anat} registration for ${subj}"
else
echo "Did not find ${func} for ${subj}.  Skipping..."
endif
