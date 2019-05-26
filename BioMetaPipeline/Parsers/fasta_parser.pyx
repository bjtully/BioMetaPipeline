# distutils: language = c++
from fasta_parser cimport FastaParser_cpp
from libcpp.vector cimport vector
import os


"""
FastaParser holds logic to call c++ optimized fasta parser

"""


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class FastaParser:
    cdef FastaParser_cpp fasta_parser_cpp
    cdef ifstream* file_pointer
    cdef string file_prefix

    def __init__(self, str file_name, str delimiter, str header):
        if not os.path.isfile(file_name):
            raise FileNotFoundError(file_name)
        # Need as pointer in class object so the pointer is kept open over generator tasks
        self.file_pointer = new ifstream(<char *>PyUnicode_AsUTF8(file_name))
        self.fasta_parser_cpp = FastaParser_cpp(self.file_pointer[0],
                                                <string>PyUnicode_AsUTF8(delimiter),
                                                <string>PyUnicode_AsUTF8(header))

    def __del__(self):
        self.file_pointer.close()
        del self.file_pointer

    def create_tuple_generator(self, bint is_python = False):
        """ Generator function yields tuple of parsed fasta info

        :return:
        """
        cdef vector[string]* record = new vector[string]()
        self.fasta_parser_cpp.grab(record[0])
        cdef int _c
        while (record[0]).size() > 0:
            # Yield tuple of str or string
            if is_python:
                yield (
                    "".join([chr(_c) for _c in record[0][0]]),
                    "".join([chr(_c) for _c in record[0][1]]),
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

    def create_string_generator(self, bint is_python = False, string simplify = ""):
        """ Generator function yields either python or c++ string

        :param simplify:
        :param is_python:
        :return:
        """
        cdef vector[string]* record = new vector[string]()
        cdef string record_name
        self.fasta_parser_cpp.grab(record[0])
        cdef int _c
        cdef int i = 0
        while (record[0]).size() > 0:
            # Yield python str or string
            if simplify == "":
                record_name = record[0][0]
            else:
                record_name = <string>"%s_%d" % (
                    simplify,
                    i
                )
                i += 1
            if is_python:
                yield (
                    "".join([chr(_c) for _c in record_name]),
                    "".join([chr(_c) for _c in record[0][2]]),
                )
            else:
                yield <string>">%s\n%s\n" % (
                    record_name,
                    record[0][2],
                )
            self.fasta_parser_cpp.grab(record[0])
        del record
        return None

    def get_values_as_dict(self):
        """ Get record, by record (as in iterate over file) and return as dict

        :return:
        """
        cdef object record_gen = self.create_tuple_generator(True)
        cdef str val
        cdef tuple record
        cdef dict return_dict = {}
        try:
            while record_gen:
                record = next(record_gen)
                return_dict[record[0]] = (record[1], record[2])
        except StopIteration:
            return return_dict

    def get_values_as_list(self):
        """ Get record, by record (as in iterate over file) and return as list

        :return:
        """
        cdef object record_gen = self.create_tuple_generator(True)
        cdef str val
        cdef list return_list = []
        try:
            while record_gen:
                return_list.append(next(record_gen))
        except StopIteration:
            return return_list

    @staticmethod
    def parse_list(str file_name, str delimiter = " ", str header = ">"):
        """ Static method will return fasta file as list [(id, desc, seq),]

        :param file_name:
        :param delimiter:
        :param header:
        :return:
        """
        return FastaParser(file_name, delimiter, header).get_values_as_list()

    @staticmethod
    def parse_dict(str file_name, str delimiter = " ", str header = ">"):
        """ Static method for creating dictionary from fasta file as id: (desc(no id), seq)

        :param file_name:
        :param delimiter:
        :param header:
        :return:
        """
        return FastaParser(file_name, delimiter, header).get_values_as_dict()

    @staticmethod
    def write_simple(str file_name, str out_file, str delimiter = " ", str header = ">", str simplify = ""):
        """ Method will write a simplified version of a fasta file (e.g. only displays id and sequence)

        :param simplify:
        :param file_name:
        :param out_file:
        :param delimiter:
        :param header:
        :return:
        """
        cdef object fp = FastaParser(file_name, delimiter, header)
        cdef object W = open(out_file, "wb")
        cdef object record_gen = fp.create_string_generator(False, PyUnicode_AsUTF8(simplify))
        try:
            while record_gen:
                W.write(next(record_gen))
        except StopIteration:
            W.close()
