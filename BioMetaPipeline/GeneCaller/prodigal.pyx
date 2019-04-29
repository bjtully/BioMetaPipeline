# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class ProdigalConstants:
    PRODIGAL = "PRODIGAL"
    OUTPUT_DIRECTORY = "prodigal_results"


class Prodigal(LuigiTaskClass):
    output_directory = luigi.Parameter()
    protein_file_suffix = luigi.Parameter(default=".protein")
    mrna_file_suffix = luigi.Parameter(default=".mrna")
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [str(self.calling_script_path),
             "-a",
             os.path.join(str(self.output_directory),
                          str(os.path.splitext(self.outfile)[0]) + str(self.protein_file_suffix)),
             "-d",
             os.path.join(str(self.output_directory),
                          str(os.path.splitext(self.outfile)[0]) + str(self.mrna_file_suffix)),
             "-o",
             os.path.join(str(self.output_directory), str(self.outfile)),
             *self.added_flags,
             "-i",
             str(self.fasta_file)],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
