# distutils: language = c++
from fasta_parser cimport FastaParser_cpp
from libcpp.vector cimport vector


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

    def get_values_as_list(self):
        cdef vector[string] record = self.fasta_parser_cpp.get()
        cdef string val
        cdef list return_list = []
        while record.size() > 0:
            return_list.append(">%s %s\n%s\n" % (
                "".join([chr(_c) for _c in record[0]]),
                "".join([chr(_c) for _c in record[1]]),
                "".join([chr(_c) for _c in record[2]]),
            ))
            record = self.fasta_parser_cpp.get()
        return return_list

    def yield_simple_record(self):
        cdef vector[string] record = self.fasta_parser_cpp.get()
        cdef str val
        cdef list return_list = []
        while record.size() > 0:
            yield ">%s\n%s\n" % (
                "".join([chr(_c) for _c in record[0]]),
                "".join([chr(_c) for _c in record[2]]),
            )
            record = self.fasta_parser_cpp.get()
        return None

    def get_values_as_dict(self):
        cdef vector[string] record = self.fasta_parser_cpp.get()
        cdef string val
        cdef dict return_dict = {}
        while record.size() > 0:
            return_dict["".join([chr(_c) for _c in record[0]])] = ">%s %s\n%s\n" % (
                "".join([chr(_c) for _c in record[0]]),
                "".join([chr(_c) for _c in record[1]]),
                "".join([chr(_c) for _c in record[2]]),
            )
            record = self.fasta_parser_cpp.get()
        return return_dict

    @staticmethod
    def parse_list(str file_name, str delimiter = " ", str header = ">"):
        return FastaParser(file_name, delimiter, header).get_values_as_list()

    @staticmethod
    def parse_dict(str file_name, str delimiter = " ", str header = ">"):
        return FastaParser(file_name, delimiter, header).get_values_as_dict()

    @staticmethod
    def write_simple(str file_name, str out_file, str delimeter = " ", str header = ">"):
        fp = FastaParser(file_name, delimeter, header)
        cdef object W = open(out_file, "w")
        cdef string val
        cdef object record = fp.yield_simple_record()
        try:
            while record:
                W.write(next(record))
        except StopIteration:
            pass
        W.close()
