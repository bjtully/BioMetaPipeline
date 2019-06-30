import os
import luigi
import pandas as pd
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class CombineOutputConstants:
    OUTPUT_DIRECTORY = "combined_results"
    HMM_OUTPUT_FILE = "combined.hmm"
    PROT_OUTPUT_FILE = "combined.protein"
    KO_OUTPUT_FILE = "combined.ko"
    CAZY_OUTPUT_FILE = "combined.cazy"
    MEROPS_OUTPUT_FILE = "combined.merops"



class CombineOutput(LuigiTaskClass):
    output_directory = luigi.Parameter()
    directories = luigi.ListParameter()
    header_once = luigi.BoolParameter(default=False)
    join_header = luigi.BoolParameter(default=False)
    delimiter = luigi.Parameter(default="\t")

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
        cdef object combined_results = pd.DataFrame([])
        for directory, suffix, output_file in self.directories:
            # Assumes that header lines are identical for all files
            if not self.join_header:
                _file = open(os.path.join(str(self.output_directory), output_file), "wb")
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
                _file.close()
            # Gathers headers by first lines, minus first value, to write final output.
            else:
                for _f in os.listdir(directory):
                    # Gather tsv info
                    combined_results.append(pd.read_csv(_f, delimiter=str(self.delimiter)))
                combined_results.to_csv(os.path.join(str(self.output_directory), output_file), sep="\t", na_rep="0")

    def output(self):
        return [
            luigi.LocalTarget(os.path.join(str(self.output_directory), directory, output_file))
            for directory, suffix, output_file
            in self.directories
        ]
