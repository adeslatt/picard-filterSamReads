//main.nf

cram = Channel.fromFilePairs(params.cram)

process picardFilterSamReads {

    tag "$name"
    publishDir "results", mode: 'copy'
    container 'pgc-images.sbgenomics.com/deslattesmaysa2/picard:v1.0'

    input:
    set val(name), file(crams) from crams

    output:
    file "*.cram" into cram_results

    script:
    """
    picard FilterSamReads \
    REFERENCE_SEQUENCE=/sbgenomics/project-files/References/Homo_sapiens_assembly38.fasta \
    INPUT=/sbgenomics/project-files/HTP_CRAMs/HTP0003A.cram \
    OUTPUT=HTP0003A_picard_test2.cram \
    FILTER=includePairedIntervals \
    INTERVAL_LIST=/sbgenomics/project-files/test2.interval_list \
    MAX_RECORDS_IN_RAM=10000000

    """
}
