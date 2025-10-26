#!/bin/csh

# ====== Post Ad-Hoc Analysis ==============#

# Run Analysis for Resting State
echo "🔁Starting Post Ad Hoc - Resting State Analysis"
echo "🔁🔁🔁 Running batch for Group Level Analysis - Linear Mixed Effect Model..."
./batch_3dLME_resting.sh

echo "🔁🔁🔁 Running batch for Fisher Z..."
./batch_Compute_maskfisherZ.sh

# Run Analysis for Hariri
echo "Starting Post Ad Hoc - Hariri Task Analysis"
echo "🔁🔁🔁 Running batch for Beta Coefficients..."
./batch_Compute_maskBeta.sh

echo "🔁🔁🔁 Running batch extraction of images"...
./batch_extract_images_hariri.sh

echo "🔁🔁🔁 Running group average of images"
./batch_group_average_images_hariri.sh

echo "🔁🔁🔁 Running batch Group Level Analysis - Linear Mixed Effect Model"
./batch_3dLME_hariri.sh

echo "✅✅✅✅✅Finished post ad-hoc analysis"✅✅✅✅✅
