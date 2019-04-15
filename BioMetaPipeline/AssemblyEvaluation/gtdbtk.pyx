# cython: language_level=3

import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class GTDBTKConstants:
    GTDBTK = "GTDBTK"
    OUTPUT_DIRECTORY = "gtdbtk_results"
    PREFIX = "GenomeEvaluation"
    BAC_OUTEXT = "_bac120_markers_summary.tsv"
    ARC_OUTEXT = "_ar122_markers_summary.tsv"


class GTDBtk(LuigiTaskClass):
    output_directory = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        """ gtdktk classify_wf --cpus 1 --genome_dir genome_folder
            --out_dir gtdbtk_classifyWF_results

            Function will determine if out_dir is not added externally.
            If not, will use the default value passed with the class

        :return:
        """
        subprocess.run(
            [
                str(self.calling_script_path),
                "classify_wf",
                *self.added_flags,
                "--genome_dir",
                str(self.fasta_folder),
                "--out_dir",
                str(self.output_directory),
                "--prefix",
                str(GTDBTKConstants.GTDBTK)
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(
            os.path.join(self.output_directory, GTDBTKConstants.PREFIX + GTDBTKConstants.BAC_OUTEXT),
        )
