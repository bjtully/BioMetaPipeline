# cython: language_level=3

import os
import glob
import luigi
import subprocess
from BioMetaPipeline.Accessories.ops import get_prefix


class Bowtie2(luigi.Task):
    calling_script_path = luigi.Parameter()
    output_directory = luigi.Parameter(default=None)


class Bowtie2Build(Bowtie2):
    reference_fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [
                self.calling_script_path,
                self.reference_fasta_file,
                os.path.join(self.output_directory or "", get_prefix(self.reference_fasta_file) + ".bt_index"),
            ],
            check=True
        )

    def output(self):
        return luigi.LocalTarget([glob.glob(os.path.join(self.output_directory or "",
                                              get_prefix(self.reference_fasta_file) + ".*.bt_index"))])


class Bowtie2Single(Bowtie2):
    data_file = luigi.Parameter()
    index_file = luigi.Parameter()
    added_flags = luigi.ListParameter(default=[])
    output_prefix = luigi.Parameter(default=None)

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [
                self.calling_script_path,
                "-q",  # file is fastq
                "-U",  # file is single
                self.data_file,
                "-S",  # output sam
                os.path.join(self.output_directory or "", (self.output_prefix or get_prefix(self.data_file)) + ".sam"),
                "-x",  # path to index file
                self.index_file,
                *self.added_flags,
            ],
            check=True
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory or "",
                                              (self.output_prefix or get_prefix(self.data_file)) + ".sam"))
