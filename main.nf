#!/usr/bin/env nextflow

def helpMessage() {
    log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --bams sample.bam [Options]
    
    Inputs Options:
    --input               Input directory for cram files.
    --interval_list       File containing the intervals to be extracted from the cram
    --max_records_in_ram  For picard tools to specify the maximum records in ram (default is 500000).
    --outdir              The directory for the filtered cram (default is filtered_crams).
    --outputfile          test place holder - shouldn't be necessary
    --reference_sequence  The assembly reference (Homo sapiens assembly as a fasta file.
    --reference_fai       The assembly reference index (Homo sapiens assembly as a fai file.
    --tracedir            Where the traces and DAG and reports are kept.
    """.stripIndent()
}

params.help = ""

// Show help message
if (params.help) {
  helpMessage()
  exit 0
}


cram_datasets      = Channel.fromPath(file(params.input))

interval_list      = Channel.fromPath(file(params.interval_list))

reference_sequence = Channel.fromPath(file(params.reference_sequence))

reference_fai      = Channel.fromPath(file(params.reference_fai))

reference_sequence.into {
  ch_reference_sequence_picardFilteredSamReads
  ch_reference_sequence_samtoolsCramToFastq
}

reference_fai.into {
  ch_reference_fai_picardFilteredSamReads
  ch_reference_fai_samtoolsCramToFastq
}

interval_list.into {
  ch_interval_list_picardFilteredSamReads
}
  
max_records_in_ram = params.max_records_in_ram

// ------------------------------------------------------------
// Define Process
// ------------------------------------------------------------

// ------------------------------------------------------------
// picardFilterSamReads
// purpose:   given a list of intervals (sam format) extract
//            paired reads with picard tool for that genomic region.
// container: picard as specified in the nextflow.config file (http://github/adeslatt/picard-docker)
// input:     via channels channels but ultimately from command line input and directories
//            for example all cram files in the input directory will be  processed in parallel.
// output:    will be the filtered cram file
// ------------------------------------------------------------
process picardFilterSamReads {

    tag "picardFiltereSamReads"
    publishDir "${params.outdir}", mode: 'copy'
    container  'pgc-images.sbgenomics.com/deslattesmaysa2/picard:v1.0'

    input:
    file (cram)               from cram_datasets
    file (reference_sequence) from ch_reference_sequence_picardFilteredSamReads
    file (reference_fai)      from ch_reference_fai_picardFilteredSamReads
    file (interval_list)      from ch_interval_list_picardFilteredSamReads
    
    output:
    file "*filtered.cram" into filtered_cram_ch
    
    script:
    """
    picard FilterSamReads \
       REFERENCE_SEQUENCE=${reference_sequence} \
       INPUT=${cram} \
       OUTPUT=${cram}_filtered.cram \
       FILTER=includePairedIntervals \
       INTERVAL_LIST=${interval_list} \
       MAX_RECORDS_IN_RAM=$max_records_in_ram

    """
  }

// ------------------------------------------------------------
// samtoolsCramToFastq
// purpose:   given our filtered cram file - extract the fastq files for the region 
// container: samtools can be specified here, in the nextflow.config or from command line
//            code here: file (http://github/adeslatt/samtools-docker)
// input:     via channels (good for parallelization)
// output:    will be the paired reads
// ------------------------------------------------------------
process samtoolsCramToFastq {

    tag "samtoolsCramToFastq"
    publishDir "${params.outdir}", mode: 'copy'
    container  'pgc-images.sbgenomics.com/deslattesmaysa2/samtools:latest'

    input:
    file (filtered_cram)      from filtered_cram_ch
    file (reference_sequence) from ch_reference_sequence_samtoolsCramToFastq 
    file (reference_fai)      from ch_reference_fai_samtoolsCramToFastq 

    output:
    file "*.fastq" into filtered_fastq_ch

    script:
    """
    samtools fastq \
      --reference ${reference_sequence} \
      -1 ${filtered_cram}_1.fastq \
      -2 ${filtered_cram}_2.fastq \
      ${filtered_cram}
    """
}

// ------------------------------------------------------------
// fastqc
// purpose:   given fastqc files - do quality control inspection
// container: fastqc can be specified here, in the nextflow.config or from command line
//            code here: file (http://github/adeslatt/fastqc-docker)
// input:     via channels (good for parallelization)
// output:    zip and html reports
// ------------------------------------------------------------
process fastqc {
    tag "fastqc"
    publishDir "results", mode: 'copy'
    container 'pgc-images.sbgenomics.com/deslattesmaysa2/fastqc:v1.0'

    input:
    set val(name), file(reads) from filtered_fastq_ch

    output:
    file "*_fastqc.{zip,html}" into fastqc_results_ch

    script:
    """
    fastqc $reads
    """
}

// ------------------------------------------------------------
// multiqc
// purpose:   given fastqc output files files - make a nice report
// container: multiqc can be specified here, in the nextflow.config or from command line
//            code here: file (http://github/adeslatt/fastqc-docker)
// input:     via channels (good for parallelization)
// output:    zip and html reports
// ------------------------------------------------------------
process multiqc {
    tag "multiqc"

    publishDir "results", mode: 'copy'
    container 'pgc-images.sbgenomics.com/deslattesmaysa2/multiqc:v1.0'

    input:
    file ('fastqc/*') from fastqc_results_ch.collect()

    output:
    file "*multiqc_report.html" into multiqc_report
    file "*_data"

    script:
    """
    multiqc . -m fastqc
    """
}
