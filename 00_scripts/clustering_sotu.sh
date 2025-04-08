#!/bin/bash
# filepath: /home/jan/fs_sh/otu_calling.sh

# Description: Script for sOTU calling in the amplicon analysis pipeline.

# Set the number of cores
CORE_NR=8

# Define file paths
BASE_DIRECTORY="/home/jan/fs_sh"
FILTERED_FILE="$BASE_DIRECTORY/04_import/joined-filtered.qza"
DENOISED_FILE="$BASE_DIRECTORY/06_sOTUs/denoised-representative-sequences.qza"
DENOISED_TABLE="$BASE_DIRECTORY/06_sOTUs/denoised-table.qza"
DENOISED_TABLE_VIZ="$BASE_DIRECTORY/06_sOTUs/denoised-table.qzv"
DENOISED_FILE_STATS="$BASE_DIRECTORY/06_sOTUs/denoised-stats.qza"
DECONTAMINATION_SCORES="$BASE_DIRECTORY/06_sOTUs/decontam-scores.qza"
DECONTAMINATION_SCORES_VIZ="$BASE_DIRECTORY/06_sOTUs/decontam-scores.qzv"
TABLE_DECONT="$BASE_DIRECTORY/06_sOTUs/filtered-denoised-table.qza"
FILE_DECONT="$BASE_DIRECTORY/06_sOTUs/filtered-denoised-sequences.qza"
VIZ_FILT="$BASE_DIRECTORY/06_sOTUs/filtered-denoised-sequences.qzv"
TABLE_VIZ_FILT="$BASE_DIRECTORY/06_sOTUs/filtered-denoised-table.qzv"
CHIMERA_DIR="$BASE_DIRECTORY/06_sOTUs/chimeras"
NOCHIMERA_TABLE="$BASE_DIRECTORY/06_sOTUs/nochimera-table.qza"
NOCHIMERA_SEQS="$BASE_DIRECTORY/06_sOTUs/nochimera-sequences.qza"
NOCHIMERA_VIZ="$BASE_DIRECTORY/06_sOTUs/nochimera-table.qzv"
METADATA_CTRL="$BASE_DIRECTORY/01_metadata/eotrh_meta_ctrl.txt"
METADATA="$BASE_DIRECTORY/01_metadata/eotrh_meta.txt"

# Set the minimum feature frequency for filtering
MINIMUM_FEATURE_FREQUENCY=30

# Task 1: Denoising with deblur
echo "Running deblur for denoising..."
qiime deblur denoise-16S \
  --i-demultiplexed-seqs "$FILTERED_FILE" \
  --p-trim-length 420 \
  --o-representative-sequences "$DENOISED_FILE" \
  --o-table "$DENOISED_TABLE" \
  --p-sample-stats \
  --o-stats "$DENOISED_FILE_STATS" \
  --p-jobs-to-start "$CORE_NR"

qiime feature-table summarize \
  --i-table "$DENOISED_TABLE" \
  --o-visualization "$DENOISED_TABLE_VIZ"


# Task 2: Remove rare features 
echo "Filtering rare features..."

qiime feature-table filter-features \
  --i-table "$DENOISED_TABLE" \
  --p-min-frequency "$MINIMUM_FEATURE_FREQUENCY" \
  --o-filtered-table "$DENOISED_TABLE"

qiime feature-table filter-seqs \
  --i-data "$DENOISED_FILE" \
  --i-table "$DENOISED_TABLE" \
  --o-filtered-data "$DENOISED_FILE"


# Task 2: Remove contaminants
echo "Identifying contaminants..."
qiime quality-control decontam-identify \
  --i-table "$DENOISED_TABLE" \
  --m-metadata-file "$METADATA_CTRL" \
  --p-method prevalence \
  --p-prev-control-column Sample_or_Control \
  --p-prev-control-indicator control \
  --p-freq-concentration-column Concentration \
  --o-decontam-scores "$DECONTAMINATION_SCORES" \
  --verbose

echo "Removing contaminants..."
qiime quality-control decontam-remove \
  --i-decontam-scores "$DECONTAMINATION_SCORES" \
  --i-table "$DENOISED_TABLE" \
  --i-rep-seqs "$DENOISED_FILE" \
  --p-threshold 0.1 \
  --o-filtered-table "$TABLE_DECONT" \
  --o-filtered-rep-seqs "$FILE_DECONT" \
  --verbose


# Task 3: Visualize filtered results (before chimera removal)
echo "Visualizing filtered results..."
qiime feature-table summarize \
  --i-table "$TABLE_DECONT" \
  --o-visualization "$TABLE_VIZ_FILT" \


qiime feature-table tabulate-seqs \
  --i-data "$FILE_DECONT" \
  --o-visualization "$VIZ_FILT"


# Task 2: Chimera detection and removal
echo "Detecting and removing chimeras..."
qiime vsearch uchime-denovo \
  --i-table "$TABLE_DECONT" \
  --i-sequences "$FILE_DECONT" \
  --o-chimeras "$CHIMERA_DIR/chimeras.qza" \
  --o-nonchimeras "$CHIMERA_DIR/nonchimeras.qza" \
  --o-stats "$CHIMERA_DIR/stats.qza" \
  --verbose

# Visualize the chimera stats
qiime metadata tabulate \
  --m-input-file "$CHIMERA_DIR/stats.qza" \
  --o-visualization "$CHIMERA_DIR/stats.qzv"

# Task 3: Filter features and sequences
echo "Filtering features and sequences..."
qiime feature-table filter-features \
  --i-table "$TABLE_DECONT" \
  --m-metadata-file "$CHIMERA_DIR/nonchimeras.qza" \
  --o-filtered-table "$NOCHIMERA_TABLE"

qiime feature-table filter-seqs \
  --i-data "$FILE_DECONT" \
  --m-metadata-file "$CHIMERA_DIR/nonchimeras.qza" \
  --o-filtered-data "$NOCHIMERA_SEQS"

qiime feature-table summarize \
  --i-table "$NOCHIMERA_TABLE" \
  --o-visualization "$NOCHIMERA_VIZ"

echo "sOTU calling completed successfully."

