#!/bin/bash
# Description: This script performs composition analysis on ASVs using Qiime2.
# It includes tasks such as taxonomic classification, phylogenetic tree generation,
# diversity metrics, and statistical analysis.

# Set the number of cores
CORE_NR=4

# Define base directory
BASE_DIRECTORY="/home/jan/fs_sh"

# Define base directory for this analysis
BASE_DIRECTORY_SPECIFIC="/home/jan/fs_sh/13_analysis_ASVs"
SOURCE_DIRECTORY_SPECIFIC="/home/jan/fs_sh/07_ASVs"

# Define file paths

# Define metadata file paths
METADATA_NO_CTRL="$BASE_DIRECTORY/01_metadata/eotrh_meta_no_ctrl.txt"
METADATA_PK="$BASE_DIRECTORY/01_metadata/eotrh_meta_PK.txt"

# Define file paths for taxonomic classification 
CLASSIFIER="$BASE_DIRECTORY/08_classifier/v3-v4-classifier.qza"
CLASSIFICATION_OUTPUT="$BASE_DIRECTORY_SPECIFIC/taxonomy/taxonomy.qza"
CLASSIFICATION_OUTPUT_VIZ="$BASE_DIRECTORY_SPECIFIC/taxonomy/taxonomy.qzv"
CLASSIFICATION_OUTPUT_TABLE="$BASE_DIRECTORY_SPECIFIC/taxonomy/taxonomy_table.qzv"

# Define file paths for phylogenetic tree and diversity metrics
TABLE="$SOURCE_DIRECTORY_SPECIFIC/nochimera-table.qza"
FILE="$SOURCE_DIRECTORY_SPECIFIC/nochimera-sequences.qza"

TABLE_NO_CTRL="$BASE_DIRECTORY_SPECIFIC/filtered-table_no_ctrl.qza"
TABLE_PK="$BASE_DIRECTORY_SPECIFIC/filtered-table_PK.qza"

FILE_NO_CTRL="$BASE_DIRECTORY_SPECIFIC/filtered-representative-sequences_no_ctrl.qza"
FILE_PK="$BASE_DIRECTORY_SPECIFIC/filtered-representative-sequences_PK.qza"

ALIGNMENT="$BASE_DIRECTORY_SPECIFIC/phylogeny/alignment.qza"
MASKED_ALIGNMENT="$BASE_DIRECTORY_SPECIFIC/phylogeny/masked_alignment.qza"
TREE="$BASE_DIRECTORY_SPECIFIC/phylogeny/tree.qza"
ROOTED_TREE="$BASE_DIRECTORY_SPECIFIC/phylogeny/rooted_tree.qza"

CORE_METRICS_OUTPUT_DIR="$BASE_DIRECTORY_SPECIFIC/diversity"

SAMPLING_DEPTH=10000


# Task 0: Filter samples based on metadata
echo "Filtering samples based on metadata..."
qiime feature-table filter-samples \
  --i-table "$TABLE" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-filtered-table "$TABLE_NO_CTRL" \
  --verbose

qiime feature-table filter-samples \
  --i-table "$TABLE" \
  --m-metadata-file "$METADATA_PK" \
  --o-filtered-table "$TABLE_PK" \
  --verbose

# Task 0b: Filter sequences based on filtered tables
echo "Filtering sequences based on filtered tables..."
qiime feature-table filter-seqs \
  --i-data "$FILE" \
  --i-table "$TABLE_NO_CTRL" \
  --o-filtered-data "$FILE_NO_CTRL" \
  --verbose

qiime feature-table filter-seqs \
  --i-data "$FILE" \
  --i-table "$TABLE_PK" \
  --o-filtered-data "$FILE_PK" \
  --verbose


# Task 1: Taxonomic classification
echo "Performing taxonomic classification..."
qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER" \
  --i-reads "$FILE_NO_CTRL" \
  --o-classification "$CLASSIFICATION_OUTPUT" \
  --p-n-jobs "$CORE_NR" \
  --verbose

qiime metadata tabulate \
  --m-input-file "$CLASSIFICATION_OUTPUT" \
  --o-visualization "$CLASSIFICATION_OUTPUT_VIZ"

qiime feature-table tabulate-seqs \
  --i-data "$FILE_NO_CTRL" \
  --o-visualization "$CLASSIFICATION_OUTPUT_TABLE"

# Task 2: Phylogenetic tree generation
echo "Generating phylogenetic tree..."
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences "$FILE_NO_CTRL" \
  --o-alignment "$ALIGNMENT" \
  --o-masked-alignment "$MASKED_ALIGNMENT" \
  --o-tree "$TREE" \
  --o-rooted-tree "$ROOTED_TREE" \
  --verbose

