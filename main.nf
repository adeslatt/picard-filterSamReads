#!/usr/bin/env nextflow

def helpMessage() {
    log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --bams sample.bam [Options]
    
    Inputs Options:
    --input               Input cram
    --max_records_in_ram  For picard tools to specify the maximum records in ram (default is 500000).
    --outdir              The directory for the filtered cram (default is CRAMS_filtered).
    --outputfile          test place holder - shouldn't be necessary
    --reference_fasta     The assembly reference (Homo sapiens assembly as a fasta file.
    --tracedir            Where the traces and DAG and reports are kept.
    """.stripIndent()
}

params.help = ""

// Show help message
if (params.help) {
  helpMessage()
  exit 0
}


ch_cram_dataset      = Channel.fromPath(file(params.input))

ch_reference_fasta   = Channel.fromPath(file(params.reference_fasta))

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
    file (cram)            from ch_cram_dataset
    file (reference_fasta) from ch_reference_fasta_samtoolsViewToSamWithHeader 

    output:
    file "*.sam" into ch_filtered_sam_with_header
    

    script:
    """
    samtools view -T ${reference_fasta} -h -o ${cram.basename}.sam ${cram}
    samtools view -H ${cram.basename}.sam > ${cram.basename}_filter.sam
    samtools view ${cram.basename}.sam | grep -e chr6 -e HLA -e "*" >> ${cram.basename}_filter.sam
    """
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

    tag "picardSamToFastq"
    publishDir "${params.outdir}", mode: 'copy'
    container  'pgc-images.sbgenomics.com/deslattesmaysa2/picard:v1.0'

    input:
    file (filtered)           from ch_filtered_sam_with_header

    output:
    file "*.fastq" into ch_filtered_fastq

    script:
    """
    picard SamToFastq -I ${filtered} -F ${filtered.basename}_R1.fastq F2=${filtered.basename}_R2.fastq
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
    set val(name), file(reads) from ch_filtered_fastq

    output:
    file "*_fastqc.{zip,html}" into ch_fastqc_results

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
    file ('fastqc/*') from ch_fastqc_results.collect()

    output:
    file "*multiqc_report.html" into multiqc_report
    file "*_data"

    script:
    """
    multiqc . -m fastqc
    """
}
