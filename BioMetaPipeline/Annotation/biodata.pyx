# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class BioDataConstants:
    BIODATA = "BIODATA"
    OUTPUT_DIRECTORY = "biodata_results"

class BioData(LuigiTaskClass):
    output_directory = luigi.Parameter()
    hmmsearch_results = luigi.Parameter()
    outfile = luigi.Parameter()
    fasta_file = luigi.Parameter()
    hmm_file = luigi.Parameter()


    def requires(self):
        return []

    def run(self):
        cdef str decoder_outfile = ""
        cdef str hmmsearch_results = ""
        cdef str expander_outfile = ""
        # Run KEGG-decoder
        subprocess.run(
            [
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
