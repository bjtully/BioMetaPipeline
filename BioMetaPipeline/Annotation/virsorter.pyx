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


class VirSorter(LuigiTaskClass):
    fasta_file = luigi.Parameter()
    wdir = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        if not os.path.exists(str(self.wdir)):
            os.makedirs(str(self.wdir))
        shutil.copy(str(self.fasta_file), str(self.wdir))
        subprocess.run(
            [
                "docker",
                "run",
                "-v",
                "%s:/data" % str(self.calling_script_path),
                "-v",
                "%s:/wdir" % str(self.wdir),
                "-w",
                "/wdir",
                "--rm",
                "simroux/virsorter:v1.0.5",
                "--fna",
                os.path.basename(str(self.fasta_file)),
                *self.added_flags,
            ],
            check=True,
        )
        os.remove(os.path.join(str(self.wdir), os.path.basename(str(self.fasta_file))))
        if not os.listdir(str(self.wdir)):
            os.rmdir(str(self.wdir))

    def output(self):
        if os.path.exists(str(self.wdir)):
            return luigi.LocalTarget(os.path.join(str(self.wdir), os.path.basename(str(self.fasta_file))))
        else:
            return []
