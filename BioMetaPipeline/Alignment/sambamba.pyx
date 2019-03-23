import os
import luigi
import subprocess
from BioMetaPipeline.Accessories.ops import get_prefix


class Sambamba(luigi.Task):
    calling_script_path = luigi.Parameter()
    output_directory = luigi.Parameter(default=None)
    added_flags = luigi.ListParameter(default=[])


class Sort(Sambamba):
    bam_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [
                self.calling_script_path,
                "sort",
                self.bam_file,
                "-o",
                os.path.join(self.output_directory or "", get_prefix(self.bam_file) + ".sorted.bam"),
                *self.added_flags
            ],
            check=True
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory or "", get_prefix(self.bam_file) + ".sorted.bam"))


class View(Sambamba):
    sam_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [
                self.calling_script_path,
                "view",
                "-S",
                self.sam_file,
                "-f",
                "bam",
                "-o",
                os.path.join(self.output_directory or "", get_prefix(self.sam_file) + ".bam"),
                *self.added_flags
            ],
            check=True
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory or "", get_prefix(self.sam_file) + ".bam"))
