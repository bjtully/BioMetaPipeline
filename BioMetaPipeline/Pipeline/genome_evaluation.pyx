# cython: language_level=3
import os
import luigi
from BioMetaPipeline.Database.dbdm_calls import Init, Update, BioMetaDBConstants
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.AssemblyEvaluation.checkm import CheckM, CheckMConstants
from BioMetaPipeline.AssemblyEvaluation.gtdbtk import GTDBtk, GTDBTKConstants
from BioMetaPipeline.MetagenomeEvaluation.fastani import FastANI, FastANIConstants
from BioMetaPipeline.Pipeline.Exceptions.GenomeEvaluationExceptions import AssertString
from BioMetaPipeline.MetagenomeEvaluation.redundancy_checker import RedundancyParserTask

"""
GenomeEvaluation wrapper class will yield each of the evaluation steps that are conducted on 
multiple genomes.
After, genome_evaluation function will run through steps called on individual genomes
Finally, a summary .tsv file will be created and used to initialize a BioMetaDB project folder

"""


class GenomeEvaluationConstants:
    GENOME_EVALUATION_TABLE_NAME = "genome_evaluation"
    GENOME_EVALUATION_TSV_OUT = "genome_evaluation.tsv"
    GENOME_LIST_FILE = "genome_list.list"
    GENOME_EVALUATION_PROJECT_NAME = "GenomeEvaluation"


def write_genome_list_to_file(str directory, str outfile):
    """  Function writes

    :param directory:
    :param outfile:
    :return:
    """
    cdef str _file
    cdef object W
    W = open(outfile, "w")
    for _file in os.listdir(directory):
        W.write("%s\n" % os.path.join(directory, _file))
    W.close()


def genome_evaluation(str directory, str config_file, bint cancel_autocommit, str output_directory,
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
    assert os.path.exists(directory) and os.path.exists(config_file), AssertString.INVALID_PARAMETERS_PASSED
    global cfg
    cfg = ConfigManager(config_file)
    if not os.path.exists(output_directory):
        # Output directory
        os.makedirs(output_directory)
        for val in (FastANIConstants, CheckMConstants, GTDBTKConstants):
            os.makedirs(os.path.join(output_directory, str(getattr(val, "OUTPUT_DIRECTORY"))))
        # Temporary storage directory - for list, .tsvs, etc, as needed by calling programs
    cdef str genome_list_path = os.path.join(output_directory, GenomeEvaluationConstants.GENOME_LIST_FILE)
    cdef str _file
    write_genome_list_to_file(directory, genome_list_path)
    if biometadb_project == "None":
        try:
            biometadb_project = cfg.get(BioMetaDBConstants.BIOMETADB, BioMetaDBConstants.DB_NAME)
        except KeyError:
            biometadb_project = "GenomeEvaluation"
    task_list = [
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
            fastANI_output_file=os.path.join(output_directory, FastANIConstants.OUTPUT_DIRECTORY, FastANIConstants.OUTFILE),
            gtdbtk_output_file=os.path.join(output_directory, GTDBTKConstants.OUTPUT_DIRECTORY, GTDBTKConstants.GTDBTK + GTDBTKConstants.BAC_OUTEXT),
            cutoffs_dict=cfg.get_cutoffs(),
            file_ext_dict={os.path.basename(os.path.splitext(file)[0]): os.path.splitext(file)[1]
                           for file in os.listdir(directory)},
            calling_script_path="None",
            outfile=os.path.join(output_directory, GenomeEvaluationConstants.GENOME_EVALUATION_TSV_OUT),
            output_directory=output_directory,
        ),
    ]
    if not cancel_autocommit:
        if not os.path.exists(biometadb_project):
            task_list.append(Init(
                db_name=biometadb_project,
                table_name=GenomeEvaluationConstants.GENOME_EVALUATION_TABLE_NAME,
                directory_name=directory,
                data_file=os.path.join(output_directory, GenomeEvaluationConstants.GENOME_EVALUATION_TSV_OUT),
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
            ))
        else:
            task_list.append(Update(
                config_file=biometadb_project,
                table_name=GenomeEvaluationConstants.GENOME_EVALUATION_TABLE_NAME,
                directory_name=directory,
                data_file=os.path.join(output_directory, GenomeEvaluationConstants.GENOME_EVALUATION_TSV_OUT),
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
            ))
    luigi.build(task_list, local_scheduler=True)
