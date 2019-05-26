# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class CombineOutputConstants:
    OUTPUT_DIRECTORY = "combined_results"
    HMM_OUTPUT_FILE = "combined.hmm"
    PROT_OUTPUT_FILE = "combined.protein"
    KO_OUTPUT_FILE = "combined.ko"


class CombineOutput(LuigiTaskClass):
    output_directory = luigi.Parameter()
    directories = luigi.ListParameter()

    def requires(self):
        return []

    def run(self):
        cdef str directory
        cdef str suffix
        cdef str output_file
        cdef object _file
        cdef str _f
        for directory, suffix, output_file in self.directories:
            _file = open(os.path.join(str(self.output_directory), output_file), "w")
            for _f in os.listdir(directory):
                if _f.endswith(suffix):
                    _file.write(open(os.path.join(directory, _f), "r").read())
            _file.close()

    def output(self):
        return [
            luigi.LocalTarget(os.path.join(str(self.output_directory), directory, output_file))
            for directory, suffix, output_file
            in self.directories
        ]
