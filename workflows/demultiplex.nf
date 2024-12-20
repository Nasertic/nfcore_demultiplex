/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.fromPath("$projectDir/assets/custom_multiqc_config.yaml", checkIfExists: true)
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.fromPath("$projectDir/assets/LogoNasertic.png", checkIfExists: true)
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { BCL_DEMULTIPLEX           } from '../subworkflows/local/bcl_demultiplex/main'
include { DRAGEN_DEMULTIPLEX        } from '../subworkflows/local/dragen_demultiplex/main'
include { FASTQ_CONTAM_SEQTK_KRAKEN } from '../subworkflows/local/fastq_contam_seqtk_kraken/main'
include { BASES_DEMULTIPLEX         } from '../subworkflows/local/bases_demultiplex/main'
include { FQTK_DEMULTIPLEX          } from '../subworkflows/local/fqtk_demultiplex/main'
include { SINGULAR_DEMULTIPLEX      } from '../subworkflows/local/singular_demultiplex/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS   } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { FASTP                         } from '../modules/nf-core/fastp/main'
include { FALCO                         } from '../modules/nf-core/falco/main'
include { KRAKEN2_KRAKEN2               } from '../modules/nf-core/kraken2/kraken2/main'
include { FASTQ_SCREEN                  } from '../modules/local/fastq_screen/main'
include { INTEROP                       } from '../modules/local/interop/main'
include { MULTIQC                       } from '../modules/nf-core/multiqc/main'
include { UNTAR                         } from '../modules/nf-core/untar/main'
include { CP2SCRATCH                    } from '../modules/local/cp2scratch/main'
include { MD5SUM                        } from '../modules/nf-core/md5sum/main'
include { KRAKENTOOLS_KREPORT2KRONA     } from '../modules/nf-core/krakentools/kreport2krona/main'
include { KRONA_KTIMPORTTEXT            } from '../modules/nf-core/krona/ktimporttext/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow DEMULTIPLEX {
    // Value inputs
    demultiplexer           = params.demultiplexer                                      // string: bases2fastq, bcl2fastq, bclconvert, fqtk, sgdemux, dragen
    trim_fastq              = params.trim_fastq                                         // boolean: true, false
    skip_tools              = params.skip_tools ? params.skip_tools.split(',') : []     // list: [falco, fastp, multiqc]
    sample_size             = params.kraken_sample_size                                 // int
    kraken_db               = params.kraken_db                                          // path
    fastq_screen_config     = params.fastq_screen_config                                // path
    fastq_screen_subset     = params.fastq_screen_subset                                // int
    save_output_fastqs      = params.save_output_fastqs                                 // boolean: true, false
    save_reads_assignment   = params.save_reads_assignment                              // boolean: true, false

    // Channel inputs
    ch_input                = file(params.input)
    ch_versions             = Channel.empty()
    ch_multiqc_files        = Channel.empty()
    ch_output_folders       = Channel.empty()
    ch_demultiplex_folder   = Channel.empty()

    // Sanitize inputs and separate input types
    // FQTK's input contains an extra column 'per_flowcell_manifest' so it is handled seperately
    // For reference:
    //      https://raw.githubusercontent.com/nf-core/test-datasets/demultiplex/samplesheet/1.3.0/fqtk-samplesheet.csv VS
    //      https://raw.githubusercontent.com/nf-core/test-datasets/demultiplex/samplesheet/1.3.0/sgdemux-samplesheet.csv
    if (demultiplexer == 'fqtk'){
        ch_inputs = extract_csv_fqtk(ch_input)
        ch_inputs.dump(tag: 'DEMULTIPLEX::inputs',{FormattingService.prettyFormat(it)})

        // Split flowcells into separate channels containg run as tar and run as path
        // https://nextflow.slack.com/archives/C02T98A23U7/p1650963988498929
        ch_flowcells = ch_inputs
            .branch { meta, samplesheet, run, manifest ->
                tar: run.toString().endsWith('.tar.gz')
                dir: true
            }

        ch_flowcells_tar = ch_flowcells.tar
            .multiMap { meta, samplesheet, run, manifest ->
                samplesheets: [ meta, samplesheet, manifest ]
                run_dirs: [ meta, run ]
            }
    } else {
        ch_inputs = extract_csv(ch_input)
        ch_inputs.dump(tag: 'DEMULTIPLEX::inputs',{FormattingService.prettyFormat(it)})

        // Split flowcells into separate channels containg run as tar and run as path
        // https://nextflow.slack.com/archives/C02T98A23U7/p1650963988498929
        ch_flowcells = ch_inputs
            .branch { meta, samplesheet, run ->
                tar: run.toString().endsWith('.tar.gz') || run.toString().startsWith('/data/medper/LAB/')
                dir: true
            }

        ch_flowcells_tar = ch_flowcells.tar
            .multiMap { meta, samplesheet, run ->
                samplesheets: [ meta, samplesheet ]
                run_dirs: [ meta, run ]
            }
    }

    // MODULE: CP2SCRATCH
    // Runs when run_dir is in /data/medper/LAB/ directory
    // Only for bclconvert and bcl2fastq
    // Re-join the metadata and the copied run directory with the samplesheet

    if (demultiplexer in ['bclconvert', 'bcl2fastq'] )
        ch_flowcells_tar_merged = ch_flowcells_tar.samplesheets.join( CP2SCRATCH (ch_flowcells_tar.run_dirs).cp2scratch, failOnMismatch:true, failOnDuplicate:true)
      //ch_versions = ch_versions.mix(CP2SCRATCH.out.versions)
    else {
        ch_flowcells_tar_merged = ch_flowcells_tar.samplesheets.join( ch_flowcells_tar.run_dirs , failOnMismatch:true, failOnDuplicate:true )
    }

    // Merge the two channels back together
    ch_flowcells = ch_flowcells.dir.mix(ch_flowcells_tar_merged)

    // RUN demultiplexing
    //
    ch_raw_fastq = Channel.empty()

    switch (demultiplexer) {
        case 'bases2fastq':
            // MODULE: bases2fastq
            // Runs when "demultiplexer" is set to "bases2fastq"
            BASES_DEMULTIPLEX ( ch_flowcells )
            ch_raw_fastq = ch_raw_fastq.mix(BASES_DEMULTIPLEX.out.fastq)
            // TODO: verify that this is the correct output
            ch_multiqc_files = ch_multiqc_files.mix(BASES_DEMULTIPLEX.out.metrics.map { meta, metrics -> return metrics} )
            ch_versions = ch_versions.mix(BASES_DEMULTIPLEX.out.versions)
            break
        case ['bcl2fastq', 'bclconvert']:
            // SUBWORKFLOW: illumina
            // Runs when "demultiplexer" is set to "bclconvert", "bcl2fastq"
            BCL_DEMULTIPLEX(ch_flowcells, demultiplexer )
            ch_raw_fastq = ch_raw_fastq.mix( BCL_DEMULTIPLEX.out.fastq )
            ch_multiqc_files = ch_multiqc_files.mix( BCL_DEMULTIPLEX.out.reports.map { meta, report -> return report} )
            ch_multiqc_files = ch_multiqc_files.mix( BCL_DEMULTIPLEX.out.stats.map   { meta, stats  -> return stats } )
            ch_versions = ch_versions.mix(BCL_DEMULTIPLEX.out.versions)
            ch_output_folders = ch_output_folders.mix(BCL_DEMULTIPLEX.out.output_folder)
            break

        case 'dragen':
            DRAGEN_DEMULTIPLEX( ch_flowcells, demultiplexer )
            ch_raw_fastq            = ch_raw_fastq.mix( DRAGEN_DEMULTIPLEX.out.fastq )
            ch_multiqc_files        = ch_multiqc_files.mix( DRAGEN_DEMULTIPLEX.out.reports.map { meta, report -> return report} )
            ch_multiqc_files        = ch_multiqc_files.mix( DRAGEN_DEMULTIPLEX.out.stats.map   { meta, stats  -> return stats } )
            ch_demultiplex_folder   = DRAGEN_DEMULTIPLEX.out.stats
            ch_versions             = ch_versions.mix(DRAGEN_DEMULTIPLEX.out.versions)
            break

        case 'fqtk':
            // MODULE: fqtk
            // Runs when "demultiplexer" is set to "fqtk"

            // Collect fastqs and read structures from field 2 of ch_flowcells
            fastq_read_structure = ch_flowcells.map{it[2]}
                .splitCsv(header:true)
                .map{[it.fastq, it.read_structure]}

            // Combine the directory containing the fastq with the fastq name and read structure
            // [example_R1.fastq.gz, 150T, ./work/98/30bc..78y/fastqs/]
            fastqs_with_paths = fastq_read_structure.combine(UNTAR.out.untar.collect{it[1]}).toList()

            // Format ch_input like so:
            // [[meta:id], <path to sample names and barcodes in tsv: path>, [<fastq name: string>, <read structure: string>, <path to fastqs: path>]]]
            ch_input = ch_flowcells.merge( fastqs_with_paths ) { a,b -> tuple(a, a[1], b)}

            FQTK_DEMULTIPLEX ( ch_input )
            ch_raw_fastq = ch_raw_fastq.mix(FQTK_DEMULTIPLEX.out.fastq)
            ch_multiqc_files = ch_multiqc_files.mix(FQTK_DEMULTIPLEX.out.metrics.map { meta, metrics -> return metrics} )
            ch_versions = ch_versions.mix(FQTK_DEMULTIPLEX.out.versions)
            break
        case 'sgdemux':
            // MODULE: sgdemux
            // Runs when "demultiplexer" is set to "sgdemux"
            SINGULAR_DEMULTIPLEX ( ch_flowcells )
            ch_raw_fastq = ch_raw_fastq.mix(SINGULAR_DEMULTIPLEX.out.fastq)
            ch_multiqc_files = ch_multiqc_files.mix(SINGULAR_DEMULTIPLEX.out.metrics.map { meta, metrics -> return metrics} )
            ch_versions = ch_versions.mix(SINGULAR_DEMULTIPLEX.out.versions)
            break
        default:
            error "Unknown demultiplexer: ${demultiplexer}"
    }
    ch_raw_fastq.dump(tag: "DEMULTIPLEX::Demultiplexed Fastq",{FormattingService.prettyFormat(it)})

    //
    // RUN QC and TRIMMING
    //

    ch_fastq_to_qc = ch_raw_fastq

    // MODULE: illumina-interop if dragen is selected
    if (!("interop" in skip_tools) && demultiplexer in ['dragen']) {
        INTEROP(
            DRAGEN_DEMULTIPLEX.out.stats
        )
    }

    // MODULE: fastp
    if (!("fastp" in skip_tools)){
        FASTP(ch_raw_fastq, [], [], [])
        ch_multiqc_files = ch_multiqc_files.mix( FASTP.out.json.map { meta, json -> return json} )
        ch_versions = ch_versions.mix(FASTP.out.versions)
        if (trim_fastq) {
            ch_fastq_to_qc = FASTP.out.reads
        }
    }

    // MODULE: falco, drop in replacement for fastqc
    if (!("falco" in skip_tools)){
        FALCO(ch_fastq_to_qc)
        ch_multiqc_files = ch_multiqc_files.mix( FALCO.out.txt.map { meta, txt -> return txt} )
        ch_versions = ch_versions.mix(FALCO.out.versions)
    }

    // MODULE: md5sum
    // Split file list into separate channels entries and generate a checksum for each
    MD5SUM(ch_fastq_to_qc.transpose())

    // SUBWORKFLOW: FASTQ_CONTAM_SEQTK_KRAKEN
    if (kraken_db && !("kraken" in skip_tools)){
        FASTQ_CONTAM_SEQTK_KRAKEN(
            ch_fastq_to_qc,
            [sample_size],  kraken_db
        )
        ch_versions = ch_versions.mix(FASTQ_CONTAM_SEQTK_KRAKEN.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix( FASTQ_CONTAM_SEQTK_KRAKEN.out.reports.map { meta, log -> return log })
    }

    // MODULE: fastq_screen // kraken excluding
    if (!("fastq_screen" in skip_tools)){
        FASTQ_SCREEN(
            ch_fastq_to_qc,
            fastq_screen_config,
            fastq_screen_subset
        )
        ch_multiqc_files = ch_multiqc_files.mix( FASTQ_SCREEN.out.fastq_screen_txt_report.map { meta, txt -> return txt} )
        ch_versions = ch_versions.mix(FASTQ_SCREEN.out.versions)
    }


    // DUMP SOFTWARE VERSIONS
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )


    // MODULE: MultiQC
    if (!("multiqc" in skip_tools)){
        workflow_summary    = WorkflowDemultiplex.paramsSummaryMultiqc(workflow, summary_params)
        ch_workflow_summary = Channel.value(workflow_summary)

        methods_description    = WorkflowDemultiplex.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
        ch_methods_description = Channel.value(methods_description)


        ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
        ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
        ch_multiqc_files.collect().dump(tag: "DEMULTIPLEX::MultiQC files",{FormattingService.prettyFormat(it)})

        ch_run_title        = ch_flowcells.map{it[0]['id']}                       // Title of the run
        ch_run_comment      = ch_flowcells.map{it[0]['multiqc_commentary']}       // Multiqc commentary of the run
        ch_run_client       = ch_flowcells.map { it[0]['client'] ?: "No client information" }

        MULTIQC (
            ch_multiqc_files.collect(),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList(),
            ch_run_title,
            ch_run_comment,
            ch_run_client
        )
        multiqc_report = MULTIQC.out.report.toList()
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

workflow.onError {
    if (workflow.errorReport.contains("Process requirement exceeds available memory")) {
        println("🛑 Default resources exceed availability 🛑 ")
        println("💡 See here on how to configure pipeline: https://nf-co.re/docs/usage/configuration#tuning-workflow-resources 💡")
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Extract information (meta data + file(s)) from csv file(s)
def extract_csv(input_csv, input_schema=null) {

    // Flowcell Sheet schema
    // Possible values for the "content" column: [meta, path, number, string, bool]
    if(input_schema == null){
        def default_input_schema = [
            'columns': [
                'id': [
                    'content': 'meta',
                    'meta_name': 'id',
                    'pattern': '',
                ],
                'samplesheet': [
                    'content': 'path',
                    'pattern': '^.*.csv$',
                ],
                'lane': [
                    'content': 'meta',
                    'meta_name': 'lane',
                    'pattern': '',
                ],
                'flowcell': [
                    'content': 'path',
                    'pattern': '',
                ],
            ],
            required: ['id','flowcell', 'samplesheet'],
        ]
        input_schema = default_input_schema
    }
    // Don't change these variables
    def row_count = 1
    def all_columns = input_schema.columns.keySet().collect()
    def mandatory_columns = input_schema.required

    // Header checks
    Channel.value(input_csv).splitCsv(strip:true).first().map({ row ->

        if(row != all_columns) {
            def commons = all_columns.intersect(row)
            def diffs = all_columns.plus(row)
            diffs.removeAll(commons)

            if(diffs.size() > 0){
                def missing_columns = []
                def wrong_columns = []
                for(diff : diffs){
                    diff in all_columns ? missing_columns.add(diff) : wrong_columns.add(diff)
                }
                if(missing_columns.size() > 0){
                    error "[Samplesheet Error] The column(s) $missing_columns is/are not present. The header should look like: $all_columns"
                }
                else {
                    error "[Samplesheet Error] The column(s) $wrong_columns should not be in the header. The header should look like: $all_columns"
                }
            }
            else {
                error "[Samplesheet Error] The columns $row are not in the right order. The header should look like: $all_columns"
            }

        }
    })

    // Field checks + returning the channels
    Channel.value(input_csv).splitCsv(header:true, strip:true).map({ row ->

        row_count++

        // Check the mandatory columns
        def missing_mandatory_columns = []
        for(column : mandatory_columns) {
            row[column] ?: missing_mandatory_columns.add(column)
        }
        if(missing_mandatory_columns.size > 0){
            error "[Samplesheet Error] The mandatory column(s) $missing_mandatory_columns is/are empty on line $row_count"
        }

        def output = []
        def meta = [:]
        def multiqc_commentary = null

        for(col : input_schema.columns) {
            key = col.key
            content = row[key]

            if(key == 'samplesheet'){
                content = content.replace('/data/medper/LAB/', '/mnt/SequencerOutput/')
            }

            if(!(content ==~ col.value['pattern']) && col.value['pattern'] != '' && content != '') {
                error "[Samplesheet Error] The content of column '$key' on line $row_count does not match the pattern '${col.value['pattern']}'"
            }

            if(col.value['content'] == 'path'){
                if (key == "samplesheet"){
                    output.add(file(content))
                    multiqc_commentary = extract_commentary(content)
                    meta['multiqc_commentary'] = multiqc_commentary

                    client_information = extract_client_information(content)
                    meta['client'] = client_information
                } else {
                    output.add(content ? file(content, checkIfExists:true) : col.value['default'] ?: [])
                }
            }
            else if(col.value['content'] == 'meta'){
                for(meta_name : col.value['meta_name'].split(",")){
                    meta[meta_name] = content != '' ? content.replace(' ', '_') : col.value['default'] ?: null
                }
            }
        }

        output.add(0, meta)
        return output
    })
}

// Parse flowcell input map
def parse_flowcell_csv(row) {
    def meta = [:]
    meta.id   = row.id.toString()
    meta.lane = null
    if (row.containsKey("lane") && row.lane ) {
        meta.lane = row.lane.toInteger()
    }

    def flowcell        = file(row.flowcell, checkIfExists: true)
    def samplesheet     = file(row.samplesheet, checkIfExists: true)
    return [meta, samplesheet, flowcell]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS FOR FQTK
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Extract information (meta data + file(s)) from csv file(s)
def extract_csv_fqtk(input_csv) {

    // Flowcell Sheet schema
    // Possible values for the "content" column: [meta, path, number, string, bool]
    def input_schema = [
        'columns': [
            'id': [
                'content': 'meta',
                'meta_name': 'id',
                'pattern': '',
            ],
            'samplesheet': [
                'content': 'path',
                'pattern': '^.*.csv$',
            ],
            'lane': [
                'content': 'meta',
                'meta_name': 'lane',
                'pattern': '',
            ],
            'flowcell': [
                'content': 'path',
                'pattern': '',
            ],
            'per_flowcell_manifest': [
                'content': 'path',
                'pattern': '',
            ]
        ],
        required: ['id','flowcell', 'samplesheet', 'per_flowcell_manifest'],
    ]

    return extract_csv(input_csv, input_schema)
}

def extract_commentary(sample_sheet) {
    sample_sheet = sample_sheet.replace("/mnt/SequencerOutput/", "/data/medper/LAB/")
    def commentary = ""
    def headerSection = false

    new File(sample_sheet).eachLine { line ->
        if (line.startsWith("[Header]")) {
            headerSection = true
        } else if (headerSection && line.startsWith("Description")) {
            // Extraer el comentario hasta el final de la línea
            commentary = line.substring("Description=".length()).trim().replace(",", " ")
            return  // Terminar el bucle una vez que se ha encontrado el comentario
        } else if (headerSection && line.startsWith("[")) {
            headerSection = false  // Salir de la sección de encabezado si se encuentra otra sección
        }
    }

    return commentary
}

def extract_client_information(sample_sheet){
    sample_sheet = sample_sheet.replace("/mnt/SequencerOutput/", "/data/medper/LAB/")
    def client = ""
    def headerSection = false
    new File(sample_sheet).eachLine { line ->
        if (line.startsWith("[Header]")) {
            headerSection = true
        } else if (headerSection && line.startsWith("Investigator Name")) {
            // Extraer el comentario hasta el final de la línea
            client = line.substring("Investigator Name=".length()).trim().replace(",", " ")
            return  // Terminar el bucle una vez que se ha encontrado el comentario
        } else if (headerSection && line.startsWith("[")) {
            headerSection = false  // Salir de la sección de encabezado si se encuentra otra sección
        }
    }
    return client
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
