# nextflow run main.nf \
#     -profile singularity \
#     --input /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/sample_sheet_for_runs.csv \
#     --outdir /data/scratch/LAB/temp_demultiplex/20241025_WGS39_Vuscan_ND_RN \
#     -resume


# TESTING
nextflow run main.nf \
    -profile singularity \
    --input /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/sample_sheet_for_testing.csv \
    --outdir /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sgalera/nfcore_demultiplex/example \
    -resume