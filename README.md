# Canine Soft Tissue Sarcoma RNA-seq Pipeline

A reproducible RNA-seq workflow (SRA download through a gene count matrix) for a published canine soft tissue sarcoma dataset. Written as a bash and Python pipeline for a SLURM-based HPC cluster. Developed as coursework for a graduate bioinformatics course.

## Source data

Reads are from the study:

Lam, L., Tien, T., Wildung, M., White, L., Sellon, R. K., Fidel, J. L., & Shelden, E. A. (2022). Comparative whole transcriptome analysis of gene expression in three canine soft tissue sarcoma types. *PLOS ONE, 17*(9), e0273705. https://doi.org/10.1371/journal.pone.0273705

- Species: dog (*Canis lupus familiaris*)
- Data: public RNA-seq runs from NCBI SRA, accessions SRR20327004 to SRR20327037 (34 runs listed in `01_get_data_convert_to_fastq.sh`)
- BioProject: PRJNA860583
- Sequencing platform: Ion Torrent Proton (GEO platform GPL27923). The pipeline treats reads as **single-end**, which is the standard layout for Ion Torrent data.
- Reference genome: NCBI RefSeq GCF_014441545.1 (ROS_Cfam_1.0), with the matching annotation

This repository contains code only. No data, alignments, or count matrices are included.

## Pipeline overview

| Step | Script | Tool | Output |
|------|--------|------|--------|
| 1 | `01_get_data_convert_to_fastq.sh` | SRA Toolkit (`prefetch`, `fasterq-dump`) | `fastq_files/` |
| 2 | `02_run_fastqc.sh` | FastQC | `fastqc_results/` |
| 3 | `03_run_trimgalore.sh` | Trim Galore (Cutadapt) | `trimmed_output/` |
| 4 | `04_generate_star_index.sh` | STAR (`genomeGenerate`) | `star_index/` |
| 5 | `05_run_star_alignment.sh` | STAR (two-pass) | `star_alignment_output/` |
| 6 | `06_run_htseq.sh` | HTSeq (`htseq-count`) | `output_counts/` |
| 7 | `07_combine_files.py` | Python (pandas) | `combined_counts.csv` |
| 8 | `08_reorder_columns.py` | Python (pandas) | `reordered_combined_counts.csv` |

Run the steps in order. Step 4 only needs to be run once per genome.

## Requirements

Versions below are those used on the original cluster.

- SLURM scheduler (the `#SBATCH` headers can be removed to run locally)
- SRA Toolkit 3.0.2
- FastQC 0.11.9 and Java (OpenJDK 19)
- Trim Galore and Cutadapt
- STAR 2.7.3a
- HTSeq
- Python 3 with `pandas`
- Anaconda/Miniconda (steps 3 and 6 activate a conda environment)

Module names such as `star/2.7.3a` are specific to the original cluster. On another system, install the tools yourself (for example with conda/bioconda) and remove or edit the `module load` lines.

Example conda environment:

```bash
conda create -n rnaseq_env -c conda-forge -c bioconda trim-galore cutadapt htseq pandas
```

## Reference genome

Download the genome FASTA and annotation for GCF_014441545.1 from NCBI Datasets (https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_014441545.1/), include the GTF annotation, and place them in a folder named `GCF_014441545.1/` containing:

- `GCF_014441545.1_ROS_Cfam_1.0_genomic.fna`
- `genomic.gtf`

## Configuring paths

No absolute paths are stored in the scripts. Each script uses a relative default that can be overridden with an environment variable when you submit the job.

