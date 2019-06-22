# distutils: language = c++
import luigi
from libcpp.string cimport string
from libcpp.vector cimport vector
from collections import defaultdict
from BioMetaPipeline.Parsers.tsv_parser import TSVParser
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


class MEROPSConstants:
    MEROPS = "MEROPS"
    OUTPUT_DIRECTORY = "merops"
    HMM_FILE = "merops_hmm.list"


class MEROPS(LuigiTaskClass):
    hmm_results = luigi.Parameter()
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    suffix = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        pass

    def output(self):
        pass


cdef set extract_MEROPS_genes(str MEROPS_hmm_results):
    """
    
    :param MEROPS_hmm_results: 
    :return: 
    """
    cdef object W = open(MEROPS_hmm_results, "rb")
    cdef set match_ids = set(TSVParser.)
    # Gather MEROPS gene ids

    # Write protein sequences that match MEROPS genes
