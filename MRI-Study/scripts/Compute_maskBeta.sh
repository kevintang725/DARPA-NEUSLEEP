#!/bin/csh

set studydir = "/Volumes/Kevin-SSD/MRI-Study/"
set base_dir = "${studydir}/IndivAnal/HARIRI"
set sess = "night"

if (! -d "$base_dir") then
    echo "ERROR: Base directory '$base_dir' does not exist."
    exit 1
endif

# List all subject directories including session suffix
foreach subj_dir (`find $base_dir -maxdepth 1 -type d -name "sub-*-*_ses-${sess}_hariri_run-01.results" | sort`)
    set subj = `basename $subj_dir`

    # Extract full subject-session ID, e.g. 014-2
    set subj_id = `echo $subj | sed -nE 's/sub-([0-9]+-[0-9]+)_ses-.*/\1/p'`

    if ("$subj_id" == "") then
        echo "WARNING: Could not parse subject ID from $subj — skipping..."
        continue
    endif

    # Compose stats file path
    set statsfile = "${subj_dir}/stats.${subj_id}_REML.nii.gz"

    if (! -f "$statsfile") then
        echo "** Missing stats file for $subj_id — skipping..."
        continue
    endif

    # List of labels to extract
    foreach label ("Anger" "Fear" "Happy" "Neutral" "Shapes" \
                   "AngervsShapes" "AngervsNeutral" "FearvsShapes" "FearvsNeutral" \
                   "HappyvsShapes" "HappyvsNeutral" "AngervsHappy" "FearvsHappy" \
                   "FearvsAnger" "AllFacesvsShapes" "AllEmotionvsShapes" \
                   "NegFacesvsShapes" "NegFacesvsNeutral" "NegFacesvsHappy" "NeutralvsShapes")

        set coef_file = "${subj_dir}/${label}_Coef.nii.gz"

        if (! -e "$coef_file") then
            echo "Extracting $label for $subj_id"
            3dbucket -prefix "$coef_file" "${statsfile}[${label}#0_Coef]"
        else
            echo "$coef_file exists — skipping."
        endif
    end

    echo ""
end

echo "✅ Finished extracting Emotion vs. Shape contrasts for all subjects in $base_dir"
