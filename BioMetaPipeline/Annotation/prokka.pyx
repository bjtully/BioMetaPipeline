# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Parsers.tsv_parser import TSVParser


class PROKKAConstants:
    PROKKA = "PROKKA"
    OUTPUT_DIRECTORY = "prokka_results"
    AMENDED_RESULTS_SUFFIX = ".amended.tsv"


class PROKKA(LuigiTaskClass):
    output_directory = luigi.Parameter()
    out_prefix = luigi.Parameter()
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [
                str(self.calling_script_path),
                "--prefix",
                str(self.out_prefix),
                "--outdir",
                os.path.join(str(self.output_directory), os.path.basename(os.path.splitext(str(self.fasta_file))[0])),
                str(self.fasta_file),
                *self.added_flags,
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), os.path.basename(os.path.splitext(str(self.fasta_file))[0])),
                                 str(self.out_prefix) + ".tsv")


cdef void write_prokka_amended(str prokka_results, str outfile):
    cdef list prokka_data = TSVParser.parse_list(prokka_results)

