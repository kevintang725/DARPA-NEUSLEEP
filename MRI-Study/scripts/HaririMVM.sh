#!/bin/tcsh

# === CONFIGURE THIS ===
# Set your parent directory containing all subject folders (e.g. sub-001-1/)
set parent_dir = "/Volumes/Kevin-SSD/MRI-Study/IndivAnal/HARIRI"

# Only include Emotion vs Control (Shape) GLT contrasts
set contrasts = (AngryShape FearShape HappyShape NeutralShape)
set bricks    = (0          2         4          6)

# Output data table
set datatable = dataTable.txt
echo "Subj Group Contrast InputFile" > $datatable

# Loop through subdirectories in parent_dir (sub-*)
foreach dir (`ls -d ${parent_dir}/sub-*`)
    set subj = `basename $dir`
    set statsfile = ${dir}/stats.${subj}_REML.nii.gz

    # Determine group (EDIT this logic as needed)
    if ("$subj" =~ *1) then
        set group = control
    else
        set group = patient
    endif

    if (! -f $statsfile) then
        echo "** Missing stats file for $subj — skipping..."
        continue
    endif

    @ i = 1
    while ($i <= $#contrasts)
        set contrast = $contrasts[$i]
        set brick = $bricks[$i]
        set outfile = ${subj}_${contrast}.nii.gz

        echo "Extracting $contrast from $statsfile (brick $brick)"
        3dbucket -prefix $outfile ${statsfile}[$brick]

        echo "$subj $group $contrast $outfile" >> $datatable

        @ i++
    end
end

echo ""
echo "✅ Finished extracting Emotion vs. Shape contrasts"
echo "🔁 Running 3dMVM..."

# Run 3dMVM with Emotion vs Shape contrasts only
3dMVM -prefix MVM_Hariri_EvS \
  -jobs 4 \
  -bsVars "Group" \
  -wsVars "Contrast" \
  -num_glt 4 \
  -gltLabel 1 Angry_vs_Shape     -gltCode 1 'Contrast : 1*AngryShape -1*shape' \
  -gltLabel 2 Fear_vs_Shape      -gltCode 2 'Contrast : 1*FearShape -1*shape' \
  -gltLabel 3 Happy_vs_Shape     -gltCode 3 'Contrast : 1*HappyShape -1*shape' \
  -gltLabel 4 Neutral_vs_Shape   -gltCode 4 'Contrast : 1*NeutralShape -1*shape' \
  -dataTable @dataTable.txt

echo ""
echo "🎉 Group-level 3dMVM complete: MVM_Hariri_EvS+tlrc.*"
