process BCLCONVERT {
    tag {"${meta.lane == 'all' ? meta.id + '.' + meta.lane : meta.id}" }
    label 'process_high'
    //debug true
    container "nf-core/bclconvert:4.2.7"

    input:
    tuple val(meta), path(samplesheet), path(run_dir)

    output:
    tuple val(meta), path("**_S[1-9]*_R?_00?.fastq.gz")          , emit: fastq
    tuple val(meta), path("**_S[1-9]*_I?_00?.fastq.gz")          , optional:true, emit: fastq_idx
    tuple val(meta), path("**Undetermined_S0*_R?_00?.fastq.gz")  , optional:true, emit: undetermined
    tuple val(meta), path("**Undetermined_S0*_I?_00?.fastq.gz")  , optional:true, emit: undetermined_idx
    tuple val(meta), path("Reports")                             , emit: reports
    tuple val(meta), path("Logs")                                , emit: logs
    tuple val(meta), path("InterOp/*.{bin,xml}")                 , emit: interop
    val(meta)                                                    , emit: demultiplex_folders
    path("versions.yml")                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BCLCONVERT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    //def input_tar = run_dir.toString().endsWith(".tar.gz") ? true : false
    //def input_dir = input_tar ? run_dir.toString() - '.tar.gz' : run_dir
    """
    bcl-convert \\
        $args \\
        --output-directory . \\
        --bcl-input-directory ${run_dir} \\
        --sample-sheet ${samplesheet}

    cp -r ${run_dir}/InterOp ./
    cp -r ${run_dir}/RunInfo.xml ./InterOp/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bclconvert: \$(bcl-convert -V 2>&1 | head -n 1 | sed 's/^.*Version //')
    END_VERSIONS
    """
}
