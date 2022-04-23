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

## making main.nf

Using the nextflow documentation faq for [How do I process multiple input files in parallel?](https://www.nextflow.io/docs/latest/faq.html#how-do-i-process-multiple-input-files-in-parallel)






