# cython: language_level=3
import luigi
import os
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Parsers.tsv_parser import TSVParser


class CombineOutputConstants:
    OUTPUT_DIRECTORY = "combined_results"
    HMM_OUTPUT_FILE = "combined.hmm"
    PROT_OUTPUT_FILE = "combined.protein"
    KO_OUTPUT_FILE = "combined.ko"


class CombineOutput(LuigiTaskClass):
    output_directory = luigi.Parameter()
    directories = luigi.ListParameter()
    header_once = luigi.BoolParameter(default=False)
    join_header = luigi.BoolParameter(default=False)

    def requires(self):
        return []

    def run(self):
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef str directory
        cdef str suffix
        cdef str output_file
        cdef str _f
        cdef object R
        cdef object _file
        cdef bint is_first = True
        for directory, suffix, output_file in self.directories:
            _file = open(os.path.join(str(self.output_directory), output_file), "wb")
            # Assumes that header lines are identical for all files
            if not self.join_header:
                for _f in os.listdir(directory):
                    # Write entire contents (for first file written or default)
                    if _f.endswith(suffix) and (self.header_once and is_first) or not self.header_once:
                        _file.write(open(os.path.join(directory, _f), "rb").read())
                        is_first = False
                    # Write contents after first line
                    elif _f.endswith(suffix) and self.header_once and not is_first:
                        R = open(os.path.join(directory, _f), "rb")
                        next(R)
                        _file.write(R.read())
            # Gathers headers by first lines, minus first value, to write final output.
            else:
                pass
            _file.close()

    def output(self):
        return [
            luigi.LocalTarget(os.path.join(str(self.output_directory), directory, output_file))
            for directory, suffix, output_file
            in self.directories
        ]
