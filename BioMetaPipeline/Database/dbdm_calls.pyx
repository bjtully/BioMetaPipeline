import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class DBDM(LuigiTaskClass):
    config_file = luigi.Parameter()


class Init(DBDM):
    db_name = luigi.Parameter(default="DB")
    table_name = luigi.Parameter(default="table")
    directory_name = luigi.Parameter(default=None)
    data_file = luigi.Parameter(default=None)

    def run(self):
        """

        :return:
        """
        subprocess.run(
            [
                "INIT",
                "-n",
                str(self.db_name),
                "-t",
                str(self.table_name),
                "-d",

            ],
            check=True,
        )
