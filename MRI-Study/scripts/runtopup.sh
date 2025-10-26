#!/bin/csh
#
set firstimage = $1
set secondimage = $2
set tdir = $3
set order = $4
set firstimprefix = `remove_ext ${firstimage}`
set secondimprefix = `remove_ext ${secondimage}`
set homedir = `pwd`
echo "cd ${tdir}"
cd ${tdir}
echo "Calculating mean timeseries image for ${firstimage}"
if (! -e ${tdir}/topup_files/${firstimprefix}_Tmean.nii.gz) then
echo "fslmaths ${firstimage} -Tmean ${firstimprefix}_Tmean.nii.gz"
fslmaths ${firstimage} -Tmean ${firstimprefix}_Tmean.nii.gz
else
echo "Found existing Tmean image in topup_files directory!  Copying..."
echo "cp ./topup_files/${firstimprefix}_Tmean.nii.gz ./"
cp ./topup_files/${firstimprefix}_Tmean.nii.gz ./
endif
if (! -e ${tdir}/topup_files/${secondimprefix}_Tmean.nii.gz) then
echo "Calculating mean timeseries image for ${secondimage}"
echo "fslmaths ${secondimage} -Tmean ${secondimprefix}_Tmean.nii.gz"
fslmaths ${secondimage} -Tmean ${secondimprefix}_Tmean.nii.gz
else
echo "Found existing Tmean image in topup_files directory!  Copying..."
echo "cp ./topup_files/${secondimprefix}_Tmean.nii.gz ./"
cp ./topup_files/${secondimprefix}_Tmean.nii.gz ./
endif
if (! -e ${tdir}/ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans.nii.gz) then
echo "Merging together two mean images"
echo "fslmerge -t ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans.nii.gz ${firstimprefix}_Tmean.nii.gz ${secondimprefix}_Tmean.nii.gz"
fslmerge -t ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans.nii.gz ${firstimprefix}_Tmean.nii.gz ${secondimprefix}_Tmean.nii.gz
else
echo "Found existing merged 2 Tmeans"
endif
echo "Removing any old acqparams.txt files"
echo "rm acqparams_${firstimage}_${secondimage}.txt"
rm acqparams_${firstimage}_${secondimage}.txt
echo "Creating acqparams.txt file for topup"
if (${order} == "appa") then
echo "Order is ap pa"
echo "0 -1 0 0.04914" >> acqparams_${firstimprefix}_${secondimprefix}.txt
echo "0 -1 0 0.04914"
echo "0 1 0 0.04914" >> acqparams_${firstimprefix}_${secondimprefix}.txt
echo "0 1 0 0.04914"
endif
if (${order} == "paap") then
echo "Order is pa ap"
echo "0 1 0 0.04914" >> acqparams_${firstimprefix}_${secondimprefix}.txt
echo "0 1 0 0.04914"
echo "0 -1 0 0.04914" >> acqparams_${firstimprefix}_${secondimprefix}.txt
echo "0 -1 0 0.04914"
endif
echo "McFlirting Tmean images to have them roughly in the same space.  Using first image as reference"
echo "mcflirt -in ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans.nii.gz -refvol 0 -out ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans_mc.nii.gz"
mcflirt -in ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans.nii.gz -refvol 0 -out ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans_mc.nii.gz
echo "Running topup command"
echo "topup --imain=ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans_mc.nii.gz --datain=acqparams_${firstimprefix}_${secondimprefix}.txt --config=b02b0.cnf --out=Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup --iout=Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup.nii.gz"
topup --imain=ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans_mc.nii.gz --datain=acqparams_${firstimprefix}_${secondimprefix}.txt --config=b02b0.cnf --out=Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup --iout=Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup.nii.gz
echo "Applying topup correction to FIRST specified image"
echo "applytopup --imain=${firstimprefix} --inindex=1 --datain=acqparams_${firstimprefix}_${secondimprefix}.txt --topup=Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup --method=jac --out=${firstimprefix}_tu.nii.gz"
applytopup --imain=${firstimprefix} --inindex=1 --datain=acqparams_${firstimprefix}_${secondimprefix}.txt --topup=Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup --method=jac --out=${firstimprefix}_tu.nii.gz
echo "Cleaning up directory"
echo "mkdir topup_files"
mkdir topup_files
echo "mv ${firstimprefix}_Tmean.nii.gz ./topup_files/"
mv ${firstimprefix}_Tmean.nii.gz ./topup_files/
echo "mv ${secondimprefix}_Tmean.nii.gz ./topup_files/"
mv ${secondimprefix}_Tmean.nii.gz ./topup_files/
echo "rm ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans*.nii.gz"
rm ForTopup_${firstimprefix}_${secondimprefix}_2Tmeans*.nii.gz
echo "mv Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup* ./topup_files/"
mv Topup_${firstimprefix}_${secondimprefix}_2Tmeans_mc_topup* ./topup_files/
echo "mv acqparams_${firstimprefix}_${secondimprefix}.txt ./topup_files/"
mv acqparams_${firstimprefix}_${secondimprefix}.txt ./topup_files/
