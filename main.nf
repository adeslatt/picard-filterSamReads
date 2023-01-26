#!/usr/bin/env nextflow

def helpMessage() {
    log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --bams sample.bam [Options]
    
    Inputs Options:
    --input               Input cram
    --max_records_in_ram  For picard tools to specify the maximum records in ram (default is 500000).
    --filter_string       String to use to filter region from cram (e.g. "grep -e chr6 -e HLA -e "*"")
    --outdir              The directory for the filtered cram (default is CRAMS_filtered).
    --outputfile          test place holder - shouldn't be necessary
    --reference_fasta     The assembly reference (Homo sapiens assembly as a fasta file.
    --tracedir            Where the traces and DAG and reports are kept.
    """.stripIndent()
}

params.help = ""
params.max_records_in_ram = 500000
params.filter_string = "grep -e chr6 -e HLA -e \"*\""

// Show help message
if (params.help) {
  helpMessage()
  exit 0
}


ch_cram_dataset      = Channel.fromPath(file(params.input))

ch_cram_dataset.into {
  ch_cram_for_names
  ch_cram_for_samtools
}
ch_reference_fasta   = Channel.fromPath(file(params.reference_fasta))

val_filter_string    = Channel.value(params.filter_string)

ch_reference_fasta.into {
  ch_reference_fasta_samtoolsViewToSamWithHeader
  ch_reference_sequence_samtoolsCramToFastq
}
  
max_records_in_ram = params.max_records_in_ram

// ------------------------------------------------------------
// Define Process
// Nick script (found in assets/nick_script.sh)
// 4-6 steps:
// 1. samtools view using a fasta file to create a sam output version of cram
// 2. samtools view to output only the header (to start a new output)
// 3. samtools view to grab the desired filtered region, chr6 and HLA region appended to header only output above.
// 4. picard-tools to take the sam to fastq files for those reads overlapping the region
// 5. (optional) quality control fastq on those reads
// 6. (optional) -- at the end a single multi-qc on all the fastqc runs.
// ------------------------------------------------------------

// ------------------------------------------------------------
// samtoolsViewToSamWithHeader
// purpose:   given our cram file - use a reference, to create a sam file output with header.
// container: samtools can be specified here, in the nextflow.config or from command line
//            code here: file (http://github/adeslatt/samtools-docker)
// input:     via channels (good for parallelization)
// output:    sam formatted file with header
// ------------------------------------------------------------
process samtoolsViewToSamWithHeader {

    tag "samtoolsViewToSamWithHeader"
    publishDir "${params.outdir}", mode: 'copy'
    container  'pgc-images.sbgenomics.com/deslattesmaysa2/samtools:v1.16.1'

    input:
    file (cram)            from ch_cram_for_samtools
    file (reference_fasta) from ch_reference_fasta_samtoolsViewToSamWithHeader 
    val (filter_string)    from val_filter_string
    
    output:
    file "${cram.baseName}.filtered.sam" into ch_filtered_sam_with_header
    

    script:
    """
    samtools view -f 0x2 -T ${reference_fasta} -h -o ${cram.baseName}.sam ${cram}
    samtools view -H ${cram.baseName}.sam  > ${cram.baseName}.filtered.sam
    samtools view ${cram.baseName}.sam | ${filter_string}  >> ${cram.baseName}.filtered.sam
    """
}


ch_filtered_sam_with_header.into {
  ch_filtered_sam_for_picardSamToFastq
  ch_filtered_sam_for_printing
}


// ------------------------------------------------------------
// picardSamToFastq
// purpose:   given our filtered sam file - extract the fastq files for the region 
// container: picard tool using the SamToFastq function containerized and specified
//            here, in the nextflow.config or from the command line
//            code here: file (http://github/adeslatt/picard-docker)
// input:     via channels (good for parallelization)
// output:    will be the paired reads
// ------------------------------------------------------------
process picardSamToFastq {

    tag           'picardSamToFastq'
    errorStrategy 'ignore'
    publishDir    "${params.outdir}", mode: 'copy'
    container     'pgc-images.sbgenomics.com/deslattesmaysa2/picard:v1.0'
    
    input:
    file (sam)   from ch_filtered_sam_for_picardSamToFastq
        
    output:
    file "${sam.baseName}_R1.fastq" into ch_sam_R1_fastq
    file "${sam.baseName}_R2.fastq" into ch_sam_R2_fastq

    script:
    """
    picard SamToFastq -I ${sam} -F ${sam.baseName}_R1.fastq -F2 ${sam.baseName}_R2.fastq
    """
}

ch_sam_R1_fastq.into {
  ch_sam_R1_fastq_for_printing
  ch_sam_R1_fastq_for_fastqc
}

ch_sam_R2_fastq.into {
  ch_sam_R2_fastq_for_printing
  ch_sam_R2_fastq_for_fastqc
}

ch_filtered_sam_for_printing.view()
ch_sam_R1_fastq_for_printing.view()
ch_sam_R2_fastq_for_printing.view()

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
    publishDir "${params.outdir}", mode: 'copy'
    container 'pgc-images.sbgenomics.com/deslattesmaysa2/fastqc:v1.0'

    input:
    file(read1) from ch_sam_R1_fastq_for_fastqc
    file(read2) from ch_sam_R2_fastq_for_fastqc

    output:
    file "*_fastqc.{zip,html}" into ch_fastqc_results

    script:
    """
    fastqc $read1
    fastqc $read2
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

    publishDir "${params.outdir}", mode: 'copy'
    container 'pgc-images.sbgenomics.com/deslattesmaysa2/multiqc:v1.0'

    input:
    file ('fastqc/*') from ch_fastqc_results.collect()

    output:
    file "*multiqc_report.html" into multiqc_report
    file "*_data"

    script:
    """
    multiqc . -m fastqc
    """
}
