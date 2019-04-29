# cython: language_level=3
import os
import luigi
from BioMetaPipeline.GeneCaller.prodigal import Prodigal, ProdigalConstants
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
    cdef str genome_list_path, alias, table_name
    cdef object cfg
    cdef list constant_classes = [ProdigalConstants,]
    genome_list_path, alias, table_name, cfg = project_check_and_creation(
        <void* >directory,
        <void* >config_file,
        <void* >output_directory,
        <void* >biometadb_project,
        <void* >constant_classes,
        MetagenomeAnnotationConstants
    )

    cdef tuple line_data
    cdef bytes line
    cdef list task_list = []
    cdef object W = open(genome_list_path, "rb")
    line = next(W)
    while line:
        task_list.append(
            Prodigal(
                output_directory=os.path.join(output_directory, ProdigalConstants.OUTPUT_DIRECTORY),
                fasta_file=line.decode().rstrip("\r\n"),
            )
        )
        line = next(W)


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
