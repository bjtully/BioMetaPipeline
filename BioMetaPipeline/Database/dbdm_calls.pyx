# cython: language_level=3

import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class BioMetaDBConstants:
    BIOMETADB = "BIOMETADB"


class DBDM(LuigiTaskClass):
    config_file = luigi.Parameter(default="None")
    db_name = luigi.Parameter(default="DB")
    table_name = luigi.Parameter(default="None")
    directory_name = luigi.Parameter(default="None")
    data_file = luigi.Parameter(default="None")
    alias = luigi.Parameter(default="None")


class Init(DBDM):
    def run(self):
        """

        :return:
        """
        subprocess.run(
            [
                str(self.calling_script_path),
                "INIT",
                "-n",
                str(self.db_name),
                "-t",
                str(self.table_name),
                "-d",
                str(self.directory_name),
                "-f",
                str(self.data_file),
                "-a",
                str(self.alias),
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(str(self.directory_name))


class Update(DBDM):
    def run(self):
        subprocess.run(
            [
                str(self.calling_script_path),
                "UPDATE",
                "-c",
                str(self.config_file),
                "-t",
                str(self.table_name),
                "-a",
                str(self.alias),
                "-f",
                str(self.data_file),
                "-d",
                str(self.directory_name),
            ],
            check=True,
        )


class Create(DBDM):
    def run(self):
        subprocess.run(
            [
                str(self.calling_script_path),
                "CREATE",
                "-c",
                str(self.config_file),
                "-t",
                str(self.table_name),
                "-a",
                str(self.alias),
                "-f",
                str(self.data_file),
                "-d",
                str(self.directory_name),
            ],
            check=True,
        )
