This repository provides scripts and metadata for horse oral microbiome analysis, a part of the bio data science master study at the FHWN. Download the entire
directory structure with the files and run read_analysis.py. 

All scripts require an activated conda environment with the QIIME 2 2024.10 Amplicon Distribution installed. Environment is also stored in folder 00-scripts. 

Before running the pipeline, train the classifier with the feat_classifier_silva_2025.sh script. 

I.	read_analysis.py – the driver script setting the directory structure and calling scripts below in the correct order.

II.	raw_read_processing.sh – imports raw data into qiime and does first read processing for OUT calling.

III.	clustering_otu.sh – clusters imported reads into OTUs, removes contaminations detected in negative control and removes chimeras.

IV.	clustering_sotu.sh - clusters imported reads into sOTUs, removes contaminations detected in negative control and removes chimeras.

V.	clustering_asv.sh - clusters imported reads into ASVs, removes contaminations detected in negative control and removes chimeras.

VI.	composition_analysis_otu.sh – performs the ecological analysis of the calculated OTUs.

VII.	composition_analysis_sotu.sh - performs the ecological analysis of the calculated sOTUs.

VIII.	composition_analysis_asv.sh - performs the ecological analysis of the calculated ASVs.

IX.	tree_ASVs_empress.sh – an optional script for tree visualization if one decides to use the empress tool for tree visualization.
