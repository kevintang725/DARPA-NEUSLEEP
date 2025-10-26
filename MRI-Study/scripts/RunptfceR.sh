#/bin/tcsh
#
#alias ptfceR /Volumes/Winterfell/SoftwareRepository/ptfceR.sh
#
# Testdir is the directory where the data lives
set testdir = $1
# Input is the 4D image from your second-level analysis, e.g., from 3dttest++
set input = $2
# Resid is the 4-D residual file you want to use for estimating the intrinsic smoothness; should be the residuals from your second-level analysis.  One 3D volume per participant.
set resid = $3
# Subbrik is the 3D volume from your 4D Input that contains the t-values for the effect of interest
set subbrik = $4
#Mask is the volume mask you want to use with pTFCE.  Should at least be restricted with a whole-brain mask, or an ROI mask.
set mask = $5
#Maskdesc is a descriptor you want to use to describe your ROI mask, e.g., "WholeBrain" or "Limbic"
set maskdesc = $6
#Suffix is the directional side of your t-test, e.g., PTvsHC, with positive t-values indicating Pt > HC.  So I would enter here "PTvsHC" for example.  It's just a string of text you want to use.
set suffix = $7
#Reversesuffix is the opposite direction of your t-test.  If your t-test was coded as PT vs. HC, than reverse suffix would be "HCvsPT".  Also just a string of text for your reference.
set reversesuffix = $8
#Change into directory
cd ${testdir}/
#Create additional directories to store outputs of pTFCE that aren't essential
if (! -d ${testdir}/smoothness/) then
mkdir ${testdir}/smoothness/
endif
if (! -d ${testdir}/numRESELs/) then
mkdir ${testdir}/numRESELs/
endif
if (! -d ${testdir}/thresh/) then
mkdir ${testdir}/thresh/
endif
if (! -d ${testdir}/Rd/) then
mkdir ${testdir}/Rd/
endif
#First, remove any existing temp directories, then create a temp directory
rm -r ptfce_temp/
mkdir ptfce_temp/
#Copy relevant files into temp directory
cp ${input} ./ptfce_temp/
cp ${resid} ./ptfce_temp/
#Change into temp directory
cd ptfce_temp/
#Remove the .nii.gz suffix from your input file to set a prefix variable
set prefix = `echo ${input}|awk -F ".nii.gz" '{print $1}'`
#Identify degrees of freedom from AFNI header for t-test, used for separating out the positive from negative t-values (as pTFCE only runs on positive Z values), and then turning them into z-values.  You  may need to change the argument number (e.g., $6) depending on what your T-test labels are.
set dof = `3dinfo -VERB ${input}|grep "statpar"|head -n1|awk '{print $6}'`
#Move positive t-values to a new image
3dcalc -a ${input}'['${subbrik}']' -expr "ispositive(a)*a" -prefix ${prefix}_${suffix}.nii.gz
#Move negative t-values to a new image, and make them positive.
3dcalc -a ${input}'['${subbrik}']' -expr "isnegative(a)*a*-1" -prefix ${prefix}_${reversesuffix}.nii.gz
#Change positive t-values to z-values
3dmerge -1zscore -prefix ${prefix}_${suffix}_Z.nii.gz ${prefix}_${suffix}.nii.gz
#Change negative t-values to z-values
3dmerge -1zscore -prefix ${prefix}_${reversesuffix}_Z.nii.gz ${prefix}_${reversesuffix}.nii.gz
#Run pTFCE.  You may need to change or remove the path in front of the ptfceR.sh script depending upon where it lives on your system.
/Volumes/Winterfell/SoftwareRepository/ptfceR.sh -r ${resid} -d ${dof} ${prefix}_${suffix}_Z.nii.gz ${mask}
#Find the FWER threshold based on the standard FSL Gaussian Random Field model from smoothest
set thresh = `more thres_z_${prefix}_${suffix}_Z.txt|awk '{print $1}'`
#Find the FWER threshold based on the ACF function of 3dFWHMx
set thresh_acf = `more thres_z_acf_${prefix}_${suffix}_Z.txt|awk '{print $1}'`
#Label the output of pTFCE as Z-values for reading into AFNI
3drefit -redo_bstat -fbuc pTFCE_Z_${prefix}_${suffix}_Z.nii.gz
#Find the maximum Z-value in the pTFCE-corrected image; you may need to change around the argument number, i.e. $12, based on your particular data
set max = `3dinfo -VERB pTFCE_Z_${prefix}_${suffix}_Z.nii.gz|grep "#"|awk '{print $12}'`
#See if the maximum pTFCE-corrected Z-value from the image exceeds the ACF-determined FWER threshold
set crittest = `echo "${thresh_acf} < ${max}" | bc -l`
#If it does exceed, create a label to append to the image for easy identification of those that are Significant or not; useful when running this in batch across multiple images
if (${crittest} == "1") then
set tag = "Significant"
else
set tag = "NoSigEffects"
endif
#Re-mask the output data.  Can't remember why I added this but there may have been some extraneous values from outside the mask that were screwing up the scale for visualization
3dcalc -a pTFCE_Z_${prefix}_${suffix}_Z.nii.gz -b ${mask} -expr "b*(ispositive(a)*a)" -prefix pTFCE_Z_${prefix}_${suffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz
#Copy files from the temp directory up a level into the test directory
cp pTFCE_Z_${prefix}_${suffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz ${testdir}/pTFCE_Z_${prefix}_${suffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz
cp numRESELs_${prefix}_${suffix}_Z.txt ${testdir}/numRESELs/numRESELs_${prefix}_${suffix}_${maskdesc}_Z.txt
cp numRESELs_acf_${prefix}_${suffix}_Z.txt ${testdir}/numRESELs/numRESELs_acf_${prefix}_${suffix}_${maskdesc}_Z.txt
cp smoothness_${prefix}_${suffix}_Z.txt ${testdir}/smoothness/smoothness_${prefix}_${suffix}_${maskdesc}_Z.txt
cp smoothness_full_${prefix}_${suffix}_Z.txt ${testdir}/smoothness/smoothness_full_${prefix}_${suffix}_${maskdesc}_Z.txt
cp thres_z_${prefix}_${suffix}_Z.txt ${testdir}/thresh/thres_z_${prefix}_${suffix}_${maskdesc}_Z.txt
cp thres_z_acf_${prefix}_${suffix}_Z.txt ${testdir}/thresh/thres_z_acf_${prefix}_${suffix}_${maskdesc}_Z.txt
cp Rd_${prefix}_${suffix}_Z.txt ${testdir}/Rd/Rd_${prefix}_${suffix}_${maskdesc}_Z.txt
#Run the pTFCE for the other (negative) side of the t-test. You may need to change or remove the path in front of the ptfceR.sh script depending upon where it lives on your system.
/Volumes/Winterfell/SoftwareRepository/ptfceR.sh -r ${resid} -d ${dof} ${prefix}_${reversesuffix}_Z.nii.gz ${mask}
#Find the FWER threshold based on the standard FSL Gaussian Random Field model from smoothest
set thresh = `more thres_z_${prefix}_${reversesuffix}_Z.txt|awk '{print $1}'`
#Find the FWER threshold based on the ACF function of 3dFWHMx
set thresh_acf = `more thres_z_acf_${prefix}_${reversesuffix}_Z.txt|awk '{print $1}'`
#Label the output of pTFCE as Z-values for reading into AFNI
3drefit -redo_bstat -fbuc pTFCE_Z_${prefix}_${reversesuffix}_Z.nii.gz
#Find the maximum Z-value in the pTFCE-corrected image; you may need to change around the argument number, i.e. $12, based on your particular data
set max = `3dinfo -VERB pTFCE_Z_${prefix}_${reversesuffix}_Z.nii.gz|grep "#"|awk '{print $12}'`
#See if the maximum pTFCE-corrected Z-value from the image exceeds the ACF-determined FWER threshold
set crittest = `echo "${thresh_acf} < ${max}" | bc -l`
#If it does exceed, create a label to append to the image for easy identification of those that are Significant or not; useful when running this in batch across multiple images
if (${crittest} == "1") then
set tag = "Significant"
else
set tag = "NoSigEffects"
endif
#Re-mask the output data.  Can't remember why I added this but there may have been some extraneous values from outside the mask that were screwing up the scale for visualization
3dcalc -a pTFCE_Z_${prefix}_${reversesuffix}_Z.nii.gz -b ${mask} -expr "b*(ispositive(a)*a)" -prefix pTFCE_Z_${prefix}_${reversesuffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz
#Copy files from the temp directory up a level into the test directory
cp pTFCE_Z_${prefix}_${reversesuffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz ${testdir}/pTFCE_Z_${prefix}_${reversesuffix}_Z_Thresh_${maskdesc}_${thresh_acf}_${thresh}_${tag}.nii.gz
cp numRESELs_${prefix}_${reversesuffix}_Z.txt ${testdir}/numRESELs/numRESELs_${prefix}_${reversesuffix}_${maskdesc}_Z.txt
cp numRESELs_acf_${prefix}_${reversesuffix}_Z.txt ${testdir}/numRESELs/numRESELs_acf_${prefix}_${reversesuffix}_${maskdesc}_Z.txt
cp smoothness_${prefix}_${reversesuffix}_Z.txt ${testdir}/smoothness/smoothness_${prefix}_${reversesuffix}_${maskdesc}_Z.txt
cp smoothness_full_${prefix}_${reversesuffix}_Z.txt ${testdir}/smoothness/smoothness_full_${prefix}_${reversesuffix}_${maskdesc}_Z.txt
cp thres_z_${prefix}_${reversesuffix}_Z.txt ${testdir}/thresh/thres_z_${prefix}_${reversesuffix}_${maskdesc}_Z.txt
cp thres_z_acf_${prefix}_${reversesuffix}_Z.txt ${testdir}/thresh/thres_z_acf_${prefix}_${reversesuffix}_${maskdesc}_Z.txt
cp Rd_${prefix}_${reversesuffix}_Z.txt ${testdir}/Rd/Rd_${prefix}_${reversesuffix}_${maskdesc}_Z.txt
#Change back into the test directory
cd ${testdir}/
#Remove the temporary directory; All relevant files should now be neatly placed in their respective homes in the test directory
rm -r ptfce_temp/
