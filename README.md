<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-demultiplex_logo_dark.png">
    <img alt="nf-core/demultiplex" src="docs/images/nf-core-demultiplex_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/demultiplex/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/demultiplex/actions?query=workflow%3A%22nf-core+CI%22)
[![GitHub Actions Linting Status](https://github.com/nf-core/demultiplex/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/demultiplex/actions?query=workflow%3A%22nf-core+linting%22)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/demultiplex/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.7153103-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.7153103)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/demultiplex)
[![nf-test](https://img.shields.io/badge/tested_with-nf--test-337ab7.svg)](https://github.com/askimed/nf-test)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23demultiplex-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/demultiplex)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/demultiplex** is a bioinformatics pipeline used to demultiplex the raw data produced by next generation sequencing machines. The following platforms are supported:

1. Illumina (via `bcl2fastq`, `bclconvert` or `dragen`)
2. Element Biosciences (via `bases2fastq`)
3. Singular Genomics (via [`sgdemux`](https://github.com/Singular-Genomics/singular-demux))
4. FASTQ files with user supplied read structures (via [`fqtk`](https://github.com/fulcrumgenomics/fqtk))

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources.The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/demultiplex/results).

## Pipeline summary

1. Demultiplexing

- [bcl-convert](#bcl-convert) - converting bcl files to fastq, and demultiplexing (CONDITIONAL)
- [bases2fastq](#bases2fastq) - converting bases files to fastq, and demultiplexing (CONDITIONAL)
- [bcl2fastq](#bcl2fastq) - converting bcl files to fastq, and demultiplexing (CONDITIONAL)
- [sgdemux](#sgdemux) - demultiplexing bgzipped fastq files produced by Singular Genomics (CONDITIONAL)
- [fqtk](#fqtk) - a toolkit for working with FASTQ files, written in Rust (CONDITIONAL)

2. [fastp](#fastp) - Adapter and quality trimming
3. [Falco](#falco) - Raw read QC
4. [Fastq screen](#fastq_screen) - Mapping reads to organisms
5. [Kraken](#kraken) - Contamination check
6. [md5sum](#md5sum) - Creates an MD5 (128-bit) checksum of every fastq.
7. [MultiQC](#multiqc) - aggregate report, describing results of the whole pipeline

![subway map](docs/pipeline_image.png)

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

> Minimum steps required to run the pipeline:
> 1. Prepare a samplesheet with your input data.
```csv
id,samplesheet,lane,flowcell
smallest_run_iSeq,./assets/smallest_run_SampleSheet.csv,all,/data/medper/LAB/illumina_iSeq/Runs/20231109_FS10001385_17_BRL95625-0922
```

  - id: Name of the output folder where results are going to be stored
  - samplesheet: Path to the samplesheet
  - lane: Lane to be processed (all for not splitting lanes). Adds up to 8 lanes to the same run
  - flowcell: Path to the flowcell folder (BCL input files)

> 2. Run the pipeline with the following command:
>
```bash
nextflow run main.nf \
 --input ./assets/sample_sheet.csv \
 --outdir /data/scratch/LAB/temp_demultiplex/to_delete_whatever \
 -c hpc.conf
```


> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

> [!NOTE]
> If you are about to run the pipeline inside the HPC (NASERTIC Urederra) cluster, we have created a [config file](conf/test_dragen.config) which runs the pipeline with  minimal possible requirements

Test the pipeline with minimal requirements:

```bash
nextflow run main.nf -profile test_dragen,singularity
```


For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/demultiplex/usage) and the [parameter documentation](https://nf-co.re/demultiplex/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/demultiplex/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/demultiplex/output).

## Credits

The nf-core/demultiplex pipeline was written by Chelsea Sawyer from The Bioinformatics & Biostatistics Group for use at The Francis Crick Institute, London.

The pipeline was re-written in Nextflow DSL2 and is primarily maintained by Matthias De Smet([@matthdsm](https://github.com/matthdsm)) from [Center For Medical Genetics Ghent, Ghent University](https://github.com/CenterForMedicalGeneticsGhent) and Edmund Miller([@edmundmiller](https://github.com/edmundmiller)) from [Element Biosciences](https://www.elementbiosciences.com/)

We thank the following people for their extensive assistance in the development of this pipeline:

- [`@ChristopherBarrington`](https://github.com/ChristopherBarrington)
- [`@drpatelh`](https://github.com/drpatelh)
- [`@danielecook`](https://github.com/danielecook)
- [`@escudem`](https://github.com/escudem)
- [`@crickbabs`](https://github.com/crickbabs)
- [`@nh13`](https://github.com/nh13)
- [`@sam-white04`](https://github.com/sam-white04)
- [`@maxulysse`](https://github.com/maxulysse)

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#demultiplex` channel](https://nfcore.slack.com/channels/demultiplex) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

If you use nf-core/demultiplex for your analysis, please cite it using the following doi: [10.5281/zenodo.7153103](https://doi.org/10.5281/zenodo.7153103)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
