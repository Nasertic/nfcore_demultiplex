process CSV2TSV {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(sample_sheet), val(fastq_readstructure_pairs)
    // fastq_readstructure_pairs example:
    // [[<fastq name: string>, <read structure: string>, <path to fastqs: path>], [example_R1.fastq.gz, 150T, ./work/98/30bc..78y/fastqs/]]

    output:
    tuple val(meta), path('samplesheet.tsv'), val(fastq_readstructure_pairs), emit: ch_output
    path "versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def version = '4.2.2' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    sed 's/,/\t/g' ${sample_sheet} > samplesheet.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: $version
    END_VERSIONS
    """
