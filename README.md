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
- Cython
- Python packages
    - luigi
    - configparser
    - argparse
    - pysam
- External programs and their dependencies
    - `MET_EVAL`
        - CheckM
        - GTDBtk
        - FastANI
    - `MET_ANNOT`
        - Prodigal
        - kofamscan
        - [KEGGDecoder](https://github.com/bjtully/BioData)
        - Interproscan
        - PROKKA
        - VirSorter
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
to make edits only to copies of these default settings.

#### Re-running steps in the pipeline

Although the data pipeline is made to run from start to finish, each major step can be rerun if needed. Delete the output 
directory and any associated files for the step needing to be rerun, and call the given pipeline as listed in the `pipedm` 
section.

#### BioMetaDB

**BioMetaPipeline** outputs a **BioMetaDB** project containing the completed results. By passing the `-a` flag, users can 
omit the creation or update of a given **BioMetaDB** project. Each pipeline outputs a final `.tsv` file of its integrated 
results.

#### Memory usage and time to completion estimates

Some programs in each pipeline can have very high memory requirements (>100GB) or long completion times (depending on 
the system used to run the pipeline). Users are advised to use a program such as `screen` or `nohup` to run this pipeline.

## pipedm

**pipedm** is the calling script for running various data pipelines.

<pre><code>usage: pipedm.py [-h] -d DIRECTORY -c CONFIG_FILE [-a] [-o OUTPUT_DIRECTORY]
                 [-b BIOMETADB_PROJECT] [-l LIST_FILE]
                 program

pipedm: Run genome evaluation and annotation pipelines

Available Programs:

EU_PAN: Assembles, aligns, annotates, and creates pan-genome for Eukaryotes
                (Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project --list_file)
MET_ANNOT: Runs gene callers and annotation programs on MAGs
                (Flags:  --directory --config_file --cancel_autocommit --output_directory --biometadb_project)
MET_EVAL: Evaluates completion, contamination, and redundancy of genomes
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
                        /path/to/list_file formatted as 'prefix\tdata_file_1,data_file_2[,...]\n'</code></pre>

The typical workflow involves creating a configuration file based on the templates in `Example/Config`. This config
file is then used to call the given pipeline.

### MET_EVAL

**MET_EVAL** uses `CheckM`, `GTDBtk`, and `FastANI` to evaluate prokaryotic meta/genome completion, contamination,
phylogeny, and redundancy. This will generate a final `BioMetaDB` project containing the results of this pipeline.
An additional `.tsv` output file is generated.

- Required flags
    - --directory (-d): /path/to/directory of fasta files
    - --config_file (-c): /path/to/config.ini file matching template in Examples/Config
- Optional flags
    - --output_directory (-o): Output prefix
    - --biometadb_project (-b): Name to assign to `BioMetaDB` project, or name of existing project to use
    - --cancel_autocommit (-a): Cancel creation/update of `BioMetaDB` project
- Example
    - `pipedm MET_EVAL -d fasta_folder/ -c Examples/Config/MET_EVAL.ini -o eval -b Metagenomes`
    - This command will use the fasta files in `fasta_folder/` in the evaluation pipeline. It will output to the folder
    `eval` and will create or update the `BioMetaDB` project `Metagenomes` in the current directory. It will use the default
    config file provided in `Examples/Config`.
    
### EVALUATION config file

The **EVALUATION** pipeline involves the use of `CheckM`, `GTDBtk`, and `FastANI`. Its default config file allows for
paths to these calling programs to be set, as well as for program-level flags to be passed. Note that individual flags
(e.g. those that are passed without arguments) are set using `FLAGS`. Ensure that all paths are valid (the bash command
`which <COMMAND>` is useful for locating program paths).

`CUTOFFS` defines the inclusive ANI value used to determine redundancy between two genomes, based on `FastANI`. 
`IS_COMPLETE` defines the inclusive minimum value to determine if a genome is complete, based on `CheckM`.
`IS_CONTAMINATED` defines the inclusive maximum value to determine if a genome is contaminated, based on `CheckM`. 

- Location: `Examples/Config/MET_EVAL.ini`
<pre><code>[CHECKM]
PATH = /usr/local/bin/checkm
--aai_strain = 0.95
-t = 10
--pplacer_threads = 10
FLAGS = --reduced_tree
--tmpdir = /media/imperator/cneely/pipedm_test

[GTDBTK]
PATH = /usr/local/bin/gtdbtk
--cpus = 1

[FASTANI]
PATH = /usr/local/bin/fastANI
--fragLen = 1500

[BIOMETADB]
PATH = /path/to/BioMetaDB/dbdm.py
--db_name = Planctomycetes

[CUTOFFS]
ANI = 98.5
IS_COMPLETE = 50
IS_CONTAMINATED = 5</code></pre>

- General Notes
    - `CheckM` and `GTDBtk` are both high memory-usage programs, often exceeding 100 GB. Use caution when multithreading.
    - `CheckM` writes to a temporary directory which may have separate user-rights, depending on the system on which it
    is installed. Users are advised to explicitly set the `--tmpdir` flag in `CHECKM` to a user-owned path.
