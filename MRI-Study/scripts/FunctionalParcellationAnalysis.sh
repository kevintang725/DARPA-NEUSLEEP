#!/bin/tcsh

set study = $1

# Set the atlas dataset
set atlas = "/Volumes/Kevin-SSD/MRI-Study/Mask_Repositories/The-HCP-MMP1.0-atlas-in-FSL-master/MNI_Glasser_HCP_v1.0.nii.gz"
set studydir = "/Volumes/Kevin-SSD/MRI-Study"

# Correct output directory path
set output_dir = "${studydir}/Atlas/MNI_Glasser_HCB_v1.0_ROI_Masks"
if (! -d $output_dir) then
    mkdir -p $output_dir
endif

# === Provide the label table directly ===
set label_table = "/Volumes/Kevin-SSD/MRI-Study/Mask_Repositories/The-HCP-MMP1.0-atlas-in-FSL-master/Glasser_LabelTable.txt"

# Copy the label table to the output directory for reference
cp $label_table "${output_dir}/Glasser_LabelTable.txt"

# Preprocess the label table to create a temp list for safe parsing
set tmp_list = "${output_dir}/ParsedLabels.txt"

awk '{print $1 "|" substr($0, index($0, $2))}' ${output_dir}/Glasser_LabelTable.txt > $tmp_list

# Loop through each index|label pair safely
foreach line (`cat $tmp_list`)
    set index = `echo $line | cut -d'|' -f1`
    set label = `echo $line | cut -d'|' -f2-`

    # Clean the label: replace spaces with underscores, remove commas, remove special characters
    set label_clean = `echo $label | tr -s ' ' | sed 's/[[:space:]]/_/g' | sed 's/,//g' | sed 's/[^A-Za-z0-9_]/_/g'`

    set roi_file = "${output_dir}/ROI_${index}_${label_clean}.nii.gz"

    # Skip if ROI mask already exists
    if (-e $roi_file) then
        echo "Mask ${roi_file} exists. Skipping..."
        continue
    endif

    echo "Extracting ROI: Index $index, Label $label_clean"
    3dcalc -a $atlas -expr "equals(a, $index)" -prefix $roi_file
end

echo "All ROI masks have been extracted to $output_dir"

# Extract ROI statistics
set contrastmap = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/${study}/3dLME_Results/pTFCE_Z_HARIRIa_FUS_vs_Sham_whole_brain_Thresh_4.9_4.901749_NoSigEffects.nii.gz"
set studydir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/${study}/3dLME_Results"

set source_maskpath = "/Volumes/Kevin-SSD/MRI-Study/Atlas/MNI_Glasser_HCB_v1.0_ROI_Masks/"
set out_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/${study}/3dLME_Results/Functional-Parcellation-ROI"

cd $studydir
if (! -d $out_dir) then
    mkdir -p $out_dir
endif

foreach file ($source_maskpath/*.nii.gz)
    echo "Processing Mask: $file"
    set prefix = `basename $file .nii.gz`
    set resampled_mask = "${out_dir}/${prefix}_resamp.nii.gz"
    set output_file = "${out_dir}/${prefix}.txt"

    # Skip if stats already calculated
    if (-e $output_file) then
        echo "Output ${output_file} exists. Skipping..."
        continue
    endif

    # Resample mask to match the statistical map
    if (! -e $resampled_mask) then
        echo "Resampling mask to match contrast map grid..."
        3dresample -master $contrastmap -inset $file -prefix $resampled_mask
    endif

    # Calculate FUS Effect T-scores in Masks using the RESAMPLED mask
    echo "Calculating Pre-FUS ROI: $prefix"
    3dROIstats -mask $resampled_mask -sigma "${contrastmap}" >> $output_file

    echo "Removing resampled mask: $resampled_mask"
    rm -f $resampled_mask


    chmod 775 $output_file
end


# ================================
# Merge all ROI outputs into a single summary file (Only for sub-brick 5[FUS_vs_Sh])
# ================================
set summary_file = "${out_dir}/WholeBrain_ROI_Summary.csv"

# Initialize the summary file
echo -n "" > $summary_file
printf "Index\tLabel\tMean\tSigma\n" >> $summary_file

foreach file ($source_maskpath/*.nii.gz)
    set prefix = `basename $file .nii.gz`
    set index = `echo $prefix | cut -d'_' -f2`
    set label_clean = `echo $prefix | cut -d'_' -f3-`

    set stats_file = "${out_dir}/${prefix}.txt"

    # Skip if the stats file doesn't exist
    if (! -e $stats_file) then
        echo "Stats file missing: $stats_file. Skipping..."
        continue
    endif

    # Extract the first data row (skip header)
    set line_test = `awk 'NR==2 {print $3, $4}' $stats_file`

    # Check if the result is empty
    if ("$line_test" == "") then
        echo "No valid stats in: $stats_file. Skipping..."
        continue
    endif


    # Assign mean and sigma only if result exists
    set mean_value = `echo $line_test | awk '{print $1}'`
    set sigma_value = `echo $line_test | awk '{print $2}'`

    # Append to the CSV file
    echo "${index},${label_clean},${mean_value},${sigma_value}" >> $summary_file
end

# ================================
# Sort the final CSV file by Index
# ================================
sort -t',' -k1,1n $summary_file -o $summary_file

echo "Sorted summary CSV file created: $summary_file"
