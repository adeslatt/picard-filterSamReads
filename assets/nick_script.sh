#!/bin/bash
samtools view -T Homo_sapiens_assembly38.fasta -h -o HTP0005A3.sam HTP0005A3.cram
samtools view -H HTP0005A3.sam > HTP0005A3_filter.sam  
samtools view HTP0005A3.sam | grep -e chr6 -e HLA -e "*" >> HTP0005A3_filter.sam
picard-tools SamToFastq I= HTP0005A3_filter.sam F= HTP0005A3_filter_R1.fastq F2= HTP0005A3_filter_R2.fastq
