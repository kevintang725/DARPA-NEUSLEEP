#!/bin/tcsh -f
# ======================================================================
# Batch DMN (tcsh): write per-subject ALL_timeseries_7cols.csv
# - Scans under:  ${ROOT}/IndivAnal/Resting/sub-*_resting_*.results
# - Masks:  Harvard–Oxford unilateral masks (7 nodes)
# - Output per subject:
#       <OUT>/<subj>_<ses>_ALL.1D
#       <OUT>/<subj>_<ses>_ALL_timeseries_7cols.csv  (with ROI header)
#
# Usage:
#   ./run_DMN_HO.sh -root /path/to/study -roidir /path/to/HO/Masks -out /path/to/out
# ======================================================================

# safety
set nonomatch
set savehist = 0
set histchars = ""

# ------------------------ Parse args -----------------------------------
set ROOT   = ""
set ROIDIR = ""
set OUT    = ""

while ( $#argv > 0 )
  set k = "$1"; shift
  switch ( "$k" )
    case -root:
      if ( $#argv == 0 ) then
        echo "ERROR: -root needs a value"; exit 1
      endif
      set ROOT = "$1"; shift; breaksw
    case -roidir:
      if ( $#argv == 0 ) then
        echo "ERROR: -roidir needs a value"; exit 1
      endif
      set ROIDIR = "$1"; shift; breaksw
    case -out:
      if ( $#argv == 0 ) then
        echo "ERROR: -out needs a value"; exit 1
      endif
      set OUT = "$1"; shift; breaksw
    case -h:
    case --help:
      echo "Usage: $0 -root ROOT -roidir ROI_DIR -out OUTDIR"; exit 0; breaksw
    default:
      echo "ERROR: unknown arg '$k'"; exit 1
  endsw
end

if ( "$ROOT" == "" || "$ROIDIR" == "" || "$OUT" == "" ) then
  echo "Usage: $0 -root ROOT -roidir ROI_DIR -out OUTDIR"; exit 1
endif

# ------------------------ Setup ----------------------------------------
mkdir -p "$OUT" || exit 1
set LOG = "$OUT/_dmn_timeseries_log.txt"
echo "== DMN timeseries export (tcsh) started: `date` ==" |& tee "$LOG"
echo "root   = $ROOT"   |& tee -a "$LOG"
echo "roidir = $ROIDIR" |& tee -a "$LOG"
echo "outdir = $OUT"    |& tee -a "$LOG"

# ------------------------ ROI masks ------------------------------------
set PCC_L  = "$ROIDIR/Left_Cingulate_Gyrus_posterior_division.nii.gz"
set PCC_R  = "$ROIDIR/Right_Cingulate_Gyrus_posterior_division.nii.gz"

set PREC_L = "$ROIDIR/Left_Precuneus_Cortex.nii.gz"
if ( ! -e "$PREC_L" ) set PREC_L = "$ROIDIR/Left_Precuneous_Cortex.nii.gz"

set PREC_R = "$ROIDIR/Right_Precuneus_Cortex.nii.gz"
if ( ! -e "$PREC_R" ) set PREC_R = "$ROIDIR/Right_Precuneous_Cortex.nii.gz"

set MPFC   = "$ROIDIR/mPFC.nii.gz"
set AG_L   = "$ROIDIR/Left_Angular_Gyrus.nii.gz"
set AG_R   = "$ROIDIR/Right_Angular_Gyrus.nii.gz"

foreach f ( "$PCC_L" "$PCC_R" "$PREC_L" "$PREC_R" "$MPFC" "$AG_L" "$AG_R" )
  if ( ! -e $f ) then
    echo "ERROR: Missing ROI mask: $f" |& tee -a "$LOG"
    exit 2
  endif
end

set NAMES = ( PCC_L PCC_R Precuneus_L Precuneus_R mPFC AG_L AG_R )
set NROIS = 7

# ------------------------ Process all subjects -------------------------
set BASE = "$ROOT"
@ n_found = 0

foreach d ( $BASE/sub-*_resting_*.results )
  if ( ! -d "$d" ) continue

  # find errts nifti
  set epi = ""
  foreach c ( $d/errts.*fanaticor_FWHM6.0.nii.gz $d/errts.*fanaticor*.nii.gz $d/errts*.nii.gz )
    if ( -e "$c" ) then
      set epi = "$c"
      break
    endif
  end
  if ( "$epi" == "" ) then
    echo "WARN: no errts found in $d" |& tee -a "$LOG"
    continue
  endif

  set folder = `basename "$d"`
  set SUBJ   = `echo "$folder" | cut -d_ -f1`  # sub-XXX-1 or sub-XXX-2
  set SES    = `echo "$folder" | cut -d_ -f2`  # ses-*
  echo "--- $SUBJ $SES ---" |& tee -a "$LOG"

  set OUTP = "$OUT/${SUBJ}_${SES}"
  mkdir -p "$OUTP"

  # ROI stack in MNI order
  set ROI_STACK = "$OUTP"_DMN_ROIs_MNI.nii.gz
  3dTcat -prefix "$ROI_STACK" \
    "$PCC_L" "$PCC_R" "$PREC_L" "$PREC_R" "$MPFC" "$AG_L" "$AG_R" \
    || ( echo "3dTcat failed" |& tee -a "$LOG"; continue )

  # Clean EPI (NaN/Inf->0)
  set EPI_CLEAN = "$OUTP"_epi_clean.nii.gz
  3dcalc -a "$epi" -expr 'equals(a,a)*a' -datum float -nscale -prefix "$EPI_CLEAN" \
    || ( echo "3dcalc clean failed" |& tee -a "$LOG"; continue )

  # Resample ROIs to this EPI grid
  set ROI_EPI = "$OUTP"_roi_epi.nii.gz
  3dresample -master "$EPI_CLEAN" -rmode NN -input "$ROI_STACK" -prefix "$ROI_EPI" \
    || ( echo "3dresample failed" |& tee -a "$LOG"; continue )

  # Analysis mask = automask ∩ union(ROIs)
  set ROI_UNION = "$OUTP"_roi_union.nii.gz
  3dmask_tool -input "$ROI_EPI" -union -prefix "$ROI_UNION" \
    || ( echo "3dmask_tool failed" |& tee -a "$LOG"; continue )

  set AUTOMASK = "$OUTP"_automask.nii.gz
  3dAutomask -prefix "$AUTOMASK" "$EPI_CLEAN" \
    || ( echo "3dAutomask failed" |& tee -a "$LOG"; continue )

  set USE_MASK = "$OUTP"_use_mask.nii.gz
  3dcalc -a "$AUTOMASK" -b "$ROI_UNION" -expr 'step(a*b)' -datum byte -prefix "$USE_MASK" \
    || ( echo "3dcalc mask failed" |& tee -a "$LOG"; continue )

  # Ensure each ROI has voxels under mask
  @ ok = 1
  @ i = 0
  while ( $i < $NROIS )
    set cnt = `3dBrickStat -non-zero -count "$ROI_EPI"[$i] -mask "$USE_MASK"`
    if ( "$cnt" == "" ) set cnt = 0
    echo "ROI[$i] masked voxels: $cnt" |& tee -a "$LOG"
    if ( $cnt == 0 ) set ok = 0
    @ i++
  end
  if ( $ok == 0 ) then
    echo "WARN: zero-voxel ROI(s) — skipping $SUBJ" |& tee -a "$LOG"
    continue
  endif

  # Extract mean ROI time series and stack to ALL.1D
  @ i = 1
  while ( $i <= $NROIS )
    @ idx = $i - 1
    set nm = "$NAMES[$i]"
    set RIMASK = "$OUTP"_roi$idx.nii.gz
    3dcalc -a "$ROI_EPI"[$idx] -b "$USE_MASK" -expr 'step(a*b)' -datum byte -prefix "$RIMASK" \
      || ( echo "3dcalc rimask failed" |& tee -a "$LOG"; break )
    3dmaskave -quiet -mask "$RIMASK" "$EPI_CLEAN" > "$OUTP"_"$nm".1D \
      || ( echo "3dmaskave failed" |& tee -a "$LOG"; break )
    @ i++
  end

  set ALL = "$OUTP"_ALL.1D
  1dcat "$OUTP"_PCC_L.1D "$OUTP"_PCC_R.1D "$OUTP"_Precuneus_L.1D \
        "$OUTP"_Precuneus_R.1D "$OUTP"_mPFC.1D "$OUTP"_AG_L.1D "$OUTP"_AG_R.1D > "$ALL" \
        || ( echo "1dcat failed" |& tee -a "$LOG"; continue )

  # Write per-subject CSV with ROI header (no time index)
  set TSCSV = "$OUTP"_ALL_timeseries_7cols.csv
  echo "PCC_L,PCC_R,Precuneus_L,Precuneus_R,mPFC,AG_L,AG_R" > "$TSCSV"
  awk '{printf "%s",$1; for(i=2;i<=NF;i++) printf ",%s",$i; printf "\n"}' "$ALL" >> "$TSCSV" \
      || ( echo "ERROR: failed to write $TSCSV" |& tee -a "$LOG"; continue )

  # sanity note
  set nrows = `wc -l < "$ALL"`
  echo "WROTE: $TSCSV  (rows: $nrows)" |& tee -a "$LOG"

  @ n_found++
end

echo "== Done. Subjects processed: $n_found ==" |& tee -a "$LOG"
