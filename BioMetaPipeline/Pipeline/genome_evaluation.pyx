# cython: language_level=3
import os
import luigi
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.GeneCaller.prodigal import Prodigal, ProdigalConstants
from BioMetaPipeline.AssemblyEvaluation.checkm import CheckM, CheckMConstants
from BioMetaPipeline.AssemblyEvaluation.gtdbtk import GTDBtk, GTDBTKConstants
from BioMetaPipeline.MetagenomeEvaluation.fastani import FastANI, FastANIConstants
from BioMetaPipeline.Pipeline.Exceptions.GenomeEvaluationExceptions import AssertString

"""
GenomeEvaluation wrapper class will yield each of the evaluation steps that are conducted on 
multiple genomes.
After, genome_evaluation function will run through steps called on individual genomes
Finally, a summary .tsv file will be created and used to initialize a BioMetaDB project folder

"""


class GenomeEvaluation(luigi.WrapperTask):
    output_directory = luigi.Parameter()
    fasta_folder = luigi.Parameter()
    fasta_listfile = luigi.Parameter()
    config_manager = None
    def requires(self):
        yield CheckM(
            output_directory=os.path.join(str(self.output_directory), CheckMConstants.OUTPUT_DIRECTORY),
            fasta_folder=str(self.fasta_folder),
            added_flags=self.config_manager.build_parameter_list_from_dict(CheckMConstants.CHECKM),
            calling_script_path=self.config_manager.get(CheckMConstants.CHECKM, ConfigManager.PATH),
        )
        yield FastANI(
            output_directory=os.path.join(str(self.output_directory), FastANIConstants.OUTPUT_DIRECTORY),
            added_flags=self.config_manager.build_parameter_list_from_dict(FastANIConstants.FASTANI),
            listfile_of_fasta_with_paths=self.fasta_listfile,
            calling_script_path=self.config_manager.get(FastANIConstants.FASTANI, ConfigManager.PATH),
        )
        # yield GTDBtk(
        #     output_directory=os.path.join(str(self.output_directory), GTDBTKConstants.OUTPUT_DIRECTORY),
        #     added_flags=self.config_manager.build_parameter_list_from_dict(GTDBTKConstants.GTDBTK),
        #     fasta_folder=str(self.fasta_folder),
        #     calling_script_path=self.config_manager.get(GTDBTKConstants.GTDBTK, ConfigManager.PATH),
        # )


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
        W.write("%s\n" % _file)
    W.close()


def genome_evaluation(str directory, str config_file, str prefix_file, bint cancel_autocommit, str output_directory):
    """ Function calls the pipeline for evaluating a set of genomes using checkm, gtdbtk, fastANI
    Creates .tsv file of final output, adds to database

    :param directory:
    :param config_file:
    :param prefix_file:
    :param cancel_autocommit:
    :param output_directory:
    :return:
    """
    assert os.path.exists(directory) and os.path.exists(config_file), AssertString.INVALID_PARAMETERS_PASSED
    cfg = ConfigManager(config_file)
    if not os.path.exists(output_directory):
        # Output directory
        os.makedirs(output_directory)
        # Temporary storage directory - for list, .tsvs, etc, as needed by calling programs
    cdef str genome_list_path = os.path.join(output_directory, "genome_list.list")
    cdef str _file
    write_genome_list_to_file(directory, genome_list_path)
    task_list = [
        GenomeEvaluation(
            output_directory=output_directory,
            fasta_folder=directory,
            config_manager=cfg,
            fasta_listfile=genome_list_path,
        ),
    ]
    for _file in os.listdir(directory):
        task_list.append(Prodigal(
            output_directory=output_directory,
            outfile=_file + ".prodigal.txt",
            fasta_file=_file,
            added_flags=cfg.build_parameter_list_from_dict(ProdigalConstants.PRODIGAL),
        ))

    luigi.build(task_list, local_scheduler=True)
