#!/bin/bash
#SBATCH --job-name=trim_galore_all     # Job name
#SBATCH --output=trim_galore_all_%j.log  # Output log file (%j will be replaced by job ID)
#SBATCH --error=trim_galore_all_%j.err   # Error log file
#SBATCH --partition=short               # Partition (adjust based on your HPC)
#SBATCH --nodes=1                       # Number of nodes
#SBATCH --ntasks=1                      # Number of tasks
#SBATCH --cpus-per-task=4               # Number of CPU cores per task
#SBATCH --mem=16G                       # Memory per node
#SBATCH --time=12:00:00                 # Time limit hrs:min:sec (adjust as needed)

# Load Anaconda
module load anaconda3/2022.05

# Activate your environment
CONDA_ENV="${CONDA_ENV:-trim_galore_env}"
eval "$(conda shell.bash hook)"
conda activate "$CONDA_ENV"

# Define paths
INPUT_DIR="${INPUT_DIR:-./fastq_files}"
OUTPUT_DIR="${OUTPUT_DIR:-/trimmed_output}"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop over all FASTQ files and run Trim Galore on each
for file in "$INPUT_DIR"/*.fastq; do
    echo "Processing $file"
    trim_galore --quality 20 --length 30 --fastqc --path_to_cutadapt $(which cutadapt) --output_dir "$OUTPUT_DIR" "$file"
done

echo "Trimming completed for all files. Results are saved in $OUTPUT_DIR"

# Deactivate the Conda environment after the job completes
conda deactivate
