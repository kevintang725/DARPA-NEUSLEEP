#!/bin/tcsh

# Set the input directory
set input_dir = "/Volumes/Kevin-SSD/MRI-Study/HaririTask/data"
set output_file = "${input_dir}/Summary_Average_Times.csv"

# Clean previous output
if ( -e ${output_file} ) rm ${output_file}

# Write header
echo "File,Anger,Fear,Happy,Neutral,Shape" >> ${output_file}

# Loop through each CSV file that ends with 'trials.csv'
foreach file (`ls $input_dir/*trials.csv`)

    set filename = `basename "${file}"`
    echo "Processing: ${filename}"

    # Initialize the row with the filename
    set row = "${filename}"

    # Loop through each condition
    foreach condition (Anger Fear Happy Neutral Shape)

        # Run awk and force safe output
        set avg = `awk -F',' -v cond="${condition}" 'BEGIN {sum=0; count=0} NR>1 && $1==cond && $26 != "" {sum+=$26; count++} END {if (count > 0) printf("%.4f\n", sum/count); else print "NA"}' "${file}" | cat`

        # Append average to the row
        set row = "${row},${avg}"
    end

    # Write the completed row to the CSV
    echo "${row}" >> ${output_file}
end

echo "Done. Results saved to ${output_file}."
