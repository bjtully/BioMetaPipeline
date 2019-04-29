# cython: language_level=3

import luigi
import os
import glob
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Config.config_manager import ConfigManager


class BioMetaDBConstants:
    BIOMETADB = "BIOMETADB"
    DB_NAME = "--db_name"
    TABLE_NAME = "--table_name"
    ALIAS = "--alias"


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
                "python3",
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
        return luigi.LocalTarget(str(self.db_name))


class Update(DBDM):
    def run(self):
        subprocess.run(
            [
                "python3",
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
                "python3",
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


def get_dbdm_call(bint cancel_autocommit, str table_name, str  alias, object cfg, str db_name,
                  str directory_name, str data_file):
    """
    
    :param cancel_autocommit: 
    :param table_name: 
    :param alias: 
    :param cfg: 
    :param db_name: 
    :param directory_name: 
    :param data_file: 
    :return: 
    """
    if not cancel_autocommit:
        if not os.path.exists(db_name):
            return Init(
                db_name=db_name,
                directory_name=directory_name,
                data_file=data_file,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                alias=alias,
                table_name=table_name,
            )
        elif os.path.exists(db_name) and not glob.glob("%s/*/%s.json" % (db_name, table_name)):
            return Create(
                directory_name=directory_name,
                data_file=data_file,
                alias=alias,
                table_name=table_name,
                config_file=db_name,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
            )
        else:
            return Update(
                config_file=db_name,
                directory_name=directory_name,
                data_file=data_file,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                alias=alias,
                table_name=table_name,
            )
    else:
        return None