# Task 3: Diversity core metrics
echo "Calculating diversity core metrics..."
qiime diversity core-metrics-phylogenetic \
  --i-table "$TABLE_NO_CTRL" \
  --i-phylogeny "$ROOTED_TREE" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --output-dir "$CORE_METRICS_OUTPUT_DIR" \
  --p-sampling-depth "$SAMPLING_DEPTH" \
  --p-n-jobs-or-threads "$CORE_NR" \
  --verbose
  
# Task 4: Export the taxonomic classification
echo "Exporting the taxonomic classification..."
qiime feature-table tabulate-seqs \
  --i-data "$FILE_NO_CTRL" \
  --i-taxonomy "$CLASSIFICATION_OUTPUT" \
  --o-visualization "$CLASSIFICATION_OUTPUT_TABLE_VIZ" \
  --verbose

# Task 5: Statistics on alpha diversity
echo "Calculating alpha diversity rarefaction..."
qiime diversity alpha-rarefaction \
  --i-table "$TABLE_NO_CTRL" \
  --p-max-depth "$SAMPLING_DEPTH" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/alpha_rarefaction.qzv" \
  --verbose

qiime diversity alpha-group-significance \
  --i-alpha-diversity "$CORE_METRICS_OUTPUT_DIR/shannon_vector.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/shannon_significance.qzv" \
  --verbose

qiime diversity alpha-group-significance \
  --i-alpha-diversity "$CORE_METRICS_OUTPUT_DIR/evenness_vector.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/evenness_significance.qzv" \
  --verbose

qiime diversity alpha-group-significance \
  --i-alpha-diversity "$CORE_METRICS_OUTPUT_DIR/faith_pd_vector.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/faith_pd_significance.qzv" \
  --verbose

qiime longitudinal anova \
  --m-metadata-file "$CORE_METRICS_OUTPUT_DIR/shannon_vector.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --p-formula 'shannon_entropy ~ type * disease' \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/shannon_anova.qzv" \
  --verbose

# Task 6: Statistics on beta diversity
echo "Calculating beta diversity statistics..."

qiime diversity beta-rarefaction \
    --i-table "$TABLE_NO_CTRL" \
    --i-phylogeny "$ROOTED_TREE" \
    --p-metric "braycurtis" \
    --p-clustering-method "nj" \
    --m-metadata-file "$METADATA_NO_CTRL" \
    --o-visualization "$CORE_METRICS_OUTPUT_DIR/beta_rarefaction.qzv" \
    --p-sampling-depth "$SAMPLING_DEPTH" \
    --verbose

qiime diversity adonis \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/permanova_unweighted_unifrac_type.qzv" \
  --p-formula "type" \
  --p-n-jobs "$CORE_NR" \
  --verbose

qiime diversity adonis \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/permanova_weighted_unifrac_type.qzv" \
  --p-formula "type" \
  --p-n-jobs "$CORE_NR" \
  --verbose

qiime diversity adonis \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/permanova_unweighted_unifrac_disease.qzv" \
  --p-formula "disease" \
  --p-n-jobs "$CORE_NR" \
  --verbose

qiime diversity adonis \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/permanova_weighted_unifrac_disease.qzv" \
  --p-formula "disease" \
  --p-n-jobs "$CORE_NR" \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "disease" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_disease_significance_permdisp.qzv" \
  --p-method "permdisp" \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "disease" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_disease_significance_permdisp.qzv" \
  --p-method "permdisp" \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "type" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_type_significance_permdisp.qzv" \
  --p-method "permdisp" \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "type" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_type_significance_permdisp.qzv" \
  --p-method "permdisp" \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "disease" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_disease_significance_pairwise.qzv" \
  --p-pairwise \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "disease" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_disease_significance_pairwise.qzv" \
  --p-pairwise \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "type" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/unweighted_unifrac_type_significance_pairwise.qzv" \
  --p-pairwise \
  --verbose

qiime diversity beta-group-significance \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_distance_matrix.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --m-metadata-column "type" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/weighted_unifrac_type_significance_pairwise.qzv" \
  --p-pairwise \
  --verbose

# Task 7: Biplot & Friends

# Generate heatmap
qiime feature-table heatmap \
  --i-table "$CORE_METRICS_OUTPUT_DIR/rarefied_table.qza" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/rarefied_table.qzv" \
  --verbose

# Generate PCoA biplot
qiime feature-table relative-frequency \
  --i-table "$CORE_METRICS_OUTPUT_DIR/rarefied_table.qza" \
  --o-relative-frequency-table "$CORE_METRICS_OUTPUT_DIR/rarefied_table_relative.qza"

