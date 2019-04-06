# cython: language_level=3
from BioMetaPipeline.Config.config_manager import ConfigManager


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
    pass
