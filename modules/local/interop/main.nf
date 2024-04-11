process INTEROP{
    tag "interop"
    label "process_single"
    debug true

    conda "interop"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/illumina-interop:1.3.1--hdbdd923_0':
        'biocontainers/illumina-interop:1.3.1--hdbdd923_0'}"

    input:
    tuple val(meta), path(reads)
    path(interop_folder)

    output:
    tuple val(meta), path("*.csv")              , emit: "interop_index_summary_report"
    path "versions.yml"                         , emit: versions

    script:
    """
    echo $interop_folder
    cp $interop_folder/Reports/IndexMetricsOut.bin $interop_folder/InterOp
    cp $interop_folder/Reports/RunInfo.xml $interop_folder

    interop_index-summary $interop_folder --csv=1 > interop_index_summary_report.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqscreen: \$(echo \$(interop_index-summary 2>&1) | sed 's/^.# Version: v//; s/ .*\$//')
    END_VERSIONS
    """
}
