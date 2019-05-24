# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class KofamScanConstants:
    KOFAMSCAN = "KOFAMSCAN"
    OUTPUT_DIRECTORY = "kofamscan_results"


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
                "-o",
                os.path.join(str(self.output_directory), str(self.outfile) + ".tsv"),
                "-f",
                "detail",
                *self.added_flags,
                str(self.fasta_file),
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
