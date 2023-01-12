cwlVersion: v1.0
class: CommandLineTool
id: samtoolsViewToSamWithHeader
doc: |-
  This tool does extracts a desired region from a cram file and saves it as a sam
  Programs run in this tool:
    - samtools view
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/deslattesmaysa2/samtools:v1.16.1'
  - class: InlineJavascriptRequirement
baseCommand: [samtools, view]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      -T $(inputs.reference_fasta) -h -o subset_$(inputs.cram.nameroot).sam $(inputs.cram)
      && samtools view -H subset_$(inputs.cram.nameroot).sam > subset_$(inputs.cram.nameroot).filtered.sam
      && samtools view subset_$(inputs.cram.nameroot).sam | $(inputs.filter_string) >> subset_$(inputs.cram.nameroot).filtered.sam
inputs:
  cram: { type: File, doc: "Input reads file" }
  reference_fasta: { type: File, doc: "Reference fasta" }
  filter_string: { type: string, doc: "filter string to parse out cram (e.g. grep -e chr22 -e USP18" }
outputs:
  output:
    type: File
    outputBinding:
      glob: "*.filtered.sam"
