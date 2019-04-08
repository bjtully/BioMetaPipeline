# distutils: language = c++
from checkm_parser cimport CheckMParser_cpp
from libcpp.vector cimport vector


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class CheckMParser:
    cdef CheckMParser_cpp checkm_parser_cpp

    def __init__(self, str file_name):
        self.checkm_parser_cpp = CheckMParser_cpp(PyUnicode_AsUTF8(file_name))

    def read_file(self):
        self.checkm_parser_cpp.readFile()

    def get_values(self):
        cdef vector[vector[string]] values_in_file = self.checkm_parser_cpp.getValues()
        cdef list return_list = []
        cdef size_t i
        for i in range(values_in_file.size()):
            if values_in_file[i].size() > 0:
                return_list.append([
                    "".join(chr(val) for val in values_in_file[i][0]),
                    float(values_in_file[i][12]),
                    float(values_in_file[i][13]),
                ])
        return return_list
