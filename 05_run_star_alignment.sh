#!/bin/bash

#SBATCH --job-name=star_alignment           # Job name
#SBATCH --ntasks=1                          # Number of cores
#SBATCH --cpus-per-task=8                   # Number of CPUs per task
#SBATCH --time=24:00:00                     # Runtime 
#SBATCH --mem=64G                           # Memory per node
#SBATCH --output=star_%j.out                # Standard output log
#SBATCH --error=star_%j.err                 # Standard error log

# Load the STAR module (STAR 2.7.3a)
module load star/2.7.3a

# Define directories
TRIMMED_DIR="${TRIMMED_DIR:-./trimmed_output}"         # Directory with single-end trimmed FASTQ files
OUTPUT_DIR="${OUTPUT_DIR:-./star_alignment_output}"    # Directory to store the output BAM files
GENOME_DIR="${GENOME_DIR:-./star_index}"           # STAR genome index directory (indexed using ROS-canfam-01)
THREADS="${SLURM_CPUS_PER_TASK:-8}"

# Make output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Loop through all trimmed FASTQ files
for R1 in $TRIMMED_DIR/*_trimmed.fastq; do
    # Get the base name of the sample (remove directory and file extension)
    BASE=$(basename $R1 _trimmed.fastq)
    
    echo "Processing single-end sample: $BASE"
    
    # Run STAR for single-end reads
    STAR --runThreadN $THREADS \
         --genomeDir $GENOME_DIR \
         --readFilesIn $R1 \
         --outFileNamePrefix $OUTPUT_DIR/${BASE}_ \
         --outSAMtype BAM SortedByCoordinate \
         --outSAMunmapped Within \
         --quantMode TranscriptomeSAM GeneCounts \
         --twopassMode Basic
done

echo "STAR alignment completed."
