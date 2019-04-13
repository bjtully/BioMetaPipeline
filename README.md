# BioMetaPipeline

## Installation
Clone or download a copy of this repository.
<pre><code>cd /path/to/BioMetaPipeline
python3 setup.py build_ext --inplace
export PYTHONPATH=/path/to/BioMetaPipeline:$PYTHONPATH
alias dbdm="python3 /path/to/BioMetaPipeline/pipedm.py"</code></pre>
Adding the last two lines of the above code to a user's `.bashrc` file will maintain these settings on next log-in.

### Dependencies

- Python &ge; 3.5
- Cython
- Python packages
    - ArgParse
    - ConfigParser
    - [BioMetaDB](https://github.com/cjneely10/BioMetaDB)
- External programs
    - CheckM
    - GTDBtk
    - fastANI


### About

**BioMetaPipeline** is a wrapper script for performing common genome analyses.

## Usage

### pipedm

**pipedm** is the calling python script that begins provided pipelines.

<pre><code>usage: pipedm.py [-h] -d DIRECTORY -c CONFIG_FILE [-l PREFIX_FILE] [-a]
                 [-o OUTPUT_DIRECTORY] [-b BIOMETADB_PROJECT]
                 program

pipedm:	Run genome evaluation and annotation pipelines

Available Programs:

EVALUATION: Evaluates completion, contamination, and redundancy of genomes
		(Req:  --directory --config_file --prefix_file --cancel_autocommit --output_directory --biometadb_project)

positional arguments:
  program               Program to run

optional arguments:
  -h, --help            show this help message and exit
  -d DIRECTORY, --directory DIRECTORY
                        Directory containing genomes
  -c CONFIG_FILE, --config_file CONFIG_FILE
                        Config file
  -l PREFIX_FILE, --prefix_file PREFIX_FILE
                        Optional list file formatted as output_prefix	<file>[	<file>]
  -a, --cancel_autocommit
                        Cancel commit to database
  -o OUTPUT_DIRECTORY, --output_directory OUTPUT_DIRECTORY
                        Output directory prefix
  -b BIOMETADB_PROJECT, --biometadb_project BIOMETADB_PROJECT
                        /path/to/BioMetaDB_project (updates existing values or initializes with name)</code></pre>

The typical **BioMetaPipeline** workflow involves creating a config file (or using an existing template from `Example/Config`)
