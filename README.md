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









