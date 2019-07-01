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
    MEROPS_PFAM_OUTPUT_FILE = "combined.merops.pfam"


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
        cdef str _f, _fi
        cdef object R
        cdef object _file
        cdef bint is_first = True
        cdef list combined_results, files
        for directory, suffix, output_file in self.directories:
            # Assumes that header lines are identical for all files
            if not self.join_header:
                _file = open(os.path.join(str(self.output_directory), output_file), "wb")
                for _f in [_fi for _fi in os.listdir(directory) if os.path.isfile(os.path.join(directory, _fi)) and _fi.endswith(suffix)]:
                    # Write entire contents (for first file written or default)
                    if (self.header_once and is_first) or not self.header_once:
                        _file.write(open(os.path.join(directory, _f), "rb").read())
                        is_first = False
                    # Write contents after first line
                    elif self.header_once and not is_first:
                        R = open(os.path.join(directory, _f), "rb")
                        next(R)
                        _file.write(R.read())
                _file.close()
            # Gathers headers by first lines, minus first value, to write final output.
            else:
                combined_results = []
                files = []
                for _f in [_fi for _fi in os.listdir(directory) if os.path.isfile(os.path.join(directory, _fi)) and _fi.endswith(suffix)]:
                    # Gather tsv info
                    files.append(_fi)
                    combined_results.append(pd.read_csv(os.path.join(directory, _f), delimiter=str(self.delimiter), header=0, index_col=0))
                pd.concat(combined_results, sort=True).to_csv(
                    os.path.join(str(self.output_directory), output_file),
                    sep="\t",
                    na_rep="0",
                    index=files,
                )

    def output(self):
        return [
            luigi.LocalTarget(os.path.join(str(self.output_directory), directory, output_file))
            for directory, suffix, output_file
            in self.directories
        ]
