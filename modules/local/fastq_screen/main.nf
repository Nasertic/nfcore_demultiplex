process FASTQ_SCREEN{
    tag "fastq_screen"
    label 'process_medium'

    conda "fastq-screen"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastq-screen:0.15.3--pl5321hdfd78af_0':
        'biocontainers/fastq-screen:0.15.3--pl5321hdfd78af_0'}"

    input:
    tuple val(meta), path(reads)
    path config
    val fastq_screen_subset

    output:
    tuple val(meta), path('*screen.html')       , emit: fastq_screen_html_report
    tuple val(meta), path('*screen.txt')        , emit: fastq_screen_txt_report
    tuple val(meta), path('*screen.png')        , emit: fastq_screen_image

    script:
    """
    fastq_screen --threads ${task.cpus} \\
        --subset $fastq_screen_subset \\
        --aligner bowtie2 \\
        --conf $config \\
        $reads \\
        $args \\
        --outdir .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqscreen: \$(echo \$(fastq_screen --version 2>&1) | sed 's/^.*FastQ Screen v//; s/ .*\$//')
    END_VERSIONS
    """
}
