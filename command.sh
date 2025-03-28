nextflow run /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/main.nf \
    -profile singularity \
    --input /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/sample_sheet_for_runs.csv \
    --outdir /data/scratch/LAB/temp_demultiplex/20250321_16S_Ibone \
    -resume

# # SYNTAX
# nextflow run /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/main.nf \
#     -profile singularity \
#     --input /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/sample_sheet_for_syntax.csv \
#     --outdir /data/scratch/LAB/temp_demultiplex/20241219_Syntax_example \
#     -resume


# # # TESTING
# nextflow run main.nf \
#     -profile singularity \
#     --input /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/sample_sheet_for_testing.csv \
#     --outdir /data/scratch/LAB/temp_demultiplex/20241219_Syntax_2 \
#     -resume
