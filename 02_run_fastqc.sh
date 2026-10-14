#!/bin/bash
#SBATCH --job-name=fastqc_analysis     # Job name
#SBATCH --output=fastqc_analysis_%j.log  # Standard output log (%j is the job ID)
#SBATCH --error=fastqc_analysis_%j.err   # Standard error log
#SBATCH --partition=short                # Partition name (adjust as needed)
#SBATCH --nodes=1                        # Number of nodes
#SBATCH --ntasks=1                       # Number of tasks
#SBATCH --cpus-per-task=4                # Number of CPU cores per task
#SBATCH --mem=16G                        # Memory per node
#SBATCH --time=12:00:00                  # Time limit (hh:mm:ss)

# Load the OpenJDK module required for FastQC
module load OpenJDK/19.0.1

# Load the FastQC module
module load fastqc/0.11.9 

# Directory containing the FASTQ files
FASTQ_DIR="${FASTQ_DIR:-./fastq_files}"
OUTPUT_DIR="${OUTPUT_DIR:-./fastqc_results}"

# Create output directory if it does not exist
mkdir -p "$OUTPUT_DIR"

# Run FastQC on all FASTQ files
fastqc "$FASTQ_DIR"/*.fastq -o "$OUTPUT_DIR" --threads 4

echo "FastQC analysis completed. Results saved in $OUTPUT_DIR"
