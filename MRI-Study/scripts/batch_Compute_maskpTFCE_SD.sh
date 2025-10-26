#!/bin/tcsh

# --- paths ---
set studydir  = "/Volumes/Kevin-SSD/DARPA-REM-Sleep/Experiments/Clinical/StudyA_STN_Targeting_fMRI/STUDY_A_MRI"
set targetdir = "Resting"
set sess      = "night"
set mask_dir  = "${studydir}/Mask_Templates"
set out_dir   = "${studydir}/IndivAnal/${targetdir}/pTFCE"
set tmp_dir   = "${out_dir}/_tmp_resampled_masks"

if (! -d "$out_dir")  mkdir -p "$out_dir"
if (! -d "$tmp_dir")  mkdir -p "$tmp_dir"

# --- contrasts (will be CSV columns) ---
set contrast_list = ( FUS_vs_Sham )

# Threshold for pTFCE Z-score
set thresh_pos = 4.9
set thresh_neg = -4.9

# === iterate sessions: one CSV per session ===
foreach session_suffix (1)

  # Build list of masks once
  set mask_list = (`ls ${mask_dir}/*.nii.gz`)
  if ("$#mask_list" == "0") then
    echo "⚠️ No masks found in ${mask_dir} — skipping session ${session_suffix}"
    continue
  endif

  # Output CSV (rows=masks, cols=contrasts × [mean,sd])
  set csv_file = ${out_dir}/pTFCE_summary-${session_suffix}.csv

  # Header
  echo -n "Mask" > "$csv_file"
  foreach c (${contrast_list})
    echo -n ",${c}_mean,${c}_sd" >> "$csv_file"
  end
  echo "" >> "$csv_file"

  # For each mask (row)
  foreach mask_file ($mask_list)
    set mask_name = `basename "${mask_file}" .nii.gz`

    # Start row with mask name
    echo -n "${mask_name}" >> "$csv_file"

    # For each contrast (columns)
    foreach label (${contrast_list})

      # Pick ONE master coef file for this contrast (group map)
      set results_dir = "${studydir}/IndivAnal/${targetdir}/3dLME_Results"
      set matches = ( ${results_dir}/*${label}_basalganglia*.nii.gz )
      if ( "$#matches" == "0" ) then
        echo -n ",NA,NA" >> "$csv_file"
        continue
      endif
      set coef_master = "$matches[1]"

      # ---- resample mask -> coef grid (cached per mask × session × contrast) ----
      set base = "${tmp_dir}/${mask_name}__sub-${session_suffix}__${label}"
      set deob = "${base}_deob.nii.gz"
      set resm = "${base}_onMaster.nii.gz"
      set binm = "${base}_onMaster_bin.nii.gz"

      if (! -f "$binm") then
        3dWarp -deoblique -prefix "$deob" "${mask_file}"
        if (! -f "$deob") then
          echo -n ",NA,NA" >> "$csv_file"
          continue
        endif

        3dresample -master "$coef_master" -rmode NN -input "$deob" -prefix "$resm"
        if (! -f "$resm") then
          \rm -f "$deob"
          echo -n ",NA,NA" >> "$csv_file"
          continue
        endif

        3dcalc -a "$resm" -expr 'step(a)' -prefix "$binm" -byte -nscale
        \rm -f "$deob" "$resm"
        if (! -f "$binm") then
          echo -n ",NA,NA" >> "$csv_file"
          continue
        endif

        echo "↻ Resampled ${mask_name} → ${label} (session ${session_suffix})"
      endif

      # Optional grid sanity check
      set samegrid = `3dinfo -same_all_grid "$binm" "$coef_master"`
      if ("$samegrid" == "0") then
        echo -n ",NA,NA" >> "$csv_file"
        continue
      endif

      # --- Threshold masks on the pTFCE map ---
      set thresh_pos_mask = "${base}_thresh_pos_mask.nii.gz"
      set thresh_neg_mask = "${base}_thresh_neg_mask.nii.gz"
      set thresh_combined_mask = "${base}_thresh_combined_mask.nii.gz"

      if (! -f "$thresh_pos_mask") then
        3dcalc -a "$coef_master" -expr "step(a-${thresh_pos})" -prefix "$thresh_pos_mask"
      endif
      if (! -f "$thresh_neg_mask") then
        3dcalc -a "$coef_master" -expr "step(${thresh_neg}-a)" -prefix "$thresh_neg_mask"
      endif
      if (! -f "$thresh_combined_mask") then
        3dcalc -a "$thresh_pos_mask" -b "$thresh_neg_mask" -expr "a+b" -prefix "$thresh_combined_mask"
      endif

      # --- Thresholded ROI mask = ROI ∩ threshold mask ---
      set thresh_roi_mask = "${base}_thresh_ROI_mask.nii.gz"
      if (! -f "$thresh_roi_mask") then
        3dcalc -a "$binm" -b "$thresh_combined_mask" -expr "a*b" -prefix "$thresh_roi_mask"
      endif

      # --- Choose mask: thresholded if any voxels survive, else full ROI ---
      set voxel_count = `3dBrickStat -count -non-zero "$thresh_roi_mask"`
      if ($voxel_count > 0) then
        set use_mask = "$thresh_roi_mask"
      else
        echo "⚠️ No surviving voxels in thresholded ROI for ${mask_name} × ${label}, using unthresholded ROI"
        set use_mask = "$binm"
      endif

      # --- Compute mean and SD within chosen mask ---
      set mean  = `3dBrickStat -mask "$use_mask" -non-zero -mean  "$coef_master"`
      set stdev = `3dBrickStat -mask "$use_mask" -non-zero -stdev "$coef_master"`

      if ("$mean" == "")  set mean  = "0"
      if ("$stdev" == "") set stdev = "0"

      echo -n ",${mean},${stdev}" >> "$csv_file"

    end  # contrast

    echo "" >> "$csv_file"
  end  # mask

  echo "✅ Saved ${csv_file}"

end  # session

echo "🎯 Done: CSV per session with mean & SD (fallback to unthresholded ROI when needed)."
