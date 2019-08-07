import os
import luigi


class CommitUnannotatedConstants:
    pass


class CommitUnannotated(luigi.Task):
    biometadb_project = luigi.Parameter()
    proteins_directory = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        cdef
    
    def output(self):
        pass
