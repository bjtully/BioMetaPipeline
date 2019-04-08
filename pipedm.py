#!/usr/bin/env python3

from BioMetaPipeline.Accessories.arg_parse import ArgParse
from BioMetaPipeline.Accessories.program_caller import ProgramCaller
from BioMetaPipeline.Pipeline.genome_evaluation import genome_evaluation


if __name__ == "__main__":
    args_list = (
        (("program",),
         {"help": "Program to run"}),
        (("-d", "--directory"),
         {"help": "Directory containing genomes", "required": True}),
        (("-c", "--config_file"),
         {"help": "Config file", "required": True}),
        (("-l", "--prefix_file"),
         {"help": "Optional list file formatted as output_prefix\t<file>[\t<file>]\n", "default": "None"}),
        (("-a", "--cancel_autocommit"),
         {"help": "Cancel commit to database", "action": "store_true", "default": False}),
        (("-o", "--output_directory"),
         {"help": "Output directory prefix", "default": "out"}),
    )

    programs = {
        "EVALUATION":          genome_evaluation,

    }

    flags = {
        "EVALUATION":           ("directory", "config_file", "prefix_file", "cancel_autocommit", "output_directory"),
    }

    errors = {

    }

    _help = {
        "EVALUATION":       "Evaluates completion, contamination, and redundancy of genomes"
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