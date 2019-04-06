# cython: language_level=3
import os
import luigi
from BioMetaPipeline.AssemblyEvaluation.checkm import CheckM
from BioMetaPipeline.Config.config_manager import ConfigManager


class GenomeEvaluation(luigi.WrapperTask):
    output_directory = luigi.Parameter()
    def requires(self):
        yield CheckM()


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
    cfg = ConfigManager(config_file)
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)
    task_list = []
