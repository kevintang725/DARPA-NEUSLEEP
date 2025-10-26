#!/bin/tcsh

# === Paths ===
set studydir  = "/Volumes/Kevin-SSD/MRI-Study"
set sess      = "night"
set mask_dir  = "${studydir}/Mask_Templates"
set out_dir   = "${studydir}/IndivAnal/HARIRI/BetaCoefficients"
set tmp_dir   = "${out_dir}/_tmp_resampled_masks"

if (! -d "$out_dir")  mkdir -p "$out_dir"
if (! -d "$tmp_dir")  mkdir -p "$tmp_dir"

# === Contrasts (one CSV per contrast) ===
set contrast_list = ( Anger Fear Happy Neutral Shapes )

# === Build full subject list once ===
set all_subj = ()
foreach dir (`find ${studydir}/IndivAnal/HARIRI -type d -name "sub-*"`)
  set subj = `echo $dir | sed -nE 's/.*sub-([0-9]+-[0-9]+).*/\1/p'`
  if ("$subj" != "") set all_subj = ($all_subj $subj)
end

# Split by session and sort
set subj_s1 = ()
set subj_s2 = ()
foreach s ($all_subj)
  set sn = `echo $s | awk -F'-' '{print $2}'`
  if ("$sn" == "1") set subj_s1 = ($subj_s1 $s)
  if ("$sn" == "2") set subj_s2 = ($subj_s2 $s)
end
# Sort numerically by first field (subject number) while keeping -1/-2 suffix
set subj_s1 = (`printf "%s\n" $subj_s1 | sort -t'-' -k1,1n`)
set subj_s2 = (`printf "%s\n" $subj_s2 | sort -t'-' -k1,1n`)

# List of masks (rows)
set mask_list = (`ls ${mask_dir}/*.nii.gz`)
if ("$#mask_list" == "0") then
  echo "⚠️ No masks found in ${mask_dir} — exiting."
  exit 1
endif

# === For each contrast, produce one CSV ===
foreach label (${contrast_list})

  set csv_file = ${out_dir}/Coef_${label}.csv

  # ----- Header: Mask, then all session-1 subjects, then all session-2 subjects -----
  echo -n "Mask" > "$csv_file"
  foreach s ($subj_s1)
    echo -n ",${s}" >> "$csv_file"
  end
  foreach s ($subj_s2)
    echo -n ",${s}" >> "$csv_file"
  end
  echo "" >> "$csv_file"

  # ----- Rows: each mask -----
  foreach mask_file ($mask_list)
    set mask_name = `basename "${mask_file}" .nii.gz`
    echo -n "${mask_name}" >> "$csv_file"

    # ---- Session 1 subjects (columns) ----
    foreach subj ($subj_s1)
      set results_dir = "${studydir}/IndivAnal/HARIRI/sub-${subj}_ses-${sess}_hariri_run-01.results"
      set coef_file   = ${results_dir}/${label}_Coef.nii.gz

      if (! -f ${coef_file}) then
        echo -n ",NA" >> "$csv_file"
        continue
      endif

      # cache per mask × subject × contrast (grid differs per subject)
      set base = "${tmp_dir}/${mask_name}__sub-${subj}__${label}"
      set deob = "${base}_deob.nii.gz"
      set resm = "${base}_onCoef.nii.gz"
      set binm = "${base}_onCoef_bin.nii.gz"

      if (! -f "$binm") then
        3dWarp -deoblique -prefix "$deob" "${mask_file}"
        if (! -f "$deob") then
          echo -n ",NA" >> "$csv_file"
          continue
        endif
        3dresample -master "$coef_file" -rmode NN -input "$deob" -prefix "$resm"
        if (! -f "$resm") then
          \rm -f "$deob"
          echo -n ",NA" >> "$csv_file"
          continue
        endif
        3dcalc -a "$resm" -expr 'step(a)' -prefix "$binm" -byte -nscale
        \rm -f "$deob" "$resm"
        if (! -f "$binm") then
          echo -n ",NA" >> "$csv_file"
          continue
        endif
      endif

      # grid sanity (avoid silent mismatch)
      set samegrid = `3dinfo -same_all_grid "$binm" "$coef_file"`
      if ("$samegrid" == "0") then
        echo -n ",NA" >> "$csv_file"
        continue
      endif

      # ROI mean (strip voxel count)
      set mean = `3dmaskave -mask "$binm" "$coef_file" | awk '{print $1}'`
      if ("$mean" == "") set mean = "NA"
      echo -n ",${mean}" >> "$csv_file"
    end  # subj_s1

    # ---- Session 2 subjects (columns) ----
    foreach subj ($subj_s2)
      set results_dir = "${studydir}/IndivAnal/HARIRI/sub-${subj}_ses-${sess}_hariri_run-01.results"
      set coef_file   = ${results_dir}/${label}_Coef.nii.gz

      if (! -f ${coef_file}) then
        echo -n ",NA" >> "$csv_file"
        continue
      endif

      # cache per mask × subject × contrast
      set base = "${tmp_dir}/${mask_name}__sub-${subj}__${label}"
      set deob = "${base}_deob.nii.gz"
      set resm = "${base}_onCoef.nii.gz"
      set binm = "${base}_onCoef_bin.nii.gz"

      if (! -f "$binm") then
        3dWarp -deoblique -prefix "$deob" "${mask_file}"
        if (! -f "$deob") then
          echo -n ",NA" >> "$csv_file"
          continue
        endif
        3dresample -master "$coef_file" -rmode NN -input "$deob" -prefix "$resm"
        if (! -f "$resm") then
          \rm -f "$deob"
          echo -n ",NA" >> "$csv_file"
          continue
        endif
        3dcalc -a "$resm" -expr 'step(a)' -prefix "$binm" -byte -nscale
        \rm -f "$deob" "$resm"
        if (! -f "$binm") then
          echo -n ",NA" >> "$csv_file"
          continue
        endif
      endif

      set samegrid = `3dinfo -same_all_grid "$binm" "$coef_file"`
      if ("$samegrid" == "0") then
        echo -n ",NA" >> "$csv_file"
        continue
      endif

      set mean = `3dmaskave -mask "$binm" "$coef_file" | awk '{print $1}'`
      if ("$mean" == "") set mean = "NA"
      echo -n ",${mean}" >> "$csv_file"
    end  # subj_s2

    echo "" >> "$csv_file"
  end  # mask

  echo "✅ Saved ${csv_file}"

end  # contrast

echo "🎯 Done: one CSV per contrast (rows = masks; columns = all sub-XXX-1 then all sub-XXX-2; entries = ROI means)."
