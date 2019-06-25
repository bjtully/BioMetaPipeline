# BioMetaPipeline

## Installation
Clone or download this repository.
<pre><code>cd /path/to/BioMetaPipeline
python3 setup.py build_ext --inplace
export PYTHONPATH=/path/to/BioMetaPipeline:$PYTHONPATH
alias pipedm="python3 /path/to/BioMetaPipeline/pipedm.py"</code></pre>
Adding the last two lines of the above code to a user's `.bashrc` file will maintain these settings on next log-in.

### Dependencies

- Python &ge; 3.5
- Python 2
- Cython
- Python packages
    - luigi
    - configparser
    - argparse
    - pysam
- External programs and their dependencies
    - **MET_EVAL**
        - CheckM
        - GTDBtk
        - FastANI
    - **MET_ANNOT**
        - diamond
        - Prodigal
        - kofamscan
        - [BioData/KEGGDecoder](https://github.com/bjtully/BioData)
        - Interproscan
        - PROKKA
        - VirSorter
        - psortb
        - signalp
        - hmmer
        - Required Data:
            - dbCAN hmm profiles, available [here](http://csbl.bmb.uga.edu/dbCAN/download.php)
            - MEROPS hmm profiles, available [here](https://www.dropbox.com/s/8pskp3hlkdnt6zm/MEROPS.pfam.hmm?dl=0)
    - [BioMetaDB](https://github.com/cjneely10/BioMetaDB)

Python dependencies are best maintained within a separate Python virtual environment. `BioMetaDB` and `BioMetaPipeline`
must be contained and built within the same python environment. However, **BioMetaPipeline** data
pipelines are managed through config files that allow direct input of the paths to the Python 2/3 environments 
that house external programs (such as `CheckM`).

## About

**BioMetaPipeline** is a wrapper-script for genome/metagenome evaluation tasks. This script will
run common evaluation and annotation programs and create a `BioMetaDB` project with the integrated results.

This wrapper script was built using the `luigi` Python package. 

## Usage Best Practices

#### Config default files

Each genome pipeline has an associated configuration file that is needed to properly call the underlying programs.
Default files are available in the `Examples/Config` directory. To preserve these files for future use, users are recommended
to make edits only to copies of these default settings. Flags and arguments that are typically passed to individual programs
can be provided here.

#### Re-running steps in the pipeline

Although the data pipeline is made to run from start to finish, skipping completed steps as they are found, each major step 
("pipe") can be rerun if needed. Delete the pipe's output directory and call the given pipeline as listed in the `pipedm`
 section. If a **BioMetaDB** project is provided in the config file or passed as a command-line argument, its contents 
 will also be updated with the new results of this pipeline.

#### BioMetaDB

**BioMetaPipeline** outputs a **BioMetaDB** project containing the completed results. By passing the `-a` flag, users can 
omit the creation or update of a given **BioMetaDB** project. Each pipeline outputs a final `.tsv` file of the results of
each individual pipe.

Multiple pipelines can be run using the same project - the results of each pipeline are stored as a new database table,
and re-running a pipeline will update the existing table within the **BioMetaDB** project.

#### Memory usage and time to completion estimates

Some programs in each pipeline can have very high memory requirements (>100GB) or long completion times (depending on 
the system used to run the pipeline). Users are advised to use a program such as `screen` or `nohup` to run this pipeline, 
as well as to redirect stderr to a separate file.

## pipedm

**pipedm** is the calling script for running various data pipelines.

<pre><code>usage: pipedm.py [-h] -d DIRECTORY -c CONFIG_FILE [-a] [-o OUTPUT_DIRECTORY]
                 [-b BIOMETADB_PROJECT] [-l LIST_FILE] [-t TYPE_FILE]
                 program

pipedm: Run genome evaluation and annotation pipelines

Available Programs:

EU_PAN: Assembles, aligns, annotates, and creates pan-genome for Eukaryotes
                (Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project --list_file)
MET_ANNOT: Runs gene callers and annotation programs on MAGs
                (Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project)
MET_EVAL: Evaluates completion, contamination, and redundancy of MAGs
                (Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project)

positional arguments:
  program               Program to run

optional arguments:
  -h, --help            show this help message and exit
  -d DIRECTORY, --directory DIRECTORY
                        Directory containing genomes
  -c CONFIG_FILE, --config_file CONFIG_FILE
                        Config file
  -a, --cancel_autocommit
                        Cancel commit to database
  -o OUTPUT_DIRECTORY, --output_directory OUTPUT_DIRECTORY
                        Output directory prefix, default out
  -b BIOMETADB_PROJECT, --biometadb_project BIOMETADB_PROJECT
                        /path/to/BioMetaDB_project (updates values of existing database)
  -l LIST_FILE, --list_file LIST_FILE
                        /path/to/list_file formatted as 'prefix\tdata_file_1,data_file_2[,...]\n'
  -t TYPE_FILE, --type_file TYPE_FILE
                        /path/to/type_file formatted as 'file_name.fna\t[Archaea/Bacteria]\t[gram+/gram-]\n'</code></pre>

The typical workflow involves creating a configuration file based on the templates in `Sample/Config`. This config
file is then used to call the given pipeline by passing to each program any flags specified by the user. This setup
allows users to customize the calling programs to better fit their needs, as well as provides a useful documentation
step for researchers.

## Available pipelines

- [MET_EVAL](MET_EVAL.md)
    - Evaluate MAGs for completion and contamination using `CheckM`, and evaluate set of passed genomes for redundancy
    using `FastANI`. Optionally predict phylogeny using `GTDBtk`.
    A final BioMetaDB project is generated, or updated, with a table that provides a summary of the results.
- [MET_ANNOT](MET_ANNOT.md)
    - Structurally and functionally annotate MAGs using several available annotation programs. Identify peptidase proteins,
    determine KEGG pathways, run PROKKA pipeline, predict viral sequences, and run interproscan.
    A final BioMetaDB project is generated, or updated, with a table that provides a summary of the results.
