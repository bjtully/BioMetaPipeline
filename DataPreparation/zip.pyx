# cython: language_level=3

import os
import luigi
import subprocess


class Gunzip(luigi.Task) :
    zipped_file = luigi.Parameter()

    def requires(self):
        return []

    def output(self):
        return luigi.LocalTarget("{}".format(os.path.splitext(self.zipped_file)[0]))

    def run(self):
        subprocess.run(
            ["gunzip", self.zipped_file],
            check=True
        )


class GZip(luigi.Task) :
    unzipped_file = luigi.Parameter()

    def requires(self):
        return []

    def output(self):
        return luigi.LocalTarget("{}.gz".format(os.path.splitext(self.unzipped_file)[0]))

    def run(self):
        subprocess.run(
            ["gzip", self.unzipped_file],
            check=True
        )
