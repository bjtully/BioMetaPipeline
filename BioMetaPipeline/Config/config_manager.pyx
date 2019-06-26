# cython: language_level=3

import os
from BioMetaPipeline.Config.config import Config
from configparser import NoSectionError

pipelines = {
    "metagenome_annotation": {
        "required": ["PRODIGAL", "HMMSEARCH", "HMMCONVERT", "HMMPRESS", "BIOMETADB", "DIAMOND"],
        "peptidase": ["CAZY", "MEROPS", "SIGNALP", "PSORTB",],
        "kegg": ["KOFAMSCAN", "BIODATA",],
        "prokka": ["PROKKA",],
        "interproscan": ["INTERPROSCAN",],
        "virsorter": ["VIRSORTER",],
    },
    "metagenome_evaluation": {
        "required": ["CHECKM", "FASTANI",],
        "gtdbtk": ["GTDBTK",],
    },
}


class ConfigManager:
    """ Class will load Config file and determine values for given programs in pipeline based
    on environment values and default settings

    """

    PATH = "PATH"
    DATA = "DATA"
    DATA_DICT = "DATA_DICT"

    def __init__(self, str config_path, tuple ignore = (), str pipeline_name = None):
        self.config = Config()
        self.config.optionxform = str
        self.config.read(config_path)
        self.ignore = ignore
        # Check pipeline's required paths/data
        if pipeline_name:
            self.check_pipe_set("required", pipeline_name)

    def get(self, str _dict, str value):
        """ Gets value from either environment variable or from Config file,
        Returns None otherwise

        :param _dict:
        :param value: (str) Value to get from Config file
        :return:
        """
        if value != "PATH":
            return os.environ.get(value) or self.config.get(_dict, value)
        try:
            return self.config.get(_dict, value)
        except KeyError:
            return None

    def build_parameter_list_from_dict(self, str _dict, tuple ignore = ()):
        """ Creates list of parameters from given values in given Config dict section
        Ignores areas set on initialization as well as those passed to this function
        Automatically ignores values with "path" in name

        :param ignore:
        :param _dict:
        :return:
        """
        cdef list parameter_list = []
        cdef str def_key, key
        cdef int i
        cdef list params = [
            key for key in self.config[_dict].keys()
            if key not in ignore
               and key not in self.ignore
               and "PATH" not in key
        ]
        for i in range(len(params)):
            if params[i] != "FLAGS":
                parameter_list.append(params[i])
                parameter_list.append(self.config[_dict][params[i]])
            # Treat values set using FLAGS as a comma-separated list
            else:
                for def_key in self.config[_dict][params[i]].rstrip("\r\n").split(","):
                    def_key = def_key.lstrip(" ").rstrip(" ")
                    parameter_list.append(def_key)
        return parameter_list

    def get_cutoffs(self):
        return dict(self.config["CUTOFFS"])

    def get_added_flags(self, str _dict, tuple ignore = ()):
        """ Method returns FLAGS line from dict in config file

        :param _dict:
        :param ignore:
        :return:
        """
        if "FLAGS" in dict(self.config[_dict]).keys():
            return [def_key.lstrip(" ").rstrip(" ")
                    for def_key in self.config[_dict]["FLAGS"].rstrip("\r\n").split(",")
                    if def_key != ""]
        else:
            return []

    def _validate_programs_in_pipeline(self):
        pass

    def check_pipe_set(self, str pipe, str pipeline_name):
        """ Method checks if all required programs have entries in config file.

        Returns true/false. Does not check validity of programs

        :param pipe:
        :param pipeline_name:
        :return:
        """
        cdef str program, key
        cdef object value, _path
        for program in pipelines[pipeline_name][pipe]:
            # Verify that the [PROGRAM] is present for the given pipe
            try:
                # value has PROGRAM:{key:val} structure
                value = self.config[program]
                # Check PATH, DATA, and DATA_DICT paths
                for key in ("PATH", "DATA", "DATA_DICT"):
                    if key in value.keys() and not os.path.exists(value[key]):
                        print("%s for %s not found" % (key, program))
                        exit(1)
            except NoSectionError:
                return False
            except KeyError:
                return False
        return True
