# Initial setup
# Run in HPC
# mamba create -c conda-forge -c bioconda -c defaults --name nf_core_2023 python nextflow nf-core singularity python-keycloak

# Locate file

# cd /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/

# Load modules and activate conda environment
ml purge
module use --append /opt/shared/modules/all/
module use --append /software/shared/modules/all
# conda activate nf_core
module load singularity/3.4.1
#conda activate nf_core_2023
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

nextflow run main.nf -profile test_dragen,singularity -c hpc.conf

# Real data NovaSeq
# nextflow run nfcore_demultiplex/main.nf \
#    -profile singularity \
#    --input samplesheet_NovaSeq.csv \
#    --outdir /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/test_nfcore_NovaSeq \
#    --demultiplexer 'bcl2fastq' \
#    -c /data/scratch/LAB/temp_demultiplex/nfcore_demultiplex/mansego/nfcore_demultiplex/demultiplex.conf \
#    #-resume