| Variable | Used in | Default |
|----------|---------|---------|
| `OUTPUT_DIR` | steps 1, 2, 3, 5, 6 | step-specific folder (see table above) |
| `FASTQ_DIR` | step 2 | `./fastq_files` |
| `INPUT_DIR` | step 3 | `./fastq_files` |
| `TRIMMED_DIR` | step 5 | `./trimmed_output` |
| `GENOME_DIR` | steps 4, 5 | `./star_index` |
| `FASTA_FILES`, `GTF_FILE` | step 4 | `./GCF_014441545.1/...` |
| `BAM_DIR`, `GTF_FILE` | step 6 | `./star_alignment_output`, `./GCF_014441545.1/genomic.gtf` |
| `CONDA_ENV` | steps 3, 6 | `trim_galore_env` |

Example with custom locations:

```bash
OUTPUT_DIR=/path/to/fastq_files sbatch 01_get_data_convert_to_fastq.sh
CONDA_ENV=rnaseq_env INPUT_DIR=/path/to/fastq_files OUTPUT_DIR=/path/to/trimmed sbatch 03_run_trimgalore.sh
```

Run the scripts from the repository root so the relative defaults resolve.

## Running the pipeline

```bash
sbatch 01_get_data_convert_to_fastq.sh
sbatch 02_run_fastqc.sh
sbatch 03_run_trimgalore.sh
sbatch 04_generate_star_index.sh
sbatch 05_run_star_alignment.sh
sbatch 06_run_htseq.sh

# Steps 7 and 8 run on a login node or locally
python 07_combine_files.py --counts-dir output_counts --out-file combined_counts.csv
python 08_reorder_columns.py --in-file combined_counts.csv --out-file reordered_combined_counts.csv
```

Submit each step after the previous one finishes (or chain them with `sbatch --dependency=afterok:<jobid>`).

## Notes and assumptions

- **Single-end reads.** Steps 3 and 5 assume one FASTQ file per run. Confirm the library layout in the SRA metadata before reusing this on other data.
- **Ion Torrent data.** Read lengths vary, and the dominant error type is indels in homopolymers rather than substitutions. STAR is splice-aware and was built for short Illumina reads, but it runs on Ion Torrent data. Count accuracy in homopolymer-rich regions may be affected.
- **Trimming limitation.** Trimming did not perform well in this analysis. Ion Torrent instruments run vendor software (Torrent Suite) that produces its own quality control reports and trims adapters during basecalling. It is unclear whether the FASTQ files deposited in SRA for this project went through that trimming. The Ion Torrent adapter sequences used for these libraries were not shared by the authors, so they could not be supplied to Trim Galore, which auto-detects Illumina adapters and may find none in Ion Torrent reads. Step 3 therefore applies only quality and length filtering (`--quality 20 --length 30`) and should not be assumed to remove adapters. Results from this step should be interpreted with that in mind. STAR soft-clips unaligned read ends during alignment, which limits the effect of any residual adapter sequence on gene counts.
- **Strandedness.** `htseq-count` is run with `-s no` (unstranded). Check the `*_ReadsPerGene.out.tab` files from STAR to confirm this suits the library.
- **Counting.** Counts are gene-level, from exon features grouped by `gene_id`. HTSeq summary rows (`__no_feature`, `__ambiguous`, etc.) are removed in step 7.
- **Sample names.** Step 7 names columns by SRA run accession. Step 8 expects the sample names used in the original study (for example `S1-02-T1`). A mapping from run accession to sample name (from the SRA metadata) must be applied between these steps.
- **Genome and annotation.** STAR 2.7.3a with the RefSeq ROS_Cfam_1.0 assembly.

## Repository layout

```
.
├── 01_get_data_convert_to_fastq.sh
├── 02_run_fastqc.sh
├── 03_run_trimgalore.sh
├── 04_generate_star_index.sh
├── 05_run_star_alignment.sh
├── 06_run_htseq.sh
├── 07_combine_files.py
├── 08_reorder_columns.py
├── README.md
└── .gitignore
```

## Not included (see `.gitignore`)

FASTQ files, FastQC reports, trimmed reads, genome files, STAR indexes, BAM files, count tables, SLURM logs.

## Author

Sara Forsythe, M.S. Candidate in Bioinformatics, Northeastern University
