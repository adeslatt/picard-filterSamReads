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

'*updated Jan 8 2022*'

Using the steps outlined by our colleague '*Nick*'

::Pseudo code::
1. a. samtools view to convert cram to sam with header file
   b. samtools view to start the new output file with header only
   c. samtools view to filter based upon a provided filter string (see script below - narrow to chromosome, gene of interest)
2. picard SamToFastq to extract the paired reads overlapping the newly extracted region and produced the R1_fastq and R2_fastq files
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
--input               Input cram
--max_records_in_ram  For picard tools to specify the maximum records in ram (default is 500000).
--filter_string       String to use to filter region from cram (e.g. "grep -e chr6 -e HLA -e "*"")
--outdir              The directory for the filtered cram (default is CRAMS_filtered).
--outputfile          test place holder - shouldn't be necessary
--reference_fasta     The assembly reference (Homo sapiens assembly as a fasta file.
--tracedir            Where the traces and DAG and reports are kept.
```


To execute the test file, the following command was run:  

Note for the test, we used the filter string `*"grep -e chr22 -e USP18 -e \"*\""*'

```bash
nextflow run main.nf \
--input data/test.chr22.Aligned.sortedByCoord.out.cram \
--filter_string "grep -e chr22 -e USP18 -e \"*\"" \
--outdir "test_output" \
--outputfile "test_outputfile" \
--reference_fasta "data/GRCh38.primary_assembly.genome.chr22.fa" \
--tracedir "execution_trace" \
-with-trace \
-with-report \
-with-dag "execution_trace/test_output.png" \
-with-timeline
```

Command when executed on my macbook pro ran very quickly with the limited data files and isolated to chr22 segment of the human genome.   GitHub actions can be set up to ensure that this nextflow script runs at all times regardless of changes.

## Execution Trace

[Nextflow](https://www.nextflow.io) has nice features for creating execution report with timeline and resource details - these may be found in the [execution trace directory](https://github.com/adeslatt/picard-filterSamReads/blob/main/execution_trace/)

The Nextflow report looks like this:

<p>
<img src=https://github.com/adeslatt/picard-filterSamReads/blob/main/assets/NextflowWorkflowReport.png width = 300 align=right>
</p>

The Nextflow Tasks Details looks like:

<p>
<img src=https://github.com/adeslatt/picard-filterSamReads/blob/main/assets/NextflowWorkflowTasksDetail.png width=300 align=right>
</p>

The Nextflow Resource Usage report looks like:

<p>
<img src=https://github.com/adeslatt/picard-filterSamReads/blob/main/assets/NextflowReportResourceUsage.png width=300 align-right>
</p>

To view the details, you can download the html files to your own computer and view within your browser (Chrome preferred)

## Multiqc and Fastqc results

Phil Ewels continues to produce so many wonderful tools, including [Multiqc](https://multiqc.info)

The output of the running of fastqc and multiqc on the test files may be found in the [test output directory]([execution trace directory](https://github.com/adeslatt/picard-filterSamReads/blob/main/test_output/)

The Multiqc report looks like:

<p>
<img src=https://github.com/adeslatt/picard-filterSamReads/blob/main/assets/MultiQCPictureFatQc.png width=300 align=right>
</p>

To view the complete details, download the html files to your own computer and view within your browser (Chrome preferred)

## Uploading Nextflow Workflow onto Cavatica

A nice feature of the Cavatica platform - now we can upload our Nextflow workflow onto Cavatica.   

The steps are as follows:

1. Create your workflow and put it into GitHub

2. Create a credentials file placed here `~/.sevenbridges/credentials`.  The content looks like this:

```bash
[deslattesmaysa2]
api_endpoint = https://cavatica-api.sbgenomics.com/v2
auth_token = [your developers token]
```

The name in between the `[]` is your username on the platform.

3. git clone your GitHub workflow in a clean directory.  This is important because the process of uploading as an application onto Cavatica zips up the directory - and you do not want your old work directories to be zipped inside!

4. Install the sbpack_nf routine.  This is done with pip

```bash
pip install sbpack
```

5. Now use the [sbpack_nf](https://docs.cavatica.org/reference/bring-nextflow-apps-to-cavatica#sbpack_nf-command-reference) command.  See the link gives all the details for the options.

```bash
sbpack_nf --profile deslattesmaysa2 --appid matthew.galbraith/picard-test/picard-filtercramfile-nf --workflow-path /Users/deslattesmaysa2/clean/picard-filterSamReads --entrypoint main.nf --dump-sb-app
```

The `--dump-sb-app` outputs two additional files (`sb_nextflow_schema.yaml` and `sb_nextflow_schema.json`)

6. Edit the `sb_nextflow_schema.yaml` to accept the input files using the details as outlined in the [Cavatica Nextflow help pages](https://docs.cavatica.org/v1.0/docs/bring-nextflow-apps-to-cavatica#section-optimizing-the-converted-app-for-execution-in-seven-bridges-environments)

The final form of the `sb_nextflow_schema.yaml` may be found in this repository [sb_nextflow_schema.yaml](https://github.com/adeslatt/picard-filterSamReads/blob/main/sb_nextflow_schema.yaml)

7. upload the edited `sb_nextflow_schema.yaml`

Note that this is done with the `sbpack` command.

```bash
sbpack deslattesmaysa2 matthew.galbraith/picard-test/picard-filtercramfile-nf  sb_nextflow_schema.yaml
```

And then it is an application ready to be used on the cavatica platform.

## Workflow Overview DAG

Generated when running Nextflow - here is the process graph

<p>
<img src="https://github.com/adeslatt/picard-filterSamReads/blob/main/execution_trace/test_output.png" width="1000">
</p>






