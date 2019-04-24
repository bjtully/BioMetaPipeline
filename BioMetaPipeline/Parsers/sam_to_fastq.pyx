# distutils: language = c++
# cython: language_level=3
from BioMetaPipeline.Accessories.ops import chunk


CHUNK_SIZE = 10000


class SamtoFastQ:

    def __init__(self, str alignment_file, dict mapping_criteria):
        self.alignment_file = alignment_file
        self.mapping_criteria = mapping_criteria

    def write_fastq(self, str outfile):
        cdef object R = open(self.alignment_file, "rb")
        cdef object W = open(outfile, "w")
        cdef str _line
        cdef list line
        cdef bytes byte_line
        cdef object smaller_chunk
        for smaller_chunk in chunk(R, CHUNK_SIZE):
            for byte_line in smaller_chunk:
                _line = byte_line.decode()
                while _line.startswith("@"):
                    try:
                        _line = next(smaller_chunk).decode()
                    except StopIteration:
                        smaller_chunk = next(chunk(R, CHUNK_SIZE))
                line = _line.rstrip("\r\n").split("\t")
                if int(line[1]) in self.mapping_criteria["FLAG"] and \
                        int(line[4]) >= int(self.mapping_criteria["MAP_QUAL"]):
                    W.write("@%s\n%s\n+\n%s\n" % (line[0], line[9], line[10]))
        W.close()
        R.close()
