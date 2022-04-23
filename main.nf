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
    --tracedir            Where the traces and DAG and reports are kept.
    """.stripIndent()
}

params.help = ""

// Show help message
if (params.help) {
  helpMessage()
  exit 0
}

//params.input              = "/sbgenomics/project-files/HTP_CRAMs/*.cram"
params.tracedir           = "tracedir"
params.outdir             = "filtered_crams"
params.interval_list      = "/sbgenomics/project-files/test2.interval_list"
params.reference_sequence = "/sbgenomics/project-files/References/Homo_sapiens_assembly38.fasta"
params.max_records_in_ram = 10000000

cram_datasets      = Channel.fromPath(params.input)

//filtered_cramfiles = Channel.fromPath(params.outdir)

interval_list      = file(params.interval_list)

reference_sequence = file(params.reference_sequence)

max_records_in_ram = params.max_records_in_ram

// Define Process
// process picardFilterSamReads {
// 
//     publishDir "${params.outdir}", mode: 'copy'
// 
//     input:
//     file (cram) from cram_datasets
//     
//     output:
//     file (*.cram)
// 
//     script:
//     """
//     picard FilterSamReads \
//     REFERENCE_SEQUENCE=$reference_sequence \
//     INPUT=${cram} \
//     OUTPUT="filtered.cram\
//     FILTER=includePairedIntervals \
//     INTERVAL_LIST=$interval_list \
//     MAX_RECORDS_IN_RAM=$max_records_in_ram
//     """
//   }

// Define Process
process picardFilterSamReads {

    tag "$sample_name"

    publishDir "${params.outdir}", mode: 'copy'

    input:
    file (cram) from cram_datasets
    
    script:
    """
    picard FilterSamReads \
       REFERENCE_SEQUENCE=$reference_sequence \
       INPUT=${cram} \
       OUTPUT=filtered.cram \
       FILTER=includePairedIntervals \
       INTERVAL_LIST=$interval_list \
       MAX_RECORDS_IN_RAM=$max_records_in_ram
    """
  }