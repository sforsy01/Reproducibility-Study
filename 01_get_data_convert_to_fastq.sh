#!/bin/bash
#SBATCH --job-name=sra_download_convert    # Job name
#SBATCH --output=sra_download_%j.log       # Standard output log (%j is the job ID)
#SBATCH --error=sra_download_%j.err        # Standard error log
#SBATCH --partition=short                  # Partition name (adjust as needed)
#SBATCH --nodes=1                          # Number of nodes
#SBATCH --ntasks=1                         # Number of tasks
#SBATCH --cpus-per-task=4                  # Number of CPU cores per task
#SBATCH --mem=16G                          # Memory per node
#SBATCH --time=12:00:00                    # Time limit (hh:mm:ss)

# Load the SRA Toolkit module
module load sratoolkit/3.0.2

# Define the output directory for FASTQ files
OUTPUT_DIR="${OUTPUT_DIR:-./fastq_files}"
mkdir -p "$OUTPUT_DIR"

# Array of SRA accessions
accessions=(
    "SRR20327004" "SRR20327005" "SRR20327006" "SRR20327007" "SRR20327008"
    "SRR20327009" "SRR20327010" "SRR20327011" "SRR20327014" "SRR20327017"
    "SRR20327020" "SRR20327023" "SRR20327026" "SRR20327029" "SRR20327032"
    "SRR20327035" "SRR20327012" "SRR20327013" "SRR20327015" "SRR20327016"
    "SRR20327018" "SRR20327019" "SRR20327021" "SRR20327022" "SRR20327024"
    "SRR20327025" "SRR20327027" "SRR20327028" "SRR20327030" "SRR20327031"
    "SRR20327033" "SRR20327034" "SRR20327036" "SRR20327037"
)

# Iterate over each accession
for accession in "${accessions[@]}"; do
    echo "Processing $accession..."

    # Download the SRA file
    prefetch "$accession"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download $accession"
        continue
    fi

    # Convert SRA to FASTQ
    fasterq-dump "$accession" -O "$OUTPUT_DIR" --split-files --threads 4
    if [ $? -ne 0 ]; then
        echo "Error: Failed to convert $accession to FASTQ"
        continue
    fi

    echo "Successfully processed $accession"
done
