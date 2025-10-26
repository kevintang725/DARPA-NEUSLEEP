#!/bin/tcsh

# Define script path
set ptfce_script = "/Volumes/Kevin-SSD/MRI-Study/scripts/ptfceR.sh"

# === Input parameters ===
set testdir = $1
set input = $2
set resid = $3
set subbrik = $4
set mask = $5
set maskdesc = $6
set suffix = $7
set reversesuffix = $8

cd ${testdir}/

# === Output directories ===
foreach dir (smoothness numRESELs thresh Rd)
    if (! -d ${testdir}/${dir}/) mkdir ${testdir}/${dir}/
end

# === Clean and setup temp directory ===
if (-d ptfce_temp/) \rm -rf ptfce_temp/
mkdir ptfce_temp/
\cp ${input} ./ptfce_temp/
\cp ${resid} ./ptfce_temp/
cd ptfce_temp/

set prefix = `basename ${input} .nii.gz`
set headvar = `expr ${subbrik} + 1`
set headvarname = `3dinfo -VERB ${input}|grep "#${subbrik}"|head -n1|awk '{print $5}' | sed "s/'//g"`
set headvartype = `3dinfo -VERB ${input} | grep "#${headvar}" | awk -F"'" '{print $2}' | awk '{print $NF}'`

echo "HEAD Variable: ${headvar}"
echo "HEAD Variable Name: ${headvarname}"
echo "HEAD Variable Type: ${headvartype}"

# === Convert to Z ===
if (${headvartype} == "F") then
    set dofn = `3dinfo -VERB ${input}|grep "statpar"|head -n${headvar}|tail -n1|awk '{print $6}'`
    set dofd = `3dinfo -VERB ${input}|grep "statpar"|head -n${headvar}|tail -n1|awk '{print $7}'`
    echo "Converting F to Z"
    3dmerge -1zscore -prefix ${prefix}_${suffix}_Z.nii.gz ${input}'['${subbrik}']'
endif

if (${headvartype} == "Z") then
    set dofd = `3dinfo -VERB ${input}|grep "statpar"|head -n1|tail -n1|awk '{print $7}'`
    echo "Creating positive and negative contrasts"
    #3dcalc -a ${input}'['${subbrik}']' -expr "ispositive(a)*a" -prefix ${prefix}_${suffix}.nii.gz
    #3dcalc -a ${input}'['${subbrik}']' -expr "isnegative(a)*a*-1" -prefix ${prefix}_${reversesuffix}.nii.gz
    3dcalc -a ${input}'['${headvar}']' -expr "ispositive(a)*a" -prefix ${prefix}_${suffix}.nii.gz
    3dcalc -a ${input}'['${headvar}']' -expr "isnegative(a)*a*-1" -prefix ${prefix}_${reversesuffix}.nii.gz
    3dmerge -1zscore -prefix ${prefix}_${suffix}_Z.nii.gz ${prefix}_${suffix}.nii.gz
    3dmerge -1zscore -prefix ${prefix}_${reversesuffix}_Z.nii.gz ${prefix}_${reversesuffix}.nii.gz
endif

# === Function to run ptfce and copy outputs ===
foreach side ("${suffix}" "${reversesuffix}")
    echo "✅ Running pTFCE for ${side}..."
    ${ptfce_script} -r ${resid} -d ${dofd} ${prefix}_${side}_Z.nii.gz ${mask}

    set zfile = ${prefix}_${side}_Z
    set pfile = pTFCE_Z_${zfile}.nii.gz
    set thres_file = ${testdir}/ptfce_temp/thres_z_${zfile}.txt
    set thres_acf_file = ${testdir}/ptfce_temp/thres_z_acf_${zfile}.txt

    if (-e ${thres_file}) then
        set thresh = `awk '{print $1}' ${thres_file}`
    else
        echo "⚠️ Missing file: ${thres_file}"
        set thresh = 4.9
    endif

    if (-e ${thres_acf_file}) then
        set thresh_acf = `awk '{print $1}' ${thres_acf_file}`
    else
        echo "⚠️ Missing file: ${thres_acf_file}"
        set thresh_acf = 4.9
    endif

    echo "Thresh: ${thresh}"
    echo "Thresh-ACF: ${thresh_acf}"

    3drefit -redo_bstat -fbuc ${pfile}
    set max = `3dinfo -VERB ${pfile} | grep "#" | awk '{print $12}'`
    echo "Max: ${max}"
    set crittest = `echo "${thresh} < ${max}" | bc -l`

    if (${crittest} == "1") then
        set tag = "Significant"
    else
        set tag = "NoSigEffects"
    endif

    3dcalc -a ${pfile} -b ${mask} -expr "b*(ispositive(a)*a)" \
        -prefix ${testdir}/ptfce_temp/pTFCE_Z_${zfile}_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz

    \cp -f ${testdir}/ptfce_temp/pTFCE_Z_${zfile}_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz \
        ${testdir}/pTFCE_Z_${zfile}_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz

    foreach filetype (numRESELs numRESELs_acf smoothness smoothness_full thres_z thres_z_acf Rd)
        set srcfile = ${testdir}/ptfce_temp/${filetype}_${zfile}.txt
        if (-e ${srcfile}) then
            set destdir = ${testdir}/$filetype
            \cp -f ${srcfile} ${destdir}/${filetype}_${zfile}_${maskdesc}.txt
        else
            echo "⚠️ Missing ${filetype} file for ${side}: ${srcfile}"
        endif
    end
end

# === Merge two maps ===
3dcalc -a ${testdir}/pTFCE_Z_${prefix}_${suffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz \
       -b ${testdir}/pTFCE_Z_${prefix}_${reversesuffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz \
       -expr 'a - b' \
       -prefix ${testdir}/pTFCE_Z_${suffix}_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz

# === Cleanup ===
\rm -f ${testdir}/pTFCE_Z_${prefix}_${suffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz
\rm -f ${testdir}/pTFCE_Z_${prefix}_${reversesuffix}_Z_${maskdesc}_Thresh_${thresh_acf}_${thresh}_${tag}.nii.gz
cd ${testdir}/
\rm -rf ptfce_temp/
