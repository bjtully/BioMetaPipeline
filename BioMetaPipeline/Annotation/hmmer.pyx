# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class HMMSearchConstants:
    HMMALIGN = "HMMALIGN"
    OUTPUT_DIRECTORY = "hmmalign_results"


class HMMSearch(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    fasta_file = luigi.Parameter()
    hmm_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [
                str(self.calling_script_path),
                "--tblout",
                os.path.join(str(self.output_directory), str(self.outfile)),
                *self.added_flags,
                str(self.hmm_file),
                str(self.fasta_file),
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
