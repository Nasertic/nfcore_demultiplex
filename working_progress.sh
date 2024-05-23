# Initial setup
# Run in HPC
# mamba create -c conda-forge -c bioconda -c defaults --name nf_core_2023 python nextflow nf-core singularity python-keycloak

# Locate file

# cd /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/

# Load modules and activate conda environment
ml purge
module use --append /opt/shared/modules/all/
module use --append /software/shared/modules/all
conda activate nf_core_2023
module load singularity/3.4.1

# Test 1 run from nf_core/demultiplex

#nextflow run nf-core/demultiplex \
#    -profile test,singularity \
#    --outdir test_nf_core \
#    -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/demultiplex.conf

# Test 2  run from nfcore_demultiplex/main.nf
# nextflow run nfcore_demultiplex/main.nf \
#    -profile test,singularity \
#    --outdir test_nf_core_fork \
#    -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/demultiplex.conf

## Test 3 Full test https://github.com/nf-core/demultiplex/tree/1.4.1/conf/test_full.config


# nextflow run nf-core/demultiplex -profile test_full,singularity --outdir test_nf_core_full -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/demultiplex.conf

# nextflow run nf-core/demultiplex --input ./tests/iSeq/samplesheet_iSeq.csv --outdir ./results -profile singularity --demultiplexer 'bcl2fastq' -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf

# Real data iSeq
# nextflow run main.nf \
#     -profile singularity \
#     --input /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/iSeq/samplesheet_iSeq.csv \
#     --outdir /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/iSeq/results/ \
#     --demultiplexer 'bcl2fastq' \
#     -c hpc.conf \
     #-resume

nextflow run main.nf -profile test_dragen,singularity -c hpc.conf --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results'
nextflow run main.nf \
        -profile test_dragen,singularity \
        -c hpc.conf --outdir 'tests/results/save_output_fastqs' \
        --skip_tools 'fastq_screen' \
        --save_output_fastqs \
        --sample_size 1000 \
        --demultiplexer 'bases2fastq'

nextflow run main.nf \
        -profile test_dragen,singularity \
        -c hpc.conf --outdir './tests/results_bcl_iSeq' \
        --demultiplexer 'bclconvert' \
        --skip_tools 'fastp,falco,fastq_screen,kraken'

nextflow run main.nf \
        -profile test_dragen,singularity \
        -c hpc.conf --outdir './tests/results_bcl_iSeq' \
        --input './assets/sample_sheet_NovaSeq_split_real.csv' \
        --demultiplexer 'bclconvert' \
        --skip_tools 'fastp,falco,fastq_screen,kraken'

nextflow run main.nf \
        -profile test_dragen,singularity \
        -c hpc.conf --outdir './tests/results/' \
        --demultiplexer 'bclconvert' \
        --skip_tools 'fastp,falco,fastq_screen,kraken'

    nextflow run main.nf \
        -profile test_dragen,singularity \
        -c hpc.conf --outdir './tests/results/' \
        --demultiplexer 'bcl2fastq' \
        --skip_tools 'fastp,falco,fastq_screen,kraken'

#Incluir lane=5


#Otra samplesheet de iSeq

/data/medper/LAB/iSeq/Runs_iSeq/20230719_FS10001385_16_BTR67709-2111

#nextflow run main.nf -profile test_dragen,singularity -c hpc.conf --NovaSeq --split


# Real data iSeq
# nextflow run main.nf  \
#    -profile singularity \
#    --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sample_sheet.csv' \
#    --outdir  '/data/scratch/LAB/temp_demultiplex/to_delete/to_delete_no_split' \
#    --demultiplexer 'dragen' \
#    -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf \
#    --sample_size 1000 \
#    --kraken_db '/data/scratch/LAB/references/dbkraken2/k2_standard_20240112'
#    #-resume

# Real data NovaSeq
nextflow run main.nf  \
    -profile singularity \
    --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/sample_sheet_NovaSeq.csv' \
    --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/to_delete/results_NovaSeq' \
    --demultiplexer 'dragen' \
    -c '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf' \
    --sample_size 1000 \
    --kraken_db '/data/scratch/LAB/references/dbkraken2/k2_standard_20240112'
#    #-resume

# Real data iSeq .tar.gz
# nextflow run main.nf  \
#    -profile singularity \
#    --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/sample_sheet_tar.gz.csv' \
#    --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results_iSeq_tar' \
#    --demultiplexer 'dragen' \
#     -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf \
#     --sample_size 10000 \
#     --kraken_db '/data/scratch/LAB/references/dbkraken2/k2_standard_20240112'
#    #-resume

# Real data iSeq con dbkraken2 (8Gb)
nextflow run main.nf  \
    -profile singularity \
    --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/assets/sample_sheet.csv' \
    --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results_bcl2fastq_kraken' \
    --demultiplexer 'bcl2fastq' \
    -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf \
    --sample_size 1000 \
    --kraken_db '/data/scratch/LAB/references/dbkraken2/k2_standard_8Gb_20240112' \
    --skip_tools 'fastp,falco,fastq_screen,interop'
#    #-resume


nextflow run main.nf \
    -profile singularity   \
    --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/assets/sample_sheet.csv'   \
    --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results_krona'  \
    --demultiplexer 'bcl2fastq'     -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf    \
    --sample_size 1000     --kraken_db '/data/scratch/LAB/references/dbkraken2/k2_standard_16_20240112/' \
    --skip_tools 'fastq_screen,interop' -resume --save_output_fastqs --save_reads_assignment --run_kraken2


nextflow run main.nf \
    -profile singularity   \
    --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/assets/sample_sheet.csv'   \
    --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results_sintar'  \
    --demultiplexer 'bcl2fastq'     -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf    \
    --skip_tools 'fastp,falco,kraken,fastq_screen,interop'

nextflow run main.nf \
    -profile singularity   \
    --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/assets/sample_sheet2.csv'   \
    --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results_sintar'  \
    --demultiplexer 'bcl2fastq'     -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf    \
    --skip_tools 'fastp,falco,kraken,fastq_screen,interop'

nextflow run main.nf -profile singularity --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/assets/sample_sheet2.csv'  --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results_sintar_bcl2fastq_local'      --demultiplexer 'bcl2fastq'     -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf  --skip_tools 'fastp,falco,kraken,fastq_screen,interop'

nextflow run main.nf -profile singularity --input '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/assets/sample_sheet_NovaSeq.csv'  --outdir '/data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/tests/results_sintar_bcl2fastq_NovaSeq'      --demultiplexer 'bcl2fastq'     -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/hpc.conf  --skip_tools 'fastp,falco,kraken,fastq_screen,interop'
