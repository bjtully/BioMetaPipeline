# cython: language_level=3

import os


def get_prefix(path):
    """ Function for returning prefix from path

    :param path:
    :return:
    """
    return os.path.splitext(os.path.basename(str(path)))[0]
