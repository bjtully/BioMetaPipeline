# distutils: language = c++
from BioMetaPipeline.Parsers.fasta_parser import FastaParser
from libcpp.string cimport string


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


def blast_to_fasta(int get_column, tuple coords_columns, str fasta_file, str blast_file, str out_file):
    """ Function will take the results of a blastx search and output corresponding
    fasta records from a file. Must provide the index of the column with id to get as int.
    Must also provide a tuple for the indices of the start/end coordinates.
    
    :param out_file: 
    :param blast_file: 
    :param get_column: 
    :param coords_columns: 
    :param fasta_file: 
    :return: 
    """
    cdef dict fasta_records = FastaParser.parse_dict(fasta_file, is_python=False)
    cdef object W = open(out_file, "wb")
    cdef object _blast_file = open(blast_file, "rb")
    cdef list line
    cdef bytes _line
    cdef tuple record
    for _line in _blast_file:
        line = _line.decode().rstrip("\r\n").split("\t")
        coords = (int(line[coords_columns[0]]), int(line[coords_columns[1]]))
        coords = tuple(sorted(coords))
        # Locate record based on column index and coords tuple passed
        record = fasta_records.get((<string>PyUnicode_AsUTF8(line[get_column])), None)
        if record:
            W.write(<string>">%s\n%s\n" % (
                record[0] + <string>"-%i_%i" % coords,
                (<string>record[1]).substr(coords[0] - 1, coords[1] - coords[0] + 1)
            ))
    W.close()
    _blast_file.close()
