# cython: language_level=3
import luigi
import os
import subprocess
import shutil
from BioMetaPipeline.Accessories.ops import get_prefix
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class VirSorterConstants:
    VIRSORTER = "VIRSORTER"
    OUTPUT_DIRECTORY = "virsorter_results"
    EXPECTED_OUT = "VIRSorter_global_phage_signal.csv"


class VirSorter(LuigiTaskClass):
    output_directory = luigi.Parameter()
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        # VirSorter requires that fasta file be in its own working directory
        cdef wdir = os.path.join(str(self.output_directory), get_prefix(str(self.fasta_file)))
        os.makedirs(wdir)
        shutil.copy(str(self.fasta_file), os.path.join(wdir, str(self.fasta_file)))
        subprocess.run(
            [
                "docker",
                "run",
                "-v",
                str(self.calling_script_path) + ":/data",
                "-v",
                wdir + ":/wdir",
                "-w",
                "/wdir",
                "--rm",
                "simroux/virsorter:v1.0.5",
                "--fna",
                str(self.fasta_file),
                *self.added_flags,
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), VirSorterConstants.EXPECTED_OUT))
