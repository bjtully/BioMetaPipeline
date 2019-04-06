# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class FastANIConstants:
    FASTANI = "FASTANI"
    OUTPUT_DIRECTORY = "fastani_results"


class FastANI(LuigiTaskClass):
    outfile = luigi.Parameter(default="fastani_results.txt")
    output_directory = luigi.Parameter()
    listfile_of_fasta_with_paths = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [str(self.calling_script_path),
             *self.added_flags,
             "--ql",
             str(self.listfile_of_fasta_with_paths),
             "--rl",
             str(self.listfile_of_fasta_with_paths),
             "-o",
             os.path.join(str(self.output_directory), str(self.outfile))],
            check=True,
        )
