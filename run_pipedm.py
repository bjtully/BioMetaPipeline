#!/usr/bin/env python3
import os
import sys
import signal
import shutil
import argparse
import subprocess
from random import randint
from datetime import datetime
from configparser import RawConfigParser
from argparse import RawTextHelpFormatter

"""
BioMetaPipeline calling script


**********
Prior to first run:

Ensure that all path arguments below are filled and that all required databases are downloaded.
If a certain program will not be used, and the database files are not downloaded, provide any valid directory.
Directory contents are never deleted, and are only used to reference stored data.

**********

"""

# Data downloaded from  https://data.ace.uq.edu.au/public/gtdbtk/
GTDBTK_FOLDER = "/path/to/gtdbtk/release_##/##.#"
# Extracted checkm data from  https://data.ace.uq.edu.au/public/CheckM_databases/
CHECKM_FOLDER = "/path/to/checkm_databases"
# Directory containing extracted ko_list and profiles/ from  ftp://ftp.genome.jp/pub/db/kofam/
KOFAM_FOLDER = "/path/to/kofam_data"
# Extracted interproscan data from  https://github.com/ebi-pf-team/interproscan/wiki/HowToDownload
INTERPROSCAN_FOLDER = "/path/to/interproscan/data"
# Directory containing 3 files - merops-as-pfams.txt, dbCAN-fam-HMMs.txt, MEROPS.pfam.hmm
PEPTIDASE_DATA_FOLDER = "/path/to/peptidase_data"
# Extracted virsorter data from  https://github.com/simroux/VirSorter
VIRSORTER_DATA_FILDER = "/path/to/virsorter-data"
# Location of BioMetaDB on system. If not used, ensure to pass `-a` flag to pipedm.py when running
BIOMETADB = "/path/to/BioMetaDB/dbdm.py"
# Signalp software package, including binary, from  http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp
SIGNALP_FOLDER = "/path/to/signalp-4.1"
# RNAmmer software package, including binary, from  http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?rnammer
RNAMMER_FOLDER = "/path/to/rnammer-1.2.src"



# BioMetaPipeline version
DOCKER_IMAGE = "pipedm"
docker_pid_filename = None


class ArgParse:

    def __init__(self, arguments_list, description, *args, **kwargs):
        """ Class for handling parsing of arguments and error handling

        """
        self.arguments_list = arguments_list
        self.args = []
        # Instantiate ArgumentParser
        self.parser = argparse.ArgumentParser(formatter_class=RawTextHelpFormatter, description=description,
                                              *args, **kwargs)
        # Add all arguments stored in self.arguments_list
        self._parse_arguments()
        # Parse arguments
        try:
            self.args = self.parser.parse_args()
        except:
            exit(1)

    def _parse_arguments(self):
        """ Protected method for adding all arguments stored in self.arguments_list
            Checks value of "require" and sets accordingly

        """
        for args in self.arguments_list:
            self.parser.add_argument(*args[0], **args[1])

    @staticmethod
    def description_builder(header_line, help_dict, flag_dict):
        """ Static method provides summary of programs/requirements

        """
        assert set(help_dict.keys()) == set(flag_dict.keys()), "Program names do not match in key/help dictionaries"
        to_return = header_line + "\n\nAvailable Programs:\n\n"
        programs = sorted(flag_dict.keys())
        for program in programs:
            to_return += program + ": " + help_dict[program] + "\n\t" + \
                         "\t(Flags: {})".format(" --" + " --".join(flag_dict[program])) + "\n"
        to_return += "\n"
        return to_return


