process CP2SCRATCH {
    // debug true //Debugging
    tag "$meta.id"
    executor 'local'
    label 'process_medium'

    input:
    tuple val(meta), path(flow_cell)

    output:
    tuple val(meta), path("$prefix"), emit: cp2scratch //untar
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    prefix    = task.ext.prefix ?: ( meta.id ? "${meta.id}" : archive.baseName.toString().replaceFirst(/\.tar$/, ""))

    """
    mkdir -p $prefix
    cp -rf ${flow_cell}/* $prefix/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cp: \$(echo \$(cp --version 2>&1) | sed 's/^.*(GNU cp) //; s/ Copyright.*\$//')
    END_VERSIONS
    """
}
