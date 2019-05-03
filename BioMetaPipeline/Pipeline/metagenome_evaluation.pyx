# cython: language_level=3
import os
import luigi
from BioMetaPipeline.Database.dbdm_calls import get_dbdm_call
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.AssemblyEvaluation.checkm import CheckM, CheckMConstants
from BioMetaPipeline.AssemblyEvaluation.gtdbtk import GTDBtk, GTDBTKConstants
from BioMetaPipeline.MetagenomeEvaluation.fastani import FastANI, FastANIConstants
from BioMetaPipeline.MetagenomeEvaluation.redundancy_checker import RedundancyParserTask
from BioMetaPipeline.PipelineManagement.project_manager cimport project_check_and_creation


"""
genome_evaluation runs CheckM, GTDBtk, fastANI, and parses output into a BioMetaDB project
Uses assembled genomes (.fna)

"""


class MetagenomeEvaluationConstants:
    TABLE_NAME = "metagenome_evaluation"
    TSV_OUT = "metagenome_evaluation.tsv"
    LIST_FILE = "metagenome_list.list"
    PROJECT_NAME = "MetagenomeEvaluation"


def metagenome_evaluation(str directory, str config_file, bint cancel_autocommit, str output_directory,
                      str biometadb_project):
    """ Function calls the pipeline for evaluating a set of genomes using checkm, gtdbtk, fastANI
    Creates .tsv file of final output, adds to database

    :param biometadb_project:
    :param directory:
    :param config_file:
    :param cancel_autocommit:
    :param output_directory:
    :return:
    """
    cdef str genome_list_path, alias, table_name
    cdef object cfg
    cdef list constant_classes = [FastANIConstants, CheckMConstants, GTDBTKConstants]
    cdef object DBDMCall
    genome_list_path, alias, table_name, cfg, biometadb_project = project_check_and_creation(
        <void* >directory,
        <void* >config_file,
        <void* >output_directory,
        biometadb_project,
        <void* >constant_classes,
        MetagenomeEvaluationConstants
    )
    cdef list task_list = [
        CheckM(
            output_directory=os.path.join(output_directory, CheckMConstants.OUTPUT_DIRECTORY),
            fasta_folder=directory,
            added_flags=cfg.build_parameter_list_from_dict(CheckMConstants.CHECKM),
            calling_script_path=cfg.get(CheckMConstants.CHECKM, ConfigManager.PATH),
        ),
        FastANI(
            output_directory=os.path.join(output_directory, FastANIConstants.OUTPUT_DIRECTORY),
            added_flags=cfg.build_parameter_list_from_dict(FastANIConstants.FASTANI),
            listfile_of_fasta_with_paths=genome_list_path,
            calling_script_path=cfg.get(FastANIConstants.FASTANI, ConfigManager.PATH),
        ),
        GTDBtk(
            output_directory=os.path.join(output_directory, GTDBTKConstants.OUTPUT_DIRECTORY),
            added_flags=cfg.build_parameter_list_from_dict(GTDBTKConstants.GTDBTK),
            fasta_folder=directory,
            calling_script_path=cfg.get(GTDBTKConstants.GTDBTK, ConfigManager.PATH),
        ),
        RedundancyParserTask(
            checkm_output_file=os.path.join(output_directory, CheckMConstants.OUTFILE),
            fastANI_output_file=os.path.join(output_directory, FastANIConstants.OUTPUT_DIRECTORY,
                                             FastANIConstants.OUTFILE),
            gtdbtk_output_file=os.path.join(output_directory, GTDBTKConstants.OUTPUT_DIRECTORY,
                                            GTDBTKConstants.GTDBTK + GTDBTKConstants.BAC_OUTEXT),
            cutoffs_dict=cfg.get_cutoffs(),
            file_ext_dict={os.path.basename(os.path.splitext(file)[0]): os.path.splitext(file)[1]
                           for file in os.listdir(directory)},
            calling_script_path="None",
            outfile=os.path.join(output_directory, MetagenomeEvaluationConstants.TSV_OUT),
            output_directory=output_directory,
        ),
    ]
    task_list.append(get_dbdm_call(
        cancel_autocommit,
        table_name,
        alias,
        cfg,
        biometadb_project,
        directory,
        os.path.join(output_directory, MetagenomeEvaluationConstants.TSV_OUT),
    ))
    luigi.build(task_list, local_scheduler=True)
