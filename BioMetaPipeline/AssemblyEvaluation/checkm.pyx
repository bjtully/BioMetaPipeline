# cython: language_level=3

import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class CheckMConstants:
    CHECKM = "CHECKM"
    OUTPUT_DIRECTORY = "checkm_lineageWF_results"
    OUTFILE = "checkm_lineageWF_results.qa.txt"


class CheckM(LuigiTaskClass):
    outfile = luigi.Parameter(default=CheckMConstants.OUTFILE)
    output_directory = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        """ checkm lineage_wf -x .fna --aai_strain 0.95 -t 10 --pplacer_threads 10 ./genome_folder
            output_directory > checkm_lineageWF_results.qa.txt

        Note that python2 is required to run checkm

        :return:
        """
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        result = subprocess.run(
            [str(self.calling_script_path),
             "lineage_wf",
             *self.added_flags,
             str(self.fasta_folder),
             str(self.output_directory)],
            check=True,
            stdout=open(os.path.join(os.path.dirname(str(self.output_directory)), str(self.outfile)), "w"),
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(os.path.dirname(str(self.output_directory)), str(self.outfile)))
