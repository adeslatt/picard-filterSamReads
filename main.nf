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


cram_datasets      = Channel.fromPath(file(params.input))

interval_list      = Channel.fromPath(file(params.interval_list))

reference_sequence = Channel.fromPath(file(params.reference_sequence))

reference_sequence into
  ch_reference_sequence_picardFilteredSamReads
  ch_reference_sequence_samtoolsCramToFastq

interval_list into
  ch_interval_list_picardFilteredSamReads
  
max_records_in_ram = params.max_records_in_ram

// Define Process
process picardFilterSamReads {

    tag "picardFiltereSamReads"

    publishDir "${params.outdir}", mode: 'copy'

    input:
    file (cram)               from cram_datasets
    file (reference_sequence) from ch_reference_sequence_picardFilteredSamReads
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

process samtoolsCramToFastq {

   tag "samtoolsCramToFastq"

   publishDir "${params.outdir}", mode: 'copy'

   input:
   file (filtered_cram)      from filtered_cram_ch
   file (reference_sequence) from ch_reference_sequence_samtoolsCramToFastq 

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
