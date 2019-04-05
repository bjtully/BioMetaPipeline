# cython: language_level=3

import luigi
import os

class Analysis1(luigi.WrapperTask):
    genome_directory = luigi.DateParameter(default="None")