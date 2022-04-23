//main.nf

params.cram               = "/sbgenomics/project-files/HTP_CRAMs/HTP0003A.cram"
params.reference_sequence = "/sbgenomics/project-files/References/Homo_sapiens_assembly38.fasta"
params.filtered_cram      = make it a filtered_cram

cram_ch = Channel.fromFilePairs(params.cram)

reference_sequence = file(params.reference_sequence)

process picardFilterSamReads {

    tag "$name"
    publishDir "results", mode: 'copy'
    container 'pgc-images.sbgenomics.com/deslattesmaysa2/picard:v1.0'

    input:
    file cram from cram_ch
    
    
    set val(name), file(crams) from crams

    output:
    file "*.cram" into cram_results

    script:
    """
    picard FilterSamReads \
    REFERENCE_SEQUENCE=$reference_sequence \
    INPUT=$cram \
    OUTPUT=HTP0003A_picard_test2.cram \
    FILTER=includePairedIntervals \
    INTERVAL_LIST=/sbgenomics/project-files/test2.interval_list \
    MAX_RECORDS_IN_RAM=10000000

    """
}
