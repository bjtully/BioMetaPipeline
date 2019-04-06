# cython: language_level=3

import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass

class Prodigal(LuigiTaskClass):
    output_directory_prefix = luigi.Parameter(default="prodigal_results")
    outfile = luigi.Parameter(default="")
    protein_file_suffix = luigi.Parameter(default=".protein")
    mrna_file_suffix = luigi.Parameter(default=".mrna")

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [str(self.calling_script_path),
             "-a",
             os.path.join(str(self.output_directory_prefix),
                          str(os.path.basename(self.outfile)) + str(self.protein_file_suffix)),
             "-d",
             os.path.join(str(self.output_directory_prefix),
                          str(os.path.basename(self.outfile)) + str(self.mrna_file_suffix)),
             "-o",
             os.path.join(str(self.output_directory_prefix), str(self.outfile)),
             *self.added_flags,
             str(self.fasta_folder)],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory))
