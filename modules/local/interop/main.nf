process INTEROP{
    tag "interop"
    label "process_single"

    conda "interop"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/illumina-interop:1.3.1--hdbdd923_0':
        'biocontainers/illumina-interop:1.3.1--hdbdd923_0'}"

    input:
    path(interop_folder)

    output:


    script:
    """
    echo $interop_folder
    """
}
