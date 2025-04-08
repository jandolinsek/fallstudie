"""
Description: This script serves as the driver for the inital part of the amplicon analysis pipeline. 
It calls the necessary functions to perform the pre-processing of the 16S amplicon reads, coordinating
the execution of the pipeline. It creates the necessary directory structure and calls the individual Bash scripts
for raw read processing, OTU calling, and DADA2 analysis.
"""

import os

# Define the directory structure for the analysis
def create_directory_structure(base_dir):
    """
    Creates a subdirectory structure under the specified base directory.
    
    Args:
    base_dir (str): The base directory where the subdirectory structure will be created.
    
    Directory Structure:
    base_dir/
    ├── 00_scripts/
    ├── 01_metadata/    
    ├── 02_raw_reads/
    ├── 03_reads/
    ├── 04_import/    
    ├── 05_OTUs/
    │   ├── chimera/
    ├── 06_sOTUs/
    │   ├── chimera/
    ├── 07_ASVs/
    │   ├── chimera/
    ├── 08_classifier/
    ├── 11_analysis_OTUs/
    │   ├── taxonomy/
    │   ├── diversity/
    │   ├── phylogeny/
    ├── 12_analysis_sOTUs/
    │   ├── taxonomy/
    │   ├── diversity/
    │   ├── phylogeny/
    ├── 13_analysis_ASVs/
    │   ├── taxonomy/
    │   ├── diversity/ 
    │   ├── phylogeny/

   """

    # Define the directory structure
    directories = [

        os.path.join(base_dir, '03_reads'),
        os.path.join(base_dir, '04_import'),
        os.path.join(base_dir, '05_OTUs'),
        os.path.join(base_dir, '05_OTUs', 'chimeras'),
        os.path.join(base_dir, '06_sOTUs'),
        os.path.join(base_dir, '06_sOTUs', 'chimeras'),
        os.path.join(base_dir, '07_ASVs'),
        os.path.join(base_dir, '07_ASVs', 'chimeras'),
        os.path.join(base_dir, '08_classifier'),
        os.path.join(base_dir, '11_analysis_OTUs'),
        os.path.join(base_dir, '11_analysis_OTUs', 'taxonomy'),
        # os.path.join(base_dir, '11_analysis_OTUs', 'diversity'), # this directory is (and must be) created in analysis
        os.path.join(base_dir, '11_analysis_OTUs', 'phylogeny'),
        os.path.join(base_dir, '12_analysis_sOTUs'),
        os.path.join(base_dir, '12_analysis_sOTUs', 'taxonomy'),
        # os.path.join(base_dir, '12_analysis_sOTUs', 'diversity'), # this directory is (and must be) created in analysis
        os.path.join(base_dir, '12_analysis_sOTUs', 'phylogeny'),
        os.path.join(base_dir, '13_analysis_ASVs'),
        os.path.join(base_dir, '13_analysis_ASVs', 'taxonomy'),
        # os.path.join(base_dir, '13_analysis_ASVs', 'diversity'), # this directory is (and must be) created in analysis
        os.path.join(base_dir, '13_analysis_ASVs', 'phylogeny'),

    ]

    # Create the directories
    for directory in directories:
        try:
            os.makedirs(directory, exist_ok=True)
            print(f"Created directory: {directory}")
        except Exception as e:
            print(f"Error creating directory {directory}: {e}")


# Step 1: Create the directory structure
base_directory = os.getcwd()
create_directory_structure(base_directory)
print("Creating directory structure...")

# Step 2: Define the paths to the Bash scripts
raw_read_processing = os.path.join(base_directory, "00_scripts/raw_read_processing.sh")
otu_calling_script = os.path.join(base_directory, "00_scripts/clustering_otu.sh")
sotu_calling_script = os.path.join(base_directory, "00_scripts/clustering_sotu.sh")
asv_calling_script = os.path.join(base_directory, "00_scripts/clustering_asv.sh")
otu_analysis_script = os.path.join(base_directory, "00_scripts/composition_analysis_otu.sh")
sotu_analysis_script = os.path.join(base_directory, "00_scripts/composition_analysis_sotu.sh")
asv_analysis_script = os.path.join(base_directory, "00_scripts/composition_analysis_asv.sh")
tree_building_script = os.path.join(base_directory, "00_scripts/tree_ASVs.sh")

# Step 3: Execute the Bash scripts sequentially
def run_script(script_path):
    print(f"Running script: {script_path}")
    exit_code = os.system(f"bash {script_path}")
    if exit_code != 0:
        print(f"Error: Script {script_path} failed with exit code {exit_code}.")
        exit(1)

# Run the raw read processing script
run_script(raw_read_processing)

# Run the OTU calling script
run_script(otu_calling_script)

# Run the sOTU calling script
run_script(sotu_calling_script)

# Run the DADA2 analysis script
run_script(asv_calling_script)

# Run the ASV composition analysis script
run_script(otu_analysis_script)

# Run the ASV composition analysis script
run_script(sotu_analysis_script)

# Run the ASV composition analysis script
run_script(asv_analysis_script)

# Run the tree building script
run_script(tree_building_script)

print("Pipeline execution completed successfully. Maybe...")

