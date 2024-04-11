process INTEROP{
    tag "interop"
    label "process_single"
    debug true

    conda "interop"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/illumina-interop:1.3.1--hdbdd923_0':
        'biocontainers/illumina-interop:1.3.1--hdbdd923_0'}"

    input:
    tuple val(meta), path(output_directory)

    output:
    tuple val(meta), path("*.csv")       , emit: "interop_index_summary_report"

    script:
    """
    echo $meta
    echo $output_directory
    cp $output_directory/Reports/IndexMetricsOut.bin $output_directory/InterOp
    cp $output_directory/Reports/RunInfo.xml $output_directory

    interop_index_summary_report $output_directory --csv=1 > interop_index_summary_report.csv
    """
}
