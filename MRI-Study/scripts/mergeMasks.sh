#!/bin/tcsh

# === User input ===
set mask_dir = '/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/Merge'    # <-- Change this to your mask folder
set output_mask = "/Volumes/Kevin-SSD/MRI-Study/Mask_Templates/Other/STN_Amyg.nii.gz"           # Output merged mask filename
set temp_dir = "${mask_dir}/temp_merge_masks"

# === Create temp working directory ===
if (-d ${temp_dir}) rm -rf ${temp_dir}
mkdir -p ${temp_dir}
cd ${temp_dir}

# === Copy only valid NIfTI masks, skip AppleDouble files ===
echo "🔍 Copying masks..."
find ${mask_dir} -maxdepth 1 -type f \( -name "*.nii" -o -name "*.nii.gz" \) ! -name "._*" -exec cp {} ${temp_dir}/ \;

# === List valid masks ===
set mask_list = (`ls *.nii* | grep -v '^\._'`)
set num_masks = $#mask_list

echo "🧠 Found ${num_masks} valid masks to merge."

if (${num_masks} == 0) then
    echo "❌ No valid mask files found in ${mask_dir}. Exiting."
    exit 1
endif

# === Build 3dcalc expression dynamically ===
set expr = ""
set input_str = ""
@ i = 1

foreach mask (${mask_list})
    set letter = `echo ${mask} | awk -v idx=$i '{printf("%c", 96+idx)}'`  # 'a', 'b', 'c', ...
    set input_str = "${input_str} -${letter} ${mask}"
    if (${i} == 1) then
        set expr = "${letter}"
    else
        set expr = "${expr}+${letter}"
    endif
    @ i++
end

# === Run 3dcalc ===
echo "🔧 Running 3dcalc..."
3dcalc ${input_str} -expr "${expr}" -prefix ${output_mask}

# === Cleanup ===
cd ..
rm -rf ${temp_dir}

echo "✅ Mask merge complete: ${output_mask}"
