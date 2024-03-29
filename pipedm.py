#!/usr/bin/env python3

from BioMetaPipeline.Accessories.arg_parse import ArgParse
from BioMetaPipeline.Accessories.program_caller import ProgramCaller
from BioMetaPipeline.Pipeline.metagenome_evaluation import metagenome_evaluation
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
        # (("-l", "--list_file"),
        #  {"help": "/path/to/list_file formatted as 'prefix\\tdata_file_1,data_file_2[,...]\\n'"}),
        (("-t", "--type_file"),
         {"help": "/path/to/type_file formatted as 'file_name.fna\\t[Archaea/Bacteria]\\t[gram+/gram-]\\n'",
          "default": "None"}),
        (("-y", "--is_docker"),
         {"help": "For use in docker version", "default": False, "action": "store_true"}),
        (("-z", "--remove_intermediates"),
         {"help": "For use in docker version", "default": True, "action": "store_false"}),

    )

    programs = {
        "MET_EVAL":       metagenome_evaluation,
        # "EU_PAN":         eukaryotic_pangenome,
        "MET_ANNOT":      metagenome_annotation,

    }

    flags = {
        "MET_EVAL":       ("directory", "config_file", "cancel_autocommit", "output_directory",
                           "biometadb_project", "is_docker", "remove_intermediates"),
        # "EU_PAN":         ("directory", "config_file", "cancel_autocommit", "output_directory",
        #                    "biometadb_project", "list_file"),
        "MET_ANNOT":      ("directory", "config_file", "cancel_autocommit", "output_directory",
                           "biometadb_project", "type_file", "is_docker", "remove_intermediates"),
    }

    errors = {

    }

    _help = {
        "MET_EVAL":         "Evaluates completion, contamination, and redundancy of MAGs",
        # "EU_PAN":           "Assembles, aligns, annotates, and creates pan-genomes for Eukaryotes",
        "MET_ANNOT":        "Runs gene callers and annotation programs on MAGs",
    }

    ap = ArgParse(
        args_list,
        description=ArgParse.description_builder(
            "pipedm:\tRun meta/genomes evaluation and annotation pipelines",
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
