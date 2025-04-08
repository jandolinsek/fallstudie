#!/bin/bash
# Description: Bash script for generating a phylogenetic tree and visualizing it using Empress.

# Set variables
CORE_NR=4

# Define base directory for this analysis
BASE_DIRECTORY="/home/jan/fs_sh"
BASE_DIRECTORY_SPECIFIC="/home/jan/fs_sh/13_analysis_ASVs"
SOURCE_DIRECTORY_SPECIFIC="/home/jan/fs_sh/07_ASVs"

TABLE_NO_CTRL="$BASE_DIRECTORY_SPECIFIC/filtered-table_no_ctrl.qza"
FILE_NO_CTRL="$BASE_DIRECTORY_SPECIFIC/filtered-representative-sequences_no_ctrl.qza"

CLASSIFICATION_OUTPUT="$BASE_DIRECTORY_SPECIFIC/taxonomy/taxonomy.qza"

TREE="$BASE_DIRECTORY_SPECIFIC/phylogeny/tree.qza"
ROOTED_TREE="$BASE_DIRECTORY_SPECIFIC/phylogeny/rooted_tree.qza"
EMPRESS_TREE="$BASE_DIRECTORY_SPECIFIC/phylogeny/rooted_tree.qzv"
METADATA_NO_CTRL="$BASE_DIRECTORY/01_metadata/eotrh_meta_no_ctrl.txt"


# Visualize phylogenetic tree with Empress
echo "Visualizing phylogenetic tree with Empress..."
qiime empress community-plot \
  --i-tree "$ROOTED_TREE" \
  --i-feature-table "$TABLE_NO_CTRL" \
  --m-sample-metadata-file "$METADATA_NO_CTRL" \
  --m-feature-metadata-file "$CLASSIFICATION_OUTPUT" \
  --o-visualization "$EMPRESS_TREE" \
  --verbose

echo "Phylogenetic tree generation and visualization completed successfully."