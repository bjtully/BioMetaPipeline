# cython: language_level=3
import os
import luigi
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.GeneCaller.prodigal import Prodigal, ProdigalConstants
from BioMetaPipeline.Annotation.interproscan import Interproscan, InterproscanConstants
from BioMetaPipeline.Annotation.virsorter import VirSorter, VirSorterConstants
from BioMetaPipeline.Annotation.prokka import PROKKA, PROKKAConstants
from BioMetaPipeline.Database.dbdm_calls import get_dbdm_call
from BioMetaPipeline.PipelineManagement.project_manager cimport project_check_and_creation

"""
metagenome_annotation consists of:

    Gene Caller
        Prodigal
    Annotation Suites
        Prodigal
        kofamscan
        Interproscan
        PROKKA
        VirSorter
    Parse results
        KEGGDecoder
        BioMetaDB

"""


class MetagenomeAnnotationConstants:
    TABLE_NAME = "metagenome_annotation"
    TSV_OUT = "metagenome_annotation.tsv"
    LIST_FILE = "metagenome_list.list"
    PROJECT_NAME = "MetagenomeAnnotation"


def metagenome_annotation(str directory, str config_file, bint cancel_autocommit, str output_directory,
                          str biometadb_project):
    """ Function calls the pipeline and is run from pipedm

    :param directory:
    :param config_file:
    :param cancel_autocommit:
    :param output_directory:
    :param biometadb_project:
    :return:
    """
    cdef str genome_list_path, alias, table_name, fasta_file, out_prefix
    cdef object cfg
    cdef list constant_classes = [
        ProdigalConstants,
        InterproscanConstants,
        PROKKAConstants,
        VirSorterConstants,
    ]
    genome_list_path, alias, table_name, cfg, biometadb_project = project_check_and_creation(
        <void* >directory,
        <void* >config_file,
        <void* >output_directory,
        biometadb_project,
        <void* >constant_classes,
        MetagenomeAnnotationConstants
    )

    cdef tuple line_data
    cdef bytes line
    cdef list task_list = []
    cdef object W = open(genome_list_path, "rb")
    cdef object task
    line = next(W)
    print("Building task list...")
    while line:
        fasta_file = line.decode().rstrip("\r\n")
        out_prefix = os.path.splitext(os.path.basename(line.decode().rstrip("\r\n")))[0]
        for task in (
            Prodigal(
                output_directory=os.path.join(output_directory, ProdigalConstants.OUTPUT_DIRECTORY),
                fasta_file=fasta_file,
                calling_script_path=cfg.get(ProdigalConstants.PRODIGAL, ConfigManager.PATH),
                outfile=out_prefix,
                run_edit=True,
                added_flags=cfg.build_parameter_list_from_dict(ProdigalConstants.PRODIGAL),
            ),
            Interproscan(
                calling_script_path=cfg.get(InterproscanConstants.INTERPROSCAN, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, InterproscanConstants.OUTPUT_DIRECTORY),
                fasta_file=fasta_file,
                out_prefix=out_prefix,
                added_flags=cfg.build_parameter_list_from_dict(InterproscanConstants.INTERPROSCAN),
            ),
            PROKKA(
                calling_script_path=cfg.get(PROKKAConstants.PROKKA, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY),
                out_prefix=out_prefix,
                fasta_file=fasta_file,
                added_flags=cfg.build_parameter_list_from_dict(PROKKAConstants.PROKKA),
            ),
            VirSorter(
                output_directory=os.path.join(output_directory, VirSorterConstants.OUTPUT_DIRECTORY),
                fasta_file=fasta_file,
                calling_script_path=cfg.get(VirSorterConstants.VIRSORTER, ConfigManager.PATH),
                added_flags=cfg.build_parameter_list_from_dict(VirSorterConstants.VIRSORTER),
            )
        ):
            task_list.append(task)
        try:
            line = next(W)
        except StopIteration:
            break
    task_list.append(get_dbdm_call(
        cancel_autocommit,
        table_name,
        alias,
        cfg,
        biometadb_project,
        directory,
        os.path.join(output_directory, MetagenomeAnnotationConstants.TSV_OUT),
    ))
    luigi.build(task_list, local_scheduler=True)
