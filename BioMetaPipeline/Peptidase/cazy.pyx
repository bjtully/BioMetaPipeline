# distutils: language = c++
import luigi
import os
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from libcpp.string cimport string
from collections import defaultdict
from libcpp.vector cimport vector


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


class CAZYConstants:
    CAZY = "CAZY"
    OUTPUT_DIRECTORY = "cazy"
    HMM_FILE = "cazy_hmm.list"
    ASSIGNMENTS = "cazy_assignments.tsv"


class CAZY(LuigiTaskClass):
    hmm_results = luigi.Parameter()
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    suffix = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        cdef dict inner_data
        cdef string genome, cazy
        cdef int count
        cdef vector[string] cazy_ids
        cdef object W = open(os.path.join(str(self.output_directory), str(self.outfile)), "wb")
        cdef dict cazy_data = create_cazy_dict(cazy_ids, str(self.hmm_results), str(self.suffix))
        cdef int val
        W.write(<string>"Genome")
        for cazy in cazy_ids:
            W.write(<string>"\t" + cazy.substr(0, cazy.size() - 4))
        W.write(<string>"\n")
        for genome, inner_data in cazy_data.items():
            W.write(genome)
            for cazy in cazy_ids:
                val = cazy_data[genome].get(cazy, 0)
                W.write(<string>(<string>"\t" + <string>PyUnicode_AsUTF8(str(val))))
            W.write(<string>"\n")
        W.close()

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))


cdef dict create_cazy_dict(vector[string]& cazy_ids, str file_name, str suffix):
    cdef object R = open(file_name, "rb")
    cdef string token, _l
    cdef size_t pos = 0
    cdef list line
    cdef string comment_header = "#"
    cdef string delimiter = " "
    cdef bytes _line
    cdef int val
    cdef string cazy_id
    cdef str cazy
    cdef object cazy_dict = defaultdict(dict)
    for _line in R:
        if _line.startswith(bytes(comment_header)):
            continue
        line = _line.decode().rstrip("\r\n").split()
        cazy = line[0].split(suffix)[0]
        cazy_ids.push_back(<string>PyUnicode_AsUTF8(line[2]))
        val = int(cazy_dict[<string>PyUnicode_AsUTF8(cazy)].get(<string>PyUnicode_AsUTF8(line[2]), 0))
        if val != 0:
            cazy_dict[<string>PyUnicode_AsUTF8(cazy)][<string>PyUnicode_AsUTF8(line[2])] += 1
        else:
            cazy_dict[<string>PyUnicode_AsUTF8(cazy)][<string>PyUnicode_AsUTF8(line[2])] = 1
    R.close()
    return <dict>cazy_dict
