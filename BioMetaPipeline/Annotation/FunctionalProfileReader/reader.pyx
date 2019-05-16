# distutils: language = c++
import os
from reader cimport ProfileReader


"""
Class reads kofamscan results file and functional profiles file
Determines if function is present in kofamscan results

"""


cdef void print_vec(vector[pair[string, string]]& vec):
    cdef size_t i
    for i in range(vec.size()):
        print(vec[i])

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class Reader:
    cdef ProfileReader profile_reader
    cdef ifstream* profile_file
    cdef ifstream* kofam_results_file

    def __init__(self, str kofam_results_file, str profiles_file):
        # Confirm file paths are valid
        if not os.path.exists(kofam_results_file):
            raise FileNotFoundError(kofam_results_file)
        if not os.path.exists(profiles_file):
            raise FileNotFoundError(profiles_file)
        # Dynamically allocate file pointers and save as object members
        self.profile_file = new ifstream(<char *>PyUnicode_AsUTF8(profiles_file))
        self.kofam_results_file = new ifstream(<char *>PyUnicode_AsUTF8(kofam_results_file))
        self.profile_reader = ProfileReader(
            self.profile_file[0],
            self.kofam_results_file[0]
        )

    def __del__(self):
        self.profile_file.close()
        self.kofam_results_file.close()
        del self.profile_file
        del self.kofam_results_file

    def quick_test(self):
        cdef vector[pair[string, string]] results
        self.profile_reader.searchNext(results)
        print_vec(results)
        # self.profile_reader.printKOResults()
