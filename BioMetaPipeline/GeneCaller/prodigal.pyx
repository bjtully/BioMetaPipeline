# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class ProdigalConstants:
    PRODIGAL = "PRODIGAL"
    OUTPUT_DIRECTORY = "prodigal_results"


class Prodigal(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    protein_file_suffix = luigi.Parameter(default=".protein.faa")
    mrna_file_suffix = luigi.Parameter(default=".mrna.fna")
    fasta_file = luigi.Parameter()
    run_edit = luigi.BoolParameter(default=True)

    def requires(self):
        return []

    def run(self):
        subprocess.run(
            [str(self.calling_script_path),
             "-a",
             os.path.join(str(self.output_directory),
                          str(os.path.splitext(str(self.outfile))[0]) + str(self.protein_file_suffix)),
             "-d",
             os.path.join(str(self.output_directory),
                          str(os.path.splitext(str(self.outfile))[0]) + str(self.mrna_file_suffix)),
             "-o",
             os.path.join(str(self.output_directory), str(self.outfile) + ".txt"),
             *self.added_flags,
             "-i",
             str(self.fasta_file)],
            check=True,
        )
        # Run file edit is needed
        if bool(self.run_edit):
            pass

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)+ ".txt"))
