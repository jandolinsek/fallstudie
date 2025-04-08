#!/bin/bash
# Description: Bash script for generating a phylogenetic tree and visualizing it using Empress.

# Set variables
CORE_NR=4
BASE_DIRECTORY="/home/jan/fs_sh"

# Define base directory for this analysis
BASE_DIRECTORY="/home/jan/fs_sh"
BASE_DIRECTORY_SPECIFIC="/home/jan/fs_sh/13_analysis_ASVs"
SOURCE_DIRECTORY_SPECIFIC="/home/jan/fs_sh/07_ASVs"

TABLE="$SOURCE_DIRECTORY_SPECIFIC/nochimera-table.qza"
FILE="$SOURCE_DIRECTORY_SPECIFIC/nochimera-sequences.qza"
TABLE_NO_CTRL="$BASE_DIRECTORY_SPECIFIC/phylogeny/nochimera-table_no_ctrl.qza"
FILE_NO_CTRL="$BASE_DIRECTORY_SPECIFIC/phylogeny/nochimera-sequences_no_ctrl.qza"
TABLE_NO_CTRL_CLASSIFIED="$BASE_DIRECTORY_SPECIFIC/taxonomy/nochimera-table_no_ctrl_classified.qza"
FILE_NO_CTRL_CLASSIFIED="$BASE_DIRECTORY_SPECIFIC/taxonomy/nochimera-sequences_no_ctrl_classified.qza"
TABLE_NO_CTRL_BACTERIA="$BASE_DIRECTORY_SPECIFIC/taxonomy/nochimera-table_no_ctrl_bacteria.qza"
FILE_NO_CTRL_BACTERIA="$BASE_DIRECTORY_SPECIFIC/taxonomy/nochimera-sequences_no_ctrl_bacteria.qza"

CLASSIFIER="$BASE_DIRECTORY/08_classifier/v3-v4-classifier.qza"
CLASSIFICATION_OUTPUT_ALL="$BASE_DIRECTORY_SPECIFIC/taxonomy/taxonomy_all.qza"
CLASSIFICATION_OUTPUT_CLASSIFIED="$BASE_DIRECTORY_SPECIFIC/taxonomy/taxonomy_classified.qza"
CLASSIFICATION_OUTPUT_BACTERIA="$BASE_DIRECTORY_SPECIFIC/taxonomy/taxonomy_bacteria.qza"

TREE_ALL="$BASE_DIRECTORY_SPECIFIC/phylogeny/tree_all.qza"
ROOTED_TREE_ALL="$BASE_DIRECTORY_SPECIFIC/phylogeny/rooted_tree_all.qza"
TREE_CLASSIFIED="$BASE_DIRECTORY_SPECIFIC/phylogeny/tree_classified.qza"
ROOTED_TREE_CLASSIFIED="$BASE_DIRECTORY_SPECIFIC/phylogeny/rooted_tree_classified.qza"
TREE_BACTERIA="$BASE_DIRECTORY_SPECIFIC/phylogeny/tree_bacteria.qza"
ROOTED_TREE_BACTERIA="$BASE_DIRECTORY_SPECIFIC/phylogeny/rooted_tree_bacteria.qza"

ALIGNMENT_ALL="$BASE_DIRECTORY_SPECIFIC/phylogeny/alignment_all.qza"
MASKED_ALIGNMENT_ALL="$BASE_DIRECTORY_SPECIFIC/phylogeny/masked_alignment_all.qza"
ALIGNMENT_CLASSIFIED="$BASE_DIRECTORY_SPECIFIC/phylogeny/alignment_classified.qza"
MASKED_ALIGNMENT_CLASSIFIED="$BASE_DIRECTORY_SPECIFIC/phylogeny/masked_alignment_classified.qza"
ALIGNMENT_BACTERIA="$BASE_DIRECTORY_SPECIFIC/phylogeny/alignment_bacteria.qza"
MASKED_ALIGNMENT_BACTERIA="$BASE_DIRECTORY_SPECIFIC/phylogeny/masked_alignment_bacteria.qza"

METADATA_NO_CTRL="$BASE_DIRECTORY/01_metadata/eotrh_meta_no_ctrl.txt"

# Diversity core metrics paths
DADA_TABLE="$BASE_DIRECTORY_SPECIFIC/table-dada2-decont.qza"
TREE_VIZ="$BASE_DIRECTORY_SPECIFIC/phylogeny/empress_tree.qzv"

# Metadata file
METADATA="$BASE_DIRECTORY/metadata/metadata.tsv"

