#!/bin/bash
# filepath: /home/jan/fs_sh/raw_read_processing.sh

# Description: Script for raw read processing in the amplicon analysis pipeline.

# Set the number of cores
CORE_NR=8

# define file paths and copy files
BASE_DIRECTORY="/home/jan/fs_sh"
SOURCE_DIR="$BASE_DIRECTORY/02_raw_reads"
DATA_DIR="$BASE_DIRECTORY/03_reads"
MANIFEST_FILE="$BASE_DIRECTORY/01_metadata/fs_manifest.txt"
OUTPUT_FILE_IMPORT="$BASE_DIRECTORY/04_import/paired-end-demux.qza"
OUTPUT_FILE_DEMUX_VIZ="$BASE_DIRECTORY/04_import/paired-end-demux.qzv"
JOINED_FILE="$BASE_DIRECTORY/04_import/joined.qza"
UNJOINED_FILE="$BASE_DIRECTORY/04_import/unjoined.qza"
JOINED_FILE_VIZ="$BASE_DIRECTORY/04_import/joined.qzv"
FILTERED_FILE="$BASE_DIRECTORY/04_import/joined-filtered.qza"
FILTERED_FILE_STATS="$BASE_DIRECTORY/04_import/joined-filtered-stats.qza"

# Task 1: Copy raw reads to the data directory
echo "Copying raw reads to the data directory..."
cp "$SOURCE_DIR"/*.gz "$DATA_DIR"

# Task 2: Import data into Qiime2
echo "Importing data into Qiime2..."

cd ~/fs_sh

qiime tools import \
  --type SampleData[PairedEndSequencesWithQuality] \
  --input-path "$MANIFEST_FILE" \
  --output-path "$OUTPUT_FILE_IMPORT" \
  --input-format PairedEndFastqManifestPhred33V2

# Task 3: Visualize the imported data
echo "Visualizing data import..."
qiime demux summarize \
  --i-data "$OUTPUT_FILE_IMPORT" \
  --o-visualization "$OUTPUT_FILE_DEMUX_VIZ"

# Task 4: Merge read pairs
echo "Merging read pairs..."
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs "$OUTPUT_FILE_IMPORT" \
  --o-merged-sequences "$JOINED_FILE" \
  --o-unmerged-sequences "$UNJOINED_FILE" \
  --p-minovlen 20 \
  --p-threads "$CORE_NR" \
  --verbose

qiime demux summarize \
  --i-data "$JOINED_FILE" \
  --o-visualization "$JOINED_FILE_VIZ" 

# Task 5: Quality control
echo "Performing quality control..."
qiime quality-filter q-score \
  --i-demux "$JOINED_FILE" \
  --o-filtered-sequences "$FILTERED_FILE" \
  --o-filter-stats "$FILTERED_FILE_STATS" \
  --p-min-quality 30 \
  --verbose

echo "Raw read processing completed."