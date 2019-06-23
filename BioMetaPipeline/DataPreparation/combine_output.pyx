# cython: language_level=3
import luigi
import os
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class CombineOutputConstants:
    OUTPUT_DIRECTORY = "combined_results"
    HMM_OUTPUT_FILE = "combined.hmm"
    PROT_OUTPUT_FILE = "combined.protein"
    KO_OUTPUT_FILE = "combined.ko"


class CombineOutput(LuigiTaskClass):
    output_directory = luigi.Parameter()
    directories = luigi.ListParameter()
    header_once = luigi.BoolParameter(default=False)

    def requires(self):
        return []

    def run(self):
        cdef str directory
        cdef str suffix
        cdef str output_file
        cdef object _file
        cdef str _f
        cdef object R
        cdef bint first = True
        for directory, suffix, output_file in self.directories:
            _file = open(os.path.join(str(self.output_directory), output_file), "wb")
            for _f in os.listdir(directory):
                if _f.endswith(suffix):
                    if (self.header_once and first) or not self.header_once:
                        _file.write(open(os.path.join(directory, _f), "rb").read())
                    elif self.header_once and not first:
                        first = True
                        R = open(os.path.join(directory, _f), "rb")
                        next(R)
                        _file.write(R.read())
            _file.close()

    def output(self):
        return [
            luigi.LocalTarget(os.path.join(str(self.output_directory), directory, output_file))
            for directory, suffix, output_file
            in self.directories
        ]
