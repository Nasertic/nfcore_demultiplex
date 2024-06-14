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
    tuple val(meta), path(demultiplex_stats_folder)

    output:
    tuple val(meta), path("*index_summary*.csv")                , emit: "interop_index_summary_report"
    path "versions.yml"                                         , emit: versions

    script:
    """
    interop_index-summary $demultiplex_stats_folder/.. --csv=1 > interop_index_summary_report.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        illumina-interop: \$(echo \$(interop_index-summary 2>&1) | sed 's/^.# Version: v//; s/ .*\$//')
    END_VERSIONS
    """
}
