process BCL2FASTQ {
    tag {"${meta.lane == 'all' ? meta.id + '.' + meta.lane : meta.id}" }
    label 'process_high'
    debug true
    stageInMode 'copy'
    
    container "nf-core/bcl2fastq:2.20.0.422"

    input:
    tuple val(meta), path(samplesheet), path(run_dir)

    output:
    tuple val(meta), path("**_S[1-9]*_R?_00?.fastq.gz")          , emit: fastq
    tuple val(meta), path("**_S[1-9]*_I?_00?.fastq.gz")          , optional:true, emit: fastq_idx
    tuple val(meta), path("**Undetermined_S0*_R?_00?.fastq.gz")  , optional:true, emit: undetermined
    tuple val(meta), path("**Undetermined_S0*_I?_00?.fastq.gz")  , optional:true, emit: undetermined_idx
    tuple val(meta), path("Reports")                             , emit: reports
    tuple val(meta), path("Stats")                               , emit: stats
    tuple val(meta), path("InterOp/*.bin")                       , emit: interop
    val(meta)                                                    , emit: demultiplex_folders
    path("versions.yml")                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BCL2FASTQ module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
     // def input_tar = run_dir.toString().endsWith(".tar.gz") ? true : false
     // def input_dir = input_tar ? run_dir.toString() - '.tar.gz' : run_dir
    """

    bcl2fastq \\
        $args \\
        --output-dir . \\
        --runfolder-dir ${run_dir} \\
        --sample-sheet ${samplesheet} \\
        --processing-threads ${task.cpus}

    cp -r ${run_dir}/InterOp ./

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcl2fastq: \$(bcl2fastq -V 2>&1 | grep -m 1 bcl2fastq | sed 's/^.*bcl2fastq v//')
    END_VERSIONS
    """
}
