# cython: language_level=3

import luigi
import os
import shutil


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


class Move(FileOperations):
    move_directory = luigi.Parameter()
    prior_directory = luigi.Parameter(default=None)

    def requires(self):
        return []

    def output(self):
        return []

    def run(self):
        cdef str file_name
        for file_name in self.data_files:
            shutil.move(os.path.join(self.prior_directory or "", file_name),
                        os.path.join(self.move_directory, file_name))


class DirectoryManager:

    @staticmethod
    def initialize_dirs(str output_prefix, list programs_in_pipeline):
        """ Method will ensure that all prodigal output directories are created prior to running task

        :param programs_in_pipeline:
        :param output_prefix:
        :return:
        """
        pass

    @staticmethod
    def manage(list list_of_prefixes):
        """ Method will be called after prodigal has completed prediction for individual genome

        :return:
        """
        pass
