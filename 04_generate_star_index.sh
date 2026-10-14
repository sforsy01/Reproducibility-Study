#!/bin/bash

#SBATCH --job-name=star_genome_generate          # Job name
#SBATCH --ntasks=1                               # Number of tasks (1 task for STAR indexing)
#SBATCH --cpus-per-task=8                        # Number of CPU cores per task 
#SBATCH --mem=64G                                # Memory allocation  
#SBATCH --time=24:00:00                          # Time limit 
#SBATCH --output=star_genome_generate_%j.out     # Output log file
#SBATCH --error=star_genome_generate_%j.err      # Error log file

# Load the STAR module 
module load star/2.7.3a

# Define directories and files
GENOME_DIR="${GENOME_DIR:-./star_index}"  # Directory for STAR index
FASTA_FILES="${FASTA_FILES:-./GCF_014441545.1/GCF_014441545.1_ROS_Cfam_1.0_genomic.fna}"  # Path to FASTA file
GTF_FILE="${GTF_FILE:-./GCF_014441545.1/genomic.gtf}"  # Path to GTF file
THREADS="${SLURM_CPUS_PER_TASK:-8}"

mkdir -p "$GENOME_DIR"

# Run STAR genomeGenerate command
STAR --runMode genomeGenerate \
     --genomeDir "$GENOME_DIR" \
     --genomeFastaFiles "$FASTA_FILES" \
     --sjdbGTFfile "$GTF_FILE" \
     --runThreadN "$THREADS"

echo "STAR genome indexing completed."
