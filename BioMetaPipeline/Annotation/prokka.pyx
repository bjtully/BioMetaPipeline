# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class PROKKAConstants:
    PROKKA = "PROKKA"
    OUTPUT_DIRECTORY = "prokka_results"


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
                str(self.output_directory),
                str(self.fasta_file),
                *self.added_flags,
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"))
