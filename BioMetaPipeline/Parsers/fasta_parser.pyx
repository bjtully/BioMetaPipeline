# distutils: language = c++
from fasta_parser cimport FastaParser_cpp
from libcpp.vector cimport vector


"""
FastaParser holds logic to call c++ optimized fasta parser

"""


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class FastaParser:
    cdef FastaParser_cpp fasta_parser_cpp
    cdef ifstream* file_pointer

    def __init__(self, str file_name, str delimiter, str header):
        self.file_pointer = new ifstream(<char *>PyUnicode_AsUTF8(file_name))
        self.fasta_parser_cpp = FastaParser_cpp(self.file_pointer[0],
                                                <string>PyUnicode_AsUTF8(delimiter),
                                                <string>PyUnicode_AsUTF8(header))

    def __del__(self):
        self.file_pointer.close()
        del self.file_pointer

    def yield_as_tuple(self):
        cdef vector[string]* record = new vector[string]()
        self.fasta_parser_cpp.grab(record[0])
        cdef int _c
        while (record[0]).size() > 0:
            yield (
                "".join([chr(_c) for _c in record[0][0]]),
                "".join([chr(_c) for _c in record[0][1]]),
                "".join([chr(_c) for _c in record[0][2]]),
            )
            self.fasta_parser_cpp.grab(record[0])
        del record
        return None

    def yield_simple_record(self, is_python = False):
        """ Yield records as strings

        :return:
        """
        cdef vector[string]* record = new vector[string]()
        self.fasta_parser_cpp.grab(record[0])
        cdef int _c
        while (record[0]).size() > 0:
            if is_python:
                yield (
                "".join([chr(_c) for _c in record[0][0]]),
                "".join([chr(_c) for _c in record[0][2]]),
            )
            else:
                yield <string>">%s\n%s\n" % (
                    record[0][0],
                    record[0][2],
                )
            self.fasta_parser_cpp.grab(record[0])
        del record
        return None

    def get_values_as_dict(self):
        """ Get record, by record (as in iterate over file) and return as dict

        :return:
        """
        cdef object record_gen = self.yield_as_tuple()
        cdef str val
        cdef tuple record
        cdef dict return_dict = {}
        try:
            while record_gen:
                record = next(record_gen)
                return_dict[record[0]] = (record[1], record[2])
        except StopIteration:
            pass
        return return_dict

    def get_values_as_list(self):
        """ Get record, by record (as in iterate over file) and return as list

        :return:
        """
        cdef object record_gen = self.yield_as_tuple()
        cdef str val
        cdef list return_list = []
        try:
            while record_gen:
                return_list.append(next(record_gen))
        except StopIteration:
            pass
        return return_list

    @staticmethod
    def parse_list(str file_name, str delimiter = " ", str header = ">"):
        return FastaParser(file_name, delimiter, header).get_values_as_list()

    @staticmethod
    def parse_dict(str file_name, str delimiter = " ", str header = ">"):
        return FastaParser(file_name, delimiter, header).get_values_as_dict()

    @staticmethod
    def write_simple(str file_name, str out_file, str delimiter = " ", str header = ">"):
        cdef object fp = FastaParser(file_name, delimiter, header)
        cdef object W = open(out_file, "wb")
        cdef object record_iter = fp.yield_simple_record(False)
        try:
            while record_iter:
                W.write(next(record_iter))
        except StopIteration:
            W.close()
