# cython: language_level=3

import os
from BioMetaPipeline.Config.config import Config


class ConfigManager:
    """ Class will load Config file and determine values for given programs in pipeline based
    on environment values and default settings

    """

    PATH = "PATH"

    def __init__(self, str config_path, tuple ignore = (), bint validate=True):
        self.config = Config()
        self.config.optionxform = str
        self.config.read(config_path)
        self.ignore = ignore
        if validate:
            self._validate_programs_in_pipeline()

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
                    parameter_list.append(def_key)
        return parameter_list

    def get_cutoffs(self):
        return dict(self.config["CUTOFFS"])


