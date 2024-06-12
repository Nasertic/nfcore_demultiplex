process INTEROP{
    tag "interop"
    // label "process_single"
    executor "local"
    debug true

    conda "interop"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/illumina-interop:1.3.1--hdbdd923_0':
        'biocontainers/illumina-interop:1.3.1--hdbdd923_0'}"

    input:
    path(interop_folder)
    tuple val(meta), path(interop_metrics)

    output:
    tuple val(meta), path("*index_summary*.csv")                , emit: "interop_index_summary_report"
    path "versions.yml"                                         , emit: versions

    script:
    // Change to channel?
    """
    echo $interop_metrics
    cp $interop_folder/IndexMetricsOut.bin $interop_folder/InterOp
    cp $interop_folder/RunInfo.xml $interop_folder/InterOp
    interop_index-summary $interop_folder/InterOp --csv=1 > interop_index_summary_report.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        illumina-interop: \$(echo \$(interop_index-summary 2>&1) | sed 's/^.# Version: v//; s/ .*\$//')
    END_VERSIONS
    """
}
