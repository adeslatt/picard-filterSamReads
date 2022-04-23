//main.nf

params.input              = "/sbgenomics/project-files/HTP_CRAMs/*.cram"
params.interval_list      = "/sbgenomics/project-files/test2.interval_list"
params.reference_sequence = "/sbgenomics/project-files/References/Homo_sapiens_assembly38.fasta"
params.max_records_in_ram = 10000000

cram_datasets = Channel.fromPath(params.input)

interval_list      = file(params.interval_list)
reference_sequence = file(params.reference_sequence)
max_records_in_ram = val(params.max_records_in_ram)

process picardFilterSamReads {

    tag "$name"
    publishDir "results", mode: 'copy'
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
