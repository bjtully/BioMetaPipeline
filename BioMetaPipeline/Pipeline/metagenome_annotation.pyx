# cython: language_level=3
import os
import luigi
from BioMetaPipeline.Database.dbdm_calls import Init, Update, BioMetaDBConstants
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.Pipeline.Exceptions.GeneralAssertion import AssertString
from BioMetaPipeline.PipelineManagement.project_manager cimport project_check_and_creation
from BioMetaPipeline.Parsers.sam_to_fastq cimport alignment_to_fastq

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
    cdef list constant_classes = []
    genome_list_path, alias, table_name, cfg = project_check_and_creation(
        <void* >directory,
        <void* >config_file,
        <void* >output_directory,
        <void* >biometadb_project,
        <void* >constant_classes,
        MetagenomeAnnotationConstants
    )