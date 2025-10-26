#!/bin/csh
#
# Input: funcdir (e.g., /path/to/sub-XXX/ses-YYY/func)
set funcdir = $1

# Extract subject and session from path
set subj = `echo ${funcdir} | awk -F "sub-" '{print $2}' | awk -F "/" '{print $1}'`
set sess = `echo ${funcdir} | awk -F "ses-" '{print $2}' | awk -F "/" '{print $1}'`

cd ${funcdir}

# Skip if output already exists
if (-e ${funcdir}/TopupFiles.txt) then
    echo "Already found TopupFiles.txt in ${funcdir}! Will not continue. Exiting...."
    exit
endif

echo "Checking Phase Encodings for ${subj} for session ${sess}"

# Extract PhaseEncodingDirection from all JSON files
rm -f TopupFiles_PEs.txt
foreach image (`ls *.json`)
    set imprefix = `echo ${image} | awk -F ".json" '{print $1}'`
    set pe = `grep '"PhaseEncodingDirection"' ${image}`
    echo "${imprefix} ${pe}" >> TopupFiles_PEs.txt
end

# Iterate through tasks that have AP acquisitions
foreach task (`ls *acq-AP*mc.nii.gz | awk -F "task-" '{print $2}' | awk -F "_acq" '{print $1}'`)
    echo "Working on ${task} for ${subj}"

    set apimage = `ls -1 *${task}*acq-AP*mc.nii.gz`
    set apimprefix = `echo ${apimage} | awk -F "_mc.nii.gz" '{print $1}'`

    set paimage = `ls -1 *${task}*acq-PA*mc.nii.gz`
    set paimprefix = `echo ${paimage} | awk -F "_mc.nii.gz" '{print $1}'`

    # Extract PhaseEncodingDirection values using sed
    set apimage_pe = `grep "${apimprefix}" TopupFiles_PEs.txt | sed 's/.*"PhaseEncodingDirection": "\(.*\)",/\1/'`
    set paimage_pe = `grep "${paimprefix}" TopupFiles_PEs.txt | sed 's/.*"PhaseEncodingDirection": "\(.*\)",/\1/'`

    if ("${apimage_pe}" == "j-") then
        echo "Subject has a to p phase encoding for ${task}!"
        echo "X${apimage}X ${paimage} appa" >> TopupFiles.txt
    else
        echo "Subject has p to a phase encoding for ${task}"
        echo "Will need to manually specify a to p phase encoding functional in TopupFile.txt"
        echo "X${apimage}X ${paimage} paap" >> TopupFiles.txt
    endif
end