# Task: filter out the reads classified only at the domain level (removes long branches) and archaea, comment out if not needed


echo "Generating phylogenetic tree for all sequences..."


qiime feature-table filter-samples \
  --i-table "$TABLE" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-filtered-table "$TABLE_NO_CTRL" \
  --verbose

qiime feature-table filter-seqs \
  --i-data "$FILE" \
  --i-table "$TABLE_NO_CTRL" \
  --o-filtered-data "$FILE_NO_CTRL" \
  --verbose

qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER" \
  --i-reads "$FILE_NO_CTRL" \
  --o-classification "$CLASSIFICATION_OUTPUT_ALL" \
  --p-n-jobs "$CORE_NR" \
  --verbose

  # Collapse taxonomy to genus level
qiime taxa collapse \
  --i-table "$TABLE_NO_CTRL" \
  --i-taxonomy "$CLASSIFICATION_OUTPUT_ALL" \
  --p-level 6 \
  --o-collapsed-table "$BASE_DIRECTORY_SPECIFIC/phylogeny/genus.qza" \
  --verbose

# Filter features
qiime feature-table filter-features \
  --i-table "$BASE_DIRECTORY_SPECIFIC/phylogeny/genus.qza" \
  --o-filtered-table "$BASE_DIRECTORY_SPECIFIC/phylogeny/table_abund.qza" \
  --verbose

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences "$FILE_NO_CTRL" \
  --o-alignment "$ALIGNMENT_ALL" \
  --o-masked-alignment "$MASKED_ALIGNMENT_ALL" \
  --o-tree "$TREE_ALL" \
  --o-rooted-tree "$ROOTED_TREE_ALL" \
  --verbose

# echo "Generating phylogenetic tree for classified sequences only..."

# qiime taxa filter-table \
#     --i-table "$TABLE_NO_CTRL" \
#     --i-taxonomy "$CLASSIFICATION_OUTPUT_ALL" \
#     --p-include "p__" \
#     --p-exclude "k__" \
#     --o-filtered-table "$TABLE_NO_CTRL_CLASSIFIED" \
#     --verbose

# qiime taxa filter-seqs \
#     --i-sequences "$FILE_NO_CTRL" \
#     --i-taxonomy "$CLASSIFICATION_OUTPUT_ALL" \
#     --p-include "p__" \
#     --p-exclude "k__" \
#     --o-filtered-sequences "$FILE_NO_CTRL_CLASSIFIED" \
#     --verbose

# qiime feature-classifier classify-sklearn \
#   --i-classifier "$CLASSIFIER" \
#   --i-reads "$FILE_NO_CTRL_CLASSIFIED" \
#   --o-classification "$CLASSIFICATION_OUTPUT_CLASSIFIED" \
#   --p-n-jobs "$CORE_NR" \
#   --verbose

# qiime phylogeny align-to-tree-mafft-fasttree \
#   --i-sequences "$FILE_NO_CTRL_CLASSIFIED" \
#   --o-alignment "$ALIGNMENT_CLASSIFIED" \
#   --o-masked-alignment "$MASKED_ALIGNMENT_CLASSIFIED" \
#   --o-tree "$TREE_CLASSIFIED" \
#   --o-rooted-tree "$ROOTED_TREE_CLASSIFIED" \
#   --verbose

# echo "Generating phylogenetic tree for classified bacteria only..."

# qiime taxa filter-table \
#     --i-table "$TABLE_NO_CTRL" \
#     --i-taxonomy "$CLASSIFICATION_OUTPUT_BACTERIA" \
#     --p-include "p__" \
#     --p-exclude "k__; ,Archaea" \
#     --o-filtered-table "$TABLE_NO_CTRL_BACTERIA" \
#     --verbose

# qiime taxa filter-seqs \
#     --i-sequences "$FILE_NO_CTRL" \
#     --i-taxonomy "$CLASSIFICATION_OUTPUT" \
#     --p-include "p__" \
#     --p-exclude "k__; ,Archaea" \
#     --o-filtered-sequences "$FILE_NO_CTRL_BACTERIA" \
#     --verbose

# qiime feature-classifier classify-sklearn \
#   --i-classifier "$CLASSIFIER" \
#   --i-reads "$FILE_NO_CTRL_BACTERIA" \
#   --o-classification "$CLASSIFICATION_OUTPUT_BACTERIA" \
#   --p-n-jobs "$CORE_NR" \
#   --verbose



# echo "Phylogenetic tree generation completed successfully."