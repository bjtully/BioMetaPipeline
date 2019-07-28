# cython: language_level=3
import os
import glob
import luigi
import shutil
import subprocess
from sys import stderr
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
    is_docker = luigi.BoolParameter()

    def requires(self):
        return []

    def run(self):
        cdef str prot_file
        print("Running PSORTb..........")
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
        # Version was called from docker installation
        if self.is_docker:
            prot_file = os.path.join("/tmp/results", os.path.basename(str(self.prot_file)))
            shutil.copy(str(self.prot_file), str(self.output_directory))
            subprocess.run(
                [
                    "psortb",
                    *data_type_flags,
                    "-o",
                    "terse",
                    prot_file,
                ],
                check=True,
                stdout=os.path.join(str(self.output_directory), "psortb_out"),
            )
            # Move results up and rename. Remove docker-created directory and
            shutil.move(
                os.path.join(str(self.output_directory), "psortb_out"),
                os.path.join(os.path.dirname(str(self.output_directory)), get_prefix(str(self.prot_file)) + ".tbl")
            )
        # Version was called from standalone script
        else:
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
            )
            # Move results up and rename. Remove docker-created directory and
            shutil.move(
                glob.glob(os.path.join(str(self.output_directory), "*.txt"))[0],
                os.path.join(os.path.dirname(str(self.output_directory)), get_prefix(str(self.prot_file)) + ".tbl")
            )
            shutil.rmtree(str(self.output_directory))
        print("PSORTb complete!")

    def output(self):
        return luigi.LocalTarget(os.path.join(os.path.dirname(str(self.output_directory)), get_prefix(str(self.prot_file)) + ".tbl"))