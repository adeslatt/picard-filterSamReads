#!/usr/bin/env nextflow

//main.nf

params.input              = "/sbgenomics/project-files/HTP_CRAMs/*.cram"
params.outputdir          = "filtered_crams"
params.interval_list      = "/sbgenomics/project-files/test2.interval_list"
params.reference_sequence = "/sbgenomics/project-files/References/Homo_sapiens_assembly38.fasta"
params.max_records_in_ram = 10000000

def helpMessage() {
    log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --bams sample.bam [Options]
    
    Inputs Options:
    --input               Input directory for cram files.
    --interval_list       File containing the intervals to be extracted from the cram
    --max_records_in_ram  For picard tools to specify the maximum records in ram (default is 500000).
    --outputdir           The directory for the filtered cram (default is filtered_crams).
    --reference_sequence  The assembly reference (Homo sapiens assembly as a fasta file.
    
    """.stripIndent()
}

// Show help message
if (params.help) {
  helpMessage()
  exit 0
}

cram_datasets      = Channel.fromPath(params.input)

interval_list      = file(params.interval_list)

reference_sequence = file(params.reference_sequence)

max_records_in_ram = val(params.max_records_in_ram)

process picard_filtered_sam_reads {
    publishDir "${params.outdir}", mode: 'copy'

    tag "$name"
    publishDir "$params.outputdir", mode: 'copy'
    container 'pgc-images.sbgenomics.com/deslattesmaysa2/picard:v1.0'

    input:
    file cram from cram_datasets
    
    output:
    file "${cram.baseName)_filtered" into cram_filtered

    script:
    """
    picard FilterSamReads \
    REFERENCE_SEQUENCE=$reference_sequence \
    INPUT=${cram} \
    OUTPUT=${cram_filtered} \
    FILTER=includePairedIntervals \
    INTERVAL_LIST=$interval_list \
    MAX_RECORDS_IN_RAM=$max_records_in_ram
    """
}
