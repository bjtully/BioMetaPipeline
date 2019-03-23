# cython: language_level=3

import os
from BioMetaPipeline.Accessories.config import Config

class ConfigManager:
    """ Class will load config file and determine values for given programs in pipeline based
    on environment values and default settings

    """

    def __init__(self, str config_path, tuple ignore = ()):
        self.config = Config()
        self.config.read(config_path)
        self.ignore = ignore

    def get(self, str _dict, str value):
        """ Gets value from either environment variable or from config file,
        Returns None otherwise

        :param _dict:
        :param value: (str) Value to get from config file
        :return:
        """
        if value != "PATH":
            return os.environ.get(value) or self.config.get(_dict, value)
        try:
            return self.config.get(_dict, value)
        except KeyError:
            return None

    def build_parameter_list_from_dict(self, str _dict, tuple ignore = ()):
        """ Creates list of parameters from given values in given config dict section
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
               and "path" not in key
        ]
        for i in range(len(params)):
            if params[i] != "flags":
                parameter_list.append(params[i])
                parameter_list.append(self.config[_dict][params[i]])
            # Treat values set using FLAGS as a comma-separated list
            else:
                for def_key in self.config[_dict][params[i]].rstrip("\r\n").split(","):
                    parameter_list.append(def_key)
        return parameter_list