class GetDBDMCall:
    def __init__(self, calling_script_path, db_name, cancel_autocommit, added_flags = []):
        """ Class handles determining state of dbdm project

        """
        self.calling_script_path = calling_script_path
        self.db_name = db_name
        self.cancel_autocommit = cancel_autocommit
        self.added_flags = added_flags

    def run(self, table_name, directory_name, data_file, alias):
        """ Runs dbdm call for specific table_name, etc

        """
        # Commit with biometadb, if passed (COPY/PASTE+REFACTOR from dbdm_calls.pyx)
        if self.cancel_autocommit:
            return
        if not os.path.isfile(data_file):
            return
        if not os.path.exists(self.db_name):
            subprocess.run(
                [
                    "python3",
                    self.calling_script_path,
                    "INIT",
                    "-n",
                    self.db_name,
                    "-t",
                    table_name.lower(),
                    "-d",
                    directory_name,
                    "-f",
                    data_file,
                    "-a",
                    alias.lower(),
                    *self.added_flags,
                ],
                check=True,
            )
        elif os.path.exists(self.db_name) and not os.path.exists(os.path.join(self.db_name, "classes", table_name.lower() + ".json")):
            subprocess.run(
                [
                    "python3",
                    self.calling_script_path,
                    "CREATE",
                    "-c",
                    self.db_name,
                    "-t",
                    table_name.lower(),
                    "-a",
                    alias.lower(),
                    "-f",
                    data_file,
                    "-d",
                    directory_name,
                    *self.added_flags,
                ],
                check=True,
            )
        elif os.path.exists(self.db_name) and os.path.exists(os.path.join(self.db_name, "classes", table_name.lower() + ".json")):
            subprocess.run(
                [
                    "python3",
                    self.calling_script_path,
                    "UPDATE",
                    "-c",
                    self.db_name,
                    "-t",
                    table_name.lower(),
                    "-a",
                    alias.lower(),
                    "-f",
                    data_file,
                    "-d",
                    directory_name,
                    *self.added_flags,
                ],
                check=True,
            )


def get_added_flags(config, _dict, ignore = ()):
    """ Function returns FLAGS line from dict in config file

    """
    if "FLAGS" in dict(config[_dict]).keys():
        return [def_key.lstrip(" ").rstrip(" ")
                for def_key in config[_dict]["FLAGS"].rstrip("\r\n").split(",")
                if def_key != ""]
    else:
        return []


def sigterm_handler(_signo, _stack_frame):
    """ Graceful exit
            End docker process, if running
            Exit application

    """
    print("Exiting...")
    if docker_pid_filename:
        subprocess.run(
            [
                "docker",
                "kill",
                "`cat %s`" % docker_pid_filename
            ],
            check=True,
        )
        os.remove(docker_pid_filename)
    sys.exit(0)

signal.signal(signal.SIGTERM, sigterm_handler)


# Parsed arguments
ap = ArgParse(
    (
    (("program",),
     {"help": "Program to run"}),
    (("-d", "--directory"),
     {"help": "Directory containing genomes", "required": True}),
    (("-c", "--config_file"),
     {"help": "Config file", "required": True}),
    (("-a", "--cancel_autocommit"),
     {"help": "Cancel commit to database", "action": "store_true", "default": False}),
    (("-o", "--output_directory"),
     {"help": "Output directory prefix, default out", "default": "out"}),
    (("-b", "--biometadb_project"),
     {"help": "/path/to/BioMetaDB_project (updates values of existing database)", "default": "None"}),
    (("-t", "--type_file"),
     {"help": "/path/to/type_file formatted as 'file_name.fna\\t[Archaea/Bacteria]\\t[gram+/gram-]\\n'",
      "default": "None"}),
    ),
    description=ArgParse.description_builder(
        "pipedm:\tRun meta/genome evaluation and annotation pipelines",
        {
            "MET_EVAL":         "Evaluates completion, contamination, and redundancy of MAGs",
            "MET_ANNOT":        "Runs gene callers and annotation programs on MAGs",
        },
        {
            "MET_EVAL":       ("directory", "config_file", "cancel_autocommit", "output_directory",
                               "biometadb_project"),
            "MET_ANNOT":      ("directory", "config_file", "cancel_autocommit", "output_directory",
                               "biometadb_project", "type_file"),
        }
    )
)

# Config file read in
cfg = RawConfigParser()
cfg.optionxform = str
cfg.read(ap.args.config_file)

# Store docker process id to file for graceful exits
docker_pid_filename = "%s.%s.pid" % (datetime.today().strftime("%Y%m%d"), str(randint(1, 1001)))

