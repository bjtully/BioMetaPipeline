# cython: language_level=3

import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass

mrna_dir_suffix = ".mrna"
protein_dir_suffix = ".protein"

class Prodigal(LuigiTaskClass):
    output_directory_prefix = luigi.Parameter(default="prodigal_results")
    outfile = luigi.Parameter(default="")
    protein_file_suffix = luigi.Parameter(default="")
    mrna_file_suffix = luigi.Parameter(default="")

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [str(self.calling_script_path),
             *self.added_flags,
             str(self.fasta_folder)],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory))
