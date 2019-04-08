# distutils: language = c++
from tsv_parser cimport TSVParser_cpp
from libcpp.vector cimport vector


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class TSVParser:
    cdef TSVParser_cpp tsv_parser_cpp

    def __init__(self, str file_name, str delimiter="\t"):
        self.tsv_parser_cpp = TSVParser_cpp(PyUnicode_AsUTF8(file_name), PyUnicode_AsUTF8(delimiter))

    def read_file(self, int skip_lines=0, str comment_line_delimiter="#", bint header_line=False):
        self.tsv_parser_cpp.readFile(skip_lines, PyUnicode_AsUTF8(comment_line_delimiter), header_line)

    def get_values(self):
        cdef vector[vector[string]] values_in_file = self.tsv_parser_cpp.getValues()
        cdef size_t i
        cdef string val
        # return return_list
        return [
            ["".join([chr(_c) for _c in val]) for val in values_in_file[i]]
            for i in range(values_in_file.size())
            if values_in_file[i].size() > 0
        ]

    def header(self):
        return self.tsv_parser_cpp.getHeader()

    @property
    def num_records(self):
        return self.tsv_parser_cpp.getValues().size()
