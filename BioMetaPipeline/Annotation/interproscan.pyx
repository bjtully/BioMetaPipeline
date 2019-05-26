# cython: language_level=3
import luigi
import os
from BioMetaPipeline.Accessories.ops import get_prefix
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class InterproscanConstants:
    INTERPROSCAN = "INTERPROSCAN"
    OUTPUT_DIRECTORY = "interproscan_results"


class Interproscan(LuigiTaskClass):
    output_directory = luigi.Parameter()
    out_prefix = luigi.Parameter()
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        cdef str outfile_name = os.path.join(str(self.output_directory), get_prefix(str(self.fasta_file)))
        cdef object outfile = open(outfile_name, "w")
        subprocess.run(
            [
                "sed",
                "s/\*//g",
                str(self.fasta_file),
            ],
            check=True,
            stdout=outfile,
        )
        subprocess.run(
            [
                str(self.calling_script_path),
                "-i",
                os.path.abspath(outfile_name),
                "-o",
                os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"),
                "-f",
                "tsv",
                *self.added_flags
            ],
            check=True,
        )
        os.remove(outfile_name)

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"))
