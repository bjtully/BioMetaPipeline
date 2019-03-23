# cython: language_level=3

import os
import luigi
import subprocess
from BioMetaPipeline.Accessories.ops import get_prefix
from BioMetaPipeline.DataPreparation.zip import Gunzip


class Dedup(luigi.Task):
    zipped_file = luigi.Parameter()
    calling_script_path = luigi.Parameter()
    added_flags = luigi.ListParameter(default=[])
    output_directory = luigi.Parameter(default=None)

    def requires(self):
        return [Gunzip(self.zipped_file)]


class SingleEnd(Dedup):

    def run(self):
        subprocess.run(
            ["perl",
             self.calling_script_path,
             "-opre",
             os.path.join(self.output_directory or "", get_prefix(self.input()[0].path)),
             str(self.input()[0].path),
             *self.added_flags],
            check=True
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory or "",
            get_prefix(self.input()[0].path) + ".ndupB"))


class PairedEnd(Dedup):

    def run(self):
        subprocess.run(
            ["perl",
             self.calling_script_path,
             "-opre",
             os.path.join(self.output_directory or "", get_prefix(self.input()[0].path)),
             self.input()[0].path,
             self.input()[1].path,
             *self.added_flags],
            check=True
        )

    def output(self):
        return luigi.LocalTarget([
            os.path.join(self.output_directory or "",
            get_prefix(self.input()[0].path)),
            os.path.join(self.output_directory or "",
            get_prefix(self.input()[1].path))
        ])
