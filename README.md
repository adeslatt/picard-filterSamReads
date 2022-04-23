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


