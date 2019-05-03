# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class KEGGDecoderConstants:
    BIODATA = "BIODATA"
    OUTPUT_DIRECTORY = "expander_results"


class KEGGDecoder(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
