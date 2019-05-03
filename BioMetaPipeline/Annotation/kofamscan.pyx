# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class KofamScanConstants:
    pass


class KofamScan(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [
                str(self.calling_script_path),
            ]
        )

    def output(self):
        pass
