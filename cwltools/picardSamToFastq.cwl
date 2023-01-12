cwlVersion: v1.0
class: CommandLineTool
id: picardSamToFastq
doc: |-
  This tool does extracts a desired region from a cram file and saves it as a sam
  Programs run in this tool:
    - picard SamToFastq
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/deslattesmaysa2/picard:v1.0'
  - class: InlineJavascriptRequirement
baseCommand: [picard]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      SamToFastq -F $(inputs.sam.nameroot)_R1.fastq -I $(inputs.sam) -F2 $(inputs.sam.nameroot)_R2.fastq
inputs:
  sam: { type: File, doc: "Input sam file" }
outputs:
  output:
    type: File
    outputBinding:
      glob: "*.fastq"