qiime diversity pcoa-biplot \
  --i-pcoa "$CORE_METRICS_OUTPUT_DIR/bray_curtis_pcoa_results.qza" \
  --i-features "$CORE_METRICS_OUTPUT_DIR/rarefied_table_relative.qza" \
  --o-biplot "$CORE_METRICS_OUTPUT_DIR/bray_curtis_pcoa_results_biplot.qza" \
  --verbose

# Visualize biplot with Emperor
qiime emperor biplot \
  --i-biplot "$CORE_METRICS_OUTPUT_DIR/bray_curtis_pcoa_results_biplot.qza" \
  --m-sample-metadata-file "$METADATA_NO_CTRL" \
  --m-feature-metadata-file "$CLASSIFICATION_OUTPUT" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/bray_curtis_pcoa_biplot.qzv" \
  --p-number-of-features 8 \
  --verbose

  
# Task 8: t-SNE
echo "Generating t-SNE visualizations..."
qiime diversity tsne \
  --i-distance-matrix "$CORE_METRICS_OUTPUT_DIR/bray_curtis_distance_matrix.qza" \
  --o-tsne "$CORE_METRICS_OUTPUT_DIR/tsne.qza" \
  --p-perplexity 3 \
  --p-random-state 42 \
  --verbose

qiime emperor plot \
  --i-pcoa "$CORE_METRICS_OUTPUT_DIR/tsne.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$CORE_METRICS_OUTPUT_DIR/tsne.qzv" \
  --verbose

# Task 9: Barplots
echo "Generating barplots..."

# Filter samples and generate barplots for no control
qiime feature-table filter-samples \
  --i-table "$TABLE_NO_CTRL" \
  --p-min-frequency 50 \
  --o-filtered-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_filtered.qza" \
  --verbose

qiime taxa barplot \
  --i-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_filtered.qza" \
  --i-taxonomy "$CLASSIFICATION_OUTPUT" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --o-visualization "$BASE_DIRECTORY_SPECIFIC/taxonomy/taxa_barplot.qzv" \
  --verbose

# Filter samples and generate barplots for PK
qiime feature-table filter-samples \
  --i-table "$TABLE_PK" \
  --p-min-frequency 1 \
  --o-filtered-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_filtered_PK.qza" \
  --verbose

qiime taxa barplot \
  --i-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_filtered_PK.qza" \
  --i-taxonomy "$CLASSIFICATION_OUTPUT" \
  --m-metadata-file "$METADATA_PK" \
  --o-visualization "$BASE_DIRECTORY_SPECIFIC/taxonomy/taxa_barplot_PK.qzv" \
  --verbose

echo "Biplot, t-SNE, and barplot tasks completed."



# Task 10: ANCOM
echo "Running ANCOM analysis..."

# Collapse taxonomy to genus level
qiime taxa collapse \
  --i-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_filtered.qza" \
  --i-taxonomy "$CLASSIFICATION_OUTPUT" \
  --p-level 6 \
  --o-collapsed-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/genus.qza" \
  --verbose

# Filter features
qiime feature-table filter-features \
  --i-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/genus.qza" \
  --p-min-frequency 50 \
  --p-min-samples 4 \
  --o-filtered-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_abund.qza" \
  --verbose

# Run ANCOM-BC for disease
qiime composition ancombc \
  --i-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_abund.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --p-formula "disease" \
  --o-differentials "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_disease.qza" \
  --verbose

# Generate barplot for disease
qiime composition da-barplot \
  --i-data "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_disease.qza" \
  --p-significance-threshold 0.05 \
  --o-visualization "$BASE_DIRECTORY_SPECIFIC/taxonomy/da_barplot_disease.qzv" \
  --p-level-delimiter ";" \
  --verbose

# Run ANCOM-BC for type
qiime composition ancombc \
  --i-table "$BASE_DIRECTORY_SPECIFIC/taxonomy/table_abund.qza" \
  --m-metadata-file "$METADATA_NO_CTRL" \
  --p-formula "type" \
  --o-differentials "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_type.qza" \
  --verbose

# Generate barplot for type
qiime composition da-barplot \
  --i-data "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_type.qza" \
  --p-significance-threshold 0.05 \
  --o-visualization "$BASE_DIRECTORY_SPECIFIC/taxonomy/da_barplot_type.qzv" \
  --p-level-delimiter ";" \
  --verbose

# Tabulate results for disease
qiime composition tabulate \
  --i-data "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_disease.qza" \
  --o-visualization "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_disease_table.qzv" \
  --verbose

# Tabulate results for type
qiime composition tabulate \
  --i-data "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_type.qza" \
  --o-visualization "$BASE_DIRECTORY_SPECIFIC/taxonomy/ancombc_type_table.qzv" \
  --verbose

echo "ANCOM analysis completed."


