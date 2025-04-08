#!/bin/bash
# filepath: /home/jan/fs_sh/otu_calling.sh

# Description: Script for OTU calling in the amplicon analysis pipeline.

# Set the number of cores
CORE_NR=8

# Define file paths
BASE_DIRECTORY="/home/jan/fs_sh"
FILTERED_FILE="$BASE_DIRECTORY/04_import/joined-filtered.qza"
DEREPLICATED_TABLE="$BASE_DIRECTORY/05_OTUs/dereplicated-table.qza"
DEREPLICATED_FILE="$BASE_DIRECTORY/05_OTUs/dereplicated-sequences.qza"
CLUSTERED_TABLE="$BASE_DIRECTORY/05_OTUs/clustered-table.qza"
CLUSTERED_FILE="$BASE_DIRECTORY/05_OTUs/clustered-sequences.qza"
CLUSTERED_TABLE_VIZ="$BASE_DIRECTORY/05_OTUs/clustered-table.qzv"
DECONTAMINATION_SCORES="$BASE_DIRECTORY/05_OTUs/decontam-scores.qza"
DECONTAMINATION_SCORES_VIZ="$BASE_DIRECTORY/05_OTUs/decontam-scores.qzv"
TABLE_DECONT="$BASE_DIRECTORY/05_OTUs/filtered-clustered-table.qza"
FILE_DECONT="$BASE_DIRECTORY/05_OTUs/filtered-clustered-sequences.qza"
VIZ_FILT="$BASE_DIRECTORY/05_OTUs/filtered-clustered-sequences.qzv"
TABLE_VIZ_FILT="$BASE_DIRECTORY/05_OTUs/filtered-clustered-table.qzv"
CHIMERA_DIR="$BASE_DIRECTORY/05_OTUs/chimeras"
NOCHIMERA_TABLE="$BASE_DIRECTORY/05_OTUs/nochimera-table.qza"
NOCHIMERA_SEQS="$BASE_DIRECTORY/05_OTUs/nochimera-sequences.qza"
NOCHIMERA_VIZ="$BASE_DIRECTORY/05_OTUs/nochimera-table.qzv"
METADATA_CTRL="$BASE_DIRECTORY/01_metadata/eotrh_meta_ctrl.txt"
METADATA="$BASE_DIRECTORY/01_metadata/eotrh_meta.txt"

# Set the percent/fraction identity for clustering
IDENTITY=0.99

# Set the minimum feature frequency for filtering
MINIMUM_FEATURE_FREQUENCY=30


# Task 1: Dereplicate sequences
echo "Dereplicating sequences..."
qiime vsearch dereplicate-sequences \
  --i-sequences "$FILTERED_FILE" \
  --o-dereplicated-table "$DEREPLICATED_TABLE" \
  --o-dereplicated-sequences "$DEREPLICATED_FILE" \
  --verbose

# Task 2: Cluster features de novo
echo "Clustering features de novo..."
qiime vsearch cluster-features-de-novo \
  --i-table "$DEREPLICATED_TABLE" \
  --i-sequences "$DEREPLICATED_FILE" \
  --p-perc-identity "$IDENTITY" \
  --o-clustered-table "$CLUSTERED_TABLE" \
  --o-clustered-sequences "$CLUSTERED_FILE" \
  --p-threads "$CORE_NR" \
  --verbose

qiime feature-table summarize \
  --i-table "$CLUSTERED_TABLE" \
  --o-visualization "$CLUSTERED_TABLE_VIZ"

# Task 3: Remove rare features 
echo "Filtering rare features..."

qiime feature-table filter-features \
  --i-table "$CLUSTERED_TABLE" \
  --p-min-frequency "$MINIMUM_FEATURE_FREQUENCY" \
  --o-filtered-table "$CLUSTERED_TABLE"

qiime feature-table filter-seqs \
  --i-data "$CLUSTERED_FILE" \
  --i-table "$CLUSTERED_TABLE" \
  --o-filtered-data "$CLUSTERED_FILE"


# Task 4: Remove contaminants
echo "Identifying contaminants..."
qiime quality-control decontam-identify \
  --i-table "$CLUSTERED_TABLE" \
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
  --i-table "$CLUSTERED_TABLE" \
  --i-rep-seqs "$CLUSTERED_FILE" \
  --p-threshold 0.1 \
  --o-filtered-table "$TABLE_DECONT" \
  --o-filtered-rep-seqs "$FILE_DECONT" \
  --verbose

qiime quality-control decontam-score-viz \
  --i-decontam-scores "$DECONTAMINATION_SCORES" \
  --i-table "$CLUSTERED_TABLE" \
  --i-rep-seqs "$CLUSTERED_FILE" \
  --p-threshold 0.1 \
  --p-no-weighted \
  --p-bin-size 0.05 \
  --o-visualization "$DECONTAMINATION_SCORES_VIZ" \
  --verbose 


# Task 5: Visualize filtered results (before chimera removal)
echo "Visualizing filtered results..."
qiime feature-table summarize \
  --i-table "$TABLE_DECONT" \
  --o-visualization "$TABLE_VIZ_FILT" \


qiime feature-table tabulate-seqs \
  --i-data "$FILE_DECONT" \
  --o-visualization "$VIZ_FILT"


# Task 6: Chimera detection and removal
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


# Task 7: Filter features and sequences
echo "Filtering features and sequences..."

qiime feature-table filter-features \
  --i-table "$TABLE_DECONT" \
  --m-metadata-file "$CHIMERA_DIR/nonchimeras.qza" \
  --o-filtered-table "$NOCHIMERA_TABLE" \
 
qiime feature-table filter-seqs \
  --i-data "$FILE_DECONT" \
  --m-metadata-file "$CHIMERA_DIR/nonchimeras.qza" \
  --o-filtered-data "$NOCHIMERA_SEQS" \
  --verbose
  
qiime feature-table summarize \
  --i-table "$NOCHIMERA_TABLE" \
  --o-visualization "$NOCHIMERA_VIZ"

echo "OTU calling completed."