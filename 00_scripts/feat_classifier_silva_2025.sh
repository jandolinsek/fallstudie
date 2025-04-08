#!/bin/bash
# Description: Bash script for creating a SILVA-based classifier for the V3-V4 region using QIIME2.

# Set variables
CORE_NR=8
BASE_DIRECTORY="/home/jan/fs_sh"
FORWARD_PRIMER="CCTACGGGNGGCWGCAG"
REVERSE_PRIMER="TACHVGGGTATCTAATCC"

# Define file paths
REF_SEQS_PATH="$BASE_DIRECTORY/08-classifier/ref-seqs.qza"
REF_TAXONOMY_PATH="$BASE_DIRECTORY/08-classifier/ref-taxonomy.qza"
REF_SEQS_PATH_DISCARDED="$BASE_DIRECTORY/08-classifier/ref-seqs-discarded.qza"
EXTRACTED_READS_PATH="$BASE_DIRECTORY/08-classifier/extracted-reads.qza"
EXTRACTED_TAXONOMY_PATH="$BASE_DIRECTORY/08-classifier/extracted-taxonomy.qza"
EXTRACTED_CLASSIFIER_OUTPUT_PATH="$BASE_DIRECTORY/08-classifier/extracted-classifier.qza"


# Task 1: Download the SILVA database
echo "Downloading the SILVA database..."
qiime rescript get-silva-data \
  --p-version "138.2" \
  --p-target "SSURef_NR99" \
  --p-include-species-labels \
  --o-silva-sequences "$REF_SEQS_PATH" \
  --o-silva-taxonomy "$REF_TAXONOMY_PATH" \
  --verbose

# Task 2: Remove low-quality sequences
echo "Removing low-quality sequences..."
qiime rescript cull-seqs \
  --i-sequences "$REF_SEQS_PATH" \
  --o-clean-sequences "$REF_SEQS_PATH" \
  --p-n-jobs "$CORE_NR" \
  --verbose

# Task 3: Remove eukaryotes
echo "Removing eukaryotes..."
qiime taxa filter-seqs \
  --i-sequences "$REF_SEQS_PATH" \
  --i-taxonomy "$REF_TAXONOMY_PATH" \
  --p-exclude "d__Eukaryota" \
  --p-mode "contains" \
  --o-filtered-sequences "$REF_SEQS_PATH" \
  --verbose

# Task 4: Filter sequences by length
echo "Filtering sequences by length..."
qiime rescript filter-seqs-length-by-taxon \
  --i-sequences "$REF_SEQS_PATH" \
  --i-taxonomy "$REF_TAXONOMY_PATH" \
  --p-labels "Archaea" "Bacteria" \
  --p-min-lens 900 1200 \
  --o-filtered-seqs "$REF_SEQS_PATH" \
  --o-discarded-seqs "$REF_SEQS_PATH_DISCARDED" \
  --verbose

# Task 5: Extract the V3-V4 region
echo "Extracting the V3-V4 region..."
qiime feature-classifier extract-reads \
  --i-sequences "$REF_SEQS_PATH" \
  --p-f-primer "$FORWARD_PRIMER" \
  --p-r-primer "$REVERSE_PRIMER" \
  --p-n-jobs 10 \
  --o-reads "$EXTRACTED_READS_PATH" \
  --verbose

# Task 6: Dereplicate the V3-V4 region
echo "Dereplicating the V3-V4 region..."
qiime rescript dereplicate \
  --i-sequences "$EXTRACTED_READS_PATH" \
  --i-taxa "$REF_TAXONOMY_PATH" \
  --o-dereplicated-sequences "$EXTRACTED_READS_PATH" \
  --o-dereplicated-taxa "$EXTRACTED_TAXONOMY_PATH" \
  --p-threads "$CORE_NR" \
  --verbose

# Task 7: Train the classifier on the V3-V4 region
echo "Training the classifier on the V3-V4 region..."
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads "$EXTRACTED_READS_PATH" \
  --i-reference-taxonomy "$EXTRACTED_TAXONOMY_PATH" \
  --o-classifier "$EXTRACTED_CLASSIFIER_OUTPUT_PATH" \
  --verbose

echo "SILVA-based classifier creation completed successfully."