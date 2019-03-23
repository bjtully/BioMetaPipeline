# cython: language_level=3

import luigi
import os


class FileOperations(luigi.Task):
    data_files = luigi.ListParameter(default=[])


class Remove(FileOperations):
    def requires(self):
        return []

    def output(self):
        return []

    def run(self):
        cdef str file_name
        for file_name in self.data_files:
            os.remove(file_name)
