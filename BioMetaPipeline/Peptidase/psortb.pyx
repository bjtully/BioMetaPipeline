# cython: language_level=3
import luigi
import os
import glob
import shutil
import subprocess
from BioMetaPipeline.Accessories.ops import get_prefix
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class PSORTbConstants:
    PSORTB = "PSORTB"
    OUTPUT_DIRECTORY = "psortb_results"


class PSORTb(LuigiTaskClass):
    data_type = luigi.Parameter()
    domain_type = luigi.Parameter()
    prot_file = luigi.Parameter()
    output_directory = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        cdef list data_type_flags
        if str(self.data_type).lower() == "gram+":
            data_type_flags = ["-p",]
        elif str(self.data_type).lower() == "gram-":
            data_type_flags = ["-n",]
        if str(self.domain_type).lower() == "archaea":
            data_type_flags = ["-a",]
        if os.path.exists(str(self.output_directory)):
            shutil.rmtree(str(self.output_directory))
        os.makedirs(str(self.output_directory))
        subprocess.run(
            [
                str(self.calling_script_path),
                *data_type_flags,
                "-i",
                str(self.prot_file),
                "-r",
                str(self.output_directory),
                "-o",
                "terse",
            ],
            check=True,
        )
        # Move results up and rename. Remove docker-created directory and
        shutil.move(
            glob.glob(os.path.join(str(self.output_directory), "*.txt"))[0],
            os.path.join(os.path.dirname(str(self.output_directory)), get_prefix(str(self.prot_file)) + ".tbl")
        )
        shutil.rmtree(str(self.output_directory))

    def output(self):
        return luigi.LocalTarget(os.path.join(os.path.dirname(str(self.output_directory)), get_prefix(str(self.prot_file)) + ".tbl"))