# Run docker version
subprocess.run(
    [
        "docker",
        "run",
        # Locale setup required for parsing files
        "-e",
        "LANG=C.UTF-8",
        # Docker pid storage
        '--cidfile="%s"' % docker_pid_filename,
        # CheckM
        "-v", CHECKM_FOLDER + ":/root/checkm",
        # GTDBtk
        "-v", GTDBTK_FOLDER + ":/root/gtdbtk/db",
        # kofamscan
        "-v", KOFAM_FOLDER + ":/root/kofamscan/db",
        # Peptidase storage
        "-v", PEPTIDASE_DATA_FOLDER + ":/root/Peptidase",
        # Interproscan
        "-v", INTERPROSCAN_FOLDER + ":/root/interproscan-5.32-71.0/data",
        # Volume to access genomes
        "-v", VIRSORTER_DATA_FILDER + ":/root/virsorter-data",
        # Volume to access signalp binary
        "-v", SIGNALP_FOLDER + ":/root/signalp",
        # Volume to access rnammer binary
        "-v", RNAMMER_FOLDER + ":/root/rnammer",
        # Change output directory here
        "-v", os.getcwd() + ":/root/wdir",
        # "-it",
        "--rm",
        DOCKER_IMAGE,
        ap.args.program,
        "-d", os.path.join("/root/wdir", ap.args.directory),
        "-o", os.path.join("/root/wdir", ap.args.output_directory),
        "-c", os.path.join("/root/wdir", ap.args.config_file),
        "-t", ap.args.type_file,
        # Notify that this was called from docker
        "-y",
        # Cancel autocommit from docker
        "-a",
        # Don't remove intermediary files
        "-z"
    ],
    check=True,
)
os.remove(docker_pid_filename)
if not ap.args.cancel_autocommit:
    # Primary output file types from MET_ANNOT (with N = number of genomes):
    # Set project name
    try:
        db_name = (ap.args.biometadb_project 
            if ap.args.biometadb_project != "None" 
            else cfg.get("BIOMETADB", "--db_name"))
    except:
        db_name = "MetagenomeAnnotation"

    dbdm = GetDBDMCall(BIOMETADB, db_name, ap.args.cancel_autocommit, get_added_flags(cfg, "BIOMETADB"))
    # CAZy (1) - out/peptidase_results/combined_results/combined.cazy
    dbdm.run(
        "functions", 
        os.path.join(ap.args.output_directory, "genomes"),
        os.path.join(ap.args.output_directory, "peptidase_results/combined_results/combined.cazy"),
        "functions",
    )
    # MEROPS (1) - out/peptidase_results/combined_results/combined.merops
    dbdm.run(
        "functions", 
        os.path.join(ap.args.output_directory, "genomes"),
        os.path.join(ap.args.output_directory, "peptidase_results/combined_results/combined.merops"),
        "functions",
    )
    # MEROPS pfam (1) - out/peptidase_results/combined_results/combined.merops.pfam
    dbdm.run(
        "functions", 
        os.path.join(ap.args.output_directory, "genomes"),
        os.path.join(ap.args.output_directory, "peptidase_results/combined_results/combined.merops.pfam"),
        "functions",
    )
    # BioData (1) - out/kegg_results/biodata_results/KEGG.final.tsv
    dbdm.run(
        "functions", 
        os.path.join(ap.args.output_directory, "genomes"),
        os.path.join(ap.args.output_directory, "kegg_results/biodata_results/KEGG.final.tsv"), 
        "functions",
    )
    # Begin commit individual genome info
    # Based on file names in metagenome_annotation.list
    genomes_run = (os.path.splitext(os.path.basename(line.rstrip("\r\n")))[0] 
                    for line in open(os.path.join(ap.args.output_directory, "metagenome_annotation.list")))
    for genome_prefix in genomes_run:
        # Virsorter out (N) - out/virsorter_results/*/virsorter-out/*.VIRSorter_adj_out.tsv
        dbdm.run(
            genome_prefix.lower(),
            os.path.join(ap.args.output_directory, "splitfiles", genome_prefix),
            os.path.join(ap.args.output_directory, "virsorter_results", genome_prefix, "virsorter-out", "%s.VIRSorter_adj_out.tsv" % genome_prefix),
            genome_prefix.lower(),
        )
        # Combined Results (N) - out/*.metagenome_annotation.tsv
        dbdm.run(
            genome_prefix.lower(),
            os.path.join(ap.args.output_directory, "splitfiles", genome_prefix),
            os.path.join(ap.args.output_directory, "%s.metagenome_annotation.tsv" % genome_prefix),
            genome_prefix.lower(),
        )
    print("BioMetaDB project complete!")
os.remove(docker_pid_filename)