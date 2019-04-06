# cython: language_level=3

import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class GTDBtk(LuigiTaskClass):
    output_directory = luigi.Parameter(default="gtdbtk_classifyWF_results")

    def requires(self):
        return []

    def run(self):
        """ gtdktk classify_wf --cpus 1 --genome_dir genome_folder
            --out_dir gtdbtk_classifyWF_results

            Function will determine if out_dir is not added externally.
            If not, will use the default value passed with the class

        :return:
        """
        calling_process_vals = [str(self.calling_script_path),
             "classify_wf",
             *self.added_flags,
             str(self.fasta_folder)]
        if "--out_dir" not in self.added_flags:
            calling_process_vals.append("--out_dir")
            calling_process_vals.append(self.output_directory)
        subprocess.run(
            calling_process_vals,
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(self.output_directory))
