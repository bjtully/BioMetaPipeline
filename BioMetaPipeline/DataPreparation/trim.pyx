# cython: language_level=3

import os
import luigi
import subprocess
from BioMetaPipeline.Accessories.ops import get_prefix

class Trim(luigi.Task):
    added_flags = luigi.ListParameter(default=[])
    output_directory = luigi.Parameter(default=None)
    calling_script_path = luigi.Parameter()


class TrimSingle(Trim):
    data_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            ["java", "-jar",
                str(self.calling_script_path),
                "SE",
                str(self.data_file),
                os.path.join(self.output_directory or "", get_prefix(self.data_file) + "_SE.fq"),
                *self.added_flags],
            check=True
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory or "",
                                              get_prefix(self.data_file) + "_SE.fq"))
