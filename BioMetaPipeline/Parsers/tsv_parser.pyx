# distutils: language = c++
from tsv_parser cimport TSVParser_cpp
from libcpp.vector cimport vector


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef class TSVParser:
    cdef TSVParser_cpp tsv_parser_cpp
    cdef string data_type

    def __init__(self, str file_name, str delimiter="\t", str data_type="python"):
        self.tsv_parser_cpp = TSVParser_cpp(<string>PyUnicode_AsUTF8(file_name), <string>PyUnicode_AsUTF8(delimiter))
        self.data_type = <string>PyUnicode_AsUTF8(data_type)

    def read_file(self, int skip_lines=0, str comment_line_delimiter="#", bint header_line=False):
        """ Method will read file into memore

        :param skip_lines:
        :param comment_line_delimiter:
        :param header_line:
        :return:
        """
        cdef int result = self.tsv_parser_cpp.readFile(skip_lines, <string>PyUnicode_AsUTF8(comment_line_delimiter), header_line)
        if result != 0:
            raise FileNotFoundError

    def get_values(self, tuple col_list=(-1,)):
        """ All values are returned as list

        :param col_list:
        :return:
        """
        cdef vector[vector[string]] values_in_file = self.tsv_parser_cpp.getValues()
        cdef vector[string] val_vec
        cdef size_t i
        cdef unsigned int j
        cdef string val
        # return return_list
        if col_list == (-1,):
            return [
                ["".join([chr(_c) for _c in val]) for val in values_in_file[i]]
                for i in range(values_in_file.size())
                if values_in_file[i].size() > 0
            ]
        return [
                ["".join([chr(_c) for _c in values_in_file[i][j]]) for j in col_list if j < values_in_file[i].size()]
                for i in range(values_in_file.size())
                if values_in_file[i].size() > 0
            ]

    def get_values_as_dict(self, tuple col_list=(-1,)):
        """ All values returned as dict

        :param col_list:
        :return:
        """
        cdef vector[vector[string]] values_in_file = self.tsv_parser_cpp.getValues()
        cdef size_t i
        cdef string val
        # return return_list
        if col_list == (-1,):
            return {"".join([chr(_c) for _c in values_in_file[i][0]]):
                ["".join([chr(_c) for _c in val]) for val in values_in_file[i][1:]]
                for i in range(values_in_file.size())
                if values_in_file[i].size() > 0}
        return {"".join([chr(_c) for _c in values_in_file[i][0]]):
                ["".join([chr(_c) for _c in val]) for val in values_in_file[i][1:]]
                for i in range(values_in_file.size())
                if values_in_file[i].size() > 0 and i in col_list}

    def header(self):
        """ Public method for accessing header

        :return:
        """
        cdef char val
        cdef string header_line
        if self.data_type == "python":
            header_line = self.tsv_parser_cpp.getHeader()
            return "".join([chr(val) for val in header_line])
        return self.tsv_parser_cpp.getHeader()

    @property
    def num_records(self):
        """ Calls size

        :return:
        """
        return self.tsv_parser_cpp.getValues().size()

    @staticmethod
    def parse_dict(str file_name, str delimiter="\t", int skip_lines=0,
                   str comment_line_delimiter="#", bint header_line=False,
                   tuple col_list=(-1,)):
        """ Class method for converting tsv file into dict

        :param file_name:
        :param delimiter:
        :param skip_lines:
        :param comment_line_delimiter:
        :param header_line:
        :param col_list:
        :return:
        """
        tsv = TSVParser(file_name, delimiter)
        tsv.read_file(skip_lines, comment_line_delimiter, header_line)
        return tsv.get_values_as_dict(col_list)

    @staticmethod
    def parse_list(str file_name, str delimiter="\t", int skip_lines=0,
                   str comment_line_delimiter="#", bint header_line=False,
                   tuple col_list=(-1,)):
        """ Class method for converting tsv file into list

        :param file_name:
        :param delimiter:
        :param skip_lines:
        :param comment_line_delimiter:
        :param header_line:
        :param col_list:
        :return:
        """
        tsv = TSVParser(file_name, delimiter)
        tsv.read_file(skip_lines, comment_line_delimiter, header_line)
        return tsv.get_values(col_list)
