# picard-filterSamReads

Using the work that Matthew Galbraith outlined - make a nextflow workflow that allows this to be run and scaled.


## use conda to keep a clean environment

create an environment to ensure all pieces required are installed in a clean environment.
Here we call it `picard`.

Conda environment management is rich and nearly complete.  Current some problems - for example samtools install via conda does not work.

Search and use [anaconda](https://anaconda.org/) for packages. 

```bash
conda create -n picard -y
```

## install [nextflow](https://nextflow.io)

We develop and install our workflow using nextflow -- we need to install it :)

```bash
conda install -c bioconda nextflow
```

## manage your GitHub

Keep track of everything on GitHub - final workflow will be `main.nf` with configuration in `nextflow.config`.

Need to use the command line interface routine `gh`.

```bash
conda install -c conda-forge gh
```

Need to use your [GitHub token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) to authenticate.

```bash
gh auth login
```

## adding emacs editor

Sorry the editor is great in [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/), I like emacs

```bash
conda install -c conda-forge emacs -y
```

## Manual check of steps

Two routines used -- `picard FilterSamReads` and `samtools fastq`


### Samtools from the command line

```bash
samtools fastq --reference data/Homo_sapiens_assembly38.fasta -1 HTP0003A.1.fastq -2 HTP0003A.2.fastq HTP0003A_filtered.cram
[M::bam2fq_mainloop] discarded 0 singletons
[M::bam2fq_mainloop] processed 1613932 reads
```

Checking results (4 lines per read in a fastq file)

```bash
(picard) wc -l *.fastq
  3227864 HTP0003A.1.fastq
  3227864 HTP0003A.2.fastq
  6455728 total
```

Double check the numbers -

3227864 / 4 = 806966

806966 * 2 = 1613932 Reads

It adds up.

### Samtools from containerized image

```bash
docker run -it -v $PWD:$PWD -w $PWD samtools samtools fastq --reference data/Homo_sapiens_assembly38.fasta -1 HTP0003A.1.fastq -2 HTP0003A.2.fastq 2022Apr23ManualRun/HTP0003A_filtered.cram
.fastq -2 HTP0003A.2.fastq 2022Apr23ManualRun/HTP0003A_filtered.cram 
[M::bam2fq_mainloop] discarded 0 singletons
[M::bam2fq_mainloop] processed 1613932 reads
```

response is identical.

### Recap

We made two containers, now we have stitched those together as two processes.   Making sure the file names are updated based upon the input file name and then into a workflow.

## making main.nf

Using the nextflow documentation faq for [How do I process multiple input files in parallel?](https://www.nextflow.io/docs/latest/faq.html#how-do-i-process-multiple-input-files-in-parallel)

Four processes

1. picardFilterSamReads - uses an interval file to filter paired reads from a cram file using container built from [picard-docker](https://github.com/adeslatt/picard-docker)
2. samtoolsCramToFastq - uses output from the picardFilterSamReads process to extract the reads as fastq files using a container built from [samtools-docker](https://github.com/adeslatt/samtools-docker)
3. fastqc - performs quality control analysis on the fastq files extracted using a container built from [fastqc-docker](https://github.com/adeslatt/fastqc-docker)
4. multiqc - creates a final quality control report using the output from fastqc using a container built from [multiqc-docker](https://github.com/adeslatt/multiqc-docker)

## executing

the input requirements can be obtained from running with option `--help`

```bash
(picard) nichdm02209715:picard-filterSamReads deslattesmaysa2$ nextflow run main.nf --help
N E X T F L O W  ~  version 21.10.6
Launching `main.nf` [modest_austin] - revision: 9d1ff459fd

Usage:
The typical command for running the pipeline is as follows:

Inputs Options:
--input               Input directory for cram files.
--interval_list       File containing the intervals to be extracted from the cram
--max_records_in_ram  For picard tools to specify the maximum records in ram (default is 500000).
--outdir              The directory for the filtered cram (default is filtered_crams).
--reference_sequence  The assembly reference (Homo sapiens assembly as a fasta file.
--reference_fai       The assembly reference index (Homo sapiens assembly as a fai file.
--tracedir            Where the traces and DAG and reports are kept.
```


To execute, all options are required:

```bash
nextflow run main.nf \
--reference_sequence "data/Homo_sapiens_assembly38.fasta" \
--reference_fai      "data/Homo_sapiens_assembly38.fasta.fai" \
--input              "data/HTP0003A.cram" \
--outdir             "2022Apr25NextFlowRun" \
--tracedir           "pipeline_info" \
--interval_list      "data/test2.interval_list" 
```

Command when executed on my macbook pro:

```bash
(picard) nichdm02209715:picard-filterSamReads deslattesmaysa2$ nextflow run main.nf --help
N E X T F L O W  ~  version 21.10.6
Launching `main.nf` [modest_austin] - revision: 9d1ff459fd

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
--reference_fai       The assembly reference index (Homo sapiens assembly as a fai file.
--tracedir            Where the traces and DAG and reports are kept.

(picard) nichdm02209715:picard-filterSamReads deslattesmaysa2$ nextflow run main.nf \
> --reference_sequence "data/Homo_sapiens_assembly38.fasta" \
> --reference_fai      "data/Homo_sapiens_assembly38.fasta.fai" \
> --input              "data/HTP0003A.cram" \
> --outdir             "2022Apr25NextFlowRun" \
> --tracedir           "pipeline_info" \
> --interval_list      "data/test2.interval_list" 
N E X T F L O W  ~  version 21.10.6
Launching `main.nf` [compassionate_shirley] - revision: 9d1ff459fd
WARN: The `into` operator should be used to connect two or more target channels -- consider to replace it with `.set { ch_interval_list_picardFilteredSamReads }`
WARN: Access to undefined parameter `max_records_in_ram` -- Initialise it to a default value eg. `params.max_records_in_ram = some_value`
executor >  local (1)
[39/d8738b] process > picardFilterSamReads (picardFiltereSamReads) [  0%] 0 of 1
[-        ] process > samtoolsCramToFastq                          -
[-        ] process > fastqc                                       -
[-        ] process > multiqc                                      -
```


## Workflow Overview DAG

Generated when running Nextflow - here is the process graph

<p>
<img src="https://github.com/adeslatt/picard-filterSamReads/blob/main/assets/pipeline_dag.png" width="1000">
</p>






