#!/usr/bin/env python3

from BioMetaPipeline.Accessories.arg_parse import ArgParse
from BioMetaPipeline.Accessories.program_caller import ProgramCaller
from BioMetaPipeline.Pipeline.genome_evaluation import genome_evaluation
from BioMetaPipeline.Pipeline.eukaryotic_pangenome import eukaryotic_pangenome
from BioMetaPipeline.Pipeline.metagenome_annotation import metagenome_annotation


if __name__ == "__main__":
    args_list = (
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
        (("-l", "--list_file"),
         {"help": "/path/to/list_file formatted as 'prefix\\tdata_file_1,data_file_2[,...]\\n'"}),
    )

    programs = {
        "MET_EVALUATION":           genome_evaluation,
        "EU_PAN":               eukaryotic_pangenome,
        "MET_ANNOTATION":       metagenome_annotation,

    }

    flags = {
        "MET_EVALUATION":       ("directory", "config_file", "cancel_autocommit", "output_directory",
                                 "biometadb_project"),
        "EU_PAN":               ("directory", "config_file", "cancel_autocommit", "output_directory",
                                 "biometadb_project", "list_file"),
        "MET_ANNOTATION":       ("directory", "config_file", "cancel_autocommit", "output_directory",
                                 "biometadb_project"),
    }

    errors = {

    }

    _help = {
        "MET_EVALUATION":       "Evaluates completion, contamination, and redundancy of genomes",
        "EU_PAN":           "Assembles, aligns, annotates, and creates pan-genome for Eukaryotes",
        "MET_ANNOTATION":   "Runs gene callers and annotation programs on MAGs",
    }

    ap = ArgParse(
        args_list,
        description=ArgParse.description_builder(
            "pipedm:\tRun genome evaluation and annotation pipelines",
            _help,
            flags
        )
    )
    pc = ProgramCaller(
        programs=programs,
        flags=flags,
        _help=_help,
        errors=errors
    )
    pc.run(ap.args, debug=True)
