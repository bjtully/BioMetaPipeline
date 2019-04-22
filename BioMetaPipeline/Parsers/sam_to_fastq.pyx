# distutils: language = c++
# cython: language_level=3
from libcpp.vector cimport vector
from libcpp.string cimport string


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)

sam_flag_mappings = {
    0x1:        "PAIRED",
    0x2:        "ALIGNED_PROPER_PAIR",
    0x3:        "UNMAPPED",
}


cdef class SamtoFastQ:
    cdef void* alignment_file
    cdef void* fastq_file
    cdef void* mapping_criteria
    cdef set read_ids

    def __init__(self, str alignment_file, str fastq_file, dict mapping_criteria):
        self.alignment_file = <void* > alignment_file
        self.fastq_file = <void *> fastq_file
        self.mapping_criteria = <void *> mapping_criteria
        self.read_ids = set()
        if (<object>self.alignment_file).split(".")[1] == "bam":
            self.initialize_bam()
        else:
            self.initialize_sam()

    cdef void initialize_bam(self):
        cdef object W = open((<object>self.alignment_file), "rb")
        cdef bytes byte_line
        cdef str _line
        cdef list line
        try:
            for byte_line in W:
                _line = byte_line.decode().rstrip("\r\n")
                while _line.startswith("@"):
                    byte_line = next(W)
                line = byte_line.decode().rstrip("\r\n").split("\t")
                if sam_flag_mappings[line[1].encode("hex")] in (<object>self.mapping_criteria)["FLAG"] and \
                        line[4] >= int((<object>self.mapping_criteria)["MAP_QUAL"]) and \
                        sam_flag_mappings[line[1].encode("hex")] in (<object>self.mapping_criteria)["FLAG"]:
                    self.read_ids.add(PyUnicode_AsUTF8(line[0]))
        except StopIteration:
            return

    cdef void initialize_sam(self):
        cdef object W = open((<object>self.alignment_file), "r")
        cdef str _line
        cdef list line
        try:
            for _line in W:
                _line = _line.rstrip("\r\n")
                while _line.startswith("@"):
                    _line = next(W)
                line = _line.rstrip("\r\n").split("\t")
                if sam_flag_mappings[line[1].encode("hex")] in (<object>self.mapping_criteria)["FLAG"] and \
                        line[4] >= int((<object>self.mapping_criteria)["MAP_QUAL"]) and \
                        sam_flag_mappings[line[1].encode("hex")] in (<object>self.mapping_criteria)["FLAG"]:
                    self.read_ids.add(PyUnicode_AsUTF8(line[0]))
        except StopIteration:
            return

    def write_fastq_reads(self, str fastq_outfile):
        cdef object W = open(fastq_outfile, "w")
        cdef object R = open((<object>self.fastq_file), "r")
        cdef str read_id
        cdef str _line
        for _line in R:
            if _line.startswith("@"):
                if _line[1:-1] in self.read_ids:
                    # Write id
                    W.write(_line)
                    _line = next(R)
                    # Write sequence
                    W.write(_line)
                    _line = next(R)
                    # Write '+'
                    W.write(_line)
                    _line = next(R)
                    # Write quality points
                    W.write(_line)
            else:
                W.write(_line)
                _line = next(R)
        W.close()
        R.close()
