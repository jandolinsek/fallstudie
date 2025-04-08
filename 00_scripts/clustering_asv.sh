#!/bin/bash
# filepath: /home/jan/fs_sh/dada2_analysis.sh

# Description: Script for DADA2 analysis in the amplicon analysis pipeline.

# Set the number of cores
CORE_NR=8

# Define file paths
BASE_DIRECTORY="/home/jan/fs_sh"
OUTPUT_FILE_IMPORT="$BASE_DIRECTORY/04_import/paired-end-demux.qza"
DADA_FILE="$BASE_DIRECTORY/07_ASVs/representative-sequences.qza"
DADA_TABLE="$BASE_DIRECTORY/07_ASVs/dada2-table.qza"
DADA_STATS="$BASE_DIRECTORY/07_ASVs/denoising-stats.qza"
DADA_TABLE_VIZ="$BASE_DIRECTORY/07_ASVs/dada2-table.qzv"
DECONTAMINATION_SCORES="$BASE_DIRECTORY/07_ASVs/decontam-scores.qza"
DECONTAMINATION_SCORES_VIZ="$BASE_DIRECTORY/07_ASVs/decontam-scores.qzv"
DADA_TABLE_DECONT="$BASE_DIRECTORY/07_ASVs/filtered-table.qza"
DADA_FILE_DECONT="$BASE_DIRECTORY/07_ASVs/filtered-representative-sequences.qza"
DADA_TABLE_VIZ_FILT="$BASE_DIRECTORY/07_ASVs/filtered-table.qzv"
DADA_VIZ_FILT="$BASE_DIRECTORY/07_ASVs/filtered-representative-sequences.qzv"
DADA_STATS_VIZ_FILT="$BASE_DIRECTORY/07_ASVs/denoising-stats.qzv"
METADATA_CTRL="$BASE_DIRECTORY/01_metadata/eotrh_meta_ctrl.txt"
METADATA="$BASE_DIRECTORY/01_metadata/eotrh_meta.txt"
CHIMERA_DIR="$BASE_DIRECTORY/07_ASVs/chimeras"
NOCHIMERA_TABLE="$BASE_DIRECTORY/07_ASVs/nochimera-table.qza"
NOCHIMERA_SEQS="$BASE_DIRECTORY/07_ASVs/nochimera-sequences.qza"
NOCHIMERA_VIZ="$BASE_DIRECTORY/07_ASVs/nochimera-table.qzv"

# Set the minimum feature frequency for filtering
MINIMUM_FEATURE_FREQUENCY=30


# Task 1: DADA2 denoising 
echo "Running DADA2 denoising..."
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs "$OUTPUT_FILE_IMPORT" \
  --p-trim-left-f 13 \
  --p-trim-left-r 13 \
  --p-trunc-len-f 260 \
  --p-trunc-len-r 220 \
  --o-representative-sequences "$DADA_FILE" \
  --o-table "$DADA_TABLE" \
  --o-denoising-stats "$DADA_STATS" \
  --p-n-threads "$CORE_NR" \
  --verbose

echo "Visualizing DADA2 results..."
qiime feature-table summarize \
  --i-table "$DADA_TABLE" \
  --o-visualization "$DADA_TABLE_VIZ"

# Task 2: Remove rare features 
echo "Filtering rare features..."

qiime feature-table filter-features \
  --i-table "$DADA_TABLE" \
  --p-min-frequency "$MINIMUM_FEATURE_FREQUENCY" \
  --o-filtered-table "$DADA_TABLE"

qiime feature-table filter-seqs \
  --i-data "$DADA_FILE" \
  --i-table "$DADA_TABLE" \
  --o-filtered-data "$DADA_FILE"

# Task 3: Remove contaminants
echo "Identifying contaminants..."
qiime quality-control decontam-identify \
  --i-table "$DADA_TABLE" \
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
  --i-table "$DADA_TABLE" \
  --i-rep-seqs "$DADA_FILE" \
  --p-threshold 0.1 \
  --o-filtered-table "$DADA_TABLE_DECONT" \
  --o-filtered-rep-seqs "$DADA_FILE_DECONT" \
  --verbose

qiime quality-control decontam-score-viz \
  --i-decontam-scores "$DECONTAMINATION_SCORES" \
  --i-table "$DADA_TABLE" \
  --i-rep-seqs "$DADA_FILE" \
  --p-threshold 0.1 \
  --p-no-weighted \
  --p-bin-size 0.05 \
  --o-visualization "$DECONTAMINATION_SCORES_VIZ" \
  --verbose 

# Task 4: Visualize filtered results (before chimera removal)
echo "Visualizing filtered results..."
qiime feature-table summarize \
  --i-table "$DADA_TABLE_DECONT" \
  --o-visualization "$DADA_TABLE_VIZ_FILT" \
  # --m-sample-metadata-file "$METADATA"

qiime feature-table tabulate-seqs \
  --i-data "$DADA_FILE_DECONT" \
  --o-visualization "$DADA_VIZ_FILT"

qiime metadata tabulate \
  --m-input-file "$DADA_STATS" \
  --o-visualization "$DADA_STATS_VIZ_FILT"

# https://forum.qiime2.org/t/dada2-merging-plates-and-chimera-removal/21030/4

# Task 5: Chimera detection and removal
echo "Detecting and removing chimeras..."
qiime vsearch uchime-denovo \
  --i-table "$DADA_TABLE_DECONT" \
  --i-sequences "$DADA_FILE_DECONT" \
  --o-chimeras "$CHIMERA_DIR/chimeras.qza" \
  --o-nonchimeras "$CHIMERA_DIR/nonchimeras.qza" \
  --o-stats "$CHIMERA_DIR/stats.qza" \
  --verbose

# Visualize the chimera stats
qiime metadata tabulate \
  --m-input-file "$CHIMERA_DIR/stats.qza" \
  --o-visualization "$CHIMERA_DIR/stats.qzv"

# Task 6: Filter features and sequences
echo "Filtering features and sequences..."
qiime feature-table filter-features \
  --i-table "$DADA_TABLE_DECONT" \
  --m-metadata-file "$CHIMERA_DIR/nonchimeras.qza" \
  --o-filtered-table "$NOCHIMERA_TABLE"

qiime feature-table filter-seqs \
  --i-data "$DADA_FILE_DECONT" \
  --m-metadata-file "$CHIMERA_DIR/nonchimeras.qza" \
  --o-filtered-data "$NOCHIMERA_SEQS"

qiime feature-table summarize \
  --i-table "$NOCHIMERA_TABLE" \
  --o-visualization "$NOCHIMERA_VIZ"



echo "DADA2 analysis completed successfully."



