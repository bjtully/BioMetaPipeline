# distutils: language = c++
import os
import luigi
from libcpp.string cimport string
from BioMetaPipeline.Parsers.fasta_parser import FastaParser
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


class MEROPSConstants:
    MEROPS = "MEROPS"
    OUTPUT_DIRECTORY = "merops"
    HMM_FILE = "merops_hmm.list"
    MEROPS_PROTEIN_FILE_SUFFIX = "merops.protein.faa"


class MEROPS(LuigiTaskClass):
    hmm_results = luigi.Parameter()
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    prot_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        # Gather MEROPS gene ids
        cdef set match_ids = set()
        cdef object R = open(str(self.hmm_results), "r")
        cdef str _line
        cdef str delimiter = "#"
        cdef list line
        for _line in R:
            line = _line.split(maxsplit=1)
            if line[0] != delimiter:
                match_ids.add(line[0])
        # Write protein sequences that match MEROPS genes
        cdef str out_file = os.path.join(str(self.output_directory), str(self.outfile))
        FastaParser.write_records(str(self.prot_file), match_ids, out_file)

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
